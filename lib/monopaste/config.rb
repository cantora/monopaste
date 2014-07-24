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

  class KeyNotFound < Exception; end

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
    adapter = Adapter::table[section]
    return nil if adapter.nil?
    return adapter.conf_default(key)
  end

  def lookup(section, key)
    val = lookup_from_ini(section, key)
    val = val.nil?? default(section, key) : val
    if val.nil?
      m = "no value for configuration " + \
          "#{section.inspect}.#{key.inspect}"
      raise KeyNotFound.new(m)
    end

    return val
  end
end

end #module Monopaste
