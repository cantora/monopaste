
module Monopaste

module ReceivesBuffers

  module ClassMethods
    def on_buffer(&bloc)
      @receive_bloc = bloc
    end

    def receive_block()
      return @receive_bloc
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  def receive_buffer(buf)
    logger.info("[#{self.class.adapter_name}] <- [monopaste]")
    if !self.class.receive_block.nil?
      self.instance_exec(buf, &self.class.receive_block)
    end

    self.last_buf = buf
  end

end

end #module Monopaste
