class Map
  attr_accessor :map
  attr_accessor :data

  TILES = {
    rock: '#',
    ground: '.',
    nothing: ' ',
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
      min_room_width: 5,
      min_room_height: 3,
      max_room_width: 9,
      max_room_height: 6,
      min_distance_between_rooms: 5,
      max_room_generation_attempts: 5,
      max_rooms_generation_attempts: 10,
      max_rooms_density: 0.5,
      verbose: false,
    }.merge!(opts)
    @data = {}
  end

  def generate
    generated = false
    while !generated
      @data[:rooms] = generate_rooms
      @data[:rooms_density] = rooms_density
      @data[:room_pairs] = generate_room_pairs
      if !connect_all_rooms
        puts 'Retrying generation' if @opts[:verbose]
      else
        generated = true
        cleanup_pathfinding
        cleanup_edges
        stamp_rooms if @opts[:verbose]
        @data[:player] = put_player(@data[:rooms].first)
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

  def fill_map_with_rock
    @map = []
    @opts[:map_height].times do |row|
      @map << []
      @opts[:map_width].times do |_col|
        @map[row] << :rock
      end
    end
  end

  def generate_room
    attempts = @opts[:max_room_generation_attempts]
    begin
      room = {}
      attempts -= 1
      room.merge!(generate_room_dimensions)
    end until attempts <= 0 || result = room_fit_map?(room) && test_room_is_rock?(room)

    result ? room : nil
  end

  def generate_room_dimensions
    top_left = 1 + @rnd.rand(@opts[:map_width] - @opts[:min_room_width]), 1 + @rnd.rand(@opts[:map_height] - @opts[:min_room_height])
    dimensions = @rnd.rand(@opts[:min_room_width]..@opts[:max_room_width]), @rnd.rand(@opts[:min_room_height]..@opts[:max_room_height])
    { x: top_left.first, y: top_left.last, w: dimensions.first, h: dimensions.last }
  end

  def room_fit_map?(room)
    room[:x] + room[:w] < @opts[:map_width] && room[:y] + room[:h] < @opts[:map_height]
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

  def rooms_density
    ground = 0
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        ground += 1 if @map[row][col] == :ground
      end
    end
    ground.to_f / (@opts[:map_height] * @opts[:map_width])
  end

  def generate_room_pairs
    # Sort rooms by distance from center
    @data[:rooms].sort_by! { |r1| sqrt_distance(get_room_center(r1), {x: @opts[:map_width] / 2, y: @opts[:map_height] / 2}) }

    pairs = []
    room_used = {}
    @data[:rooms].size.times do |i|
      room_used[i] = 0 if room_used[i].nil?
      k = (i + 1) % @data[:rooms].size
      room_used[k] = 0 if room_used[k].nil?
      unless i == k || pairs.include?([k, i]) || room_used[i] > 2 || room_used[k] > 2
        pairs << [i, k]
        room_used[i] +=1
        room_used[k] +=1
      end
    end

    # Sort pairs by distance between each other
    pairs.sort_by! { |r1, r2| sqrt_distance(get_room_center(@data[:rooms][r1]), get_room_center(@data[:rooms][r2])) }

    pairs
  end

  def stamp_rooms
    @data[:rooms].each_with_index do |room, index|
      st = get_room_center(room)
      @map[st[:y]][st[:x]] = index.to_s.to_sym
    end
  end

  def get_room_center(room)
    { x: room[:x] + (room[:w] / 2.0).ceil - 1, y: room[:y] + (room[:h] / 2.0).ceil - 1 }
  end

  def connect_all_rooms
    @data[:room_pairs].each do |pair|
      #puts "start #{Time.now}"
      return false unless connect_rooms(@data[:rooms][pair.first], @data[:rooms][pair.last])
      #puts "end #{Time.now}"
    end
  end

  def connect_rooms(room1, room2)
    get_door_pairs(room1, room2).each do |door1, door2|
      start = door1[:path_start]
      destination = door2[:path_start]

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
          new_distance = integer_distance(pt[:point], destination)
          if new_distance < distance
            distance = new_distance
            from = pt
          end
        end

        open.delete(from)

        visited << from
        visited_coords << [from[:point][:x], from[:point][:y]]

        [
          [{ x: from[:point][:x] - 1, y: from[:point][:y] }, 'w'],
          [{ x: from[:point][:x] + 1, y: from[:point][:y] }, 'e'],
          [{ x: from[:point][:x], y: from[:point][:y] - 1 }, 'n'],
          [{ x: from[:point][:x], y: from[:point][:y] + 1 }, 's'],
        ].each do |to_visit, dir|
          if process_to_visit(to_visit, destination, start, visited, visited_coords, open, from, dir)
            return true
          end
        end
      end
    end
    false
  end

  def get_door_pairs(room1, room2)
    door_pairs = []
    room1[:doors].each do |door1|
      room2[:doors].each do |door2|
        door_pairs << [door1, door2] unless door_pairs.include?([door1, door2]) || door_pairs.include?([door2, door1])
      end
    end

    door_pairs.sort_by! { |d1, d2| sqrt_distance({x: d1[:x], y: d1[:y]}, {x: d2[:x], y: d2[:y]}) }
    door_pairs
  end

  def sqrt_distance(p1, p2)
    Math.sqrt((p1[:x] - p2[:x])**2 + (p1[:y] - p2[:y])**2)
  end

  def integer_distance(p1, p2)
    [(p1[:x] - p2[:x]).abs, (p1[:y] - p2[:y]).abs].min
  end

  def process_to_visit(to_visit, destination, start, visited, visited_coords, open, from, dir)
    if path_point_fits_map?(to_visit) && no_path_in_direction?(to_visit, dir) && no_ground_around?(to_visit) && !visited_coords.include?([to_visit[:x], to_visit[:y]])
      if to_visit == destination #|| @map[to_visit[:y]][to_visit[:x]] == :path
        back_point = from[:point]
        while { x: back_point[:x], y: back_point[:y] } != start
          @map[back_point[:y]][back_point[:x]] = :path

          visited.each do |pt|
            if pt[:point][:x] == back_point[:x] && pt[:point][:y] == back_point[:y]
              back_point = pt[:back]
            end
          end
        end
        return true
      elsif [:rock].include?(@map[to_visit[:y]][to_visit[:x]])
        open << { point: to_visit, back: from[:point] }
      end
    end
    false
  end

  def path_point_fits_map?(point)
    point[:x] < @opts[:map_width] - 1 && point[:y] < @opts[:map_height] - 1 && point[:x] != 0 && point[:y] != 0
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

  def no_ground_around?(p)
    grounds = [:ground, :path_start]
    !grounds.include?(@map[p[:y] - 1][p[:x] - 1]) &&
      !grounds.include?(@map[p[:y] - 1][p[:x] + 1]) &&
      !grounds.include?(@map[p[:y] + 1][p[:x] - 1]) &&
      !grounds.include?(@map[p[:y] + 1][p[:x] + 1])
  end

  def cleanup_pathfinding
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        if [:path_start].include?(@map[row][col])
          if no_sym_around?(:path, {x: col, y: row})
            @map[row][col] = :rock
          end
        end
      end
    end

    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        if [:door].include?(@map[row][col])
          if no_sym_around?(:path_start, {x: col, y: row})
            @map[row][col] = :rock
          end
        end
      end
    end

    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        if [:path, :path_start].include?(@map[row][col])
          @map[row][col] = :ground
        end
      end
    end
  end

  def no_sym_around?(sym, p)
    grounds = [*sym]
    begin !grounds.include?(@map[p[:y] - 1][p[:x] - 1]) rescue true end &&
      begin !grounds.include?(@map[p[:y] - 1][p[:x] + 1]) rescue true end &&
      begin !grounds.include?(@map[p[:y] + 1][p[:x] - 1]) rescue true end &&
      begin !grounds.include?(@map[p[:y] + 1][p[:x] + 1]) rescue true end &&
      begin !grounds.include?(@map[p[:y] - 1][p[:x]]) rescue true end &&
      begin !grounds.include?(@map[p[:y]][p[:x] - 1]) rescue true end &&
      begin !grounds.include?(@map[p[:y]][p[:x] + 1]) rescue true end &&
      begin !grounds.include?(@map[p[:y] + 1][p[:x]]) rescue true end
  end

  def cleanup_edges
    @opts[:map_height].times do |row|
      @opts[:map_width].times do |col|
        if [:rock].include?(@map[row][col])
          if no_sym_around?(:ground, {x: col, y: row})
            @map[row][col] = :nothing
          end
        end
      end
    end
  end

  def put_player(room)
    coords = @rnd.rand((room[:x] + 1)...(room[:x] + room[:w] - 1)), @rnd.rand((room[:y] + 1)...(room[:y] + room[:h] - 1))
    @map[coords.last][coords.first] = :player
    { x: coords.first, y: coords.last }
  end
end
