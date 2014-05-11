
module Overpaste

module Schedule

  def self.callback_every(n_microseconds, *args, **kwargs, &bloc)
    if n_microseconds < 1
      raise ArgumentError.new, "invalid n_microseconds"
    end

    flt = n_microseconds/1000000.0
    loop do
      sleep(flt)
      return if !bloc.call(*args)
    end
  end

end

end #module Overpaste
