class Map
  attr_accessor :raw

  TILES = {
    rock: '#'
  }

  def initialize(opts={})
    @opts = opts

    @raw = []
  end

  def generate
    fill_with_rock
  end

  def draw
    @opts[:height].times do |w|
      puts @raw[w].map { |c| TILES[c] }.join('')
    end
  end

private

  def fill_with_rock
    @opts[:height].times do |row|
      @raw << []
      @opts[:width].times do |_|
        @raw[row] = [] if @raw[row].nil?
        @raw[row] << :rock
      end
    end
  end
end
