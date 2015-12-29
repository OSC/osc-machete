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
  def run_on_oakley?(script)
    open(script) { |f| f.read =~ /#PBS -q @oak-batch/ }
  end

  # return the name of the host to use based on the pbs header
  def run_on_host(script)
    if (open(script) { |f| f.read =~ /#PBS -q @oak-batch/ })
      host = "oakley"
    elsif (open(script) { |f| f.read =~ /#PBS -q @opt-batch/ })
      host = "glenn"
    elsif (open(script) { |f| f.read =~ /#PBS -q @ruby-batch/ })
      host = "ruby"
    elsif (open(script) { |f| f.read =~ /#PBS -q @quick-batch/ })
      host = "quick"
    else
      host = "oakley"  # DEFAULT
    end
    host
  end

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

    pbs_conn   =   PBS::Conn.batch(run_on_host(script))
    pbs_job    =   PBS::Job.new(conn: pbs_conn)

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

    #FIXME if command returns nil, this will crash
    # irb(main):007:0> nil.strip
    # NoMethodError: undefined method `strip' for nil:NilClass
    #`#{cmd}`.strip
    #pbs_job.submit
    cmd.empty? ? pbs_job.submit(string: script, qsub: true).id : pbs_job.submit(string: script, depend: cmd, qsub: true).id
  end

  # Performs a qstat -x command to return the xml output of a job.
  #
  #TODO: bridge to the python torque lib? is there a ruby torque lib?
  # or external service?
  #
  # @param [String] pbsid
  #
  # @return [String] results of qstat -x pbsid
  def qstat_xml(pbsid)
    cmd = qstat_cmd
    # Check if running on Oakley
    prefix = pbsid =~ /oak-batch/ ? ". /etc/profile.d/modules-env.sh && module swap torque torque-4.2.8_vis &&" : ""
    `#{prefix} #{cmd} #{pbsid} -x` unless cmd.nil?
  end

  # Performs a qstat request on a single job.
  #
  # **FIXME: this might not belong here!**
  #
  # @param [String] pbsid The pbsid of the job to inspect.
  #
  # @return [Status] The job state
  def qstat(pbsid)

    output = qstat_xml pbsid
    output = parse_qstat_output(output) unless output.nil?

    # FIXME: handle errors when switching to qstat
    # We need a NULL qstat object (i.e. unknown)
    # when an error occurs. 
    # TODO: Status.unavailable
    status_for_char(output)
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
    #TODO: testing on Oakley?
    #TODO: testing on Glenn?
    #TODO: error handling?
    # Check if running on Oakley
    pbs_conn   =   PBS::Conn.batch("oakley")
    pbs_job    =   PBS::Job.new(conn: pbs_conn, id: pbsid)

    pbs_job.delete

    #prefix = pbsid =~ /oak-batch/ ? ". /etc/profile.d/modules-env.sh && module swap torque torque-4.2.8_vis &&" : ""
    #cmd = "#{prefix} qdel #{pbsid}"
    #`#{cmd}`

    true
  end

  # **FIXME: this might not belong here!**
  # but not sure whether it should be here, on Job, or somewhere in between
  #
  # @param output  xml output from qstat -x pbsid
  # @return [String, nil] nil, 'Q', 'H', 'R' for job state
  def parse_qstat_output(output)
    # FIXME: rescue nil - this is potentially recovering from an error silently
    # which is bad
    Nokogiri::XML(output).xpath('//Data/Job/job_state').children.first.content unless output.empty? || output.nil? rescue nil
  end

  private

  # Creates a pbs job object with the pbsid
  def pbs_job_obj(host, pbsid)
    begin
      c = PBS::Conn.batch host
      q = PBS::Query.new conn: c, type: :job
      q.find(id: pbsid).first
    rescue
      PBS::Job.new(conn: c)
    end
  end

  def cmd_exists?(cmd)
    `/usr/bin/which #{cmd} 2>/dev/null`
    $?.exitstatus == 0
  end

  def qstat_cmd
    $cmd = 'qstat'
    $cmd = '/usr/local/torque-2.4.10/bin/qstat' unless cmd_exists?($cmd)
    $cmd = '/usr/local/torque/2.5.12/bin/qstat' unless cmd_exists?($cmd)
    cmd_exists?($cmd) ? $cmd : nil
  end
end
