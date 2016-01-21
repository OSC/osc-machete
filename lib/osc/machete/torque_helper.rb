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

  # Returns an OSC::Machete::Status ValueObject for a char
  #
  # @param [String] :char The Torque status char
  #
  # @example Completed
  #   status_for_char("C") #=> OSC::Machete::Status.completed
  # @example Queued
  #   status_for_char("W") #=> OSC::Machete::Status.queued
  #
  # @return [OSC::Machete::Status] The status corresponding to the char
  def status_for_char(char)
    case char
    when "C", nil
      OSC::Machete::Status.passed
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
  def qsub( script, host: nil, depends_on: {})
    # if the script is set to run on Oakley in PBS headers
    # this is to obviate current torque filter defect in which
    # a script with PBS header set to specify oak-batch ends
    # isn't properly handled and the job gets limited to 4GB
    pbs_job = get_pbs_job( host.nil? ? get_pbs_conn(script: script) : get_pbs_conn(host: host) )

    # add dependencies
    cmd = depends_on.map { |x|
      x.first.to_s + ":" + Array(x.last).join(":") unless Array(x.last).empty?
    }.compact.join(",")

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
  def qstat(pbsid, host: nil)

    # Create a PBS::Job object based on the pbsid or the optional host param
    pbs_conn = host.nil? ? get_pbs_conn(pbsid: pbsid.to_s) : get_pbs_conn(host: host)
    pbs_job = get_pbs_job(pbs_conn, pbsid)

    job_status = pbs_job.status
    # Get the status char value from the job.
    status_for_char job_status[:attribs][:job_state][0]
  rescue PBS::Error => err
    if err.to_s.include?("Unknown Job Id Error")
      # Common use-case, job with this pbsid is no longer in the system.
      OSC::Machete::Status.passed
    else
      raise err
    end
  end

  # Perform a qdel command on a single job.
  #
  # @param [String] pbsid The pbsid of the job to be deleted.
  #
  # @return [nil]
  def qdel(pbsid, host: nil)

    pbs_conn   =   host.nil? ? get_pbs_conn(pbsid: pbsid.to_s) : get_pbs_conn(host: host)
    pbs_job    =   get_pbs_job(pbs_conn, pbsid.to_s)

    pbs_job.delete

  rescue PBS::Error => err
    # Common use case where trying to delete a job that is no longer in the system.
    # FIXME: This error could also happen when the string is wildly incorrect.
    #        We may want to return false after this exception is caught and true
    #        above. Any unexpected errors will continue to be passed up the chain.
    #        These methods may be used by developers independently of the job model
    #        and should probably provide a response.
    #        PBS::Job#delete returns nil
    raise err unless err.to_s.include?("Unknown Job Id Error")
  end

  private

    # Factory to return a PBS::Job object
    def get_pbs_job(conn, pbsid=nil)
      pbsid.nil? ? PBS::Job.new(conn: conn) : PBS::Job.new(conn: conn, id: pbsid.to_s)
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
      elsif options[:host]
        PBS::Conn.batch(options[:host])
      else
        PBS::Conn.batch("oakley")
      end
    end

    # return the name of the host to use based on the pbs header
    # TODO: Think of a more efficient way to do this.
    def host_from_script_pbs_header(script)
      if (File.open(script) { |f| f.read =~ /#PBS -q @oak-batch/ })
        "oakley"
      elsif (File.open(script) { |f| f.read =~ /#PBS -q @opt-batch/ })
        "glenn"
      elsif (File.open(script) { |f| f.read =~ /#PBS -q @ruby-batch/ })
        "ruby"
      elsif (File.open(script) { |f| f.read =~ /#PBS -q @quick-batch/ })
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
      elsif (pbsid.to_s =~ /^\d+$/ )
        "ruby"
      elsif (pbsid =~ /quick/ )
        "quick"
      else
        "oakley"  # DEFAULT
      end
    end
end
