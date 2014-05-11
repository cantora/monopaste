require 'overpaste/schedule'

module Overpaste

module PollsForBuffers

  module ClassMethods
    def to_poll(&bloc)
      @poll_bloc = bloc
    end

    def poll_block()
      return @poll_bloc
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
    klass.to_init(self.name) do |inst|
      inst.run_poll_thread()
    end
  end

  def run_poll_thread()
    Thread.new do
      Thread.current.abort_on_exception = true

      msecs = conf('poll_interval').to_i
      usecs = msecs*1000
      Schedule::callback_every(usecs) do
        self.do_poll()
      end
    end
  end

  def do_poll()
    self.instance_exec(&self.class.poll_block())
  end
end

end #module Overpaste
