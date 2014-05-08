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
  
  def qsub(script)
    `qsub #{script}`
  end
  
  #TODO: bridge to the python torque lib? is there a ruby torque lib?
  # or external service?
  # 
  # @param pbsid
  # @return results of qstat -x pbsid
  def qstat_xml(pbsid)
    cmd = qstat_cmd
    `#{cmd} #{pbsid} -x` unless qstat_cmd.nil?
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
    Nokogiri::XML(output).xpath('//Data/Job/job_state').children.first.content unless output.empty? || output.nil?
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
