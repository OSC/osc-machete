# Class that maintains the name and home identifiers of a User.
# 
# @attr_reader [String] :name The ENV['USER'] or ENV['APACHE_USER']
# @attr_reader [String] :home The ENV['HOME']
class OSC::Machete::User
  attr_reader :name, :home
  
  # Sets the machete user to the ENV['USER'], or the ENV['APACHE_USER'] if ENV['USER'] is not set.
  # Sets the machete home to the ENV['HOME']
  def initialize()
    @name = ENV['USER'] || ENV['APACHE_USER']
    @home = ENV['HOME']
  end
end
