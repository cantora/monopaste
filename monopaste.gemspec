Gem::Specification.new do |s|
  s.name        = 'monopaste'
  s.version     = '0.0.1'
  s.date        = '2014-05-07'
  s.summary     = 'push {clip|paste}board content out to multiple environments'
  s.description = s.summary
  s.authors     = ['anthony cantor']
  s.files       = ['lib/monopaste.rb'] + [
    'daemon',
    'buffer',
    'adapter',
    'originatesbuffers',
    'originatesandreceivesbuffers',
    'receivesbuffers',
    'timestamp',
    'config',
    'logs',
    'pollsforbuffers',
    'schedule'
  ].map {|x| ['lib', 'monopaste', x + ".rb"].join("/") } + [
    'tmux-cli',
    'osx-cli'
  ].map {|x| ['lib', 'monopaste', 'adapters', x + ".rb"].join("/") }
  s.license       = 'GPLv3'
  s.executables   = ['monopasted']
end
