require 'minitest/autorun'
require 'osc/machete'

class TestCrimson < Minitest::Test
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
