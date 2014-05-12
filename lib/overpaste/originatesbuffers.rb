require 'thread'

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

  def add_to_buffer_history(record)
    with_buffer_history do
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
