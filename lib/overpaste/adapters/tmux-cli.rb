[
  'pollsforbuffers',
  'receivesbuffers',
  'originatesbuffers',
  'logs',
  'adapter',
  'buffer',
  'timestamp'
].each {|x| require(File.join('overpaste', x)) }

module Overpaste

Adapter::define_adapter_for('tmux-cli') do
  include OriginatesBuffers
  include PollsForBuffers
  include ReceivesBuffers
  include Logs

  set_conf_default('poll_interval', 500)

  to_poll do |itr|
    @buf_history ||= []
    buf = `tmux show-buffer`
    ts = Time.now

    #logger.debug("buf(#{itr}): #{buf[0..31].inspect}")
    if !buf.nil? && !buf.empty? \
        && (@prev_buf.nil? || buf != @prev_buf)
      stamp = Timestamp.new(ts.to_i, ts.tv_usec)
      record = Buffer.new(stamp, buf)
      logger.info("got buffer from tmux at #{stamp.inspect}")
      @buf_history << record
      @prev_buf = buf
    end
  end

end

end #module Overpaste
