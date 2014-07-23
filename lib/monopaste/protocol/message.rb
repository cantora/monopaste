module Monopaste::Protocol::Message
  class Base; end

  class ProtoError < Base
    Byte = 0x00
  end

  class ReqBufN < Base
    Byte = 0x01
    
    attr_reader :index
    def initialize(index)
      @index = index
    end
  end

  class ResBufN < Base
    Byte = 0x02

    attr_reader :buf
    def initialize(buf)
      @buf = buf
    end
  end

  #OP_REQ_PUSH = 0x03
  #OP_RES_PUSH = 0x04
end #module Message

