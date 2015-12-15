class OSC::Machete::Process

  def initialize
    @user = OSC::Machete::User.new
  end

  def username
    @user.name
  end

  # use gid not egid
  def groupname
    Etc.getgrgid(Process.gid).name
  end

  def awesim_user?
    @user.awesim_user?
  end

  # has the group membership changed since this process started?
  def group_membership_changed?
    Process.groups.uniq.sort != @user.groups
  end

  def home
    @user.home
  end

end
