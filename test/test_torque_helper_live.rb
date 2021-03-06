require 'minitest/autorun'
require 'osc/machete'
require 'pbs'
require 'mocha/setup'
require 'socket'

# test helper class
class TestTorqueHelperLive < Minitest::Test

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
  #
  def live_test_enabled?
    ! ENV['LIVETEST'].nil?
  end

  def setup

    # FIXME: Torque only works from websvsc02
    #   This raises an issue mentioning that it is not being submitted on the
    #   correct host, comment out the raise to skip the live tests.
    #   Maybe this would be better accomplished with a separate rake task.
    @submit_host = "webdev02.hpc.osc.edu"

    @job_state_queued = OSC::Machete::Status.queued
    @job_state_completed = OSC::Machete::Status.passed
    @job_state_running = OSC::Machete::Status.running

    @shell = OSC::Machete::TorqueHelper.new

    # test staging using HSP template
    #@params = YAML.load(File.read('test/fixtures/app-params.yml'))
    #@template = 'test/fixtures/app-template'
    #@expected = 'test/fixtures/app-template-rendered'

    # directory where to create jobs
    #@target = Dir.mktmpdir
    #@script = 'GLO_job'

    @script_oakley = 'test/fixtures/oakley.sh'
    @script_ruby = 'test/fixtures/ruby.sh'
    @script_quick = 'test/fixtures/quick.sh'
  end

  # This tests an actual live workflow by
  #   submitting a job to oakley,
  #   checking it's status, and
  #   deleting it.
  #
  # Only works on the current submit host.
  def test_qsub_oakley
    return unless live_test_enabled?

    torque = OSC::Machete::TorqueHelper.new

    # Don't run the tests if the host doesn't match.
    if Socket.gethostname == @submit_host
      # Submit a small job.
      live_job = torque.qsub(@script_oakley)
      assert_match(/\d+.oak-batch.osc.edu/, live_job)

      # Qstat it to make sure it's queued.
      live_status = torque.qstat(live_job)
      assert_includes OSC::Machete::Status.active_values, live_status

      # Delete it and assert true returned.
      live_delete_status = torque.qdel(live_job)
      assert_equal 0, live_delete_status
    else
      puts "Run test 'test_qsub_oakley' on the batch system from #{@submit_host}."
    end

  end

  # This tests an actual live workflow by
  #   submitting a job to ruby with an oakley script,
  #   checking it's status, and
  #   deleting it.
  #
  # Only works on the current submit host.
  def test_qsub_ruby_with_oakley_script
    return unless live_test_enabled?

    torque = OSC::Machete::TorqueHelper.new

    # Don't run the tests if the host doesn't match.
    if Socket.gethostname == @submit_host
      # Submit a small job to ruby using an Oakley script,
      # ensuring that we are no longer evaluating the headers.
      live_job = torque.qsub(@script_oakley, host: "ruby")
      assert_match(/\d+$/, live_job)

      # Qstat it to make sure it's queued.
      live_status = torque.qstat(live_job)
      assert_includes OSC::Machete::Status.active_values, live_status

      # Delete it and assert true returned.
      live_delete_status = torque.qdel(live_job)
      assert_equal 0, live_delete_status
    else
      puts "Run test 'test_qsub_ruby_with_oakley_script' on the batch system from #{@submit_host}."
    end

  end

  # This tests an actual live workflow by
  #   submitting a job to ruby,
  #   checking it's status, and
  #   deleting it.
  #
  # Only works on the current submit host.
  def test_qsub_ruby
    return unless live_test_enabled?

    torque = OSC::Machete::TorqueHelper.new

    # Don't run the tests if the host doesn't match.
    if Socket.gethostname == @submit_host
      # Submit a small job.
      live_job = torque.qsub(@script_ruby)
      assert_match(/^\d+$/, live_job)

      # Qstat it to make sure it's queued.
      live_status = torque.qstat(live_job)
      assert_includes OSC::Machete::Status.active_values, live_status

      # Delete it and assert true returned.
      live_delete_status = torque.qdel(live_job)
      assert_equal 0, live_delete_status
    else
      puts "Run test 'test_qsub_ruby' on the batch system from #{@submit_host}."
    end
  end

  # This tests an actual live workflow by
  #   submitting a job to quick,
  #   checking it's status, and
  #   deleting it.
  #
  # Only works on the current submit host.
  def test_qsub_quick
    return unless live_test_enabled?

    torque = OSC::Machete::TorqueHelper.new

    # Don't run the tests if the host doesn't match.
    if Socket.gethostname == @submit_host
      # Submit a small job.
      live_job = torque.qsub(@script_quick, host: 'quick')
      assert_match(/\d+.quick-batch.ten.osc.edu/, live_job)

      # Qstat it to make sure it's queued.
      live_status = torque.qstat(live_job)
      assert_includes OSC::Machete::Status.active_values, live_status

      # Delete it and assert true returned.
      live_delete_status = torque.qdel(live_job)
      assert_equal 0, live_delete_status
    else
      puts "Run test 'test_qsub_quick' on the batch system from #{@submit_host}."
    end
  end


end
