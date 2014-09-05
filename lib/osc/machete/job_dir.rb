# helper class to create job directories
class OSC::Machete::JobDir
  def initialize(target)
    @target = Pathname.new(target).cleanpath
  end
  
  # return true if the string is a job dir name
  def jobdir_name?(name)
    name[/^\d+$/]
  end
  
  # return true if Pathname is a job directory
  def jobdir?(path)
    jobdir_name?(path.basename.to_s)
  end
  
  # get a list of all job directories
  def jobdirs
    @target.children.select { |i| jobdir?(i) }
  end
  
  # get a list of directories in the target directory
  def targetdirs
    @target.children.select(&:directory?)
  end
  
  # find the next unique integer name for a job directory
  def unique_dir
    dirs = jobdirs.map { |i| i.basename.to_s.to_i }
    (dirs.count > 0) ? (dirs.max + 1).to_s : 1.to_s
  end
  
  def new_jobdir
    @target + unique_dir
  end
end
