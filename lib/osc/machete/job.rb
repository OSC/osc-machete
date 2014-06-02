require 'pathname'
# do we have to do OSC::Appkit:: for every class we create in a gem?
# or can we just have require be inside a module?
class OSC::Machete::Job
  attr_reader :pbsid, :script_path
  
  # Create new job closure
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
  # TODO: Is there ever a situation where this is not the case?
  # If so, we can revert to separate path and script arguments or
  # add special case arguments to handle this situation.
  # 
  # 
  # @param script  full path to script (required)
  # @param pbsid   pbsid of a job already submitted (optional)
  # @param torque_helper  override default torque helper (optional)
  #                       NOTE: used for testing purposes
  #                       we could use it also if we had different
  #                       torque_helper classes for different systems
  def initialize(args)
    @script_path = Pathname.new(args[:script]).cleanpath unless args[:script].nil?
    # @script_path = @script_path.expand_path would change this to absolute path
    
    @pbsid =  args[:pbsid]
    @torque = args[:torque_helper] || OSC::Machete::TorqueHelper.new()
    
    # FIXME: revisit after we design/address how dependencies should really work
    # @dependencies = Array(args[:dependent_on])
    
    # not enough requirements
    # @status = nil
    # @valid = nil
    
    # would you ask System.oakley for the oakley instance of System?
    # or System.glenn for the glenn instance of System?
    # how would we change this to oakley?
    # @system = :oakley
  end
  
  # name of the script
  def script_name
    Pathname.new(@script_path).basename.to_s if @script_path
  end
  
  # path to job directory 
  def path
    Pathname.new(@script_path).dirname if @script_path
  end
  
  #TODO: needs more robust solution here, for error checking, etc.
  def submit
    return if submitted?
    
    # FIXME: revisit after we design/address how dependencies should really work
    # @dependencies.each do |j|
    #   j.submit
    # end
    
    # cd into directory, submit job from there
    # so that PBS_O_WORKDIR is set to location
    # where job is run
    Dir.chdir(path.to_s) do
      @pbsid = @torque.qsub script_name
    end
  end
  
  def submitted?
    ! @pbsid.nil?
  end
  
  def status
    @torque.qstat @pbsid unless @pbsid.nil?
  end
  
  # TODO: moving caching status/workflow into here
  # or keep in other objects outside of Job?
  # def status_as_string(status)
  #   {:Q => "Queued", :H => "Hold", :R => "Running"}.fetch(status, "Completed")
  # end
end
