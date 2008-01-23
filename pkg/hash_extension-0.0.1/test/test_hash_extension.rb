require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment'))

class HashExtensionTest < Test::Unit::TestCase
  def setup
    @h = Hash.new
  end

  def test_missing_value
    assert_nil @h.baz!
  end
  
  def test_assignment
    @h.foo = 'bar'
    assert_equal @h.foo, 'bar'
  end
end
