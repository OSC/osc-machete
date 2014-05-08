require 'minitest/autorun'
require 'osc/machete'
require 'mocha/setup'

# test helper class
class TestTorqueHelper < MiniTest::Unit::TestCase
  def setup
    @xml = '<Data><Job><Job_Id>16376372.opt-batch.osc.edu</Job_Id><Job_Name>stage.pbs.sh</Job_Name><Job_Owner>efranz@websvcs06.osc.edu</Job_Owner><job_state>Q</job_state><queue>serial</queue><server>opt-batch.osc.edu:15001</server><Checkpoint>u</Checkpoint><ctime>1386618379</ctime><Error_Path>websvcs06.osc.edu:/nfs/17/efranz/crimson_files/EweldPredictor/11/stage.pbs.error</Error_Path><Hold_Types>n</Hold_Types><Join_Path>n</Join_Path><Keep_Files>n</Keep_Files><Mail_Points>a</Mail_Points><mtime>1386618379</mtime><Output_Path>websvcs06.osc.edu:/nfs/17/efranz/crimson_files/EweldPredictor/11/stage.pbs.output</Output_Path><Priority>0</Priority><qtime>1386618379</qtime><Rerunable>True</Rerunable><Resource_List><arch>x86_64</arch><nodect>1</nodect><nodes>1:ppn=8</nodes><walltime>10:00:00</walltime></Resource_List><Shell_Path_List>/bin/sh</Shell_Path_List><Variable_List>PBS_O_HOME=/nfs/17/efranz,PBS_O_LANG=C,PBS_O_LOGNAME=root,PBS_O_PATH=/sbin:/usr/sbin:/bin:/usr/bin,PBS_O_MAIL=/var/spool/mail/epi,PBS_O_SHELL=/bin/bash,PBS_SERVER=opt-batch:15001,PBS_O_WORKDIR=/nfs/17/efranz/crimson_files/EweldPredictor/11,PBS_O_QUEUE=batch,PBS_O_HOST=websvcs06.osc.edu</Variable_List><etime>1386618379</etime><submit_args>-S /bin/sh stage.pbs.sh</submit_args><Walltime><Remaining>3600</Remaining></Walltime><fault_tolerant>False</fault_tolerant></Job></Data>'
    @job_state = :Q
    @shell = OSC::Machete::TorqueHelper.new
    
    @shell.stubs(:qstat_xml).returns(@xml)
    
    # test staging using HSP template
    @params = YAML.load(File.read('test/fixtures/app-params.yml'))
    @template = 'test/fixtures/app-template'
    @expected = 'test/fixtures/app-template-rendered'
    
    # directory where to create jobs
    @target = Dir.mktmpdir
    @script = 'GLO_job'
  end
  
  def test_qstat_state_job_avail
    @shell.stubs(:qstat_xml).returns(@xml)
    assert_equal @job_state, @shell.qstat('16376372.opt-batch.osc.edu')
  end
  
  def test_qstat_state_no_job
    @shell.stubs(:qstat_xml).returns("")
    assert_nil @shell.qstat('16376372.opt-batch.osc.edu')
  end
end
