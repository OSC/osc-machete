require 'minitest/autorun'
require 'osc/machete'

class TestLocation < Minitest::Test

  def setup
    # tmp directory
    # and we are making a location object that wraps that directory
    # we add mustache templates and test rendering
    # we add another tmp directory/location and we test copy to
    @dir1 = Dir.mktmpdir("location")
    @dir2 = Dir.mktmpdir("location")
    @location1 = OSC::Machete::Location.new(@dir1)
    @location2 = OSC::Machete::Location.new(@dir2)
  end

  def teardown
    FileUtils.remove_entry @dir1
    FileUtils.remove_entry @dir2
  end

  # Location.render(params, options = {})

  def test_render_default_replace_template
    setup_render
    @location1.render("")
    assert_equal true,  File.exist?("#{@dir1}/file.txt")
    assert_equal false, File.exist?("#{@dir1}/file.txt.mustache")
  end

  def test_render_user_replace_template
    setup_render
    @location1.render("", {replace: true})
    assert_equal true,  File.exist?("#{@dir1}/file.txt")
    assert_equal false, File.exist?("#{@dir1}/file.txt.mustache")
  end

  def test_render_user_doesnt_replace_template
    setup_render
    @location1.render("", {replace: false})
    assert_equal true,  File.exist?("#{@dir1}/file.txt")
    assert_equal true,  File.exist?("#{@dir1}/file.txt.mustache")
  end

  def test_copy_to_shouldnt_copy_developer_files
    setup_copy_to
    
    @location1.copy_to(@dir2)
    assert_equal true,  Dir.exist?("#{@dir2}")
    assert_equal false, Dir.exist?("#{@dir2}/.git")
    assert_equal false, Dir.exist?("#{@dir2}/.svn")
    assert_equal false, Dir.exist?("#{@dir2}/test.dir.1")
    assert_equal true,  Dir.exist?("#{@dir2}/test.dir.2")
    assert_equal true,  File.exist?("#{@dir2}/test.1")
    assert_equal false, File.exist?("#{@dir2}/test.2")
    assert_equal true,  File.exist?("#{@dir2}/test.3")
    assert_equal false, File.exist?("#{@dir2}/test.4")
    assert_equal false, File.exist?("#{@dir2}/test.dir.2/test.1")
    assert_equal false, File.exist?("#{@dir2}/test.dir.2/test.2")
    assert_equal true,  File.exist?("#{@dir2}/test.dir.2/test.4")
    assert_equal false, File.exist?("#{@dir2}/.gitignore")
  end
  
  
  private

    def setup_render
      FileUtils.touch("#{@dir1}/file.txt.mustache")
    end

    def setup_copy_to
      # Example directory/file structure of developer
      Dir.mkdir("#{@dir1}/.git")
      Dir.mkdir("#{@dir1}/.svn")
      Dir.mkdir("#{@dir1}/test.dir.1")
      Dir.mkdir("#{@dir1}/test.dir.2")
      FileUtils.touch("#{@dir1}/test.1")
      FileUtils.touch("#{@dir1}/test.2")
      FileUtils.touch("#{@dir1}/test.3")
      FileUtils.touch("#{@dir1}/test.4")
      FileUtils.touch("#{@dir1}/test.dir.2/test.1")
      FileUtils.touch("#{@dir1}/test.dir.2/test.2")
      FileUtils.touch("#{@dir1}/test.dir.2/test.4")

      # Make example .gitignore
      gitignore = <<-END.gsub(/^ {20}/, '')
                    # All files here will be ignored
                    test.2
                    #test.3
                    /test.4
                    test.dir.1
                    test.dir.2/test.1
                  END

      File.open("#{@dir1}/.gitignore", 'w') {|f| f.write(gitignore) }
    end
end
