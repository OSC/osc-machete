require 'minitest/autorun'
require 'osc/machete'

class TestJobDir < Minitest::Test
  def setup
    @data_root = Dir.mktmpdir
  end
  
  def teardown
    FileUtils.remove_entry @data_root
  end
  
  # test and verify if we create a JobDir helper
  # with a parent directory that doesn't yet exist
  # new_jobdir returns  /path/to/parent/1
  def test_job_dir_with_missing_parent_dir
    parent = Pathname.new(@data_root).join("containers")
    dirhelper = OSC::Machete::JobDir.new(parent)
    
    assert_equal [], dirhelper.jobdirs
    assert_equal [], dirhelper.targetdirs
    assert_equal parent.join("1"), dirhelper.new_jobdir
  end
end
