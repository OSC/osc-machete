require 'nokogiri'

# == Helper object: ruby interface to torque shell commands
# in the same vein as stdlib's Shell which 
# "implements an idiomatic Ruby interface for common UNIX shell commands"
# also helps to have these separate so we can use a mock shell for unit tests
# 
# == FIXME: This contains no state whatsoever. It should probably be changed into a module.
class OSC::Machete::TorqueHelper
  
  #*TODO:*
  # consider using cocoaine gem
  # consider using Shellwords and other tools
  
  # return true if script has PBS header specifying Oakley queue
  def run_on_oakley?(script)
    open(script) { |f| f.read =~ /#PBS -q @oak-batch/ }
  end
  
  def qsub(script)
    # if the script is set to run on Oakley in PBS headers
    # this is to obviate current torque filter defect in which
    # a script with PBS header set to specify oak-batch ends
    # isn't properly handled and the job gets limited to 4GB
    queue = run_on_oakley?(script) ? "-q @oak-batch.osc.edu" : ""
    cmd = "qsub #{queue} #{script}".squeeze(' ')
    
    #FIXME if command returns nil, this will crash
    # irb(main):007:0> nil.strip
    # NoMethodError: undefined method `strip' for nil:NilClass
    `#{cmd}`.strip
  end
  
  #TODO: bridge to the python torque lib? is there a ruby torque lib?
  # or external service?
  # 
  # @param pbsid
  # @return results of qstat -x pbsid
  def qstat_xml(pbsid)
    cmd = qstat_cmd
    `#{cmd} #{pbsid} -x` unless cmd.nil?
  end
  
  # **FIXME: this might not belong here!**
  # 
  # @param pbsid
  # @return nil, :Q, :H, :R for job state
  def qstat(pbsid)
    output = qstat_xml pbsid
    output = parse_qstat_output(output) unless output.nil?
    
    output.to_sym unless output.nil?
  end
  
  # **FIXME: this might not belong here!**
  # but not sure whether it should be here, on Job, or somewhere in between
  # 
  # @param output  xml output from qstat -x pbsid
  # @return nil, 'Q', 'H', 'R' for job state
  def parse_qstat_output(output)
    # FIXME: rescue nil - this is potentially recovering from an error silently
    # which is bad
    Nokogiri::XML(output).xpath('//Data/Job/job_state').children.first.content unless output.empty? || output.nil? rescue nil
  end
  
  private
  
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
