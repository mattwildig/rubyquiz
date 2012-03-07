require 'test/unit'
require './solitaire'

JOKER_A = 53
JOKER_B = 54

UNKEYED_DECK = (1..54).to_a
UNKEYED_RESULTS = [4, 49, 10, JOKER_A, 24, 8, 51, 44, 6, 4, 33]
UNKEYED_LETTERS = [4, 23, 10, 24, 8, 25, 18, 6, 4, 7]

class SolitaireTest < Test::Unit::TestCase

  def test_keystream_create
    assert Solitaire::KeyStream.new(UNKEYED_DECK).is_a? Solitaire::KeyStream
  end
  
  def test_keystream_joker_A_down_1
    s = Solitaire::KeyStream.new [1,2,JOKER_A,3,4]
    s.joker_A_down_1
    assert_equal [1,2,3,JOKER_A,4], s.deck
    
    s = Solitaire::KeyStream.new [1,2,3,4,JOKER_A]
    s.joker_A_down_1
    assert_equal [1, JOKER_A, 2, 3, 4], s.deck
  end
  
  def test_keystream_joker_B_down_2
    s = Solitaire::KeyStream.new [1, 2, JOKER_B, 3, 4]
    s.joker_B_down_2
    assert_equal [1, 2, 3, 4, JOKER_B], s.deck
    
    s = Solitaire::KeyStream.new [1,2,3,JOKER_B,4]
    s.joker_B_down_2
    assert_equal [1, JOKER_B, 2, 3, 4], s.deck
  end
  
  def test_keystream_triple_cut
    s = Solitaire::KeyStream.new [1, 2, JOKER_A, 3, 4, JOKER_B, 5, 6]
    s.triple_cut
    assert_equal [5, 6, JOKER_A, 3, 4, JOKER_B, 1, 2], s.deck
    
    s = Solitaire::KeyStream.new [1, JOKER_B, 2, 3, 4, JOKER_A, 5, 6]
    s.triple_cut
    assert_equal [5, 6, JOKER_B, 2, 3, 4, JOKER_A, 1], s.deck
    
    s = Solitaire::KeyStream.new [JOKER_B, 1, 2, 3, 4, 5, 6, JOKER_A]
    s.triple_cut
    assert_equal [JOKER_B, 1, 2, 3, 4, 5, 6, JOKER_A], s.deck
  end
  
  def test_keystream_count_cut_bottom
    s = Solitaire::KeyStream.new [1, 2, JOKER_A, 3, 4, JOKER_B, 5, 6]
    s.count_cut_bottom
    assert_equal [5, 1, 2, JOKER_A, 3, 4, JOKER_B, 6], s.deck
  end
  
  def test_keystream_output_letter
    s = Solitaire::KeyStream.new [3, 1, 2, 4, 5, 6]
    assert_equal 4, s.output_letter
  end
  
  def test_keystream_next_key
    s = Solitaire::KeyStream.new UNKEYED_DECK
    n = s.next_key
    assert_equal 4, n
  end
  
  def test_keystream_unkeyed_sequence
    s = Solitaire::KeyStream.new UNKEYED_DECK
    UNKEYED_RESULTS.each do |result|
      assert_equal result, s.next_key#, s.deck.to_s
    end
  end
  
  def test_keystream_unkeyed_sequence_letters
    s = Solitaire::KeyStream.new UNKEYED_DECK
    UNKEYED_LETTERS.each do |result|
      assert_equal result, s.next_letter#, s.deck.to_s
    end
  end
  
  def test_encrypter_create
    e = Solitaire::Encrypter.new(Solitaire::KeyStream.new(UNKEYED_DECK))
    assert e.is_a? Solitaire::Encrypter
  end
  
  def test_encrypter_unkeyed
    e = Solitaire::Encrypter.new(Solitaire::KeyStream.new(UNKEYED_DECK))
    assert_equal "GLNCQ MJAFF FVOMB JIYCB", e.encrypt("CODEI NRUBY LIVEL ONGER")
  end
  
  def test_encrypter_unkeyed
    d = Solitaire::Decrypter.new(Solitaire::KeyStream.new(UNKEYED_DECK))
    assert_equal "CODEI NRUBY LIVEL ONGER", d.decrypt("GLNCQ MJAFF FVOMB JIYCB")
  end
  
  def test_module_encrypt_unkeyed
    assert_equal "GLNCQ MJAFF FVOMB JIYCB", Solitaire.encrypt("Code in Ruby, live longer", UNKEYED_DECK)
  end
  
  def test_module_decrypt_unkeyed
    assert_equal "CODEI NRUBY LIVEL ONGER", Solitaire.decrypt("GLNCQ MJAFF FVOMB JIYCB", UNKEYED_DECK)
  end
  
  def test_examples
    assert_equal "YOURC IPHER ISWOR KINGX", Solitaire.decrypt("CLEPK HHNIY CFPWH FDFEH", UNKEYED_DECK)
    assert_equal "WELCO METOR UBYQU IZXXX", Solitaire.decrypt("ABVAW LWZSY OORYK DUPVH", UNKEYED_DECK)
  end
  
  def self.setup_test hash
    hash['Key'] = hash['Key'].gsub /'/, ''
    deck = hash['Key'] == '<null key>' ? UNKEYED_DECK : Solitaire.key_deck(hash['Key'])

    define_method "test_#{hash.object_id}" do
      assert_equal hash['Ciphertext'], Solitaire.encrypt(hash['Plaintext'], deck)
    end
  end
  
  File.foreach('sol-test.txt').inject({}) do |hash, line|
    next(hash) if line.strip == ''
    k, v = line.split(':').map(&:strip)
    hash[k] = v
    
    if k == 'Ciphertext'
      setup_test hash
      next {}
    end
    hash
  end
  
end