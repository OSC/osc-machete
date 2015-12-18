# Class that maintains the User and additional methods for the process.
# Helper methods provided use the Process module underneath.
#
class OSC::Machete::Process

  def initialize
    @user = OSC::Machete::User.new
  end

  # The system name of the process user
  def username
    @user.name
  end

  # use gid not egid
  def groupname
    Etc.getgrgid(Process.gid).name
  end

  # has the group membership changed since this process started?
  def group_membership_changed?
    Process.groups.uniq.sort != @user.groups
  end

  # The home directory path of the process user.
  #
  # @return [String] The directory path.
  def home
    @user.home
  end

end
