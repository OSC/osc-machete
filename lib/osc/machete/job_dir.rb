# helper class to create job directories
class OSC::Machete::JobDir
  def initialize(target)
    @target = Pathname.new(target).cleanpath
  end
  
  # return true if the string is a job dir name
  def jobdir_name?(name)
    name[/^\d+$/]
  end
  
  # get a list of directories in the target directory
  def targetdirs
    @target.children.select(&:directory?)
  end
  
  # find the next unique integer name for a job directory
  def unique_dir
    paths = @target.children.select { |i| jobdir_name?(i.basename.to_s) }
    dirs = paths.map { |i| i.basename.to_s.to_i }
    (dirs.count > 0) ? (dirs.max + 1).to_s : 1.to_s
  end
  
  def new_jobdir
    @target + unique_dir
  end
end
