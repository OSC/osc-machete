require 'minitest/autorun'
require 'osc/machete'
require 'mocha/setup'

# test helper class
class TestTorqueHelper < Minitest::Test
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
  
  def test_run_on_oakley
    assert @shell.run_on_oakley?('test/fixtures/oakley.sh'), "oakley script not recognized to run on oakley"
    assert ! @shell.run_on_oakley?('test/fixtures/glenn.sh'), "glenn script incorrectly recognized to run on oakley"
  end
  
  def test_qsub_oakley
    # test actual shell command used i.e. in backticks
    @shell.expects(:`).with("qsub -q @oak-batch.osc.edu test/fixtures/oakley.sh").returns("16376372.oak-batch.osc.edu\n")
    @shell.qsub("test/fixtures/oakley.sh")
  end
  
  def test_qsub_glenn
    # test actual shell command used i.e. in backticks
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh")
  end
  
  
  # FIXME: tests for job dependencies seem to have aweful amount of duplication
  # is there a clean way to fix this duplication?
  def test_qsub_afterany
    # test single job dependency as array arg
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=afterany:1234.oakbatch.osc.edu").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: { afterany: ["1234.oakbatch.osc.edu"] })
  end
  
  def test_qsub_afterany_alt
    # test single job dependency as string arg
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=afterany:1234.oakbatch.osc.edu").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: { afterany: "1234.oakbatch.osc.edu" })
  end
  
  def test_qsub_afterany_2
    # test 2 job dependencies as array arg
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=afterany:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: { afterany: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
  end

  def test_qsub_afterok
    # test single job dependency as array arg
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=afterok:1234.oakbatch.osc.edu").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: { afterok: ["1234.oakbatch.osc.edu"] })
  end
  
  def test_qsub_afterok_2
    # test 2 job dependencies as array arg
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=afterok:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: { afterok: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
  end
  
  # With multiple dependency types, is formatted:
  #   type[:argument[:argument...][,type:argument...]
  # i.e. 
  #   -W depend=afterany:1234.oakbatch.osc.edu,afterok:2345.oakbatch.osc.edu"
  # 
  # See qsub manpage for details
  def test_qsub_afterok_and_afterany
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=afterany:1234.oakbatch.osc.edu,afterok:2345.oakbatch.osc.edu").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: { afterany: "1234.oakbatch.osc.edu", afterok: "2345.oakbatch.osc.edu" })
  end
  
  def test_qsub_after
    # test single job dependency as array arg
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=after:1234.oakbatch.osc.edu").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: { after: ["1234.oakbatch.osc.edu"] })
  end
  
  def test_qsub_afternotok
    # test 2 job dependencies as array arg
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=afternotok:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: { afternotok: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
  end
  
  def test_qsub_all_dependencies
    dependencies = {
      afterany: "1234.oakbatch.osc.edu",
      afterok: "2345.oakbatch.osc.edu",
      after: ["2347.oakbatch.osc.edu", "2348.oakbatch.osc.edu"],
      afternotok: ["2349.oakbatch.osc.edu", "2350.oakbatch.osc.edu", "2351.oakbatch.osc.edu"]
    }
    
    depencencies_str = "afterany:1234.oakbatch.osc.edu"
    depencencies_str += ",afterok:2345.oakbatch.osc.edu"
    depencencies_str += ",after:2347.oakbatch.osc.edu:2348.oakbatch.osc.edu"
    depencencies_str += ",afternotok:2349.oakbatch.osc.edu:2350.oakbatch.osc.edu:2351.oakbatch.osc.edu"
    
    @shell.expects(:`).with("qsub test/fixtures/glenn.sh -W depend=#{depencencies_str}").returns("16376372.opt-batch.osc.edu\n")
    @shell.qsub("test/fixtures/glenn.sh", depends_on: dependencies)
  end
  
  # TODO: test when nil is returned from qsub
  # def test_qsub_nil
  #   @shell.expects(:`).returns(nil)
  #   @shell.qsub("test/fixtures/glenn.sh")
  # end
  
end
