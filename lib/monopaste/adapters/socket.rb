require 'socket'
[
  'originatesbuffers',
  'receivesbuffers',
  'logs',
  'adapter',
  'poolsthreads'
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

    self.with_thread(setup_sock()) do |sock|
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
    File.unlink(addr)
    sock = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
    sock.bind(Socket.pack_sockaddr_un(addr))
    sock.listen(5)

    return sock
  end

  def accept_loop(sock)
    loop do
      client, _ = sock.accept()
      self.handle_client(client)
    end
  end

  def handle_client(csock)
    self.with_thread do
      pkt = csock.recv(1)
      csock.send(pkt, 0)
      csock.close()
    end
  end
end

end #module Monopaste
