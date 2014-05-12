require 'tempfile'
[
  'pollsforbuffers',
  'receivesbuffers',
  'originatesbuffers',
  'logs',
  'adapter',
].each {|x| require(File.join('overpaste', x)) }

module Overpaste

Adapter::define_adapter_for('tmux-cli') do
  include OriginatesBuffers
  include PollsForBuffers
  include ReceivesBuffers
  include Logs

  set_conf_default('poll_interval', 500)

  to_poll do |itr|
    process_buffer(`tmux show-buffer`)
  end

  def receive_buffer(buf)
    f = Tempfile.new("overpaste-tmux-cli.tmp")
    f << buf.value
    f.close()

    `tmux load-buffer #{f.path()}`
    f.unlink()
  end
end

end #module Overpaste
