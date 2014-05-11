require 'inifile'

require 'overpaste/adapter'
require 'overpaste/logs'

module Overpaste

=begin
example:
[tmux]
poll_interval = 500 ; milliseconds

=end

class Config
  include Logs

  def self.default_path(env)
    File.join(ENV['HOME'] || '/etc', '.overpasterc')
  end

  def initialize(path)
    @ini = if File.file?(path)
      IniFile::load(path)
    else
      nil
    end

    @ini.sections.each do |adap|
      begin
        require(File.join('overpaste', 'adapters', adap))
      rescue LoadError => e
        logger.warn("failed to load adapter #{adap}: #{e.message}")
      end
    end
  end

  def from_ini(section, key)
    return nil if !@ini
    return @ini[section][key]
  end

  def tmux_default(key)
    case key
    when 'poll_interval'
      500
    else
      nil
    end
  end

  def default(section, key)
    case section
    when 'tmux'
      tmux_default(key)
    else
      nil
    end
  end

  def [](section)
    return @ini[section]    
  end
end

end #module Overpaste
