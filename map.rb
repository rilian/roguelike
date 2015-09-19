class Map
  attr_accessor :map

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
    }.merge!(opts)
    @map = []
    @random = Random.new
  end

  def generate
    fill_map_with_rock
    create_first_room
  end

  def draw
    @opts[:map_height].times do |row|
      puts @map[row].map { |c| TILES[c] }.join('')
    end
  end

private

  def create_first_room
    begin
      begin
        puts "\n"
        top_left = 1 + @random.rand(@opts[:map_width]), 1 + @random.rand(@opts[:map_height])
        dimensions = @random.rand(@opts[:min_room_width]...@opts[:max_room_width]), @random.rand(@opts[:min_room_height]...@opts[:max_room_height])
        puts "room width=#{dimensions.first} height=#{dimensions.last}"
      end until room_fit_map?(top_left.first, top_left.last, dimensions.first, dimensions.last)


      puts "top left on x=#{top_left.last} y=#{top_left.first}"
    end until test_room_is_rock?(top_left.first, top_left.last, dimensions.first, dimensions.last)

    fill_with_ground(top_left.first, top_left.last, dimensions.first, dimensions.last)

    player_coords = @random.rand(top_left.first...(top_left.first + dimensions.first)), @random.rand(top_left.last...(top_left.last + dimensions.last))
    puts "player on x=#{player_coords.first} y=#{player_coords.last}"
    @map[player_coords.last][player_coords.first] = :player
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
      puts 'does not fit map'
      return false
    end
    puts 'fits map'
    true
  end

  def test_room_is_rock?(x, y, w, h)
    only_rock = true
    (x...(x + w)).each do |col|
      (y...(y + h)).each do |row|
        if @map[row][col] != :rock
          only_rock = false
          break
        end
      end
    end
    puts "contains rock only ? #{only_rock}"
    only_rock
  end

  def fill_with_ground(x, y, w, h)
    (x...(x + w)).each do |col|
      (y...(y + h)).each do |row|
        @map[row][col] = :ground
      end
    end
  end
end
