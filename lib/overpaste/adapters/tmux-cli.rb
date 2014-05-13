require 'tempfile'
[
  'pollsforbuffers',
  'originatesandreceivesbuffers',
  'logs',
  'adapter',
].each {|x| require(File.join('overpaste', x)) }

module Overpaste

Adapter::define_adapter_for('tmux-cli') do
  include OriginatesAndReceivesBuffers
  include PollsForBuffers
  include Logs

  set_conf_default('poll_interval', 500)

  to_poll do |itr|
    originate_buffer do
      `tmux show-buffer`
    end
  end

  on_buffer do |buf|
    f = Tempfile.new("overpaste-tmux-cli.tmp")
    f << buf.value
    f.close()

    `tmux load-buffer #{f.path()}`
    f.unlink()
  end
end

end #module Overpaste
