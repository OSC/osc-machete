require 'minitest/autorun'
require 'osc/machete'

class TestJobDir < Minitest::Test
  def setup
    @data_root = Dir.mktmpdir
    @parent = Pathname.new(@data_root).join("containers")
  end
  
  def teardown
    FileUtils.remove_entry @data_root
  end
  
  # test and verify if we create a JobDir helper
  # with a parent directory that doesn't yet exist
  # new_jobdir returns  /path/to/parent/1
  def test_job_dir_with_missing_parent_dir
    dirhelper = OSC::Machete::JobDir.new(@parent)
    
    assert_equal [], dirhelper.jobdirs
    assert_equal [], dirhelper.targetdirs
    assert_equal @parent.join("1"), dirhelper.new_jobdir
  end

  def test_new_jobdir_succeeds_with_numbered_directories
    FileUtils.mkdir_p @parent
    
    # Initialize app directory with multiple jobs
    # and a file with a larger number
    Dir.mkdir("#{@parent}/1")
    Dir.mkdir("#{@parent}/5")
    FileUtils.touch("#{@parent}/8")
    
    # Create unique directory
    new_jobdir = OSC::Machete::JobDir.new(@parent).new_jobdir
    Dir.mkdir(new_jobdir)
    assert Dir.exists?("#{@parent}/9"), "Directory was not created: #{@parent}/9"
  end
end
