class Map
  attr_accessor :map
  attr_accessor :data

  TILES = {
    rock: '#',
    ground: '.',
    player: '@',
    door: '+',
    path_start: 'o',
    path: '*'
  }
  (0..9).to_a.each { |i| TILES[i.to_s.to_sym] = i.to_s.to_sym }

  def initialize(opts={})
    @rnd = Random.new
    @opts = {
      map_width: 80,
      map_height: 20,
      min_room_dimension: 3,
      max_room_width: 9,
      max_room_height: 6,
      min_distance_between_rooms: 5,
      max_room_generation_attempts: 5,
      max_rooms_generation_attempts: 5,
      max_rooms_density: 0.2,
      # max_rooms_connection_attempts: 1,
    }.merge!(opts)
    @data = {}
  end

  def generate
    generated = false
    while !generated

      @data[:rooms] = generate_rooms
      stamp_rooms
      @data[:rooms_density] = rooms_density
      @data[:room_pairs] = generate_room_pairs
      @data[:player] = put_player(@data[:rooms].first)
      # @data[:rooms_unconnected] = @data[:rooms].dup
      # @data[:rooms_connected] = []
      # connect_all_rooms
      # generate_path_lines
      # cleanup_path_line_dead_ends
      # replace_path_to_ground
      if !connect_all_rooms
        #puts "retrying generation"
      else
        generated = true
        cleanup_pathfinding
      end
    end
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
      #puts "connecting rooms #{pair.first} to #{pair.last}"
      if connect_rooms(@data[:rooms][pair.first], @data[:rooms][pair.last])
       # puts "success"
      else
        #puts "fail"
        return false
      end
    end
  end

  def process_to_visit(to_visit, destination, start, visited, visited_coords, open, from, dir)
    if path_point_fits_map?(to_visit) && no_path_in_direction?(to_visit, dir) && no_ground_around?(to_visit) && !visited_coords.include?([to_visit[:x], to_visit[:y]])
      if to_visit == destination #|| @map[to_visit[:y]][to_visit[:x]] == :path
        # build path back
        #puts "path found!"
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
    door_pairs = []
    room1[:doors].each do |door1|
      room2[:doors].each do |door2|
        door_pairs << [door1, door2] if !door_pairs.include?([door1, door2]) && !door_pairs.include?([door2, door1])
      end
    end

    # puts "door pairs unsorted = #{door_pairs}"
    # door_pairs.each do |pair|
    #   puts sqrt_distance({x: pair.first[:x], y: pair.first[:y]}, {x: pair.last[:x], y: pair.last[:y]})
    # end
    door_pairs.sort_by! { |d1, d2| sqrt_distance({x: d1[:x], y: d1[:y]}, {x: d2[:x], y: d2[:y]}) }
    # puts "door pairs sorted = #{door_pairs}"
    # door_pairs.each do |pair|
    #   puts sqrt_distance({x: pair.first[:x], y: pair.first[:y]}, {x: pair.last[:x], y: pair.last[:y]})
    # end

    door_pairs.each do |door1, door2|
    # room1[:doors].each do |door1|
    #   room2[:doors].each do |door2|
        start = door1[:path_start]
        destination = door2[:path_start]
      # start = room1[:doors].sample[:path_start]
      # destination = room2[:doors].sample[:path_start]
      #puts "going from #{start} to #{destination}"

      # A+
      visited = []
      visited_coords = []
      open = [{ point: start, back: { x: nil, y: nil } }]
      # found = false
      steps = 0

      while open.size > 0 && steps < @opts[:map_width] + @opts[:map_height]
        steps += 1
        from = open.first
        distance = 999
        open.each do |pt|
          new_distance = distance(pt[:point], destination)
          if new_distance < distance
            distance = new_distance
            from = pt
          end
        end
        #puts "from #{open.size} points selected #{from} with distance #{distance}"
        open.delete(from)

        visited << from
        visited_coords << [from[:point][:x], from[:point][:y]]

        # check left direction
        to_visit = { x: from[:point][:x] - 1, y: from[:point][:y] }
        dir = 'w'
        if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from, dir)
          # found = true
          return true
        end

        # check right direction
        to_visit = { x: from[:point][:x] + 1, y: from[:point][:y] }
        dir = 'e'
        if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from, dir)
          # found = true
          return true
        end

        # check top direction
        to_visit = { x: from[:point][:x], y: from[:point][:y] - 1 }
        dir = 'n'
        if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from, dir)
          # found = true
          return true
        end

        # check bottom direction
        to_visit = { x: from[:point][:x], y: from[:point][:y] + 1 }
        dir = 's'
        if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from, dir)
          # found = true
          return true
        end
      end

      # puts "visited = #{visited}"
      # puts "visited_coords = #{visited_coords}"
      # puts "open = #{open}"
    # end until attempts <= 0
    # found

      # end
    end
    false
  end

  def generate_room_pairs
    # i1 = (0..@data[:rooms].size - 1).to_a
    # i2 = (0...(i1.size-1)).inject([]) {|pairs,x| pairs += ((x+1)...i1.size).map {|y| [i1[x],i1[y]]}}
    #
    # puts "pairs = #{i2}"
    # i2
    pairs = []
    room_used = {}

    # puts "unsorted rooms = #{@data[:rooms].map{|r| [r[:x], r[:y]]}}"
    # @data[:rooms].each do |r|
    #   puts sqrt_distance(get_room_center(r), {x: @opts[:map_width] / 2, y: @opts[:map_height] / 2})
    # end
    @data[:rooms].sort_by! { |r1| sqrt_distance(get_room_center(r1), {x: @opts[:map_width] / 2, y: @opts[:map_height] / 2}) }
    # puts "sorted rooms = #{@data[:rooms].map{|r| [r[:x], r[:y]]}}"
    # @data[:rooms].each do |r|
    #   puts sqrt_distance(get_room_center(r), {x: @opts[:map_width] / 2, y: @opts[:map_height] / 2})
    # end

    @data[:rooms].size.times do |i|
      room_used[i] = 0 if room_used[i].nil?
      other = (i + 1) % @data[:rooms].size
      room_used[other] = 0 if room_used[other].nil?
      unless i == other || pairs.include?([i, other]) || pairs.include?([other, i]) || room_used[i] > 2 || room_used[other] > 2
        pairs << [i, other]
        room_used[i] +=1
        room_used[other] +=1
      end
    end
    #puts "pairs = #{pairs}"
    # puts "unsorted pairs = #{pairs}"
    pairs.sort_by! { |r1, r2| sqrt_distance(get_room_center(@data[:rooms][r1]), get_room_center(@data[:rooms][r2])) }
    # puts "sorted pairs = #{pairs}"

    pairs
  end

  def stamp_rooms
    @data[:rooms].each_with_index do |room, index|
      st = get_room_center(room)
      @map[st[:y]][st[:x]] = index.to_s.to_sym
    end
  end

  def no_ground_around?(p)
    grounds = [:ground, :path_start]
    !grounds.include?(@map[p[:y] - 1][p[:x] - 1]) &&
      !grounds.include?(@map[p[:y] - 1][p[:x] + 1]) &&
      !grounds.include?(@map[p[:y] + 1][p[:x] - 1]) &&
      !grounds.include?(@map[p[:y] + 1][p[:x] + 1]) #&&
      # !grounds.include?(@map[p[:y] - 1][p[:x]]) &&
      #    !grounds.include?(@map[p[:y]][p[:x] - 1]) &&
      #      !grounds.include?(@map[p[:y]][p[:x] + 1]) &&
      #          !grounds.include?(@map[p[:y] + 1][p[:x]])
  end

  def no_sym_around?(sym, p)
    grounds = [sym]
    !grounds.include?(@map[p[:y] - 1][p[:x] - 1]) &&
      !grounds.include?(@map[p[:y] - 1][p[:x] + 1]) &&
      !grounds.include?(@map[p[:y] + 1][p[:x] - 1]) &&
      !grounds.include?(@map[p[:y] + 1][p[:x] + 1]) #&&
      !grounds.include?(@map[p[:y] - 1][p[:x]]) &&
         !grounds.include?(@map[p[:y]][p[:x] - 1]) &&
           !grounds.include?(@map[p[:y]][p[:x] + 1]) &&
               !grounds.include?(@map[p[:y] + 1][p[:x]])
  end

  def no_path_in_direction?(p, dir)
    case dir
    when 'n'
      ![:path].include?(@map[p[:y] - 1][p[:x]])
    when 's'
      ![:path].include?(@map[p[:y] + 1][p[:x]])
    when 'e'
      ![:path].include?(@map[p[:y]][p[:x] + 1 ])
    when 'w'
      ![:path].include?(@map[p[:y]][p[:x] - 1])
    end
  end

  def cleanup_pathfinding
    # cleanup unsed path
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        if [:path_start].include?(@map[row][col])
          if no_sym_around?(:path, {x: col, y: row})
            @map[row][col] = :rock
          end
        end
      end
    end

    # cleanup unsed doors
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        if [:door].include?(@map[row][col])
          if no_sym_around?(:path_start, {x: col, y: row})
            @map[row][col] = :rock
          end
        end
      end
    end

    # cleanup unsed path_start
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        if [:path, :path_start].include?(@map[row][col])
          @map[row][col] = :ground
        end
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

  def get_room_center(room)
    { x: room[:x] + (room[:w] / 2.0).ceil - 1, y: room[:y] + (room[:h] / 2.0).ceil - 1 }
  end

  def distance(p1, p2)
    #Math.sqrt((p1[:x] - p2[:x])**2 + (p1[:y] - p2[:y])**2)
    [(p1[:x] - p2[:x]).abs, (p1[:y] - p2[:y]).abs].min
  end

  def sqrt_distance(p1, p2)
    Math.sqrt((p1[:x] - p2[:x])**2 + (p1[:y] - p2[:y])**2)
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
