class Map
  attr_accessor :map
  attr_accessor :info

  TILES = {
    rock: '#',
    ground: '.',
    player: '@'
  }

  def initialize(opts={})
    @opts = {
      map_width: 40,
      map_height: 10,
      min_room_dimension: 3,
      max_room_width: 9,
      max_room_height: 5,
      min_distance_between_rooms: 2,
      max_single_room_generation_attempts: 100,
      max_rooms_generation_attempts: 10,
      max_rooms_density: 0.2
    }.merge!(opts)
    @map = []
    @rnd = Random.new
  end

  def generate
    fill_map_with_rock

    rooms = []
    attempts = @opts[:max_rooms_generation_attempts]
    begin
      attempts -= 1
      if room = generate_room
        fill_room_with_ground(*room)
        rooms << room
      end
    end until attempts <= 0 || rooms_density >= @opts[:max_rooms_density]

    @info = {
      player: put_player(*rooms.first),
      rooms: rooms,
      rooms_density: rooms_density
    }
  end

  def draw
    puts "\n"
    @opts[:map_height].times do |row|
      puts @map[row].map { |c| TILES[c] }.join('')
    end
    puts "\n"
  end

private

  def generate_room_dimensions
    top_left = 1 + @rnd.rand(@opts[:map_width]), 1 + @rnd.rand(@opts[:map_height])
    dimensions = @rnd.rand(@opts[:min_room_dimension]...@opts[:max_room_width]), @rnd.rand(@opts[:min_room_dimension]...@opts[:max_room_height])
    [top_left.first, top_left.last, dimensions.first, dimensions.last]
  end

  def generate_room
    attempts = @opts[:max_single_room_generation_attempts]
    begin
      attempts -= 1
      x, y, w, h = generate_room_dimensions
    end until result = room_fit_map?(x, y, w, h) && test_room_is_rock?(x, y, w, h) || attempts <= 0

    (result && attempts > 0) ? [x, y, w, h] : nil
  end

  def fill_map_with_rock
    @opts[:map_height].times do |row|
      @map << []
      @opts[:map_width].times do |_col|
        @map[row] = [] if @map[row].nil?
        @map[row] << :rock
      end
    end
  end

  def room_fit_map?(x, y, w, h)
    x + w < @opts[:map_width] - 1 && y + h < @opts[:map_height] - 1
  end

  def test_room_is_rock?(x, y, w, h)
    only_rock = true
    ((x - @opts[:min_distance_between_rooms]) ...(x + w + @opts[:min_distance_between_rooms])).each do |col|
      ((y - @opts[:min_distance_between_rooms])...(y + h + @opts[:min_distance_between_rooms])).each do |row|
        if @map[row][col] != :rock
          only_rock = false
          break
        end
      end
    end
    only_rock
  end

  def fill_room_with_ground(x, y, w, h)
    (x...(x + w)).each do |col|
      (y...(y + h)).each do |row|
        @map[row][col] = :ground
      end
    end
  end

  def rooms_density
    ground_tiles = 0
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        ground_tiles += 1 if @map[row][col] != :rock
      end
    end
    ground_tiles.to_f / (@opts[:map_height] * @opts[:map_width])
  end

  def put_player(x, y, w, h)
    player_coords = @rnd.rand((x + 1)...(x + w - 1)), @rnd.rand((y + 1)...(y + h - 1))
    @map[player_coords.last][player_coords.first] = :player
    [player_coords.first, player_coords.last]
  end
end
