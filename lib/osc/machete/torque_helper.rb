require 'pbs'

# == Helper object: ruby interface to torque shell commands
# in the same vein as stdlib's Shell which
# "implements an idiomatic Ruby interface for common UNIX shell commands"
# also helps to have these separate so we can use a mock shell for unit tests
#
# == FIXME: This contains no state whatsoever. It should probably be changed into a module.
class OSC::Machete::TorqueHelper
  # FIXME: Use ood_cluster gem
  LIB = ENV['TORQUE_LIB'] || '/opt/torque/lib64'
  BIN = ENV['TORQUE_BIN'] || '/opt/torque/bin'
  HOSTS = {
    'oakley' => 'oak-batch.osc.edu',
    'ruby'   => 'ruby-batch.osc.edu',
    'quick'  => 'quick-batch.osc.edu',
    'owens'  => 'owens-batch.ten.osc.edu',
    :default => 'oak-batch.osc.edu'
  }

  class << self
    #@!attribute default
    #  @return [TorqueHelper] default TorqueHelper instance to use
    attr_writer :default
    def default
      @default ||= self::new()
    end
  end

  # Returns an OSC::Machete::Status ValueObject for a char
  #
  # @param [String] char The Torque status char
  #
  # @example Passed
  #   status_for_char("C") #=> OSC::Machete::Status.passed
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
  # Bills against the project specified by the primary group of the user.
  def qsub(script, host: nil, depends_on: {}, account_string: nil)
    headers = { depend: qsub_dependencies_header(depends_on) }
    headers.clear if headers[:depend].empty?

    # currently we set the billable project to the name of the primary group
    # this will probably be both SUPERCOMPUTER CENTER SPECIFIC and must change
    # when we want to enable our users at OSC to specify which billable project
    # to bill against
    if account_string
      headers[PBS::ATTR[:A]] = account_string
    elsif account_string_valid_project?(default_account_string)
      headers[PBS::ATTR[:A]] = default_account_string
    end

    pbs(host: host, script: script).submit_script(script, headers: headers, qsub: true)
  end

  # convert dependencies hash to a PBS header string
  def qsub_dependencies_header(depends_on = {})
    depends_on.map { |x|
      x.first.to_s + ":" + Array(x.last).join(":") unless Array(x.last).empty?
    }.compact.join(",")
  end

  # return the account string required for accounting purposes
  # having this in a separate method is useful for monkeypatching in short term
  # or overridding with a subclass you pass into OSC::Machete::Job
  #
  # FIXME: this may belong on OSC::Machete::User; but it is OSC specific...
  #
  # @return [String] the project name that job submission should be billed against
  def default_account_string
    OSC::Machete::Process.new.groupname
  end

  def account_string_valid_project?(account_string)
    /^P./ =~ account_string
  end

  # Performs a qstat request on a single job.
  #
  # **FIXME: this might not belong here!**
  #
  # @param [String] pbsid The pbsid of the job to inspect.
  #
  # @return [Status] The job state
  def qstat(pbsid, host: nil)
    id = pbsid.to_s
    status = pbs(host: host, id: id).get_job(id, filters: [:job_state])
    status_for_char status[id][:job_state][0] # get status from status char value
  rescue PBS::UnkjobidError
    OSC::Machete::Status.passed
  end

  # Perform a qdel command on a single job.
  #
  # @param [String] pbsid The pbsid of the job to be deleted.
  #
  # @return [nil]
  def qdel(pbsid, host: nil)
    id = pbsid.to_s
    pbs(host: host, id: id).delete_job(id)
  rescue PBS::UnkjobidError
    # Common use case where trying to delete a job that is no longer in the system.
  end

  def pbs(host: nil, id: nil, script: nil)
    if host
      # actually check if host is "oakley" i.e. a cluster key
      host = HOSTS.fetch(host.to_s, host.to_s)
    else
      # try to determine host
      key = host_from_pbsid(id) if id
      key = host_from_script_pbs_header(script) if script && key.nil?

      host = HOSTS.fetch(key, HOSTS.fetch(:default))
    end

    pbs = PBS::Batch.new(
      host: host,
      lib: LIB,
      bin: BIN
    )
  end

  private
    # return the name of the host to use based on the pbs header
    # TODO: Think of a more efficient way to do this.
    def host_from_script_pbs_header(script)
      if (File.open(script) { |f| f.read =~ /#PBS -q @oak-batch/ })
        "oakley"
      elsif (File.open(script) { |f| f.read =~ /#PBS -q @ruby-batch/ })
        "ruby"
      elsif (File.open(script) { |f| f.read =~ /#PBS -q @quick-batch/ })
        "quick"
      elsif (File.open(script) { |f| f.read =~ /#PBS -q @owens-batch/ })
        "owens"
      end
    end

    # Return the PBS host string based on a full pbsid string
    def host_from_pbsid(pbsid)
      if (pbsid =~ /oak-batch/ )
        "oakley"
      elsif (pbsid.to_s =~ /^\d+$/ )
        "ruby"
      elsif (pbsid =~ /quick/ )
        "quick"
      elsif (pbsid =~ /owens/ )
        "owens"
      end
    end
end
