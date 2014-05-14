
module Monopaste

  def self.logger()
    @logger ||= Logger.new('/dev/null')
    return @logger
  end

  def self.set_logger(lgr)
    @logger = lgr
  end
end

module Monopaste
module Logs

  module ClassMethods
    def set_logger(lgr)
      @log_logger = lgr
    end

    def logger()
      if @log_logger.nil?
        Monopaste::logger()
      else
        @log_logger
      end
    end

  end

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  def set_logger(lgr)
    @log_logger = lgr
  end

  def logger
    if @logs_logger.nil?
      self.class.logger()
    else
      @logs_logger
    end
  end
end

end #module Monopaste
