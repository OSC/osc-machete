require 'minitest/autorun'
require 'osc/machete'

class TestSimpleJob < Minitest::Test
  def setup
  end
  
  def teardown
  end
  
  def test_simple_job_include
    cls = Class.new do
      def self.after_find
      end
      
      include OSC::Machete::SimpleJob
    end
    
    obj = cls.new
    
    # verify responds to status methods
    assert_respond_to obj, :submitted?
    assert_respond_to obj, :completed?
    assert_respond_to obj, :status_human_readable
    assert_respond_to obj, :update_status!
    
    # verify responds to submit methods
    assert_respond_to obj, :staging_template_name
    assert_respond_to obj, :staging
    assert_respond_to obj, :submit
  end
  
  def test_simple_job_include_submittable
    cls = Class.new do
      def self.after_find
      end
      
      include OSC::Machete::SimpleJob::Submittable
    end
    
    obj = cls.new
    
    # verify responds to submit methods
    assert_respond_to obj, :staging_template_name
    assert_respond_to obj, :staging
    assert_respond_to obj, :submit
    
    # verify does not respond to status methods
    assert_raises(NoMethodError) { obj.submitted? }
    assert_raises(NoMethodError) { obj.update_status! }
  end
  
  def test_simple_job_include_statusable
    cls = Class.new do
      def self.after_find
      end
      
      include OSC::Machete::SimpleJob::Statusable
    end
    
    obj = cls.new
    
    # verify responds to status methods
    assert_respond_to obj, :submitted?
    assert_respond_to obj, :completed?
    assert_respond_to obj, :status_human_readable
    assert_respond_to obj, :update_status!
    
    # verify does not respond to submit methods
    assert_raises(NoMethodError) { obj.submit }
    assert_raises(NoMethodError) { obj.staging }
  end
end

