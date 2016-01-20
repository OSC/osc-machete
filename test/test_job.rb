require 'minitest/autorun'
require 'osc/machete'

class TestJob < Minitest::Test
  def setup
    @id1 = "16376371.opt-batch.osc.edu"
    @id2 = "16376372.opt-batch.osc.edu"
    
    @jobdir = Pathname.new(Dir.mktmpdir)
    @scriptname = "main.sh"
    @scriptpath = @jobdir.join(@scriptname)
  end
  
  def teardown
    @jobdir.rmtree if @jobdir.exist?
  end
  
  def test_basic_job
    job = OSC::Machete::Job.new(script: @scriptpath)
    assert_equal job.path.to_s, @jobdir.to_s
    assert_equal job.script_name, @scriptname
  end
  
  # test outgoing qsub messages send correct dependency arguments
  # when setting up a job that depends on another job
  def test_job_dependency_afterany
    # create first job and expect qsub to work as it does before
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qsub).with(@scriptname, depends_on: {}, host: nil).returns(@id1)
    job1 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque1
    
    # create second job that depends on the first and expect qsub to send pbsid of the first job
    # which will not be known until the first job qsub-ed and 16376371.opt-batch.osc.edu is returned
    torque2 = OSC::Machete::TorqueHelper.new
    torque2.expects(:qsub).with(@scriptname, depends_on: { afterany: [@id1] }, host: nil).returns(@id2)
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
  def test_job_dependency_afterok
    # create first job and expect qsub to work as it does before
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qsub).with(@scriptname, depends_on: {}, host: nil).returns(@id1)
    job1 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque1

    # create second job that depends on the first and expect qsub to send pbsid of the first job
    # which will not be known until the first job qsub-ed and 16376371.opt-batch.osc.edu is returned
    torque2 = OSC::Machete::TorqueHelper.new
    torque2.expects(:qsub).with(@scriptname, depends_on: { afterok: [@id1] }, host: nil).returns(@id2)
    job2 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque2

    # add the dependency and submit the job
    job2.afterok job1
    job2.submit

    # assertions
    assert job1.submitted?, "dependent job not submitted"
    assert job2.submitted?, "job not submitted"

    assert_equal @id1, job1.pbsid
    assert_equal @id2, job2.pbsid
  end
  
  # here we repeat the above test but when setting up the dependency we chain
  # OSC::Machete::Job.new(...).afterok(...)
  # as long as afterok returns self, chaining will work
  def test_job_dependency_afterok_chaining
    # create first job and expect qsub to work as it does before
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qsub).with(@scriptname, depends_on: {}, host: nil).returns(@id1)
    job1 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque1

    # create second job that depends on the first and expect qsub to send pbsid of the first job
    # which will not be known until the first job qsub-ed and 16376371.opt-batch.osc.edu is returned
    torque2 = OSC::Machete::TorqueHelper.new
    torque2.expects(:qsub).with(@scriptname, depends_on: { afterok: [@id1] }, host: nil).returns(@id2)
    job2 = OSC::Machete::Job.new(script: @scriptpath, torque_helper: torque2).afterok(job1)
    job2.submit
  end
  
  def test_job_dependency_after
    # create first job and expect qsub to work as it does before
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qsub).with(@scriptname, depends_on: {}, host: nil).returns(@id1)
    job1 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque1

    # create second job that depends on the first and expect qsub to send pbsid of the first job
    # which will not be known until the first job qsub-ed and 16376371.opt-batch.osc.edu is returned
    torque2 = OSC::Machete::TorqueHelper.new
    torque2.expects(:qsub).with(@scriptname, depends_on: { after: [@id1] }, host: nil).returns(@id2)
    job2 = OSC::Machete::Job.new script: @scriptpath, torque_helper: torque2

    # add the dependency and submit the job
    job2.after job1
    job2.submit
  end

  def test_job_status
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qstat).with(@id1, {:host => nil}).returns(OSC::Machete::Status.running)
    job = OSC::Machete::Job.new pbsid: @id1, torque_helper: torque1

    assert_equal job.status, OSC::Machete::Status.running

    job = OSC::Machete::Job.new script: @scriptpath
    assert_equal job.status, OSC::Machete::Status.not_submitted
  end
  
  
  def test_job_delete
    # FIXME: the unit tests in this file are not dry...
    # FIXME: rethink the interface: should delete return true if a job was actually deleted?
    
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qdel).with(@id1, host: nil).returns(true)
    job = OSC::Machete::Job.new(script: @scriptpath, pbsid: @id1, torque_helper: torque1)
    job.delete
    assert @jobdir.exist?, "deleting job by default should not deleted the directory too"
    
    torque2 = OSC::Machete::TorqueHelper.new
    torque2.expects(:qdel).with(@id1, host: nil).returns(true)
    job = OSC::Machete::Job.new(script: @scriptpath, pbsid: @id1, torque_helper: torque2)
    job.delete(rmdir: true)
    
    assert ! @jobdir.exist?, "deleting job and specifying rmdir:true should have deleted the directory too"
  end
  
  def test_job_dependency_delete
    torque1 = OSC::Machete::TorqueHelper.new
    torque1.expects(:qdel).with(@id1, host: nil).returns(true)
    torque1.expects(:qdel).with(@id2, host: nil).returns(true)
    job1 = OSC::Machete::Job.new(script: @scriptpath, pbsid: @id1, torque_helper: torque1)
    job2 = OSC::Machete::Job.new(script: @scriptpath, pbsid: @id2, torque_helper: torque1)
    
    job2.afterok job1
    
    # we want to be able to safely delete two jobs that share the same pbs_work_dir and don't
    # want to be able to call rmdir: true on both without worrying that the first one deleted
    # the actual directory so the second might fail
    # both should succeed (if the directory doesn't exist, just ignore that step)
    job1.delete(rmdir: true)
    job2.delete(rmdir: true)
  end
end
