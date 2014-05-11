require 'optparse'
require 'logger'

require 'overpaste/config'

module Overpaste

class Daemon

  def self.parse(argv)
    options = {
      :verbose       => 0,
      :daemonize     => true,
      :conf          => Overpaste::Config::default_path(ENV)
    }

    optparse = OptionParser.new do |opts|
      opts.banner = "usage: #{File.basename(__FILE__)} [options]"
      opts.separator ""

      opts.separator "common options:"

      opts.on('--dd', 'dont daemonize') do
        options[:daemonize] = false
      end

      conf_help = "configuration file. default: #{options[:conf]}"
      opts.on('-C', '--config PATH', conf_help) do |path|
        options[:conf] = path
      end

      opts.on('-v', '--verbose', 'verbose output') do
        options[:verbose] += 1
      end

      h_help = 'display this message.'
      opts.on('-h', '--help', h_help) do
        raise ArgumentError.new,  ""
      end
    end

    begin
      optparse.parse!(argv)

    rescue ArgumentError => e
      puts e.message if !e.message.empty?
      puts optparse

      exit
    end

    return options
  end #self.parse

  def initialize(options)
    @options = options
    @log = Logger.new($stderr)
    #@log.formatter = proc do |sev, t, pname, msg|
    #  msg + "\n"
    #end

    @log.level = case @options[:verbose]
    when 0
      Logger::WARN
    when 1
      Logger::INFO
    else
      Logger::DEBUG
    end

    Overpaste::set_logger(@log)
  end

  def run
    @log.debug("options: #{@options.inspect}")

    conf = Config.new(@options[:conf])

    adapters = {}
    Adapter::table.each do |name, klass|
      @log.info("setup adapter: #{name.inspect}")
      adapters[name] = klass.new(conf)
    end

    loop do

    end
  end

end #class Daemon

end #module Overpaste
