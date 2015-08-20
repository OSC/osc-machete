# helper class to create job directories
class OSC::Machete::JobDir
  def initialize(parent_directory)
    @target = Pathname.new(parent_directory).cleanpath
  end

  # Returns a unique path for a job
  #
  # @return [String] A path of a unique job directory as string.
  def new_jobdir
    @target + unique_dir
  end

  #FIXME: BELOW METHODS SHOULD BE PRIVATE

  # return true if the string is a job dir name
  def jobdir_name?(name)
    name[/^\d+$/]
  end

  # return true if Pathname is a job directory
  # FIXME: this is not used anywhere; remove it?
  def jobdir?(path)
    jobdir_name?(path.basename.to_s) && path.directory?
  end

  # get a list of all job directories
  # FIXME: this is not used anywhere; remove it?
  def jobdirs
    @target.exist? ? @target.children.select { |i| jobdir?(i) } : []
  end


  # get a list of directories in the target directory
  # FIXME: this is not used anywhere; remove it?
  def targetdirs
    @target.exist? ? @target.children.select(&:directory?) : []
  end

  # find the next unique integer name for a job directory
  def unique_dir
    taken_ints = taken_paths.map { |path| path.basename.to_s.to_i }
    (taken_ints.count > 0) ? (taken_ints.max + 1).to_s : 1.to_s
  end

  private

  # paths that are unavailable for creating a new job directory
  def taken_paths
    if @target.exist?
      @target.children.select { |path| jobdir_name?(path.basename.to_s) }
    else
      []
    end
  end
end
