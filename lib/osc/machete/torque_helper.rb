require 'pbs'

# == Helper object: ruby interface to torque shell commands
# in the same vein as stdlib's Shell which
# "implements an idiomatic Ruby interface for common UNIX shell commands"
# also helps to have these separate so we can use a mock shell for unit tests
#
# == FIXME: This contains no state whatsoever. It should probably be changed into a module.
class OSC::Machete::TorqueHelper

  def self.default
    self::new()
  end

  def status_for_char(char)
    case char
    when "C", nil
      OSC::Machete::Status.completed
    when "Q", "T", "W" # T W happen before job starts
      OSC::Machete::Status.queued
    when "H"
      OSC::Machete::Status.held
    else
      # all other statuses considerd "running" state
      # including S, E, etc.
      # see http://docs.adaptivecomputing.com/torque/4-1-3/Content/topics/commands/qstat.htm
      OSC::Machete::Status.running
    end
  end

  #*TODO:*
  # consider using cocaine gem
  # consider using Shellwords and other tools

  # return true if script has PBS header specifying Oakley queue
  #def run_on_oakley?(script)
  #  open(script) { |f| f.read =~ /#PBS -q @oak-batch/ }
  #end

  # usage: <tt>qsub("/path/to/script")</tt> or
  #        <tt>qsub("/path/to/script", depends_on: { afterany: ["1234.oak-batch.osc.edu"] })</tt>
  #
  # Where depends_on is a hash with key being dependency type and array containing the
  # arguments. See documentation on dependency_list in qsub man pages for details.
  #
  def qsub(script, depends_on: {})
    # if the script is set to run on Oakley in PBS headers
    # this is to obviate current torque filter defect in which
    # a script with PBS header set to specify oak-batch ends
    # isn't properly handled and the job gets limited to 4GB
    #queue = run_on_oakley?(script) ? "-q @oak-batch.osc.edu" : ""
    #prefix = run_on_oakley?(script) ? ". /etc/profile.d/modules-env.sh && module swap torque torque-4.2.8_vis &&" : ""
    #cmd = "#{prefix} qsub #{queue} #{script}".squeeze(' ')

    #pbs_conn   =   PBS::Conn.batch(host_from_script_pbs_header(script))
    pbs_job    =   get_pbs_job(get_pbs_conn(script: script))

    # add dependencies
    comma=false # FIXME: better name?
    cmd = ""

    depends_on.each do |type, args|
      args = Array(args)

      unless args.empty?
        cmd += comma ? "," : ""
        comma = true

        # type is "afterany" or :afterany
        cmd += type.to_s + ":" + args.join(":")
      end
    end

    cmd.empty? ? pbs_job.submit(file: script, qsub: true).id : pbs_job.submit(file: script, depend: cmd, qsub: true).id
  end

  # Performs a qstat request on a single job.
  #
  # **FIXME: this might not belong here!**
  #
  # @param [String] pbsid The pbsid of the job to inspect.
  #
  # @return [Status] The job state
  def qstat(pbsid)

    pbs_conn   =   get_pbs_conn(pbsid: pbsid)
    pbs_job    =   get_pbs_job(pbs_conn, pbsid)

    # FIXME: handle errors when switching to qstat
    # We need a NULL qstat object (i.e. unknown)
    # when an error occurs. 
    # TODO: Status.unavailable
    status_char = pbs_job.status[:attribs][:job_state] rescue nil
    status_for_char(status_char)
  end

  # Perform a qdel command on a single job.
  #
  # FIXME: Needs Testing on clusters
  # FIXME: Needs Error handling
  #
  # @param [String] pbsid The pbsid of the job to be deleted.
  #
  # @return [Boolean] Returns true.
  def qdel(pbsid)

    #TODO: error handling?
    pbs_conn   =   get_pbs_conn(pbsid: pbsid)
    pbs_job    =   get_pbs_job(pbs_conn, pbsid)

    pbs_job.delete
    true
  end

  # TODO make private
  def get_pbs_job(conn, pbsid=nil)
    pbsid.nil? ? PBS::Job.new(conn: conn) : PBS::Job.new(conn: conn, id: pbsid)
  end

  #TODO make private
  # Returns a PBS connection object
  #
  # @option [:script] A PBS script with headers as string
  # @option [:pbsid] A valid pbsid as string
  #
  # @return [PBS::Conn] A connection option for the PBS host (Default: Oakley)
  def get_pbs_conn(options={})
    if options[:script]
      PBS::Conn.batch(host_from_script_pbs_header(options[:script]))
    elsif options[:pbsid]
      PBS::Conn.batch(host_from_pbsid(options[:pbsid]))
    else
      PBS::Conn.batch("oakley")
    end
  end

  private

    # return the name of the host to use based on the pbs header
    # TODO: Think of a more efficient way to do this.
    def host_from_script_pbs_header(script)
      if (open(script) { |f| f.read =~ /#PBS -q @oak-batch/ })
        "oakley"
      elsif (open(script) { |f| f.read =~ /#PBS -q @opt-batch/ })
        "glenn"
      elsif (open(script) { |f| f.read =~ /#PBS -q @ruby-batch/ })
        "ruby"
      elsif (open(script) { |f| f.read =~ /#PBS -q @quick-batch/ })
        "quick"
      else
        "oakley"  # DEFAULT
      end
    end

    # Return the PBS host string based on a full pbsid string
    def host_from_pbsid(pbsid)
      if (pbsid =~ /oak-batch/ )
        "oakley"
      elsif (pbsid =~ /opt-batch/ )
        "glenn"
      elsif (pbsid =~ /^\d+$/ )
        "ruby"
      elsif (pbsid =~ /quick/ )
        "quick"
      else
        "oakley"  # DEFAULT
      end
    end
end
