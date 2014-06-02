[
  'pollsforbuffers',
  'originatesandreceivesbuffers',
  'logs',
  'adapter',
].each {|x| require(['monopaste', x].join("/")) }

module Monopaste

module XClip
  OPTIONS = '-selection clipboard'
  CMD = 'xclip'

  def self.get_buffer(display)
    `#{CMD} -o #{OPTIONS} -display '#{display}'`
  end

  def self.put_buffer(display, buf)
    IO.popen("#{CMD} -in #{OPTIONS} -display '#{display}'", mode="w") do |io|
      io << buf.value
    end
  end
end

missing = false
if `which #{XClip::CMD}`.strip.empty?
  warning = "cannot use xclip adapter: #{XClip::CMD} command is missing"
  Monopaste.logger().warn(warning)
  missing = true
end

Adapter::define_adapter_for('xclip') do
  include OriginatesAndReceivesBuffers
  include PollsForBuffers
  include Logs

  set_conf_default('poll_interval', 500)
  set_conf_default('display', ':0')

  to_poll do |itr|
    originate_buffer do
      XClip::get_buffer(self.conf('display'))
    end
  end

  on_buffer do |buf|
    XClip::put_buffer(self.conf('display'), buf)
  end
end if missing != true

end #module Monopaste
