require_relative 'map'

map = Map.new
map.generate
puts "Map: #{map.info}"

map.draw
