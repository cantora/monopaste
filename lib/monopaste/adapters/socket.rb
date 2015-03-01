require 'socket'
[
  'originatesbuffers',
  'receivesbuffers',
  'logs',
  'adapter',
  'poolsthreads',
  'protocol',
  'protocol/message'
].each {|x| require(['monopaste', x].join("/")) }

module Monopaste

Adapter::define_adapter_for('socket') do
  include OriginatesBuffers
  include ReceivesBuffers
  include Logs
  include PoolsThreads

  set_conf_default(
    'address',
    File.join(Monopaste::TMP_DIR, "socket")
  )

  def initialize(conf)
    super(conf)
    initialize_thread_pool(5)

    self.with_thread(setup_sock()) do |_, sock|
      loop do
        begin
          accept_loop(sock)
        rescue Exception => e
          log_exception(e)
        end
      end
    end
  end

  def setup_sock()
    addr = conf('address')
    begin
      File.unlink(addr)
    rescue Errno::ENOENT
    end

    perms = conf('permissions')
    sock = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
    sock.bind(Socket.pack_sockaddr_un(addr))
    if !perms.nil?
      File.chmod(perms.to_i(8), addr)
    end
    sock.listen(5)

    return sock
  end

  def accept_loop(sock)
    loop do
      client, _ = sock.accept()
      self.handle_client(client)
    end
  end

  def parse(parser, bytes, tid, &to_send)
    parser.parse(bytes) do |msg|
      self.logger.debug "[socket#{tid}] got msg #{msg.inspect}"
      abort = case msg
      when Protocol::Message::ProtoError
        self.logger.warn "[socket#{tid}] peer claims protocol error"
        reply = nil
        true
      when Protocol::Message::Bye
        self.logger.info("[socket#{tid}] peer leaves")
        reply = nil
        true
      when Protocol::Message::ReqBufN
        buf = if msg.index < 1 && !self.last_buf.nil?
          self.last_buf.value
        else
          ""
        end
        reply = Protocol::Message::ResBufN.from_str(buf)
        false
      when Protocol::Message::ReqPush
        self.originate_buffer do
          msg.to_str()
        end
        reply = Protocol::Message::ResOK.new()
        false
      else
        reply = Protocol::Message::ProtoError.new()
        true
      end

      to_send.call(reply.serialize()) if reply
      abort
    end
  end

  def handle_client(csock)
    self.with_thread do |tid|
      prefix = "[socket#{tid}] "
      self.logger.info prefix + "connection from peer"
      parser = Protocol::Parser.new do
        self.logger.warn prefix + "protocol error from peer"
        true
      end

      last_data = Time.now()
      loop do
        bytes = begin
          csock.recv_nonblock(1024)
        rescue IO::EAGAINWaitReadable
          ""
        rescue Errno::ECONNRESET
          break
        end

        if bytes.size < 1
          if Time.now() - last_data > 2
            self.logger.warn prefix + "peer timeout"
            break
          end
          next
        end

        last_data = Time.now()
        self.logger.debug prefix + "process #{bytes.inspect}"
        n = self.parse(parser, bytes, tid) do |data|
          self.logger.debug prefix + "reply with #{data.inspect}"
          csock.send(data, 0)
        end
        break if n < bytes.size
      end

      self.logger.debug prefix + "close connection"
      csock.close()
    end
  end
end

end #module Monopaste
