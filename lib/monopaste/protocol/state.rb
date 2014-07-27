require 'monopaste/protocol/message'

module Monopaste
module Protocol
module State

  class Base
    #b is the byte to parse
    #bloc is a callback invoked on a parsed message
    def parse_byte(b, &bloc)
      raise "not implemented"
    end
  end

  class End < Base
    attr_reader :value
    attr_accessor :abort

    def initialize(value=nil, abort=false)
      @value = value
      @abort = abort
    end
  end

  class Error < End; end

  class UInt16 < Base
    def initialize()
      @first_byte = nil
    end

    def parse_byte(b, &_)
      if !@first_byte
        @first_byte = b
        self
      else
        val = [@first_byte, b].pack("C*").unpack("S<").first
        End.new(val)
      end
    end
  end

  class ReqBufN < UInt16
    def parse_byte(b, &bloc)
      state = super(b, &bloc)

      #puts "ReqBufN.parse_byte: #{state.inspect}"
      if state.is_a?(End)
        state.abort = bloc.call(
          Protocol::Message::ReqBufN.new(state.value)
        )
      end

      return state
    end
  end

  class LV < Base
    def initialize()
      @state = :length
      @uint16 = UInt16.new()
      @value = []
    end

    def parse_byte_length(b, &bloc)
      @uint16 = @uint16.parse_byte(b, &bloc)
      if @uint16.is_a?(End)
        @uint16 = @uint16.value
        if @uint16 < 0 || @uint16 > 65535
          raise "how could @uint16 = #{@uint16.inspect}?"
        end
        (@uint16 == 0)? :done : :value
      else
        :length
      end
    end

    def parse_byte_value(b, &_)
      @value << b
      if @value.size >= @uint16
        return :done
      end

      return :value
    end

    def parse_byte(b, &bloc)
      @state = case @state
      when :length
        self.parse_byte_length(b, &bloc)
      when :value
        self.parse_byte_value(b, &bloc)
      else
        raise "shouldnt get here"
      end

      if @state == :done
        End.new(@value)
      else
        self
      end
    end
  end

  class BufMsg < LV

    def make_msg(bytes)
      raise "not implemented"
    end

    def parse_byte(b, &bloc)
      state = super(b, &bloc)
      if state.is_a?(End)
        state.abort = bloc.call(
          make_msg(state.value)
        )
      end

      return state
    end
  end

  class ResBufN < BufMsg
    def make_msg(bytes)
      Protocol::Message::ResBufN.new(bytes)
    end
  end

  class ReqPush < BufMsg
    def make_msg(bytes)
      Protocol::Message::ReqPush.new(bytes)
    end
  end

  class ResFail < BufMsg
    def make_msg(bytes)
      Protocol::Message::ResFail.new(bytes)
    end
  end

  class Seek < Base
    def initialize()
      @state = :seek0
    end

    def state_from_opcode(opcode, &bloc)
      case opcode
      when Protocol::Message::ProtoError::BYTE
        abort = bloc.call(Protocol::Message::ProtoError.new())
        End.new(nil, abort)
      when Protocol::Message::Bye::BYTE
        abort = bloc.call(Protocol::Message::Bye.new())
        End.new(nil, abort)
      when Protocol::Message::ReqBufN::BYTE
        ReqBufN.new()
      when Protocol::Message::ResBufN::BYTE
        ResBufN.new()
      when Protocol::Message::ReqPush::BYTE
        ReqPush.new()
      when Protocol::Message::ResOK::BYTE
        abort = bloc.call(Protocol::Message::ResOK.new())
        End.new(nil, abort)
      when Protocol::Message::ResFail::BYTE
        ResFail.new()
      else
        Error.new()
      end
    end

    def parse_byte_opcode(b, &bloc)
      if !@opcode_state
        @opcode_state = state_from_opcode(b, &bloc)
      else
        @opcode_state = @opcode_state.parse_byte(b, &bloc)
      end
      #puts @opcode_state.inspect

      if @opcode_state.is_a?(End) \
         || @opcode_state.is_a?(Error)
        @state = :seek0
        return @opcode_state
      end

      return self
    end

    def parse_byte(b, &bloc)
      #puts @state.inspect
      if @state == :opcode
        return parse_byte_opcode(b, &bloc)
      end

      @state = case [b, @state]
      when [Protocol::MAGIC[0], :seek0]
        :seek1
      when [Protocol::MAGIC[1], :seek1]
        :seek2
      when [Protocol::MAGIC[2], :seek2]
        :seek3
      when [Protocol::MAGIC[3], :seek3]
        @opcode_state = nil
        :opcode
      else
        :seek0
      end

      return self
    end #parse_byte
  end #class Seek

end #module State
end #module Protocol
end #module Monopaste
