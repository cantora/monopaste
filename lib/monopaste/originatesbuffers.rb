require 'thread'

require 'monopaste/timestamp'
require 'monopaste/buffer'

module Monopaste

module OriginatesBuffers

  def buffer_history()
    @buf_history ||= []

    return @buf_history
  end

  def with_buffer_history(&bloc)
    @buf_history_mtx ||= Mutex.new

    @buf_history_mtx.synchronize do
      bloc.call(self.buffer_history)
    end
  end

  def originate_buffer(&bloc)
    str = bloc.call
    if !str.nil? && !str.empty? \
        && (self.last_buf.nil? || str != self.last_buf.value)
      self.last_buf = add_to_buffer_history(str)
    end
  end

  def add_to_buffer_history(str)
    with_buffer_history do
      record = self.produce_buffer(Timestamp.now(), str)
      logger.info("[#{self.class.adapter_name}] -> [monopaste]")
      self.buffer_history << record
      record
    end
  end

  def buffers()
    with_buffer_history do
      sz = self.buffer_history.size
      if sz > 0
        self.buffer_history.pop(sz)
      else
        []
      end
    end
  end

end

end #module Monopaste
