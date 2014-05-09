require 'minitest/autorun'
require 'osc/machete'

class TestCrimson < MiniTest::Unit::TestCase
  def setup
  end
  
  def teardown
  end
  
  def test_crimson
    # instantiate crimson object
    crimson = OSC::Machete::Crimson.new 'DemoSim'
    
    assert_equal "#{ENV['HOME']}/crimson_files/DemoSim", crimson.files_path.to_s
  end
end
