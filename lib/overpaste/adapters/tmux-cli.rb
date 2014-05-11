[
  'pollsforbuffers',
  'receivesbuffers',
  'originatesbuffers',
  'logs',
  'adapter'
].each {|x| require(File.join('overpaste', x)) }

module Overpaste

Adapter::define_adapter_for('tmux-cli') do
  include OriginatesBuffers
  include PollsForBuffers
  include ReceivesBuffers
  include Logs

  set_conf_default('poll_interval', 500)
    
  to_poll do
    logger.debug("tmux poll")
  end

end

end #module Overpaste
