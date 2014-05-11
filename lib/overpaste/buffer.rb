require 'overpaste/timestamp'

module Overpaste

class Buffer
  attr_reader :timestamp, :value, :tag

  def initialize(ts, value, tag="")
    if !ts.is_a?(Timestamp)
      raise ArgumentError.new, "ts must be a timestamp"
    end
    @ts = ts

    if value.encoding != Encoding::UTF_8
      raise ArgumentError.new, "value must be utf-8 encoded"
    end
    @value = value

    @tag = tag
  end

end

end #module Overpaste
