require 'pathname'
# do we have to do OSC::Appkit:: for every class we create in a gem?
# or can we just have require be inside a module?
class OSC::Machete::Job
  attr_reader :path, :script, :pbsid
  
  # Create new job closure
  # 
  # Pass these parameters as a hash i.e.
  # 
  #     Job.new(path: '/path/to/job/dir', script: 'go.sh')
  # 
  # or
  # 
  #     opts = Hash.new(path: '/path/to/job/dir', script: 'go.sh')
  #     Job.new(opts)
  # 
  # @param path    full path to the job directory
  # @param script  path/name relative to the job directory
  # 
  def initialize(args)
    # @path = @path.expand_path would change this to absolute path
    
    # FIXME: consider instead of path and script name just an absolute script path
    @path = Pathname.new(args[:path].to_s).cleanpath unless args[:path].nil?
    @script = @path.join(args[:script]).cleanpath unless args[:script].nil?
    @pbsid =  args[:pbsid]
    
    # FIXME: revisit after we design/address how dependencies should really work
    # @dependencies = Array(args[:dependent_on])
    
    @torque = args[:torque_helper] || OSC::Machete::TorqueHelper.new()
    
    # not enough requirements
    # @status = nil
    # @valid = nil
    
    # would you ask System.oakley for the oakley instance of System?
    # or System.glenn for the glenn instance of System?
    # how would we change this to oakley?
    # @system = :oakley
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
    Dir.chdir(@path.to_s) do
      @pbsid = @torque.qsub @script
    end
  end
  
  def submitted?
    ! @pbsid.nil?
  end
  
  def status
    @torque.qstat @pbsid unless @pbsid.nil?
  end
  
  # Should we make a status object?
  # def status_as_string(status)
  #   {:Q => "Queued", :H => "Hold", :R => "Running"}.fetch(status, "Completed")
  # end
  
  # pbsid should have form 1903909.oak-batch or 1903909.opt-batch
  # should job store a cached status var on this? or is caching 
  # the responsibility of other objects?
  # def status
  # end
  # 
  # def running_queued_or_held?
  # end
  # 
  # def submitted?
  #   ! @pbsid.nil?
  # end
  # 
  # def completed?
  # end
  # 
  # def failed?
  # end
  # 
  # # either extend job to override this method or pass in a validator class
  # def valid_results?
  #   true
  # end
  # 
  # 
  # private
  # 
  # def update_status
  # end
end
