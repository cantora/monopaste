require 'socket'
require 'monopaste/protocol'
require 'monopaste/protocol/message'

module Monopaste
module ConnectsToServer

  class Error < Exception; end

  def connect_to_server(path)
    raise "already initialized socket" if !@sock.nil?
    if !File.socket?(path)
      return "file #{path} is not a socket"
    end

    sock = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
    begin
      sock.connect(Socket.pack_sockaddr_un(path))
    rescue Errno => e
      return "failed to connect to server: #{e.inspect}"
    end

    @CTS_sock = sock
    true
  end

  def disconnect_to_server()
    @CTS_sock.send(Protocol::Message::Bye.new().serialize(), 0)
    @CTS_sock.close()
  end

  def response_from_server()
    last_data = Time.now()
    parser = Protocol::Parser.new()

    loop do
      bytes = begin
        @CTS_sock.recv_nonblock(1)
      rescue IO::EAGAINWaitReadable
        ""
      end

      if bytes.size < 1
        if Time.now() - last_data > 2
          return "server timeout"
        end
        next
      end

      last_data = Time.now()
      n = parser.parse(bytes) do |msg|
        return msg
      end
      return "parser error" if n < bytes.size
    end

    raise "shouldnt get here"
  end

  def push_to_server(buf)
    if buf.size < 1
      return "buf is empty"
    end

    if buf.encoding != Encoding::UTF_8
      raise "buf is not utf encoded!"
    end

    req = Protocol::Message::ReqPush.from_str(buf)
    data = req.serialize()
    @CTS_sock.send(data, 0)

    resp = response_from_server()
    return resp if resp.is_a?(String) #error

    case resp
    when Protocol::Message::ResOK
      true
    when Protocol::Message::ResFail
      msg = resp.to_str()
      "failed to push buffer: #{msg}"
    else
      "server replied with #{resp.class} message"
    end
  end # push_to_server

  def buf_from_server(index)
    req = Protocol::Message::ReqBufN.new(index)
    data = req.serialize()
    @CTS_sock.send(data, 0)

    resp = response_from_server()
    raise Error.new(resp) if resp.is_a?(String)

    if resp.is_a?(Protocol::Message::ResBufN)
      return resp.to_str()
    end

    raise Error.new("server replied with #{resp.class} message: #{resp.inspect}")
  end

end #ConnectsToServer
end #Monopaste
