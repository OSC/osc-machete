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
  end
end
