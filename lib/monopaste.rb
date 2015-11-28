require 'fileutils'

module Monopaste
  userid = Process::UID.rid

  TMP_DIR = File.join("/tmp", "monopaste-#{userid}")
  FileUtils.mkdir_p(TMP_DIR, {:mode => 0750})
end

['daemon', 'config', 'client'].each do |f|
  require(['monopaste', f].join("/"))
end
