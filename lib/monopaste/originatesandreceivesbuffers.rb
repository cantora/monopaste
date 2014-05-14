require 'monopaste/originatesbuffers'
require 'monopaste/receivesbuffers'

module Monopaste

module OriginatesAndReceivesBuffers

  module ModuleMethods
    def receive_buffer(buf)
      @last_received_buf = buf.value
      super(buf)
    end

    def originate_buffer(&bloc)
      super() do
        str = bloc.call
        if str != @last_received_buf
          #logger.debug("str = #{str.inspect}")
          #logger.debug("last_received_buf = #{@last_received_buf.inspect}")
          @last_received_buf = nil
          str
        else
          nil
        end
      end
    end
  end

  def self.included(klass)
    mods = [OriginatesBuffers, ReceivesBuffers, ModuleMethods]
    mods.each do |m|
      klass.send(:include, m)
    end
  end

end

end
