
module Monopaste

module Schedule

  def self.callback_every(n_microseconds, *args, **kwargs, &bloc)
    if n_microseconds < 1
      raise ArgumentError.new, "invalid n_microseconds"
    end

    itr = 0
    flt = n_microseconds/1000000.0
    loop do
      sleep(flt)
      return if bloc.call(itr, *args) != true
      itr += 1
    end
  end

end

end #module Monopaste
