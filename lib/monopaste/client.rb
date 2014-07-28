require 'optparse'
require 'logger'

require 'monopaste/config'
require 'monopaste/protocol'
require 'monopaste/protocol/message'

module Monopaste

class Client
  CMDS = ["buf", "push"]

  def self.parse(argv)
    options = {
      :verbose       => 1,
      :conf          => Monopaste::Config::default_path(ENV),
      :no_newline    => false,
      :strip         => true,
      :cmd           => "buf",
      :cmd_args      => []
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

  def cmd_buf(sock, index)
    req = Protocol::Message::ReqBufN.new(index)
    data = req.serialize()
    @log.debug("send #{data.inspect}")
    sock.send(data, 0)

    resp = get_response(sock)
    if resp.nil?
      @log.warn "no response from server"
      return 4
    end

    @log.debug("response #{resp.inspect}")
    if resp.is_a?(Protocol::Message::ResBufN)
      buf = resp.to_str()
      #puts buf.inspect
      if buf.size > 0
        print(buf)
        print("\n") if !@options[:no_newline]
        0
      else
        1
      end
    else
      @log.error("server replied with #{resp.class} message")
      @log.debug("the message: #{resp.inspect})")
      2
    end
  end

  def cmd_push(sock, fpath)
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

    req = Protocol::Message::ReqPush.from_str(data)
    data = req.serialize()
    @log.debug("send #{data.inspect}")
    sock.send(data, 0)

    resp = get_response(sock)
    if resp.nil?
      @log.warn "no response from server"
      return 4
    end

    @log.debug("response #{resp.inspect}")
    case resp
    when Protocol::Message::ResOK
      0
    when Protocol::Message::ResFail
      msg = resp.to_str()
      @log.error("failed to push buffer: #{msg}")
      3
    else
      @log.error("server replied with #{resp.class} message")
      @log.debug("the message: #{resp.inspect})")
      2
    end
  end

  def run
    @log.debug("options: #{@options.inspect}")

    conf = Config.new(@options[:conf])
    @log.debug("config: #{conf.inspect}")
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

    status = case @options[:cmd]
    when "buf"

      n = if @options[:cmd_args].size > 0
        @options[:cmd_args][0].to_i
      else
        0
      end
      cmd_buf(sock, n)
    when "push"
      fpath = if @options[:cmd_args].size > 0
        @options[:cmd_args][0]
      else
        :stdin
      end
      cmd_push(sock, fpath)
    else
      1
    end

    sock.send(Protocol::Message::Bye.new().serialize(), 0)
    sock.close()
    @log.debug("closed socket")

    return status
  end

end #class Client

end #module Monopaste
