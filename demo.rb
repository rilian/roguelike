require_relative 'map'

map = Map.new
map.generate
puts "Map: #{map.data}"

map.draw
