require 'fileutils'

module Monopaste
  user = ENV["USER"] || ""

  TMP_DIR = File.join("/tmp", "monopaste", user)
  FileUtils.mkdir_p(TMP_DIR)
end

['daemon', 'config', 'client'].each do |f|
  require(['monopaste', f].join("/"))
end
