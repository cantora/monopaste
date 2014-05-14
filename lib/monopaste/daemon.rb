require 'optparse'
require 'logger'

require 'monopaste/config'
require 'monopaste/schedule'

module Monopaste

class Daemon

  def self.parse(argv)
    options = {
      :verbose       => 0,
      :daemonize     => false,
      :conf          => Monopaste::Config::default_path(ENV)
    }

    optparse = OptionParser.new do |opts|
      opts.banner = "usage: #{File.basename(__FILE__)} [options]"
      opts.separator ""

      opts.separator "common options:"

      deamonize_help = 'daemonize. make sure to redirect ' +
                       'stdout and stderr somewhere.'
      opts.on('-d', '--daemonize', daemonize_help) do
        options[:daemonize] = true
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
    @log.formatter = proc do |sev, t, pname, msg|
      t.strftime("%m-%d, %H:%M:%S $ ") + msg + "\n"
    end

    @log.level = case @options[:verbose]
    when 0
      Logger::WARN
    when 1
      Logger::INFO
    else
      Logger::DEBUG
    end

    Monopaste::set_logger(@log)
  end

  def push(adapters)
      bufs = []
      adapters.each do |name, inst|
        inst.buffers().each do |buf|
          bufs << [name, buf].freeze
        end
      end
      return if bufs.empty?

      bufs.sort_by! {|name, buf| buf.timestamp }
      source_name, buf = bufs.last()

      @log.debug("push buffer out to endpoints:")
      @log.debug("  #{buf.inspect}")

      adapters.each do |name, inst|
        next if source_name == name
        inst.receive_buffer(buf)
      end
  end

  def run
    @log.debug("options: #{@options.inspect}")

    conf = Config.new(@options[:conf])

    if @options[:daemonize]
      Process.daemon(nochdir=true, noclose=true)
    end

    adapters = {}
    Adapter::table.each do |name, klass|
      @log.info("setup adapter: #{name.inspect}")
      adapters[name] = klass.new(conf)
    end

    Schedule::callback_every(250*1000) do
      push(adapters)
      true
    end
  end

end #class Daemon

end #module Monopaste
