require 'minitest/autorun'
require 'osc/machete'

class TestJob < Minitest::Test
  def setup
    @id1 = "16376371.opt-batch.osc.edu"
    @id2 = "16376372.opt-batch.osc.edu"
    
    @scriptpath = "/tmp/main.sh"
    @jobdir = "/tmp"
    @scriptname = "main.sh"
  end
  
  def teardown
  end
  
  def test_basic_job
    job = OSC::Machete::Job.new(script: @scriptpath)
    assert_equal job.path.to_s, @jobdir
    assert_equal job.script_name, @scriptname
  end
  
  # test outgoing qsub messages send correct dependency arguments
  # when setting up a job that depends on another job
  def test_job_dependency_afterany
    # create first job and expect qsub to work as it does before
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qsub).with(@scriptname, depends_on: {}).returns(@id1)
    job1 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque1
    
    # create second job that depends on the first and expect qsub to send pbsid of the first job
    # which will not be known until the first job qsub-ed and 16376371.opt-batch.osc.edu is returned
    torque2 = OSC::Machete::TorqueHelper.new
    torque2.expects(:qsub).with(@scriptname, depends_on: { afterany: [@id1] }).returns(@id2)
    job2 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque2
    
    # add the dependency and submit the job
    job2.afterany job1
    job2.submit
    
    # assertions
    assert job1.submitted?, "dependent job not submitted"
    assert job2.submitted?, "job not submitted"
    
    assert_equal @id1, job1.pbsid
    assert_equal @id2, job2.pbsid
  end
  
  # test outgoing qsub messages send correct dependency arguments
  # when setting up a job that depends on another job
  # def test_job_dependency_afterok
  #   # create first job and expect qsub to work as it does before
  #   torque1 = OSC::Machete::TorqueHelper.new
  #   torque1.expects(:qsub).with(@scriptname).returns(@id1)
  #   job1 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque1
  #   
  #   # create second job that depends on the first and expect qsub to send pbsid of the first job
  #   # which will not be known until the first job qsub-ed and 16376371.opt-batch.osc.edu is returned
  #   torque2 = OSC::Machete::TorqueHelper.new
  #   torque2.expects(:qsub).with(@scriptname, afterok: [@id1]).returns(@id2)
  #   job2 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque2
  #   
  #   # add the dependency and submit the job
  #   job2.afterok job1
  #   job2.submit
  #   
  #   # assertions
  #   assert job1.submitted?, "dependent job not submitted"
  #   assert job2.submitted?, "job not submitted"
  #   
  #   assert_equal @id1, job1.pbsid
  #   assert_equal @id2, job2.pbsid
  # end
end
