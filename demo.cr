require "./map.cr"

map = Map.new
map.generate
puts "Map: #{map.data}"

map.draw
