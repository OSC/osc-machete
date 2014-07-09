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
    assert_respond_to obj, :crimson_files_dir_name
    assert_respond_to obj, :staging
    assert_respond_to obj, :submit
  end
end

