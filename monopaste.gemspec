Gem::Specification.new do |s|
  s.name        = 'monopaste'
  s.version     = '0.0.1'
  s.date        = '2014-05-07'
  s.summary     = 'push {clip|paste}board content out to multiple environments'
  s.description = s.summary
  s.authors     = ['anthony cantor']
  s.files       = [File.join('lib', 'monopaste.rb')] + [
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
  ].map {|x| File.join('lib', 'monopaste', x + ".rb") } + [
    'tmux-cli'
  ].map {|x| File.join('lib', 'monopaste', 'adapters', x + ".rb") }
  s.license       = 'GPLv3'
  s.executables   = ['monopasted']
end
