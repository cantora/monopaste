[
  'pollsforbuffers',
  'originatesandreceivesbuffers',
  'logs',
  'adapter',
].each {|x| require(['monopaste', x].join("/")) }

module Monopaste

module OSXCLI
  OPTIONS = '-pboard general'
  def self.get_buffer()
    `pbpaste #{OPTIONS}`
  end

  def self.put_buffer(buf)
    IO.popen("pbcopy #{OPTIONS}", mode="w") do |io|
      io << buf
    end
  end
end

missing = false
["pbpaste", "pbcopy"].each do |cmd|
  if `which #{cmd}`.strip.empty?
    warning = "cannot use osx-cli adapter: #{cmd} command is missing"
    Monopaste.logger().warn(warning)
    missing = true
    break
  end
end

within_tmux = false
if !missing
  original = OSXCLI.get_buffer()
  test = (0...16).map { (65 + rand(26)).chr }.join
  OSXCLI.put_buffer(test)
  if test != OSXCLI.get_buffer()
    warning = "cannot use osx-cli adapter within tmux, " +
              "start daemon outside of tmux session"
    Monopaste.logger().warn(warning)
    within_tmux = true
  else
    OSXCLI.put_buffer(original)
  end
end

Adapter.define_adapter_for('osx-cli') do
  include OriginatesAndReceivesBuffers
  include PollsForBuffers
  include Logs

  set_conf_default('poll_interval', 500)

  to_poll do |itr|
    originate_buffer do
      OSXCLI.get_buffer()
    end
  end

  on_buffer do |buf|
    OSXCLI.put_buffer(buf.value)
  end

end if !missing && !within_tmux

end #module Monopaste
