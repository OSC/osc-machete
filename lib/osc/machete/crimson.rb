# wrapper around crimson conventions
class OSC::Machete::Crimson
  attr_reader :files_path, :config_path
  # @param portal  FanPortal - crimson files name
  # @param user    optional user object to use
  def initialize(portal, user = nil)
    @portal = portal
    @user = user || Machete::User.new
    
    @files_path = Pathname.new(@user.home).join("crimson_files/#{@portal}")
    @config_path = Pathname.new(@user.home).join(".crimson_cfg/#{@portal}")
  end
end
