
module Monopaste
end

['daemon', 'config'].each do |f|
  require(['monopaste', f].join("/"))
end
