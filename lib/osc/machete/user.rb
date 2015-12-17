# Class that maintains the name and home identifiers of a User.
#
class OSC::Machete::User

  attr_reader :name

  def initialize(username = Etc.getpwuid.name)
    @name = username
  end

  def member_of_group?(group)
    Etc.getgrnam(group).mem.include?(@name) rescue false
  end

  # get sorted list of group ids that user is part of
  # by inspecting the /etc/group file
  # there is also a ruby impl of this
  def groups
    `id -G $USER`.strip.split.map(&:to_i).uniq.sort
  end

  # return Pathname for home directory
  def home
    Dir.home(@name)
  end

end
