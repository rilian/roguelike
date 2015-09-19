class Map
  attr_accessor :map
  attr_accessor :info

  TILES = {
    rock: '#',
    ground: '.',
    test: 'z',
    player: '@'
  }

  def initialize(opts={})
    @opts = {
      map_width: 40,
      map_height: 10,
      min_room_width: 3,
      max_room_width: 9,
      min_room_height: 3,
      max_room_height: 5,
      min_distance_between_rooms: 1,
      max_room_generation_attempts: 100
    }.merge!(opts)
    @map = []
    @random = Random.new
  end

  def generate
    fill_map_with_rock

    rooms = []
    5.times do
      room = generate_room

      if room
        fill_room_with_ground(*room)
        rooms << room
      end
    end

    player_coords = put_player(*rooms.first)

    @info = {
      player: player_coords,
      rooms: rooms
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
    top_left = 1 + @random.rand(@opts[:map_width]), 1 + @random.rand(@opts[:map_height])
    # puts "\ntop left on x=#{top_left.last} y=#{top_left.first}"
    dimensions = @random.rand(@opts[:min_room_width]...@opts[:max_room_width]), @random.rand(@opts[:min_room_height]...@opts[:max_room_height])
    # puts "room width=#{dimensions.first} height=#{dimensions.last}"
    [top_left.first, top_left.last, dimensions.first, dimensions.last]
  end

  def generate_room
    attempts = @opts[:max_room_generation_attempts]
    begin
      attempts -= 1
      x, y, w, h = generate_room_dimensions
    end until result = room_fit_map?(x, y, w, h) && test_room_is_rock?(x, y, w, h) || attempts <= 0

    (result && attempts > 0) ? [x, y, w, h] : nil
  end

  def put_player(x, y, w, h)
    player_coords = @random.rand(x...(x + w)), @random.rand(y...(y + h))
    # puts "player on x=#{player_coords.first} y=#{player_coords.last}"
    @map[player_coords.last][player_coords.first] = :player
    [player_coords.first, player_coords.last]
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
    if x + w >= @opts[:map_width] - 1 || y + h >= @opts[:map_height] - 1
      # puts 'does not fit map'
      return false
    end
    # puts 'fits map'
    true
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
    # puts "contains rock only ? #{only_rock}"
    only_rock
  end

  def fill_room_with_ground(x, y, w, h)
    (x...(x + w)).each do |col|
      (y...(y + h)).each do |row|
        @map[row][col] = :ground
      end
    end
  end
end
