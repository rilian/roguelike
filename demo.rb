require_relative 'map'

map = Map.new(width: 80, height: 20)

map.generate

puts "\n\n"

map.draw
