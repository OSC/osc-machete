require 'minitest/autorun'
require 'osc/machete'

class TestJob < Minitest::Test
  def setup
    @pbsid = '16376372.opt-batch.osc.edu'
  end
  
  def teardown
  end
  
  def test_basic_job
    job = OSC::Machete::Job.new(script: "/path/to/jobdir/main.sh")
    assert_equal job.path.to_s, "/path/to/jobdir"
    assert_equal job.script_name, "main.sh"
  end
  
  def test_job_dependency
    id1 = "16376371.opt-batch.osc.edu"
    id2 = "16376372.opt-batch.osc.edu"
    script = "/tmp/main.sh"
    scriptname = "main.sh"
    
    # create first job
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qsub).with(scriptname).returns(id1)
    job1 = OSC::Machete::Job.new script: script, torque_helper: torque1
    
    # create second job
    torque2 = OSC::Machete::TorqueHelper.new
    torque2.expects(:qsub).with(scriptname, afterany: [id1]).returns(id2)
    job2 = OSC::Machete::Job.new script: script, torque_helper: torque2
    
    job2.afterany job1
    
    job2.submit
    
    assert job1.submitted?, "dependent job not submitted"
    assert job2.submitted?, "job not submitted"
    
    assert_equal id1, job1.pbsid
    assert_equal id2, job2.pbsid
  end
  
  # 
  # def test_job_dependencies
  #   jobpre = newjob
  #   jobs = []
  #   5.times { jobs << newjob(dependent_on: jobpre) }
  #   jobpost = newjob(dependent_on: jobs)
  #   
  #   jobpost.submit
  #   
  #   assert jobpre.submitted?, "pre job not submitted"
  #   assert jobs.all? { |j| j.submitted? }, "jobs after pre before post not submitted"
  #   assert jobpost.submitted?, "post job not submitted"
  # end
end
