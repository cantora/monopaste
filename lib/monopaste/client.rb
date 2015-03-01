require 'optparse'
require 'logger'

require 'monopaste/config'
require 'monopaste/connectstoserver'

module Monopaste

class Client
  include ConnectsToServer

  CMDS = ["buf", "push"]

  def self.parse(argv)
    options = {
      :verbose       => 1,
      :conf          => Monopaste::Config::default_path(ENV),
      :no_newline    => false,
      :strip         => true,
      :cmd           => "buf",
      :cmd_args      => [],
      :addr          => nil
    }

    optparse = OptionParser.new do |opts|
      opts.banner = "usage: monopaste [options] [CMD] [CMD-OPTS]"
      opts.separator ""

      opts.separator "CMD := #{CMDS.join(", ")}"
      opts.separator ""

      opts.separator "command (default): buf [N]"
      newline_help = 'dont print a newline after output'
      opts.on('-n', '--no-newline', newline_help) do
        options[:no_newline] = true
      end
      opts.separator ""

      opts.separator "command: push [FILE]"
      strip_help = "strip data before sending." \
                 + " default: #{options[:strip]}"
      opts.on('--[no-]strip', strip_help) do |v|
        options[:strip] = v
      end
      opts.separator ""

      opts.separator "common options:"

      conf_help = "configuration file. default: #{options[:conf]}"
      opts.on('-C', '--config PATH', conf_help) do |path|
        options[:conf] = path
      end

      opts.on('-s', '--sock PATH', "socket address.") do |path|
        options[:addr] = path
      end

      opts.on('-v', '--verbose', 'verbose output') do
        options[:verbose] += 1
      end

      opts.on('-q', '--quiet', 'quiet log output') do
        options[:verbose] -= 1
        options[:verbose] = 0 if options[:verbose] < 0
      end

      h_help = 'display this message.'
      opts.on('-h', '--help', h_help) do
        raise ArgumentError.new,  ""
      end
    end

    begin
      optparse.parse!(argv)
      if argv.size > 0
        options[:cmd] = argv.shift()
        if !CMDS.include?(options[:cmd])
          m = "invalid command #{options[:cmd].inspect}"
          raise ArgumentError.new(m)
        end
        options[:cmd_args] = argv
      end
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
      #t.strftime("%H:%M:%S $ ") + msg + "\n"
      msg + "\n"
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

  def err_exit(msg)
    $stderr.puts(msg)
    exit(1)
  end

  def cmd_buf(index)
    buf = begin
      buf_from_server(index)
    rescue ConnectsToServer::Error => e
      @log.error(e.message)
      2
    end

    if buf.size > 0
      print(buf)
      print("\n") if !@options[:no_newline]
      0
    else
      3
    end
  end

  def cmd_push(fpath)
    contents = if fpath == :stdin
      $stdin.read()
    else
      begin
        File.open(fpath) do |f|
          f.read()
        end
      rescue Errno::ENOENT => e
        @log.error("error opening #{fpath}: #{e.message}")
        return 1
      end
    end

    if contents.encoding != Encoding::UTF_8
      contents.encode!(Encoding::UTF_8)
    end

    data = @options[:strip]? contents.strip() : contents
    if data.size < 1
      @log.error("contents is empty")
      return 1
    end

    result = push_to_server(data)
    if !result
      @log.error(result)
      2
    else
      0
    end
  end

  def addr_from_conf
    conf = Config.new(@options[:conf])
    @log.debug("config: #{conf.inspect}")
    begin
      conf.lookup("socket", "address")
    rescue Config::KeyNotFound
      err_exit "could not determine the path of " + \
               "the server socket"
    end
  end

  def get_addr
    addr = @options[:addr]
    if addr.nil?
      addr_from_conf()
    else
      addr
    end
  end

  def run
    @log.debug("options: #{@options.inspect}")

    addr = get_addr()
    @log.debug("server socket: #{addr.inspect}")
    result = connect_to_server(addr)
    if result.is_a?(String)
      err_exit result
    end

    status = case @options[:cmd]
    when "buf"
      n = if @options[:cmd_args].size > 0
        @options[:cmd_args][0].to_i
      else
        0
      end
      cmd_buf(n)
    when "push"
      fpath = if @options[:cmd_args].size > 0
        @options[:cmd_args][0]
      else
        :stdin
      end
      cmd_push(fpath)
    else
      1
    end

    disconnect_to_server()

    return status
  end

end #class Client

end #module Monopaste
