class Game
  ALLOWABLE_MISSES = 20
  attr_accessor :secret_word, :misses
  
  def initialize(player1, player2)
    @guesser = player1
    @chooser = player2
    @word_length = @chooser.get_word_length
    @secret_word = Array.new(@word_length)
    @misses = []
  end
  
  def won?
    @secret_word.join.length == @word_length
  end
  
  def retrieve_guess
    loop do
      guess = @guesser.get_guess(@secret_word, @misses)
      valid_guess?(guess) ? (return guess) : (puts "Invalid guess! Choose again")
    end
  end
  
  def valid_guess?(guess)
    ("A".."Z").include?(guess) && !@secret_word.include?(guess) && !@misses.include?(guess)
  end
  
  def play
    while @misses.length < ALLOWABLE_MISSES && !won?
      print_secret_word
      guess = retrieve_guess
      @chooser.update_with_guess(guess, self)
      @misses << guess unless @secret_word.include?(guess)
      print_misses
    end
    print_secret_word
    puts won? ? "Hangman is saved!" : "Hangman is hung!"
  end
  
  def print_misses
    print "Misses: "
    @misses[0...-1].each do |char|
      print "#{char}, "
    end
    print "#{@misses[-1]}\n"
  end
  
  def print_secret_word
    @secret_word.each do |char|
      char.nil? ? (print "_ ") : (print "#{char} ")
    end
    puts
  end
end

class ComputerPlayer
  def initialize
    @dictionary = get_dictionary
    @word_choice = @dictionary.sample
  end
  
  def get_dictionary
    result = []
    File.foreach("dictionary.txt") do |line|
      result << line.chomp.upcase
    end
    result
  end
  
  def update_with_guess(guess, game)
    game.secret_word.each_index do |index|
      game.secret_word[index] = guess if guess == @word_choice[index]
    end
  end
  
  def get_word_length
    @word_choice.length
  end
  
  def words_match?(word, secret_word)
    return false if word.length != secret_word.length
  
    word.each_char.with_index do |char, index|
      if secret_word[index] != nil
        return false if secret_word[index] != char
      else
        return false if secret_word.include?(char)
      end
    end
    true
  end
  
  def update_dictionary(secret_word)
    @dictionary.select! do |word|
      words_match?(word, secret_word)
    end
  end
  
  def get_guess(secret_word, misses)
    #simple guess: ("A".."Z").to_a.sample
    update_dictionary(secret_word)
    letter_frequencies = Hash.new(0)
    indices = (0...secret_word.length).to_a.select{|i| !secret_word[i]}
    @dictionary.each do |word|
      indices.each do |i|
        next if misses.include?(word[i])
        letter_frequencies[word[i]] += 1
      end
    end
    letter_frequencies.key(letter_frequencies.values.max)
  end
end

class HumanPlayer
  def get_num_matches(game)
    loop do
      puts "How many?"
      num_matches = gets.chomp.to_i
      return num_matches if num_matches.between?(1, game.secret_word.count(nil))
      puts "Invalid move!"
    end
  end
  
  def update_secret_word(guess, game)
    num_matches = get_num_matches(game)
    puts "Enter each position and hit enter."
    num_matches.times do |i|
      loop do
        match = gets.chomp.to_i
        if game.secret_word[match - 1] == nil && match.between?(1, game.secret_word.count)
          game.secret_word[match - 1] = guess
          break
        end
        puts "Invalid position!"
      end
    end
  end
  
  def update_with_guess(guess, game)
    puts "Is \"#{guess}\" in the word? (y/n)"
    choice = gets.chomp.upcase
    if choice == "Y"
      update_secret_word(guess, game)
    elsif choice != "N"
      puts "Invalid input. Type y/n."
      update_with_guess(guess, game)
    end
  end
  
  def get_guess(secret_word, misses)
    puts "Pick your letter:"
    gets.chomp.upcase
  end

  def get_word_length
    puts "How long is your word?"
    length = gets.chomp.to_i
    unless length.between?(1,20)
      puts "Invalid length!"
      return get_length
    end  
    length
  end
end

game = Game.new(ComputerPlayer.new, HumanPlayer.new)
game.play