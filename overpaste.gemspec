Gem::Specification.new do |s|
  s.name        = 'overpaste'
  s.version     = '0.0.1'
  s.date        = '2014-05-07'
  s.summary     = 'push {clip|paste}board content out to multiple environments'
  s.description = s.summary
  s.authors     = ['anthony cantor']
  s.files       = [File.join('lib', 'overpaste.rb')] + [
    'daemon',
    'buffer',
    'adapter',
    'originatesbuffers',
    'receivesbuffers',
    'timestamp',
    'config',
    'logs',
    'pollsforbuffers',
    'schedule'
  ].map {|x| File.join('lib', 'overpaste', x + ".rb") } + [
    'tmux-cli'
  ].map {|x| File.join('lib', 'overpaste', 'adapters', x + ".rb") }
  s.license       = 'GPLv3'
  s.executables   = ['overpasted']
end
