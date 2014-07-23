require 'monopaste/protocol/state'

module Monopaste

module Protocol

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
        if bytes.encoding != 'US-ASCII'
          raise "invalid encoding: #{bytes.encoding.inspect}"
        end

        bytes = bytes.bytes        
      end

      bytes.each do |b|
        self.parse_byte(b, &bloc)
      end
    end

    def parse_byte(b, &bloc)
      if !b.is_a?(Numeric)
        raise "invalid byte #{b.inspect}"
      end

      @state = @state.parse_byte(b, &bloc)
      case @state
      when Error
        @on_error.call()
        self.reset_state()
      when End
        self.reset_state()
      else
        #do nothing
      end
    end
  end
end

end # Monopaste
