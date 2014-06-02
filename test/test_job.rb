require 'minitest/autorun'
require 'osc/machete'

class TestJob < Minitest::Test
  def setup
    @pbsid = '16376372.opt-batch.osc.edu'
  end
  
  def teardown
  end
  
  def newjob(args = {})
    # verifies each job is submitted at most one time
    # and stubs qsub to return pbsid without actually qsubing job
    torque = OSC::Machete::TorqueHelper.new
    torque.expects(:qsub).returns(@pbsid).at_most_once
    job = OSC::Machete::Job.new(args.merge(:torque_helper => torque))
  end
  
  def test_simple_job
    job = newjob(script: "/path/to/jobdir/main.sh")
    assert_equal job.path.to_s, "/path/to/jobdir"
    assert_equal job.script_name, "main.sh"
  end
  
  # FIXME: these break because now jobs need a proper path
  # and we cd into them prior to running
  # 
  # revisit after we address how dependencies should really work
  # def test_job_dependency
  #   job1 = newjob
  #   job2 = newjob(dependent_on: job1)
  #   
  #   job2.submit
  #   assert job1.submitted?, "dependent job not submitted"
  #   assert job2.submitted?, "job not submitted"
  # end
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
