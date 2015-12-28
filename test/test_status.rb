require 'minitest/autorun'
require 'osc/machete'

class TestStatus < Minitest::Test
  include OSC::Machete
  
  def setup
    @completed = Status.completed
    @running = Status.running
    @held = Status.held
    @queued = Status.queued
    @failed = Status.failed
    @new = Status.not_submitted
    @suspended = Status.suspended
  end
  
  def teardown
  end
  
  def test_status_equality
    assert Status.new(:F).eql?(Status.new("F"))
    assert_equal Status.new(:F), Status.new("F")
    assert_equal @failed, Status.new("F")
    assert_equal @completed, Status.new("C")
    
    #FIXME: is supporting comparisons between Status values and Strings a good idea?
    assert_equal @completed, "C"
    
    # default value is 
    assert_equal Status.new(""), @new
    assert_equal Status.new(nil), @new
    assert_nil @new.char
  end
  
  def test_inspect
    assert_equal "Completed", @completed.inspect
    assert_equal "Not Submitted", @new.inspect
    assert_equal "Running", @running.inspect
  end
  
  def test_helpers
    assert_equal false, @completed.active?
    assert_equal true, @completed.completed?
    assert_equal true, @queued.queued?
    assert_equal true, @queued.active?
  end
  
  def test_max
    assert_equal @completed, [@completed, @completed].max
    assert_equal @completed, [@new, @completed].max
    assert_equal @running, [@running, @queued].max
    assert_equal @failed, [@completed, @failed].max
    assert_equal @running, [@completed, @running].max
    assert_equal @running, [@running, @queued].max
    assert_equal @queued, [@new, @queued].max
  end
  
  def test_add
    assert_equal @completed, @completed + @completed
    assert_equal @completed, @new + @completed
    assert_equal @running, @running + @queued
    assert_equal @failed, @completed + @failed
    assert_equal @running, @completed + @running
    assert_equal @running, @running + @queued
    assert_equal @queued, @new + @queued
  end

  def test_undetermined
    assert_equal Status.new("X"), Status.undetermined
  end

  def test_submitted
    assert @completed.submitted?
    assert @running.submitted?
    assert @queued.submitted?
    assert @failed.submitted?
    assert @completed.submitted?
    assert ! @new.submitted?
    assert ! Status.undetermined.submitted?
  end

  def test_active_status_values
    assert_equal Status.active_values.sort, [@running, @queued, @held, @suspended].sort
  end
end
