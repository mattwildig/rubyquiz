module Solitaire
  
  UNKEYED_DECK = (1..54).to_a
  
  module Useful
    def ascii_to_a1 codepoint
      codepoint - ?A.ord + 1
    end
  
    def a1_to_ascii a1
      a1 -= 26 if a1 > 26
      a1 += 26 if a1 < 1
      a1 + ?A.ord - 1
    end
  
    def group_in_fives text
      count = 0
      text.each_char.inject('') do |out, char|
        out << char
        count += 1
        (out << ' '; count = 0) if count == 5
        out
      end.strip
    end
  end
  
  class KeyStream
    include Useful
    attr_reader :deck

    def initialize(deck)
      @deck = deck.dup
    end
  
    def next_key
      joker_A_down_1
      joker_B_down_2
      triple_cut
      count_cut_bottom
      o = output_letter
      o == 54 ? 53 : o
    end
    
    def next_letter
      n = next_key
      n = next_key while n == 53
      n % 26
    end
  
    def joker_A_down_1
      move_down 53, 1
    end
  
    def joker_B_down_2
      move_down 54, 2
    end
    
    def move_down(card, dist)
      pos = @deck.index(card)
      @deck.delete_at(pos)
      pos -= @deck.length if (pos + dist) > @deck.length
      @deck.insert(pos + dist, card)
    end
  
    def triple_cut
      a, b = @deck.index(53), @deck.index(54)
      a, b = b, a if b < a
      @deck = @deck[(b+1)..-1] + @deck[a..b] + @deck[0...a]
    end
  
    def count_cut_bottom
      count_cut @deck.last
    end
    
    def count_cut count
      count = 53 if count == 54
      @deck = @deck[count..-2] + @deck[0, count] + [@deck.last]
    end
  
    def output_letter
      val = @deck[0]
      val = val == 54 ? 53 : val
      @deck[val]
    end
    
    def key_deck char
      joker_A_down_1
      joker_B_down_2
      triple_cut
      count_cut_bottom
      count_cut ascii_to_a1(char)
    end
  end
  
  class Encrypter
    include Useful
    
    def initialize keystream
      @keystream = keystream
    end
    
    def encrypt plaintext
      plaintext.gsub! /[^A-Za-z]/, ''
      plaintext.upcase!
      plaintext << 'X' * (5 - plaintext.length % 5) if plaintext.length % 5 != 0
      
      ciphertext = plaintext.codepoints.inject('') do |encrypted, char|
        char = ascii_to_a1(char)
        char += @keystream.next_letter
        encrypted << a1_to_ascii(char).chr
      end
      
      group_in_fives(ciphertext)
    end
  end
  
  class Decrypter
    include Useful
    
    def initialize keystream
      @keystream = keystream
    end
    
    def decrypt ciphertext
      ciphertext.codepoints.inject('') do |plain, cp|
        next(plain << ' ') if cp == ' '.ord
        cp = ascii_to_a1(cp)
        cp -= @keystream.next_letter
        plain << a1_to_ascii(cp)
      end
    end
  end
  
  def self.encrypt message, keystream
    Encrypter.new(KeyStream.new(keystream)).encrypt(message)
  end
  
  def self.decrypt ciphertext, keystream
    Decrypter.new(KeyStream.new(keystream)).decrypt(ciphertext)
  end
  
  def self.key_deck passphrase
    passphrase.upcase!
    k = KeyStream.new UNKEYED_DECK
    passphrase.codepoints do |cp|
      k.key_deck cp
    end
    k.deck
  end
  
end

if __FILE__ == $0
  if ARGV[0] == '-e'
    puts Solitaire.encrypt ARGV[1..-1].join(' '), Solitaire::UNKEYED_DECK
  elsif ARGV[0] == '-d'
    puts Solitaire.decrypt ARGV[1..-1].join(' '), Solitaire::UNKEYED_DECK
  else
    puts "Wrong arguments"
  end
end