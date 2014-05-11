
module Overpaste

module Adapter

  class Abstract

    def initialize(config)
      set_conf(config)
      self.class::init_blocks().each do |formod, bloc|
        logger.debug("init block for #{formod}")
        bloc.call(self)
      end
    end

    def set_conf(config)
      @config = config
    end

    def conf(key)
      return @config[self.class.adapter_name()][key]
    end

    def self.set_adapter_name(name)
      @a_name = name
    end

    def self.adapter_name()
      return @a_name
    end

    def self.defaults()
      @defaults ||= {}
      return @defaults
    end

    def self.set_conf_default(key, val)
      self.defaults[key] = val
    end

    def self.init_blocks()
      @init_blocs ||= []
      return @init_blocs
    end

    def self.to_init(mod_name, &bloc)
      self.init_blocks() << [mod_name, bloc].freeze
    end

  end

  def self.table()
    @adapters ||= {}
    return @adapters
  end

  def self.define_adapter_for(adapter_name, &bloc)
    klass = Class.new(Abstract, &bloc)
    klass.set_adapter_name(adapter_name)

    self.table[adapter_name] = klass
    return klass
  end

end

end