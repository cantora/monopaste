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
      raise "not implemented"
    end
  end

  class ProtoError < Base
    Byte = 0x00

    def payload()
      [self.opcode].pack("C")
    end
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
        raise ArgumentError.new("expected an array of bytes")
      end
      @buf = buf
    end

    def payload()
      ([self.opcode, @buf.size] + @buf).pack("CS<C*")
    end
  end

  #OP_REQ_PUSH = 0x03
  #OP_RES_PUSH = 0x04
end #module Message
end #module Protocol
end #module Monopaste
