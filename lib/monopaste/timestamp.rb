
module Monopaste

class Timestamp
  include Comparable

  attr_reader :unix_ts, :microseconds

  def initialize(unix_ts, microseconds)
    @unix_ts = unix_ts
    @microseconds = microseconds
    if @microseconds >= 1000000
      raise ArgumentError.new, "invalid microseconds: #{@microseconds}"
    end
  end

  def self.now()
    ts = Time.now
    return self.new(ts.to_i, ts.tv_usec)
  end

  def <=>(other_ts)
    unix_result = (@unix_ts <=> other_ts.unix_ts)
    return unix_result if unix_result != 0

    return @microseconds <=> other_ts.microseconds
  end

end

end #module Monopaste
