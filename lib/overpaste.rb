
module Overpaste
end

['daemon', 'config'].each do |f|
  require(['overpaste', f].join("/"))
end