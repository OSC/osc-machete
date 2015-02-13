require 'minitest/autorun'
require 'osc/machete'

class TestLocation < Minitest::Test

  def setup
    @target = Dir.mktmpdir("location")
    @subject = OSC::Machete::Location.new @target
  end

  def teardown
    FileUtils.remove_entry @target
  end

  # Location.render(params, options = {})

  def test_render_default_replace_template
    setup_render
    @subject.render("")
    assert_equal true,  File.exists?("#{@target}/file.txt")
    assert_equal false, File.exists?("#{@target}/file.txt.mustache")
  end

  def test_render_user_replace_template
    setup_render
    @subject.render("", {replace: true})
    assert_equal true,  File.exists?("#{@target}/file.txt")
    assert_equal false, File.exists?("#{@target}/file.txt.mustache")
  end

  def test_render_user_doesnt_replace_template
    setup_render
    @subject.render("", {replace: false})
    assert_equal true,  File.exists?("#{@target}/file.txt")
    assert_equal true,  File.exists?("#{@target}/file.txt.mustache")
  end

  def test_copy_to_shouldnt_copy_developer_files
    setup_copy_to
    begin
      @subject.copy_to(@new_target)
      assert_equal true,  Dir.exists?("#{@new_target}")
      assert_equal false, Dir.exists?("#{@new_target}/.git")
      assert_equal false, Dir.exists?("#{@new_target}/.svn")
      assert_equal false, Dir.exists?("#{@new_target}/test.dir.1")
      assert_equal true,  Dir.exists?("#{@new_target}/test.dir.2")
      assert_equal true,  File.exists?("#{@new_target}/test.1")
      assert_equal false, File.exists?("#{@new_target}/test.2")
      assert_equal true,  File.exists?("#{@new_target}/test.3")
      assert_equal false, File.exists?("#{@new_target}/test.4")
      assert_equal false, File.exists?("#{@new_target}/test.dir.2/test.1")
      assert_equal false, File.exists?("#{@new_target}/test.dir.2/test.2")
      assert_equal true,  File.exists?("#{@new_target}/test.dir.2/test.4")
      assert_equal false, File.exists?("#{@new_target}/.gitignore")
    ensure
      teardown_copy_to
    end
  end
  
  
  private

    def setup_render
      FileUtils.touch("#{@target}/file.txt.mustache")
    end

    def setup_copy_to
      # Destination of copied files
      @new_target = "#{@target}_1"

      # Example directory/file structure of developer
      Dir.mkdir("#{@target}/.git")
      Dir.mkdir("#{@target}/.svn")
      Dir.mkdir("#{@target}/test.dir.1")
      Dir.mkdir("#{@target}/test.dir.2")
      FileUtils.touch("#{@target}/test.1")
      FileUtils.touch("#{@target}/test.2")
      FileUtils.touch("#{@target}/test.3")
      FileUtils.touch("#{@target}/test.4")
      FileUtils.touch("#{@target}/test.dir.2/test.1")
      FileUtils.touch("#{@target}/test.dir.2/test.2")
      FileUtils.touch("#{@target}/test.dir.2/test.4")

      # Make example .gitignore
      gitignore = <<-END.gsub(/^ {20}/, '')
                    # All files here will be ignored
                    test.2
                    #test.3
                    /test.4
                    test.dir.1
                    test.dir.2/test.1
                  END

      File.open("#{@target}/.gitignore", 'w') {|f| f.write(gitignore) }
    end

    def teardown_copy_to
      FileUtils.remove_entry @new_target
    end
end
