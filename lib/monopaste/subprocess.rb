
require 'open3'

module Monopaste

module Subprocess

  def self.open(*args, &bloc)
    Open3::popen3(*args) do |in_s, out_s, err_s, thr|
      pid = thr.pid
      bloc.call(in_s, out_s, err_s, pid) if !bloc.nil?
      in_s.close()
      out_s.close()
      err_s.close()
      thr.value
    end
  end

  def self.stdout_if_success(*args)
    result = nil
    status = Subprocess::open(*args) do |in_s, out_s|
      result = out_s.read()
    end

    status.success?? result : nil
  end

  def self.pipe(data, *args)
    status = Subprocess::open(*args) do |in_s|
      in_s << data
    end

    status.success?
  end

  def self.success?(*args)
    Subprocess::open(*args).success?
  end

end

end #Monopaste
