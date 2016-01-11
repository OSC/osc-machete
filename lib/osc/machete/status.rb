# Class for storing an architecture-independent job status.
#
class OSC::Machete::Status
  include Comparable
  
  attr_reader :char
  
  # C Job is completed after having run.
  # H Job is held.
  # Q Job is queued, eligible to run or routed.
  # R Job is running.
  #
  # U Status is unavailable (null status object)
  VALUES = [["U", "undetermined"], [nil, "not_submitted"], ["C", "completed"], ["F", "failed"],
            ["H", "held"], ["Q", "queued"], ["R", "running"], ["S", "suspended"]]
  # A hashed version of the values array
  VALUES_HASH = Hash[VALUES]

  PRECEDENCE = VALUES.map(&:first)

  # Get an array of all the possible Status values
  #
  # @return [Array] - all possible Status values
  def self.values
    VALUES.map{ |v| OSC::Machete::Status.new(v.first) }
  end

  # Get an array of all the possible active Status values
  #
  # @return [Array] - all possible active Status values
  def self.active_values
    values.select(&:active?)
  end

  # create self.completed, self.running, etc.
  class << self
    VALUES_HASH.each do |char, name|
      define_method(name) do
        OSC::Machete::Status.new(char)
      end
    end
  end
  
  # create completed?, running?, etc.
  VALUES_HASH.each do |char, name|
    define_method("#{name}?") do
      self == OSC::Machete::Status.new(char)
    end
  end

  def initialize(char)
    @char = char.to_s
    @char = nil if @char.empty?

    # if invalid status value char, default to undetermined
    @char = self.class.undetermined.to_s unless VALUES_HASH.has_key?(@char)
  end

  def submitted?
    ! (not_submitted? || undetermined?)
  end

  def active?
    running? || queued? || held? || suspended?
  end

  # Returns the status as the char value.
  #
  # @return [String] The status char
  def to_s
    @char.to_s
  end


  def inspect
    # FIXME: ActiveSupport  replace with .humanize and simpler datastructure
     VALUES_HASH[@char].split("_").map(&:capitalize).join(" ")
  end

  def +(other)
    [self, other].max
  end

  def <=>(other)
    precedence <=> other.precedence
  end

  def eql?(other)
    other.to_s == to_s
  end

  def ==(other)
    self.eql?(other)
  end

  def hash
    @char.hash
  end

  def precedence
    # Hashes enumerate their values in the order that the corresponding keys were inserted
    PRECEDENCE.index(@char)
  end
end
