require 'optparse'
require 'logger'

require 'monopaste/config'
require 'monopaste/protocol'
require 'monopaste/protocol/message'

module Monopaste

class Client

  def self.parse(argv)
    options = {
      :verbose       => 1,
      :conf          => Monopaste::Config::default_path(ENV)
    }

    optparse = OptionParser.new do |opts|
      opts.banner = "usage: monopaste [options]"
      opts.separator ""

      opts.separator "common options:"

      conf_help = "configuration file. default: #{options[:conf]}"
      opts.on('-C', '--config PATH', conf_help) do |path|
        options[:conf] = path
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

  def get_response(sock)
    last_data = Time.now()
    parser = Protocol::Parser.new()

    loop do
      bytes = begin
        sock.recv_nonblock(1)
      rescue IO::EAGAINWaitReadable
        ""
      end

      if bytes.size < 1
        if Time.now() - last_data > 2
          @log.warn "peer timeout"
          break
        end
        next
      end

      last_data = Time.now()
      n = parser.parse(bytes) do |msg|
        return msg
      end
      break if n < bytes.size
    end

    nil
  end

  def reqbufn(sock, index)
    req = Protocol::Message::ReqBufN.new(0)
    sock.send(req.serialize(), 0)

    resp = get_response(sock)
    if resp.nil?
      @log.warn "no response from server"
      return
    end

    puts resp.inspect
  end

  def run
    @log.debug("options: #{@options.inspect}")

    conf = Config.new(@options[:conf])
    #@log.debug("config: #{conf.inspect}")
    addr = begin
      conf.lookup("socket", "address")
    rescue Config::KeyNotFound
      err_exit "could not determine the path of " + \
               "the server socket"
    end

    @log.debug("server socket: #{addr.inspect}")
    if !File.socket?(addr)
      err_exit "file #{addr} is not a socket"
    end

    sock = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
    begin
      sock.connect(Socket.pack_sockaddr_un(addr))
    rescue Exception => e
      err_exit("failed to connect to server: #{e.message}")
    end

    reqbufn(sock, 0)
    sock.close()
  end

end #class Client

end #module Monopaste
