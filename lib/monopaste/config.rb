require 'inifile'

require 'monopaste/adapter'
require 'monopaste/logs'

module Monopaste

=begin
example:
[tmux]
poll_interval = 500 ; milliseconds

=end

class Config
  include Logs

  def self.default_path(env)
    File.join(ENV['HOME'] || '/etc', '.monopasterc')
  end

  def initialize(path)
    @ini = if File.file?(path)
      IniFile::load(path)
    else
      nil
    end

    @ini.sections.each do |adap|
      begin
        require(File.join('monopaste', 'adapters', adap))
      rescue LoadError => e
        logger.warn("failed to load adapter #{adap}: #{e.message}")
      end
    end
  end

  def lookup_from_ini(section, key)
    return nil if !@ini
    return @ini[section][key]
  end

  def default(section, key)
    val = Adapter::table[section].conf_default(key)
    if val.nil?
      raise "no default value for configuration #{section.inspect}.#{key.inspect}"
    end

    return val
  end

  def lookup(section, key)
    val = lookup_from_ini(section, key)
    return val.nil?? default(section, key) : val
  end
end

end #module Monopaste
