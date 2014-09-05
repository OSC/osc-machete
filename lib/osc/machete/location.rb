require 'pathname'
require 'mustache'

# FIXME: Location has two methods of interest:
# copy_to and render; otherwise, could we just use
# Pathname or URI to refer to a location?
# Is this extra class necessary?
class OSC::Machete::Location
  # URIs, Paths, rendering, and copying
  # this should be refactored into separate objects
  
  # @param path  either string, Pathname, or Machete::Location object
  def initialize(path)
    @path = Pathname.new(path.to_s).cleanpath
    @template_ext = ".mustache"
  end
  
  def to_s
    @path.to_s
  end
  
  def copy_to(dest)
    # @path has / auto-dropped, so we add it to make sure we copy everything
    # in the old directory to the new
    destloc = self.class.new(dest)
    `rsync -r --exclude='.svn' --exclude='.git' --filter=':- .gitignore' #{@path.to_s}/ #{destloc.to_s}`
    
    # return target location so we can chain method
    destloc
  end
  
  # return list of template files in directory (recursively searched)
  def template_files
    if @path.directory?
      Dir.glob(File.join(@path, "**/*#{@template_ext}"))
    else
      @path.to_s.end_with? @template_ext ? [@path.to_s] : []
    end
  end
  
  #TODO: see how you use pystache for the renderer...
  def render(params, options = {})
    # custom_delimiters = options['delimeters'] || nil
    replace_template_files = options['replace'] || true
    
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
