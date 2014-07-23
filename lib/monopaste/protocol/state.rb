require 'monopaste/protocol/message'

module Monopaste::Protocol::State

  class Base
    #b is the byte to parse
    #bloc is a callback invoked on a parsed message
    def parse_byte(b, &bloc)
      raise "not implemented"
    end
  end

  class End < Base
    def initialize(value=nil)
      @value = value
    end
  end

  class UInt16 < Base
    def initialize()
      @first_byte = nil
    end

    def parse_byte(b, &_)
      if !@first_byte
        @first_byte = b
        self
      else
        End.new([@first_byte, b].pack("S<"))
      end
    end
  end

  class ReqBufN < UInt16
    def parse_bytes(b, &bloc)
      state = super(b, &bloc)

      if state.is_a?(End)
        bloc.call(Protocol::Message::ReqBufN(result.value))
      end

      return state
    end
  end

  class LV < Base
    def initialize()
      @state = :length
      @uint16 = UInt16.new()
      @value = ''.encode('US-ASCII')
    end

    def parse_byte_length(b, &bloc)
      @uint16 = @uint16.parse_byte(b, &bloc)
      if @uint16.is_a?(End)
        @state = :value
        @uint16 = @uint16.value
        if @uint16 < 0 || @uint16 > 65535
          raise "how could @uint16 = #{@uint16.inspect}?"
        end
      end
    end

    def parse_byte_value(b, &_)
      if @value.size < @uint16
        @value << b.chr().encode('US-ASCII')
        return false
      end
      return true
    end

    def parse_byte(b, &bloc)
      @state = if @state == :length
        self.parse_byte_length(b, &bloc)
      else
        if self.parse_byte_value(b, &bloc)
          return End.new(@value)
        end
      end

      return self
    end
  end

  class ResBufN < LV

    def parse_byte(b, &bloc)
      state = super(b, &bloc)
      if state.is_a?(End)
        bloc.call(Protocol::Message::ResBufN.new(state.value))
      end

      return state
    end
  end

  class Seek < Base
    MAGIC = "\x37\xd6\x4d\x02"

    def initialize()
      @state = :seek0
    end

    def state_from_opcode(opcode, &bloc)
      case opcode
      when Protocol::Message::ProtoError.Byte
        bloc.call(ProtoError.new())
        End.new()
      when Protocol::Message::ReqBufN.Byte
        ReqBufN.new()
      when Protocol::Message::ResBufN.Byte
        ResBufN.new()
      else
        Error.new()
      end
    end

    def parse_byte(b, &bloc)
      if @state == :opcode
        if !@opcode_state
          @opcode_state = state_from_opcode(b, &bloc)
        end
        @opcode_state = @opcode_state.parse_byte(b, &bloc)

        if @opcode_state.is_a?(End) \
           || @opcode_state.is_a?(Error)
          @state = :seek0
          return @opcode_state
        end
      end

      @state = case [b, @state]
      when [MAGIC[0], :seek0]
        :seek1
      when [MAGIC[1], :seek1]
        :seek2
      when [MAGIC[2], :seek2]
        :seek3
      when [MAGIC[3], :seek3]
        @opcode_state = nil
        :opcode
      else
        :seek0
      end

      return self
    end #parse_byte
  end #class Seek

end #module State
