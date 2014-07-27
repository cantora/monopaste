module Monopaste
module Protocol
module Message
  class Base
    def opcode()
      self.class::Byte
    end

    def serialize()
      Protocol::MAGIC_BYTES + self.payload()
    end

    def payload()
      [self.opcode].pack("C")
    end
  end

  class ProtoError < Base
    Byte = 0x00
  end

  class Bye < Base
    Byte = 0xff
  end

  class ReqBufN < Base
    Byte = 0x01
    
    attr_reader :index
    def initialize(index)
      @index = index
    end

    def payload()
      [self.opcode, @index].pack("CS<")
    end
  end

  class ResBufN < Base
    Byte = 0x02

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

  #OP_REQ_PUSH = 0x03
  #OP_RES_PUSH = 0x04
end #module Message
end #module Protocol
end #module Monopaste
