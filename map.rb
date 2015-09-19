class Map
  attr_accessor :map

  TILES = {
    rock: '#',
    ground: ' '
  }

  def initialize(opts={})
    @opts = opts

    @map = []
    @random = Random.new
  end

  def generate
    fill_with_rock
    create_first_room
  end

  def draw
    @opts[:height].times do |row|
      puts @map[row].map { |c| TILES[c] }.join('')
    end
  end

private

  def create_first_room
    center_x = @random.rand(@opts[:width])
    center_y = @random.rand(@opts[:height])
    @map[center_y][center_x] = :ground
  end

  def fill_with_rock
    @opts[:height].times do |row|
      @map << []
      @opts[:width].times do |_col|
        @map[row] = [] if @map[row].nil?
        @map[row] << :rock
      end
    end
  end
end
