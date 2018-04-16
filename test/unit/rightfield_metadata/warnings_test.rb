require 'test_helper'

class WarningsTest < ActiveSupport::TestCase
  def setup
    @warnings = Seek::Templates::Extract::Warnings.new
  end

  test 'add' do
    assert_equal 0, @warnings.count
    @warnings.add('1', 'a', 'aa')
    @warnings.add('2', 'b', 'bb')
    assert_equal 2, @warnings.count

    # rejects duplicates
    @warnings.add('2', 'b', 'bb')
    assert_equal 2, @warnings.count
  end

  test 'warning equality' do
    a = Seek::Templates::Extract::Warnings::Warning.new('a', 'aa', 'aaa')
    a2 = Seek::Templates::Extract::Warnings::Warning.new('a', 'aa', 'aaa')

    assert a == a2
    assert a.eql? a2
    refute a.equal? a2

    b = Seek::Templates::Extract::Warnings::Warning.new('b', 'aa', 'aaa')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    b = Seek::Templates::Extract::Warnings::Warning.new('a', 'bb', 'aaa')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    b = Seek::Templates::Extract::Warnings::Warning.new('a', 'aa', 'bbb')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    assert_equal a.hash, a2.hash
    refute_equal a.hash, b.hash
  end

  test 'iterate' do
    @warnings.add('1', 'a', 'aa')
    @warnings.add('2', 'b', 'bb')
    @warnings.add('3', 'c', 'cc')

    result = []
    @warnings.each do |warning|
      result << [warning.item, warning.text, warning.value]
    end

    assert_equal [%w[1 a aa], %w[2 b bb], %w[3 c cc]], result
  end

  test 'merge' do
    @warnings.add('1', 'a', 'aa')
    warnings2 = Seek::Templates::Extract::Warnings.new
    warnings2.add('1', 'a', 'aa')
    warnings2.add('2', 'b', 'bb')

    @warnings.merge(warnings2)

    assert_equal 2, @warnings.count

    result = []
    @warnings.each do |warning|
      result << [warning.item, warning.text, warning.value]
    end

    assert_equal [%w[1 a aa], %w[2 b bb]], result
  end
end
