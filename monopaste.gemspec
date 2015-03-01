Gem::Specification.new do |s|
  s.name        = 'monopaste'
  s.version     = '0.0.2'
  s.date        = '2014-07-26'
  s.summary     = 'push/pull {clip|paste}board content to/from multiple environments'
  s.description = s.summary
  s.authors     = ['anthony cantor']
  s.homepage    = 'https://github.com/cantora/monopaste'
  s.add_runtime_dependency 'inifile', '~> 2.0'
  s.files       = ['lib/monopaste.rb'] + [
    'daemon',
    'buffer',
    'adapter',
    'originatesbuffers',
    'receivesbuffers',
    'timestamp',
    'config',
    'logs',
    'pollsforbuffers',
    'poolsthreads',
    'connectstoserver',
    'schedule',
    'subprocess',
    'protocol',
    'protocol/state',
    'protocol/message',
    'client',
    'poolsthreads'
  ].map {|x| ['lib', 'monopaste', x + ".rb"].join("/") } + [
    'tmux-cli',
    'osx-cli',
    'xclip',
    'socket'
  ].map {|x| ['lib', 'monopaste', 'adapters', x + ".rb"].join("/") }
  s.license       = 'GPLv3'
  s.executables   = ['monopasted', 'monopaste']
end
