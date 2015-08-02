require 'pathname'


# Core object for working with batch jobs, including:
#
# * submitting jobs
# * checking job status
# * setting dependencies between jobs via a directed acyclic graph
#
# Create a new Job from a script:
#
#     job = Job.new(script: '/nfs/17/efranz/jobs/1/script.sh')
#     job.submitted? #=> false
#     job.path #=> '/nfs/17/efranz/jobs/1'
#     job.script_name #=> 'script.sh'
#     job.status #=> nil
#     job.pbsid #=> nil
#
#     # PBS_O_WORKDIR will be set to the directory containing the script
#     job.submit
#
#     job.submitted? #=> true
#     job.status #=> "Q"
#     job.pbsid #=> "3422735.oak-batch"
#
#     # if you know the pbs id you can instantiate a
#     # Job object to ask for the status of it
#     job2 = Job.new(pbsid: "3422735.oak-batch")
#     job2.status #=> "Q"
#
#     # because the object was created with only the pbsid passed in,
#     # path and script_name and dependency information is not available
#     job2.path #=> nil
#     job2.script_name #=> nil
#
#     # but an unknown pbsid results in status nil
#     job3 = Job.new(pbsid: "12345.oak-batch")
#     job3.status #=> nil
#
# Create two Job instances and form a dependency between them:
#
#     job1 = Job.new(script: '/nfs/17/efranz/jobs/1/script.sh')
#     job2 = Job.new(script: '/nfs/17/efranz/jobs/1/post.sh')
#
#     job2.afterany(job1) # job2 runs after job1 completes with any exit status
#
#     job1.submit
#     job2.submit
#
#     job1.status #=> "Q"
#     job2.status #=> "H"
#
# @!attribute [r] pbsid 
#   @return [String, nil] the PBS job id, or nil if not set
# @!attribute [r] script_path 
#   @return [String, nil] path of the job script, or nil if not set
#
class OSC::Machete::Job
  attr_reader :pbsid, :script_path

  # Create Job instance to represent an unsubmitted batch job from the specified
  # script, or an existing, already submitted batch job from the specified pbsid
  #
  # Takes params in options hash as single argument:
  #
  #     Job.new(script: '/path/to/job/dir/go.sh')
  #
  # or
  #
  #     opts = Hash.new(script: '/path/to/job/dir/go.sh')
  #     Job.new(opts)
  #
  # Job class makes assumption that a job's PBS_O_WORKDIR will be
  # in the directory containing the shell script that is run. 
  #
  # @param [Hash] args the arguments to create the job
  # @option args [String] :script  full path to script (optional)
  # @option args [String, nil] :pbsid   pbsid of a job already submitted (optional)
  # @option args [TorqueHelper, nil]  :torque_helper  override default torque helper (optional)
  #                       NOTE: used for testing purposes
  #                       we could use it also if we had different
  #                       torque_helper classes for different systems
  def initialize(args)
    @script_path = Pathname.new(args[:script]).cleanpath unless args[:script].nil?
    # @script_path = @script_path.expand_path would change this to absolute path

    @pbsid =  args[:pbsid]
    @torque = args[:torque_helper] || OSC::Machete::TorqueHelper.new()

    @dependencies = {} # {:afterany => [Job, Job], :afterok => [Job]}
  end

  # @return [String, nil] script name or nil if instance wasn't initialized with a script
  def script_name
    Pathname.new(@script_path).basename.to_s if @script_path
  end

  # @return [String, nil] job directory or nil if instance wasn't initialized with a script
  def path
    Pathname.new(@script_path).dirname if @script_path
  end

  # Submit any dependent jobs that haven't been submitted
  # then submit this job, specifying dependencies as required by Torque.
  # Submitting includes cd-ing into the script's directory and qsub-ing from
  # that location, ensuring that environment variable PBS_O_WORKDIR is
  # set to the directory containing the script.
  def submit
    return if submitted?

    #TODO: needs more robust solution here, for error checking, etc.

    # submit any dependent jobs that have not yet been submitted
    submit_dependencies

    # cd into directory, submit job from there
    # so that PBS_O_WORKDIR is set to location
    # where job is run
    #
    #TODO: you can set PBS_O_WORKDIR via qsub args, is this necessary? there is
    # another env var besides PBS_O_WORKDIR that is affected by the path of the
    # current directory when the job is submitted
    #
    #TODO: what if you want to submit via piping to qsub i.e. without creating a file?
    Dir.chdir(path.to_s) do
      @pbsid = @torque.qsub script_name, depends_on: dependency_ids
    end
  end

  # @return [Boolean] true if @pbsid is set
  def submitted?
    ! @pbsid.nil?
  end

  # @return [String, nil] character representation of status such as "H", "Q", "R" or nil if not in the system
  def status
    # FIXME: this method returns nil in two different cases for 2 different reasons
    # 1. @pbsid is nil
    # 2. qstat returns nil because qstat's output returned ""
    # a solution to this problem is switching to using a StatusValue object.
    # Then TorqueHelper#qstat will always return a StatusValue object (never nil)
    @torque.qstat @pbsid unless @pbsid.nil?
  end

  # Ensure Job starts only after the specified Job(s) complete
  #
  # @param [Job, Array<Job>] jobs Job(s) that this Job should depend on (wait for)
  # @return [self] self so you can chain method calls
  def afterany(jobs)
    add_dependencies(:afterany, jobs)
  end

  # Ensure Job starts only after the specified Job(s) complete with successful
  # return value.
  #
  # @param (see #afterany)
  # @return (see #afterany)
  def afterok(jobs)
    add_dependencies(:afterok, jobs)
  end

  # Ensure Job starts only after the specified Job(s) start.
  #
  # @param (see #afterany)
  # @return (see #afterany)
  def after(jobs)
    add_dependencies(:after, jobs)
  end

  # Ensure Job starts only after the specified Job(s) complete with error
  # return value.
  #
  # @param (see #afterany)
  # @return (see #afterany)
  def afternotok(jobs)
    add_dependencies(:afternotok, jobs)
  end

  # Kill the currently running batch job
  #
  # @param [Boolean] rmdir (false) if true, recursively remove the containing directory of the job script if killing the job succeeded
  # @return [nil]
  def delete(rmdir: false)
    # FIXME: rethink this interface... should qdel be idempotent? 
    # After first call, no errors thrown after?

    if pbsid && @torque.qdel(pbsid)
      # FIXME: removing a directory is always a dangerous action.
      # I wonder if we can add more tests to make sure we don't delete
      # something if the script name is munged

      # recursively delete the directory after killing the job
      Pathname.new(path).rmtree if path && rmdir && File.exists?(path)
    end
  end

  private

  def submit_dependencies
    #  assumes each dependency is a Job object
    @dependencies.values.flatten.each { |j| j.submit }
  end

  # build a dictionary of ids for each dependency type
  def dependency_ids
    ids = {}

    @dependencies.each do |type, jobs|
      ids[type] = jobs.map(&:pbsid).compact
    end

    ids.keep_if { |k,v| ! v.empty? }
  end

  def add_dependencies(type, jobs)
    @dependencies[type] = [] unless @dependencies.has_key?(type)
    @dependencies[type].concat(Array(jobs))

    self
  end
end
