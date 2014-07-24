require 'monopaste/protocol/state'

module Monopaste

module Protocol

  ENCODING = Encoding::ASCII_8BIT
  MAGIC = [0xff, 0xfe, 0xfd, 0xfc]
  MAGIC_BYTES = MAGIC.pack("C*")

  class Parser
    def initialize(&on_error)
      self.reset_state()
      @on_error = on_error
    end

    def reset_state()
      @state = Protocol::State::Seek.new()
    end

    def parse(bytes, &bloc)
      if bytes.is_a?(String)
        if bytes.encoding != ENCODING
          raise "invalid encoding: #{bytes.encoding.inspect}"
        end

        bytes = bytes.bytes        
      end

      n = 0
      bytes.each do |b|
        if self.parse_byte(b, &bloc)
          return n
        end
        n += 1
      end

      return n
    end

    def parse_byte(b, &bloc)
      if !b.is_a?(Numeric)
        raise "invalid byte #{b.inspect}"
      end

      @state = @state.parse_byte(b, &bloc)
      if @state.is_a?(State::Error)
        @state.abort = @on_error.nil?? true : @on_error.call()
      end

      if @state.is_a?(State::End)
        abort = @state.abort
        self.reset_state()
        abort == true
      else
        false
      end
    end
  end
end

end # Monopaste
