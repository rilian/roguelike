class Map
  attr_accessor :map
  attr_accessor :data

  TILES = {
    rock: '#',
    ground: '.',
    player: '@',
    door: '/',
    path_start: 'o',
    path: '*'
  }

  def initialize(opts={})
    @rnd = Random.new
    @opts = {
      map_width: 80,
      map_height: 20,
      min_room_dimension: 3,
      max_room_width: 9,
      max_room_height: 5,
      min_distance_between_rooms: 2,
      max_room_generation_attempts: 100,
      max_rooms_generation_attempts: 5,
      max_rooms_density: 0.2,
      # max_rooms_connection_attempts: 1,
    }.merge!(opts)
    @data = {}
  end

  def generate
    @data[:rooms] = generate_rooms
    @data[:rooms_density] = rooms_density
    @data[:player] = put_player(@data[:rooms].first)
    @data[:room_pairs] = generate_room_pairs
    # @data[:rooms_unconnected] = @data[:rooms].dup
    # @data[:rooms_connected] = []
    # connect_all_rooms
    # generate_path_lines
    # cleanup_path_line_dead_ends
    # replace_path_to_ground
    connect_all_rooms
    #cleanup_pathfinding
  end

  def draw
    puts "\n"
    @opts[:map_height].times do |row|
      puts @map[row].map { |c| TILES[c] }.join('')
    end
    puts "\n"
  end

