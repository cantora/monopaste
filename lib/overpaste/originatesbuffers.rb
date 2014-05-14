require 'thread'

require 'overpaste/timestamp'
require 'overpaste/buffer'

module Overpaste

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
        && (@prev_buf.nil? || str != @prev_buf)
      add_to_buffer_history(str)
      @prev_buf = str
    end
  end

  def add_to_buffer_history(str)
    with_buffer_history do
      ts = Time.now
      stamp = Timestamp.new(ts.to_i, ts.tv_usec)
      record = Buffer.new(stamp, str)
      logger.info("got buffer from #{self.class.adapter_name} at #{stamp.inspect}")
      self.buffer_history << record
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

end #module Overpaste
