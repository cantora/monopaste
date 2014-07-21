require 'monopaste/timestamp'

module Monopaste

class Buffer
  attr_reader :timestamp, :value, :source

  def initialize(source, ts, value)
    if !ts.is_a?(Timestamp)
      raise ArgumentError.new, "ts must be a timestamp"
    end
    @ts = ts

    if value.encoding != Encoding::UTF_8
      raise ArgumentError.new, "value must be utf-8 encoded"
    end
    @value = value

    @source = source
  end

end

end #module Monopaste
