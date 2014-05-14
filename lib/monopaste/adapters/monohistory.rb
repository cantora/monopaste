require 'thread'

[
  'originatesandreceivesbuffers',
  'logs',
  'adapter',
  'schedule'
].each {|x| require(['monopaste', x].join("/")) }

module Monopaste

Adapter::define_adapter_for('monohistory') do
  include OriginatesAndReceivesBuffers
  include Logs

  def info(s)
    logger.info("[monohistory] " + s)
  end

  after_init do
    @history = []
    @history_mtx = Mutex.new
    info("start socket thread")
    Thread.new do
      Thread.current.abort_on_exception = true
      socket_loop()
    end
  end

  def with_history(&bloc)
    @history_mtx.synchronize do
      bloc.call()
    end
  end

  def history_push(buf)
    with_history do
      @history << buf
    end
  end

  def socket_loop()
    Schedule::callback_every(10000*1000) do
      info("table:")
      with_history do
        @history.each do |buf|
          info("  "+buf)
        end
      end

      true
    end
  end

  on_buffer do |buf|
    #logger.debug("buf = #{buf.value.inspect}")
    @history << buf.value
  end
end

end #module Monopaste
