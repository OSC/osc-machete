# Value object representing job status independent of underlying resource manager.
#
# All of the possible Torque statuses are not represented here. Its the
# responsibility of the Torque adapter (TorqueHelper) to create the appropriate
# Status object to represent the Torque status.
#
# The possible values are: Undetermined, Not Submitted, Passed, Failed, Held, Queued, Running, Suspended
#
class OSC::Machete::Status
  include Comparable
  
  attr_reader :char

  # C Job is passed (completed successfully)
  # F Job is failed (completed with errors)
  # H Job is held.
  # Q Job is queued, eligible to run or routed.
  # R Job is running.
  #
  # U Status is unavailable (null status object)
  VALUES = [["U", "undetermined"], [nil, "not_submitted"], ["C", "passed"], ["F", "failed"],
            ["H", "held"], ["Q", "queued"], ["R", "running"], ["S", "suspended"]]
  private_constant :VALUES

  # A hashed version of the values array.
  VALUES_HASH = Hash[VALUES]
  private_constant :VALUES_HASH

  # An array of status char values by precedence.
  #
  # @example
  #   OSC::Machete::Status::PRECEDENCE #=> ["U", nil, "C", "F", "H", "Q", "R", "S"]
  PRECEDENCE = VALUES.map(&:first)
  private_constant :PRECEDENCE

  # Get an array of all the possible Status values
  #
  # @return [Array<Status>] - all possible Status values
  def self.values
    VALUES.map{ |v| OSC::Machete::Status.new(v.first) }
  end

  # Get an array of all the possible active Status values
  #
  # @return [Array<Status>] - all possible active Status values
  def self.active_values
    values.select(&:active?)
  end

  # Get an array of all the possible completed Status values
  #
  # @return [Array<Status>] - all possible completed Status values
  def self.completed_values
    values.select(&:completed?)
  end


  # NOTE: on yard documentation: to do something like what I do below,
  # documenting a set of class methods, you must have the documentation block be
  # inside the `class << self` block or else the last documented method will be
  # ignored or hidden if newlines exist between each @!method block. If no
  # newlines exist, like below, the entire block would have been ignored.
  # Also, indenting the tags for the rest of the methods is required when
  # omitting newlines, otherwise, each method includes all of the returns below
  # it - so yard displays 6 return Status lines for the method.
  #
  # Why do we have no newlines here? So that "View source" on each of these
  # class methods points to the block itself.
  class << self
    # @!method undetermined
    #   A 'null' special case for Status
    #   @return [Status]
    #
    # @!method not_submitted
    #   @return [Status]
    #
    # @!method passed
    #   @return [Status]
    #
    # @!method failed
    #   @return [Status]
    #
    # @!method running
    #   @return [Status]
    #
    # @!method queued
    #   @return [Status]
    #
    # @!method held
    #   @return [Status]
    #
    # @!method suspended
    #   @return [Status]
    VALUES_HASH.each do |char, name|
      define_method(name) do
        OSC::Machete::Status.new(char)
      end
    end
  end

  # @!method undetermined?
  # @return [Boolean] true if undetermined

  # @!method not_submitted?
  # @return [Boolean] true if not_submitted

  # @!method failed?
  # @return [Boolean] true if failed

  # @!method passed?
  # @return [Boolean] true if passed

  # @!method held?
  # @return [Boolean] true if held

  # @!method queued?
  # @return [Boolean] true if queued

  # @!method running?
  # @return [Boolean] true if running

  # @!method suspended?
  # @return [Boolean] true if suspended
  VALUES_HASH.each do |char, name|
    define_method("#{name}?") do
      self == OSC::Machete::Status.new(char)
    end
  end

  def initialize(char)
    # char could be a status object or a string
    @char = (char.respond_to?(:char) ? char.char : char).to_s.upcase
    @char = nil if @char.empty?

    # if invalid status value char, default to undetermined
    @char = self.class.undetermined.char unless VALUES_HASH.has_key?(@char)
  end

  # @return [Boolean] true if submitted
  def submitted?
    ! (not_submitted? || undetermined?)
  end

  # @return [Boolean] true if in active state (running, queued, held, suspended)
  def active?
    running? || queued? || held? || suspended?
  end

  # @return [Boolean] true if in completed state (passed or failed)
  def completed?
    passed? || failed?
  end

  # Return a readable string of the status
  #
  # @example Running
  #     OSC::Machete::Status.running.to_s #=> "Running"
  #
  # @return [String] The status value as a formatted string
  def to_s
    # FIXME: ActiveSupport  replace with .humanize and simpler datastructure
     VALUES_HASH[@char].split("_").map(&:capitalize).join(" ")
  end

  # Return the a StatusValue object based on the highest precedence of the two objects.
  #
  # @example One job is running and a dependent job is queued.
  #   OSC::Machete::Status.running + OSC::Machete::Status.queued #=> Running
  #
  # Return [OSC::Machete::Status] The max status by precedence
  def +(other)
    [self, other].max
  end

  # The comparison operator for sorting values.
  #
  # @return [Integer] Comparison value based on precedence
  def <=>(other)
    precedence <=> other.precedence
  end

  # Boolean evaluation of Status object equality.
  #
  # @return [Boolean] True if the values are the same
  def eql?(other)
    # compare Status to Status OR "C" to Status
    (other.respond_to?(:char) ? other.char : other) == char
  end

  # Boolean evaluation of Status object equality.
  #
  # @return [Boolean] True if the values are the same
  def ==(other)
    self.eql?(other)
  end

  # Return a hash based on the char value of the object.
  #
  # @return [Fixnum] A hash value of the status char
  def hash
    @char.hash
  end

  # Return the ordinal position of the status in the precidence list
  #
  # @return [Integer] The order of precedence for the object
  def precedence
    # Hashes enumerate their values in the order that the corresponding keys were inserted
    PRECEDENCE.index(@char)
  end
end
