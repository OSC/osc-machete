class OSC::Machete::Status
  include Comparable
  
  attr_reader :char
  
  # adaptive computing:
  # http://docs.adaptivecomputing.com/torque/4-1-3/Content/topics/commands/qstat.htm
  # C Job is completed after having run.
  # E Job is exiting after having run.
  # H Job is held.
  # Q Job is queued, eligible to run or routed.
  # R Job is running.
  # T Job is being moved to new location.   transition
  # W Job is waiting for its execution time (-a option) to be reached.
  # S (Unicos only) Job is suspended.
  #
  # Ordered hash for precedence
  # Hashes enumerate their values in the order that the corresponding keys were inserted
  VALUES = {nil=>"not_submitted", "C"=>"completed", "F"=>"failed", 
            "E"=>"exiting", "T"=>"transitioning", "W"=>"waiting", "S"=>"suspended", 
            "H"=>"held", "Q"=>"queued", "R"=>"running"}
  
  # create self.completed, self.running, etc.
  class << self
    VALUES.each do |char, name|
      define_method(name) do
        OSC::Machete::Status.new(char)
      end
    end
  end
  
  # create completed?, running?, etc.
  VALUES.each do |char, name|
    define_method("#{name}?") do
      self == OSC::Machete::Status.new(char)
    end
  end
  
  def active?
    running? || queued? || held? || exiting? || transitioning? || waiting? || suspended?
  end
  
  def initialize(char)
    @char = char.to_s
    @char = nil if @char.empty?
    raise "Invalid status value" unless VALUES.has_key?(@char)
  end
  
  def to_s
    @char.to_s
  end
  
  def inspect
    # FIXME: ActiveSupport  replace with .humanize and simpler datastructure
     VALUES[@char].split("_").map(&:capitalize).join(" ")
  end
  
  def +(other)
    [self, other].max
  end
  
  def <=>(other)
    precendence <=> other.precendence
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
  
  def precendence
    # Hashes enumerate their values in the order that the corresponding keys were inserted
    VALUES.keys.index(@char)
  end
end
