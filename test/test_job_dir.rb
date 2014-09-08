require 'minitest/autorun'
require 'osc/machete'

class TestJobDir < Minitest::Test

  def setup
    @target = Dir.mktmpdir("jobdir")
    @subject = OSC::Machete::JobDir.new @target
  end

  def teardown
    FileUtils.remove_entry @target
  end

  # JobDir.new_jobdir()

  def test_new_jobdir_succeeds_with_numbered_directories
    # Initialize app directory with multiple jobs
    # and a file with a larger number
    Dir.mkdir("#{@target}/1")
    Dir.mkdir("#{@target}/5")
    FileUtils.touch("#{@target}/8")

    # Create unique directory
    new_jobdir = @subject.new_jobdir
    Dir.mkdir(new_jobdir)
    assert_equal true, Dir.exists?("#{@target}/9")
  end

end
