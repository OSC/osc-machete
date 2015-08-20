require 'pathname'
require 'mustache'

# A util class with methods used with staging a simulation template directory.
# Use it by wrapping a file path (either string or Pathname object).
# For example, if I have a template directory at "/nfs/05/efranz/template"
# I can recursivly copy the template directory:
#
#     target = "/nfs/05/efranz/simulations/1"
#     simulation = Location.new("/nfs/05/efranz/template").copy_to(target)
#
# Then I can recursively render all the mustache templates in the copied directory,
# renaming each file from XXXX.mustache to XXXX:
#
#     simulation.render(iterations: 20, geometry: "/nfs/05/efranz/geos/fan.stl")
#
class OSC::Machete::Location
  # URIs, Paths, rendering, and copying
  # this should be refactored into separate objects

  # @param path  either string, Pathname, or Machete::Location object
  def initialize(path)
    @path = Pathname.new(path.to_s).cleanpath
    @template_ext = ".mustache"
  end

  # @return [String] The location path as String.
  def to_s
    @path.to_s
  end

  # Copies the data in a Location to a destination path using rsync.
  #
  # @param [String, Pathname] dest The target location path.
  # @return [Location] The target location path wrapped by Location instance.
  def copy_to(dest)
    # @path has / auto-dropped, so we add it to make sure we copy everything
    # in the old directory to the new
    destloc = self.class.new(dest)
    `rsync -r --exclude='.svn' --exclude='.git' --exclude='.gitignore' --filter=':- .gitignore' #{@path.to_s}/ #{destloc.to_s}`

    # return target location so we can chain method
    destloc
  end

  # **This should be a private method**
  #
  # Get a list of template files in this Location, where a template file is a
  # file with the extension .mustache
  #
  # @return [Array<String>] list of template files in directory (recursively searched)
  def template_files
    if @path.directory?
      Dir.glob(File.join(@path, "**/*#{@template_ext}"))
    else
      @path.to_s.end_with? @template_ext ? [@path.to_s] : []
    end
  end

  # Render each mustache template and rename the file, removing the extension
  # that indicates it is a template file i.e. `.mustache`.
  #
  # @param [Hash] params the "context" or "hash" for use when rendering mustache templates
  # @param [Hash] options to modify rendering behavior
  # @option options [Boolean] :replace (true) if true will delete the template file after the rendered file is created
  # @return [self] returns self for optional chaining
  def render(params, options = {})
    # custom_delimiters = options['delimeters'] || nil
    replace_template_files = options[:replace].nil? ? true : options[:replace]

    renderer = Mustache.new

    template_files.each do |template|
      rendered_file = template.chomp(@template_ext)

      rendered_string = nil
      File.open(template, 'r') do |f|
        rendered_string = renderer.render(f.read, params)
      end
      # boo...
      # rendered_string = renderer.render_file(template, params)

      File.open(rendered_file, 'w') { |f| f.write(rendered_string) }

      FileUtils.rm template if replace_template_files
    end

    # return self so this can be at the end of a chained method
    self
  end
end
