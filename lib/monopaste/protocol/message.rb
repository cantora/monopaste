module Monopaste
module Protocol
module Message
  class Base
    def opcode()
      self.class::BYTE
    end

    def serialize()
      Protocol::MAGIC_BYTES + self.payload()
    end

    def payload()
      [self.opcode].pack("C")
    end
  end

  class ProtoError < Base
    BYTE = 0x00
  end

  class Bye < Base
    BYTE = 0xff
  end

  class ReqBufN < Base
    BYTE = 0x01
    
    attr_reader :index
    def initialize(index)
      @index = index
    end

    def payload()
      [self.opcode, @index].pack("CS<")
    end
  end

  class BufMsg < Base

    attr_reader :buf
    def initialize(buf)
      if !buf.is_a?(Array)
        m = "expected an array of bytes: #{buf.inspect}"
        raise ArgumentError.new(m)
      end
      @buf = buf
    end

    def self.from_str(s)
      if s.encoding != Encoding::UTF_8
        m = "expected utf-8, not #{s.encoding.inspect}"
        raise ArgumentError.new(m)
      end
      #treat the UTF-8 as raw bytes for transfer
      self.new(s.unpack("C*"))
    end

    def payload()
      ([self.opcode, @buf.size] + @buf).pack("CS<C*")
    end

    def to_str()
      #unpack as raw bytes (no conversion) then
      #change encoding to UTF-8
      @buf.pack("C*").force_encoding('UTF-8')
    end
  end

  class ResBufN < BufMsg
    BYTE = 0x02
  end

  class ReqPush < BufMsg
    BYTE = 0x03
  end

  class ResOK < Base
    BYTE = 0x04
  end

  class ResFail < BufMsg
    BYTE = 0x05
  end

end #module Message
end #module Protocol
end #module Monopaste
