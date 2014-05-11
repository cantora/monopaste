
module Overpaste

class Timestamp
  attr_reader :unix_ts, :microseconds

  def initialize(unix_ts, microseconds)
    @unix_ts = unix_ts
    @microseconds = microseconds
    if @microseconds >= 100000
      raise ArgumentError.new, "invalid microseconds: #{@microseconds}"
    end
  end
end

end #module Overpaste
