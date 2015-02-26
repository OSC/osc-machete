require 'minitest/autorun'
require 'osc/machete'

class TestStatusable < Minitest::Test
  def setup
    # create an object that is statusable and has the status value set
    @job = OpenStruct.new
    @job.pbsid = "123456.oak-batch.osc.edu"
    @job.job_path = "/path/to/tmp"
    @job.script_name = "test.sh"
    
    @job.extend(OSC::Machete::SimpleJob::Statusable)
  end
  
  def teardown
  end
  
  # if calling status returns :Q for Queued, make sure this
  def test_status_sym
    @job.status = :Q
    
    assert @job.submitted?
    assert ! @job.completed?
    assert @job.running_queued_or_hold?
    assert @job.active?
    assert_equal "Queued", @job.status_human_readable
    
    @job.status = :R
    assert @job.running_queued_or_hold?
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
    assert @job.running_queued_or_hold?
    assert @job.active?
    assert_equal "Queued", @job.status_human_readable
    
    @job.status = "R"
    assert @job.running_queued_or_hold?
    assert @job.active?
    assert_equal "Running", @job.status_human_readable
    
    @job.status = "C"
    assert @job.completed?, "completed? should return true when status is F or C"
    assert ! @job.failed?, "failed? should return false when status is not F"
    
    @job.status = "F"
    assert @job.completed?, "completed? should return true when status is F or C"
    assert @job.failed?, "failed? should return true when status is F"
  end
end
