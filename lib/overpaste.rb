
module Overpaste
end

['daemon', 'config'].each do |f|
  require File.join('overpaste', f)
end