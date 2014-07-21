require 'thread'

module Monopaste

module PoolsThreads
  def initialize_thread_pool(sz)
    @pool_q = Queue.new
    @pool_threads = []
    self.start_n_threads(sz)
  end

  def start_n_threads(n)
    (1..n).each do |i|
      @pool_threads << self.thread do
        self.main(i-1)
      end
    end
  end

  def with_thread(*args, &bloc)
    @pool_q.push([bloc, args])
  end

  def main(i)
    loop do
      bloc, args = @pool_q.pop()
      begin
        self.instance_exec(*args, &bloc)
      rescue Exception => e
        log_exception(e, "in thread #{i}")
      end
    end
  end

  def thread(&bloc)
    Thread.new do
      Thread.current.abort_on_exception = true
      bloc.call()
    end
  end
end

end #Monopaste
