class Map
  attr_accessor :map
  attr_accessor :data

  TILES = {
    rock: '#',
    ground: '.',
    player: '@',
    marker: 'x',
    door: '/',
    path_start: 'o',
    path: '*',
    path_current: '%',
  }

  def initialize(opts={})
    @rnd = Random.new
    @opts = {
      map_width: 80,
      map_height: 20,
      min_room_dimension: 3,
      max_room_width: 9,
      max_room_height: 5,
      min_distance_between_rooms: 3,
      max_single_room_generation_attempts: 10,
      max_rooms_generation_attempts: 1,
      max_rooms_density: 0.2
    }.merge!(opts)
    @data = {}
  end

  def generate
    @data[:rooms] = generate_rooms
    @data[:rooms_unconnected] = @data[:rooms].dup
    @data[:rooms_connected] = []
    @data[:player] = put_player(*@data[:rooms].first)
    @data[:rooms_density] = rooms_density
    generate_doors
    #connect_all_rooms
    generate_path_lines
    # cleanup_path_line_dead_ends
    #replace_path_to_ground
  end

  def draw
    puts "\n"
    @opts[:map_height].times do |row|
      puts @map[row].map { |c| TILES[c] }.join('')
    end
    puts "\n"
  end

private

  def replace_path_to_ground
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        @map[row][col] = :ground if [:path, :path_start].include?(@map[row][col])
      end
    end
  end

  def cleanup_path_line_dead_ends
    replaced = true
    while replaced
      replaced = false
      (1..(@opts[:map_height] - 1)).each do |row|
        (1..(@opts[:map_width] - 1)).each do |col|
          if @map[row][col] == :path
            adjacent_paths = 0
            adjacent_paths += 1 if [:path, :path_start].include?(@map[row - 1][col])
            adjacent_paths += 1 if [:path, :path_start].include?(@map[row + 1][col])
            adjacent_paths += 1 if [:path, :path_start].include?(@map[row][col - 1])
            adjacent_paths += 1 if [:path, :path_start].include?(@map[row][col + 1])

            if adjacent_paths < 2
              @map[row][col] = :rock
              replaced = true
            end
          end
        end
      end
    end
  end

  def generate_doors
    @data[:rooms].each do |room|
      doors = 0
      [
        [room[0] + @rnd.rand(0...room[2]), room[1] - 1],
        [room[0] - 1, room[1] + @rnd.rand(0...room[3])],
        [room[0] + @rnd.rand(0...room[2]), room[1] + room[3]],
        [room[0] + room[2], room[1] + @rnd.rand(0...room[3])],
      ].shuffle.each do |point|
        if doors < 3
          unless [0, 1, @opts[:map_width] - 1, @opts[:map_width] - 2].include?(point.first) || [0, 1, @opts[:map_height] - 1, @opts[:map_height] - 2].include?(point.last)
            @map[point.last][point.first] = :door
            if point.first == room[0] - 1
              @map[point.last][point.first - 1] = :path_start
            end
            if point.first == room[0] + room[2]
              @map[point.last][point.first + 1] = :path_start
            end
            if point.last == room[1] -1
              @map[point.last - 1][point.first] = :path_start
            end
            if point.last == room[1] + room[3]
              @map[point.last + 1][point.first] = :path_start
            end
            doors += 1
          end
        end
      end
    end
  end

  def generate_path_lines
    # TODO: for each room generate lines. if line touch line of same room, then discard this line
    path_points = []
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        path_points << [col, row] if @map[row][col] == :path_start
      end
    end
    # puts "path_points = #{path_points}"

    path_points.each do |point|
      # puts "point = #{point}"
      x = point.first
      while x > 1
        x -= 1
        map[point.last][x] == :rock &&
          ![:ground, :door].include?(map[point.last][x - 1]) &&
          !(
            (
              [:path].include?(map[point.last - 1][x - 1]) ||
              [:path].include?(map[point.last + 1][x - 1])
            ) &&
            ![:path].include?(map[point.last][x - 1])
          ) &&
          ![:ground, :door].include?(map[point.last - 1][x]) &&
          ![:ground, :door].include?(map[point.last + 1][x]) ?
        map[point.last][x] = :path : break
      end
      x = point.first
      while x < @opts[:map_width] - 2
        x += 1
        map[point.last][x] == :rock &&
          ![:ground, :door].include?(map[point.last][x + 1]) &&
          !(
            (
              [:path].include?(map[point.last - 1][x + 1]) ||
              [:path].include?(map[point.last + 1][x + 1])
            ) &&
            ![:path].include?(map[point.last][x + 1])
          ) &&
          ![:ground, :door].include?(map[point.last - 1][x]) &&
          ![:ground, :door].include?(map[point.last + 1][x]) ?
        map[point.last][x] = :path : break
      end
      y = point.last
      while y > 1
        y -= 1
        map[y][point.first] == :rock &&
          ![:ground, :door].include?(map[y - 1][point.first]) &&
          ![:path].include?(map[y - 1][point.first - 1]) &&
          ![:path].include?(map[y - 1][point.first + 1]) &&
          ![:ground, :door].include?(map[y][point.first - 1]) &&
          ![:ground, :door].include?(map[y][point.first + 1]) ?
        map[y][point.first] = :path : break
      end
      y = point.last
      while y < @opts[:map_height] - 2
        y += 1
        map[y][point.first] == :rock &&
          ![:ground, :door].include?(map[y + 1][point.first]) &&
          ![:path].include?(map[y + 1][point.first - 1]) &&
          ![:path].include?(map[y + 1][point.first + 1]) &&
          ![:ground, :door].include?(map[y][point.first + 1]) &&
          ![:ground, :door].include?(map[y][point.first - 1]) ?
        map[y][point.first] = :path : break
      end
    end
  end

  def connect_all_rooms
    return if @data[:rooms_unconnected].empty?

    @data[:rooms_connected] << @data[:rooms_unconnected].pop

    while !@data[:rooms_unconnected].empty?
      room_1 = @data[:rooms_unconnected].pop
      center = get_room_center(*room_1)
      room_2 = @data[:rooms_connected].sort { |a, b|
        distance(get_room_center(*a), center) <=> distance(get_room_center(*b), center)
      }.first.dup
      # @map[center.last][center.first] = :marker
      # @map[get_room_center(*room_2).last][get_room_center(*room_2).first] = :marker

      connect_rooms(room_1, room_2)
      @data[:rooms_connected] << room_1
    end
  end

  def connect_rooms(room_1, room_2)
    # puts "\nconnecting rooms\n"
    # puts "room_1 = #{room_1.inspect}"
    # puts "room_2 = #{room_2.inspect}"
    center_1 = get_room_center(*room_1)
    center_2 = get_room_center(*room_2)
    # puts "center_1 = #{center_1.inspect}"
    # puts "center_2 = #{center_2.inspect}"

    diff_x = center_2.first - center_1.first
    diff_y = center_2.last - center_1.last
  end

  def get_room_center(x, y, w, h)
    [x + (w / 2.0).ceil - 1, y + (h / 2.0).ceil - 1]
  end

  def distance(p1, p2)
    Math.sqrt((p1.last - p1.first)**2 + (p2.last - p2.first)**2)
  end

  def generate_rooms
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
    rooms
  end

  def generate_room_dimensions
    top_left = 1 + @rnd.rand(@opts[:map_width] - @opts[:min_room_dimension]), 1 + @rnd.rand(@opts[:map_height] - @opts[:min_room_dimension])
    dimensions = @rnd.rand(@opts[:min_room_dimension]..@opts[:max_room_width]), @rnd.rand(@opts[:min_room_dimension]..@opts[:max_room_height])
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
    @map = []
    @opts[:map_height].times do |row|
      @map << []
      @opts[:map_width].times do |_col|
        @map[row] = [] if @map[row].nil?
        @map[row] << :rock
      end
    end
  end

  def room_fit_map?(x, y, w, h)
    x + w < @opts[:map_width] && y + h < @opts[:map_height]
  end

  def test_room_is_rock?(x, y, w, h)
    only_rock = true
    ((x - @opts[:min_distance_between_rooms]) ...(x + w + @opts[:min_distance_between_rooms])).each do |col|
      ((y - @opts[:min_distance_between_rooms])...(y + h + @opts[:min_distance_between_rooms])).each do |row|
        if @map[row] && @map[row][col] && @map[row][col] != :rock
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