private

  def connect_all_rooms
    @data[:room_pairs].each do |pair|
      connect_rooms(@data[:rooms][pair.first], @data[:rooms][pair.last])
    end
  end

  def process_to_visit(to_visit, destination, start, visited, visited_coords, open, from)
    if path_point_fits_map?(to_visit) && no_ground_around?(to_visit) && !visited_coords.include?([to_visit[:x], to_visit[:y]])
      if to_visit == destination || @map[to_visit[:y]][to_visit[:x]] == :path
        # build path back
        puts "path found!"
        back_point = from[:point]
        while { x: back_point[:x], y: back_point[:y] } != start
          @map[back_point[:y]][back_point[:x]] = :path

          visited.each do |pt|
            if pt[:point][:x] == back_point[:x] && pt[:point][:y] == back_point[:y]
              #puts "found back point #{pt[:back]}"
              back_point = pt[:back]
            end
          end
        end
        return true
      elsif [:rock].include?(@map[to_visit[:y]][to_visit[:x]])
        #puts "add to open #{to_visit}"
        open << { point: to_visit, back: from[:point] }
      end
    end
    false
  end

  def connect_rooms(room1, room2)
    # attempts = @opts[:max_rooms_connection_attempts]
    # begin
    #   attempts -= 1
      # Choose random door in each of rooms
    room1[:doors].each do |door1|
      room2[:doors].each do |door2|
        start = door1[:path_start]
        destination = door2[:path_start]
      # start = room1[:doors].sample[:path_start]
      # destination = room2[:doors].sample[:path_start]
      puts "going from #{start} to #{destination}"

      # A+
      visited = []
      visited_coords = []
      open = [{ point: start, back: { x: nil, y: nil } }]
      # found = false

      while open.size > 0
        from = open.first
        distance = 99999
        open.each do |pt|
          # use min x or y
          if distance(pt[:point], destination) < distance
            distance = distance(pt[:point], destination)
            from = pt
          end
        end
        #puts "from #{open.size} points selected #{from} with distance #{distance}"
        open.delete(from)

        visited << from
        visited_coords << [from[:point][:x], from[:point][:y]]

        # check left direction
        to_visit = { x: from[:point][:x] - 1, y: from[:point][:y] }
        if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from)
          # found = true
          break
        end

        # check right direction
        to_visit = { x: from[:point][:x] + 1, y: from[:point][:y] }
        if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from)
          # found = true
          break
        end

        # check top direction
        to_visit = { x: from[:point][:x], y: from[:point][:y] - 1 }
        if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from)
          # found = true
          break
        end

        # check bottom direction
        to_visit = { x: from[:point][:x], y: from[:point][:y] + 1 }
        if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from)
          # found = true
          break
        end
      end

      # puts "visited = #{visited}"
      # puts "visited_coords = #{visited_coords}"
      # puts "open = #{open}"
    # end until attempts <= 0
    # found

      end
    end
  end

  def generate_room_pairs
    i1 = (0..@data[:rooms].size - 1).to_a
    i2 = (0...(i1.size-1)).inject([]) {|pairs,x| pairs += ((x+1)...i1.size).map {|y| [i1[x],i1[y]]}}

    # pairs = []
    # @data[:rooms].size.times do |i|
    #   other = (i + 1) % @data[:rooms].size
    #   pairs << [i, other] unless i == other || pairs.include?([i, other]) || pairs.include?([other, i])
    # end
    # pairs
  end

  def no_ground_around?(p)
    grounds = [:ground, :path_start]
    !grounds.include?(@map[p[:y] - 1][p[:x] - 1]) &&
      #!grounds.include?(@map[p[:y] - 1][p[:x]]) &&
        !grounds.include?(@map[p[:y] - 1][p[:x] + 1]) &&
       #   !grounds.include?(@map[p[:y]][p[:x] - 1]) &&
        #    !grounds.include?(@map[p[:y]][p[:x] + 1]) &&
              !grounds.include?(@map[p[:y] + 1][p[:x] - 1]) &&
         #       !grounds.include?(@map[p[:y] + 1][p[:x]]) &&
                  !grounds.include?(@map[p[:y] + 1][p[:x] + 1])
  end

  def cleanup_pathfinding
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        @map[row][col] = :ground if [:path, :path_start].include?(@map[row][col])
      end
    end
  end

  # def replace_path_to_ground
  #   @opts[:map_height].times do |row|
  #     @opts[:map_width].times do |col|
  #       @map[row][col] = :ground if [:path, :path_start].include?(@map[row][col])
  #     end
  #   end
  # end
  #
  # def cleanup_path_line_dead_ends
  #   replaced = true
  #   while replaced
  #     replaced = false
  #     (1..(@opts[:map_height] - 1)).each do |row|
  #       (1..(@opts[:map_width] - 1)).each do |col|
  #         if @map[row][col] == :path
  #           adjacent_paths = 0
  #           adjacent_paths += 1 if [:path, :path_start].include?(@map[row - 1][col])
  #           adjacent_paths += 1 if [:path, :path_start].include?(@map[row + 1][col])
  #           adjacent_paths += 1 if [:path, :path_start].include?(@map[row][col - 1])
  #           adjacent_paths += 1 if [:path, :path_start].include?(@map[row][col + 1])
  #
  #           if adjacent_paths < 2
  #             @map[row][col] = :rock
  #             replaced = true
  #           end
  #         end
  #       end
  #     end
  #   end
  # end

  def generate_doors(room)
    doors = []
    [
      { x: room[:x] + @rnd.rand(0...room[:w]), y: room[:y] - 1 }, # top
      { x: room[:x] + @rnd.rand(0...room[:w]), y: room[:y] + room[:h] }, # bottom
      { x: room[:x] - 1, y: room[:y] + @rnd.rand(0...room[:h]) }, # left
      { x: room[:x] + room[:w], y: room[:y] + @rnd.rand(0...room[:h]) }, # right
    ].shuffle.each do |point|
      door = { x: point[:x], y: point[:y] }
      if point[:x] == room[:x] - 1 # left
        door[:path_start] = { x: point[:x] - 1, y: point[:y] }
        doors << door unless [0, 1].include?(point[:x])
      end
      if point[:x] == room[:x] + room[:w] # right
        door[:path_start] = { x: point[:x] + 1, y: point[:y] }
        doors << door unless [@opts[:map_width] - 1, @opts[:map_width] - 2].include?(point[:x])
      end
      if point[:y] == room[:y] - 1
        door[:path_start] = { x: point[:x], y: point[:y] - 1 }
        doors << door unless [0, 1].include?(point[:y])
      end
      if point[:y] == room[:y] + room[:h]
        door[:path_start] = { x: point[:x], y: point[:y] + 1 }
        doors << door unless [@opts[:map_height] - 1, @opts[:map_height] - 2].include?(point[:y])
      end
    end

    doors.each do |door|
      @map[door[:y]][door[:x]] = :door
      @map[door[:path_start][:y]][door[:path_start][:x]] = :path_start
    end
    doors
  end

  # def generate_path_lines
  #   # TODO: for each room generate lines. if line touch line of same room, then discard this line
  #   path_points = []
  #   @opts[:map_height].times do |row|
  #     @opts[:map_width].times do |col|
  #       path_points << [col, row] if @map[row][col] == :path_start
  #     end
  #   end
  #   # puts "path_points = #{path_points}"
  #
  #   path_points.each do |point|
  #     # puts "point = #{point}"
  #     x = point.first
  #     while x > 1
  #       x -= 1
  #       map[point.last][x] == :rock &&
  #         ![:ground, :door].include?(map[point.last][x - 1]) &&
  #         !(
  #           (
  #             [:path].include?(map[point.last - 1][x - 1]) ||
  #             [:path].include?(map[point.last + 1][x - 1])
  #           ) &&
  #           ![:path].include?(map[point.last][x - 1])
  #         ) &&
  #         ![:ground, :door].include?(map[point.last - 1][x]) &&
  #         ![:ground, :door].include?(map[point.last + 1][x]) ?
  #       map[point.last][x] = :path : break
  #     end
  #     x = point.first
  #     while x < @opts[:map_width] - 2
  #       x += 1
  #       map[point.last][x] == :rock &&
  #         ![:ground, :door].include?(map[point.last][x + 1]) &&
  #         !(
  #           (
  #             [:path].include?(map[point.last - 1][x + 1]) ||
  #             [:path].include?(map[point.last + 1][x + 1])
  #           ) &&
  #           ![:path].include?(map[point.last][x + 1])
  #         ) &&
  #         ![:ground, :door].include?(map[point.last - 1][x]) &&
  #         ![:ground, :door].include?(map[point.last + 1][x]) ?
  #       map[point.last][x] = :path : break
  #     end
  #     y = point.last
  #     while y > 1
  #       y -= 1
  #       map[y][point.first] == :rock &&
  #         ![:ground, :door].include?(map[y - 1][point.first]) &&
  #         ![:path].include?(map[y - 1][point.first - 1]) &&
  #         ![:path].include?(map[y - 1][point.first + 1]) &&
  #         ![:ground, :door].include?(map[y][point.first - 1]) &&
  #         ![:ground, :door].include?(map[y][point.first + 1]) ?
  #       map[y][point.first] = :path : break
  #     end
  #     y = point.last
  #     while y < @opts[:map_height] - 2
  #       y += 1
  #       map[y][point.first] == :rock &&
  #         ![:ground, :door].include?(map[y + 1][point.first]) &&
  #         ![:path].include?(map[y + 1][point.first - 1]) &&
  #         ![:path].include?(map[y + 1][point.first + 1]) &&
  #         ![:ground, :door].include?(map[y][point.first + 1]) &&
  #         ![:ground, :door].include?(map[y][point.first - 1]) ?
  #       map[y][point.first] = :path : break
  #     end
  #   end
  # end

  # def connect_all_rooms
  #   return if @data[:rooms_unconnected].empty?
  #
  #   @data[:rooms_connected] << @data[:rooms_unconnected].pop
  #
  #   while !@data[:rooms_unconnected].empty?
  #     room_1 = @data[:rooms_unconnected].pop
  #     center = get_room_center(*room_1)
  #     room_2 = @data[:rooms_connected].sort { |a, b|
  #       distance(get_room_center(*a), center) <=> distance(get_room_center(*b), center)
  #     }.first.dup
  #     # @map[center.last][center.first] = :marker
  #     # @map[get_room_center(*room_2).last][get_room_center(*room_2).first] = :marker
  #
  #     connect_rooms(room_1, room_2)
  #     @data[:rooms_connected] << room_1
  #   end
  # end
  #
  # def connect_rooms(room_1, room_2)
  #   # puts "\nconnecting rooms\n"
  #   # puts "room_1 = #{room_1.inspect}"
  #   # puts "room_2 = #{room_2.inspect}"
  #   center_1 = get_room_center(*room_1)
  #   center_2 = get_room_center(*room_2)
  #   # puts "center_1 = #{center_1.inspect}"
  #   # puts "center_2 = #{center_2.inspect}"
  #
  #   diff_x = center_2.first - center_1.first
  #   diff_y = center_2.last - center_1.last
  # end
  #
  # def get_room_center(x, y, w, h)
  #   [x + (w / 2.0).ceil - 1, y + (h / 2.0).ceil - 1]
  # end

  def distance(p1, p2)
    #Math.sqrt((p1[:x] - p2[:x])**2 + (p1[:y] - p2[:y])**2)
    [(p1[:x] - p2[:x]).abs, (p1[:y] - p2[:y]).abs].min
  end

  def generate_rooms
    fill_map_with_rock

    rooms = []
    attempts = @opts[:max_rooms_generation_attempts]
    begin
      attempts -= 1
      if room = generate_room
        fill_room_with_ground(room)
        room[:doors] = generate_doors(room)
        rooms << room
      end
    end until attempts <= 0 || rooms_density >= @opts[:max_rooms_density]
    rooms
  end

  def generate_room_dimensions
    top_left = 1 + @rnd.rand(@opts[:map_width] - @opts[:min_room_dimension]), 1 + @rnd.rand(@opts[:map_height] - @opts[:min_room_dimension])
    dimensions = @rnd.rand(@opts[:min_room_dimension]..@opts[:max_room_width]), @rnd.rand(@opts[:min_room_dimension]..@opts[:max_room_height])
    { x: top_left.first, y: top_left.last, w: dimensions.first, h: dimensions.last }
  end

  def generate_room
    attempts = @opts[:max_room_generation_attempts]
    begin
      room = {}
      attempts -= 1
      room.merge! generate_room_dimensions
    end until attempts <= 0 || result = room_fit_map?(room) && test_room_is_rock?(room)

    result ? room : nil
  end

  def fill_map_with_rock
    @map = []
    @opts[:map_height].times do |row|
      @map << []
      @opts[:map_width].times do |_col|
        @map[row] << :rock
      end
    end
  end

  def room_fit_map?(room)
    room[:x] + room[:w] < @opts[:map_width] && room[:y] + room[:h] < @opts[:map_height]
  end

  def path_point_fits_map?(point)
    point[:x] < @opts[:map_width] - 1 && point[:y] < @opts[:map_height] - 1 && point[:x] != 0 && point[:y] != 0
  end

  def test_room_is_rock?(room)
    ((room[:x] - @opts[:min_distance_between_rooms]) ...(room[:x] + room[:w] + @opts[:min_distance_between_rooms])).each do |col|
      ((room[:y] - @opts[:min_distance_between_rooms])...(room[:y] + room[:h] + @opts[:min_distance_between_rooms])).each do |row|
        if @map[row] && @map[row][col] && @map[row][col] != :rock
          return false
        end
      end
    end
    true
  end

  def fill_room_with_ground(room)
    (room[:x]...(room[:x] + room[:w])).each do |col|
      (room[:y]...(room[:y] + room[:h])).each do |row|
        @map[row][col] = :ground
      end
    end
  end

  def rooms_density
    ground = 0
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        ground += 1 if @map[row][col] != :rock
      end
    end
    ground.to_f / (@opts[:map_height] * @opts[:map_width])
  end

  def put_player(room)
    coords = @rnd.rand((room[:x] + 1)...(room[:x] + room[:w] - 1)), @rnd.rand((room[:y] + 1)...(room[:y] + room[:h] - 1))
    @map[coords.last][coords.first] = :player
    { x: coords.first, y: coords.last }
  end
end
