class Generator
  def initialize(words)
    @words = words
  end

  def generate(width, height)
    crosswords = []

    100000.times do |i|
      crosswords << generate_single(width, height, Random.new_seed)

      if i % 100 == 0
        crossword = crosswords.reverse.max_by(&:score)
        crosswords = [crossword]

        puts "Current best (of #{i})"
        puts
        puts crossword
        puts
        puts "Score: #{crossword.score}"
        puts "Seed: #{crossword.seed}"
      end
    end

    crosswords.max_by(&:score)
  end

  def generate_single(width, height, seed)
    random = Random.new(seed)
    crossword = Crossword.new(width, height, seed, random)

    crossword.force_add_word('астеа', [4, 3], :right)
    crossword.force_add_word('стаж', [6, 4], :right)

    while true
      placed_words = 0

      words = @words.shuffle(random: random)
      words.each do |word|
        crossword.add_word(word)
      end

      break if placed_words == 0
    end

    crossword
  end
end

class Crossword
  attr_reader :seed

  def initialize(width, height, seed, random)
    @width = width
    @height = height
    @board = height.times.map { width.times.map { nil } }
    @dir_map = height.times.map { width.times.map { nil } }
    @seed = seed
    @random = random
    @intersections = 0
    @words = 0
  end

  def score
    result = 0

    @height.times do |row|
      @width.times do |col|
        result += 1 if @board[row][col] && @board[row][col] != '#'
      end
    end

    @intersections * 10 + result
  end

  def to_s
    @board.map do |row|
      line = row.map { |letter| letter && letter != '#' ? letter : '.' }.join(' ')

      line
    end.join("\n")
  end

  def add_word(word)
    fits = possible_fits(word, @words == 0)

    return false if fits.empty?

    max_score = fits.map { |fit| fit[2] }.max
    max_fits = fits.select { |fit| fit[2] == max_score }

    random_index = @random.rand(max_fits.size)
    coords, direction = max_fits[random_index]

    place_word word, coords, direction

    true
  end

  def force_add_word(word, coords, direction)
    raise "Cannot place #{word}" unless possible_fit(word, coords, direction, true)

    place_word word, coords, direction
  end

  private

  def place_word(word, coords, direction)
    before_start = move_coords(coords, 1, opposite_direction(direction))
    if before_start
      row, col = before_start
      @board[row][col] = '#'
    end

    after_end = move_coords(coords, word.size, direction)
    if after_end
      row, col = after_end
      @board[row][col] = '#'
    end

    word.chars.each.with_index do |c, i|
      row, col = move_coords(coords, i, direction)

      @intersections += 1 if @board[row][col] == c

      @board[row][col] = c
      @dir_map[row][col] = direction
    end

    @words += 1
  end

  def possible_fits(word, first_word)
    directions = [:right, :down]
    possibilities = []

    @board.each.with_index do |_, row|
      @board.each.with_index do |_, col|
        coords = [row, col]

        directions.each do |direction|
          score = possible_fit(word, coords, direction, first_word)

          if score != nil
            possibilities << [coords, direction, score]
          end
        end
      end
    end

    possibilities
  end

  # Direction is :right or :down
  def possible_fit(word, coords, direction, first_word)
    score = 0

    # Empty before word
    before_word_coords = move_coords(coords, 1, opposite_direction(direction))
    if before_word_coords
      row, col = before_word_coords
      return if @board[row][col]
    end

    # Empty after word
    after_word_coords = move_coords(coords, word.size, direction)
    if after_word_coords
      row, col = after_word_coords
      return if @board[row][col]
    end

    word.chars.each.with_index do |c, i|
      row, col = move_coords(coords, i, direction)

      return if row.nil? || col.nil?

      score += 1 if @board[row][col] == c

      return if @board[row][col] && @board[row][col] != c
    end

    #
    perpendicular(direction).each do |perpendicular_direction|
      parallel_coords = move_coords(coords, 1, perpendicular_direction)
      next unless parallel_coords

      word.chars.each.with_index do |c, i|
        row, col = move_coords(parallel_coords, i, direction)

        return if row.nil? || col.nil?
        return if @dir_map[row][col] && @dir_map[row][col] == direction
      end
    end

    return if !first_word && score == 0

    score
  end

  def opposite_direction(direction)
    case direction
    when :up then :down
    when :left then :right
    when :down then :up
    when :right then :left
    end
  end

  def perpendicular(direction)
    case direction
    when :down, :up then [:right, :left]
    when :left, :right then [:up, :down]
    end
  end

  def move_coords(coords, n, direction)
    row, col = coords

    case direction
    when :up then [row - n, col] if row - n >= 0
    when :left then [row, col - n] if col - n >= 0
    when :right then [row, col + n] if col + n < @width
    when :down then [row + n, col] if row + n < @height
    end
  end
end

words = File.read('words').split("\n").map(&:strip)

crossword = Generator.new(words).generate(13, 13)

puts crossword
puts
puts "Score: #{crossword.score}"
puts "Seed: #{crossword.seed}"
