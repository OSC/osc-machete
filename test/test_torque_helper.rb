require 'minitest/autorun'
require 'osc/machete'
require 'pbs'
require 'mocha/setup'

# test helper class
class TestTorqueHelper < Minitest::Test

  # FIXME:
  #   All of our tests here are broken after updating to PBS
  #   Everything will need to be revisited.
  
  # FIXME:
  # will be replacing with programmatic access to torque
  # however... we should have our tests actually submit tiny jobs on a queue that can respond immediately,
  # run for a minute, and die
  # perhaps using the Oxymoron cluster for this purpose?
  #
  # 2016/01/08  Implemented this in `test_qsub_oakley` and `test_qsub_ruby`. The test only runs when rake
  #             is called on the correct submit host. On all other systems, only the stubs are used.

  def setup

    # FIXME: Torque only works from websvsc02
    #   This raises an issue mentioning that it is not being submitted on the
    #   correct host, comment out the raise to skip the live tests.
    #   Maybe this would be better accomplished with a separate rake task.
    @submit_host = "websvcs02.osc.edu"
    raise "Run this test on the batch system from #{@submit_host}." unless Socket.gethostname == @submit_host

    @job_state_queued = OSC::Machete::Status.queued
    @job_state_completed = OSC::Machete::Status.completed
    @job_state_running = OSC::Machete::Status.running

    @shell = OSC::Machete::TorqueHelper.new

    # test staging using HSP template
    #@params = YAML.load(File.read('test/fixtures/app-params.yml'))
    #@template = 'test/fixtures/app-template'
    #@expected = 'test/fixtures/app-template-rendered'
    
    # directory where to create jobs
    #@target = Dir.mktmpdir
    #@script = 'GLO_job'

    @script_glenn = 'test/fixtures/glenn.sh'
    @script_oakley = 'test/fixtures/oakley.sh'
    @script_ruby = 'test/fixtures/ruby.sh'
  end

  # This tests an actual live workflow by
  #   submitting a job to oakley,
  #   checking it's status, and
  #   deleting it.
  #
  # Only works on the current submit host.
  def test_qsub_oakley

    # Don't run the tests if the host doesn't match.
    if Socket.gethostname == @submit_host

      # Submit a small job.
      live_job = @shell.qsub(@script_oakley)
      assert_match /\d+.oak-batch.osc.edu/, live_job

      # Qstat it to make sure it's queued.
      live_status = @shell.qstat(live_job)
      assert_equal @job_state_queued, live_status

      # Delete it and assert true returned.
      live_delete_status = @shell.qdel(live_job)
      assert_equal true, live_delete_status

    end

  end

  # This tests an actual live workflow by
  #   submitting a job to ruby,
  #   checking it's status, and
  #   deleting it.
  #
  # Only works on the current submit host.
  def test_qsub_ruby

    # Don't run the tests if the host doesn't match.
    if Socket.gethostname == @submit_host

      # Submit a small job.
      live_job = @shell.qsub(@script_ruby)
      assert_match /^\d+$/, live_job

      # Qstat it to make sure it's queued.
      live_status = @shell.qstat(live_job)
      assert_equal @job_state_queued, live_status

      # Delete it and assert true returned.
      live_delete_status = @shell.qdel(live_job)
      assert_equal true, live_delete_status

    end

  end

  # FIXME:  The stubbed qsub tests actually don't tell us much.
  #         Need to figure out how to test the input parameters for PBS::Job.submit

  # Test qstat parameters for completed job.
  def test_qsub_oakley_stub
    PBS::Job.any_instance.stubs(:submit).returns(PBS::Job.new(conn: 'oakley', id: '1234598.oak-batch.osc.edu'))
    assert_equal "1234598.oak-batch.osc.edu", @shell.qsub(@script_oakley)
  end

  # Test job state parser when returning queued
  def test_qsub_ruby_stub
    PBS::Job.any_instance.stubs(:submit).returns(PBS::Job.new(conn: 'ruby', id: '1234598'))
    assert_equal "1234598", @shell.qsub(@script_ruby)
  end
  
  def test_qstat_state_no_job
    # FIXME: Add test
  end

  # Test that qstat returns Running job StatusValue
  def test_qstat_state_running_oakley
    PBS::Job.any_instance.stubs(:status).returns({ :attribs => { :job_state => "R" }})
    assert_equal @job_state_running, @shell.qstat("123.oak-batch.osc.edu")

  end

  # Test that qstat returns Queued job StatusValue
  def test_qstat_state_queued_oakley

    PBS::Job.any_instance.stubs(:status).returns({ :attribs => { :job_state => "Q" }})
    assert_equal @job_state_queued, @shell.qstat("123.oak-batch.osc.edu")

  end

  # Test that qstat returns Queued job StatusValue
  def test_qstat_state_running_ruby

    PBS::Job.any_instance.stubs(:status).returns({ :attribs => { :job_state => "Q" }})
    assert_equal @job_state_queued, @shell.qstat("12398765")

  end

  # Test that qstat returns Completed job StatusValue when state is nil.
  def test_qstat_state_completed_oakley

    PBS::Job.any_instance.stubs(:status).returns({ :attribs => { :job_state => nil }})
    assert_equal @job_state_completed, @shell.qstat("123.oak-batch.osc.edu")
  end

  # Test that qstat returns Completed job when job is nil.
  def test_qstat_state_no_job

    PBS::Job.any_instance.stubs(:status).returns(nil)
    assert_equal @job_state_completed, @shell.qstat("123.oak-batch.osc.edu")
  end

  # Test that qdel works for oakley
  def test_qdel_oakley

    PBS::Job.any_instance.stubs(:delete).returns(true)
    assert_equal true, @shell.qdel("123.oak-batch.osc.edu")

  end

  # Test that qdel works for quick batch
  def test_qdel_quick

    PBS::Job.any_instance.stubs(:delete).returns(true)
    assert_equal true, @shell.qdel("123.quick-batch.osc.edu")

  end

  # Test that qdel works for Ruby cluster
  def test_qdel_ruby

    PBS::Job.any_instance.stubs(:delete).returns(true)
    assert_equal true, @shell.qdel("12365478")
  end

  # Test that qdel returns false on PBS exception
  def test_qdel_oakley

    PBS::Job.any_instance.stubs(:delete).raises(Exception)
    assert_equal false, @shell.qdel("123.quick-batch.osc.edu")

  end
  
  # assert helper method to verify that
  # the provided hash of dependencies to qsub command produces the desired
  # dependency_list string
  # 
  # dependency_list: the desired string to follow  :depend in the pbs command
  # dependencies: the hash to pass as an argument with keyword depends_on: to qsub
  # 
  def assert_qsub_dependency_list(dependency_list, dependencies)

    PBS::Job.any_instance.stubs(:submit)
        .with(:file => 'test/fixtures/glenn.sh', :headers => {:depend => dependency_list}, :qsub => true)
        .returns(PBS::Job.new(conn: 'oakley', id: '16376372.opt-batch.osc.edu'))
    @shell.qsub("test/fixtures/glenn.sh", depends_on: dependencies)

  end
  
  def test_qsub_afterany
    assert_qsub_dependency_list("afterany:1234.oak-batch.osc.edu", { afterany: ["1234.oak-batch.osc.edu"] })
    assert_qsub_dependency_list("afterany:1234.oakbatch.osc.edu", { afterany: "1234.oakbatch.osc.edu" })
    assert_qsub_dependency_list("afterany:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu", { afterany: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
    return true
  end
  

  def test_qsub_afterok
    assert_qsub_dependency_list("afterok:1234.oakbatch.osc.edu", { afterok: ["1234.oakbatch.osc.edu"] })
    assert_qsub_dependency_list("afterok:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu", { afterok: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
    return true
  end
  
  # With multiple dependency types, is formatted:
  #   type[:argument[:argument...][,type:argument...]
  # i.e. 
  #   -W depend=afterany:1234.oakbatch.osc.edu,afterok:2345.oakbatch.osc.edu"
  # 
  # See qsub manpage for details
  def test_qsub_afterok_and_afterany
    assert_qsub_dependency_list("afterany:1234.oakbatch.osc.edu,afterok:2345.oakbatch.osc.edu", { afterany: "1234.oakbatch.osc.edu", afterok: "2345.oakbatch.osc.edu" } )
    return true
  end
  
  def test_qsub_other
    assert_qsub_dependency_list("after:1234.oakbatch.osc.edu", { after: ["1234.oakbatch.osc.edu"] })
    assert_qsub_dependency_list("afternotok:1234.oakbatch.osc.edu:2345.oakbatch.osc.edu", { afternotok: ["1234.oakbatch.osc.edu", "2345.oakbatch.osc.edu"] })
    return true
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
    
    assert_qsub_dependency_list(depencencies_str, dependencies)
    return true
  end
  
end
