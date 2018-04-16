require 'test_helper'

class WarningsTest < ActiveSupport::TestCase
  def setup
    @warnings = Seek::Templates::Extract::Warnings.new
  end

  test 'add' do
    assert_equal 0, @warnings.count
    @warnings.add('a', 'aa')
    @warnings.add('b', 'bb')
    assert_equal 2, @warnings.count

    # rejects duplicates
    @warnings.add('b', 'bb')
    assert_equal 2, @warnings.count
  end

  test 'warning equality' do
    a = Seek::Templates::Extract::Warnings::Warning.new('aa', 'aaa')
    a2 = Seek::Templates::Extract::Warnings::Warning.new('aa', 'aaa')

    assert a == a2
    assert a.eql? a2
    refute a.equal? a2

    b = Seek::Templates::Extract::Warnings::Warning.new('bb', 'aaa')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    b = Seek::Templates::Extract::Warnings::Warning.new('aa', 'bbb')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    assert_equal a.hash, a2.hash
    refute_equal a.hash, b.hash
  end

  test 'iterate' do
    @warnings.add('a', 'aa')
    @warnings.add('b', 'bb')
    @warnings.add('c', 'cc')

    result = []
    @warnings.each do |warning|
      result << [warning.text, warning.value]
    end

    assert_equal [%w[a aa], %w[b bb], %w[c cc]], result
  end

  test 'merge' do
    @warnings.add('a', 'aa')
    warnings2 = Seek::Templates::Extract::Warnings.new
    warnings2.add('a', 'aa')
    warnings2.add('b', 'bb')

    @warnings.merge(warnings2)

    assert_equal 2, @warnings.count

    result = []
    @warnings.each do |warning|
      result << [warning.text, warning.value]
    end

    assert_equal [%w[a aa], %w[b bb]], result
  end

  test 'any? and empty?' do
    assert @warnings.empty?
    refute @warnings.any?
    @warnings.add('a', 'aa')
    refute @warnings.empty?
    assert @warnings.any?
  end
end
