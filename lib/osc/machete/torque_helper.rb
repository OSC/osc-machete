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
    pbs_job    =   get_pbs_job(get_pbs_conn(script: script))

    comma=false # FIXME: better name?
    # add dependencies
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
    headers = cmd.empty? ? {} : { depend: cmd }

    pbs_job.submit(file: script, headers: headers, qsub: true).id
  end

  # Performs a qstat request on a single job.
  #
  # **FIXME: this might not belong here!**
  #
  # @param [String] pbsid The pbsid of the job to inspect.
  #
  # @return [Status] The job state
  def qstat(pbsid)

    pbs_job    =   get_pbs_job(get_pbs_conn(pbsid: pbsid), pbsid)

    # We need a NULL qstat object (i.e. unknown)
    # when an error occurs. 
    # TODO: Status.unavailable
    status_for_char(job_state(pbs_job))
  end

  # Perform a qdel command on a single job.
  #
  # @param [String] pbsid The pbsid of the job to be deleted.
  #
  # @return [Boolean] Returns true if successfully deleted.
  def qdel(pbsid)

    pbs_conn   =   get_pbs_conn(pbsid: pbsid)
    pbs_job    =   get_pbs_job(pbs_conn, pbsid)

    pbs_job.delete
    true

  rescue
    false
  end

  private

    # Get the char of the status from the PBS Job object.
    def job_state(job)
      job.status[:attribs][:job_state] rescue nil
    end

    # Factory to return a PBS::Job object
    def get_pbs_job(conn, pbsid=nil)
      pbsid.nil? ? PBS::Job.new(conn: conn) : PBS::Job.new(conn: conn, id: pbsid)
    end

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
