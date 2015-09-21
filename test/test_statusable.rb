require 'minitest/autorun'
require 'osc/machete'

class TestStatusable < Minitest::Test
  def setup
    # create an object that is statusable and has the status value set
    @job = OpenStruct.new
    @job.pbsid = "123456.oak-batch.osc.edu"
    @job.job_path = "/path/to/tmp"
    @job_without_script_name = @job.dup

    @job.script_name = "test.sh"
    @job.extend(OSC::Machete::SimpleJob::Statusable)
    @job_without_script_name.extend(OSC::Machete::SimpleJob::Statusable)
  end

  def teardown
  end

  # verify both of these calls work without crashing
  def test_job_getter_works
    assert_equal "test.sh", @job.job.script_name
    assert_nil @job_without_script_name.job.script_name
  end

  # if calling status returns :Q for Queued, make sure this
  def test_status_sym
    @job.status = :Q

    assert @job.submitted?
    assert ! @job.completed?
    assert @job.active?
    assert_equal "Queued", @job.status_human_readable

    @job.status = :R
    assert @job.active?
    assert_equal "Running", @job.status_human_readable

    @job.status = :C
    assert @job.completed?, "completed? should return true when status is F or C"
    assert ! @job.failed?, "failed? should return false when status is not F"

    @job.status = :F
    assert @job.completed?, "completed? should return true when status is F or C"
    assert @job.failed?, "failed? should return true when status is F"
  end

  def test_status_str
    @job.status = "Q"

    assert @job.submitted?
    assert ! @job.completed?
    assert @job.active?
    assert_equal "Queued", @job.status_human_readable

    @job.status = "R"
    assert @job.active?
    assert_equal "Running", @job.status_human_readable

    @job.status = "C"
    assert @job.completed?, "completed? should return true when status is F or C"
    assert ! @job.failed?, "failed? should return false when status is not F"

    @job.status = "F"
    assert @job.completed?, "completed? should return true when status is F or C"
    assert @job.failed?, "failed? should return true when status is F"
  end

  def test_results_valid_hook_called
    #FIXME: these tests should use a Job object with a custom Torque helper
    #that is our mock. Solution: add TorqueHelper.default and use that in Job
    #then we can mock default with our own modified TorqueHelper instance
    #that returns status for the right values and get rid of these OpenStructs
    #below.

    # normally, qstat returns nil, and we call hook
    @job.define_singleton_method(:job) { OpenStruct.new(:status => nil) }
    assert_nil @job.job.status

    @job.status = "R"
    @job.expects(:"results_valid?").at_least_once
    @job.update_status!

    # sometimes, qstat returns "C": still call the hook!
    @job.define_singleton_method(:job) { OpenStruct.new(:status => "C") }
    assert "C", @job.job.status

    @job.status = "R"
    @job.expects(:"results_valid?").at_least_once
    @job.update_status!

    # but if the status is completed we don't want the hook to run again
    @job.expects(:"results_valid?").never
    @job.status = "C"
    @job.update_status!
  end

end
