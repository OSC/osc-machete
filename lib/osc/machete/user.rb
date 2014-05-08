class OSC::Machete::User
  attr_reader :name, :home
  
  def initialize()
    @name = ENV['USER'] || ENV['APACHE_USER']
    @home = ENV['HOME']
  end
end
