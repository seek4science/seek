require 'test_helper'

class WarningsTest < ActiveSupport::TestCase
  include Seek::Templates::Extract

  def setup
    @warnings = Seek::Templates::Extract::Warnings.new
  end

  test 'add' do
    assert_equal 0, @warnings.count
    @warnings.add(Warnings::NO_PERMISSION, 'aa', 'aaa')
    @warnings.add(Warnings::NO_STUDY, 'bb', 'bbb')
    assert_equal 2, @warnings.count

    # rejects duplicates
    @warnings.add(Warnings::NO_STUDY, 'bb', 'bbb')
    assert_equal 2, @warnings.count
  end

  test 'warning equality' do
    a = Warnings::Warning.new(Warnings::NO_PERMISSION, 'aa', 'extra')
    a2 = Warnings::Warning.new(Warnings::NO_PERMISSION, 'aa', 'extra')

    assert a == a2
    assert a.eql? a2
    refute a.equal? a2

    b = Warnings::Warning.new(Warnings::NOT_IN_DB, 'aa', 'extra')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    b = Warnings::Warning.new(Warnings::NO_PERMISSION, 'bb', 'extra')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    b = Warnings::Warning.new(Warnings::NO_PERMISSION, 'aa', 'extra different')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    assert_equal a.hash, a2.hash
    refute_equal a.hash, b.hash
  end

  test 'iterate' do
    @warnings.add(Warnings::NO_PERMISSION, 'a', 'aa')
    @warnings.add(Warnings::NO_PERMISSION, 'b', 'bb')
    @warnings.add(Warnings::DUPLICATE_ASSAY, 'c', 'cc')

    result = []
    @warnings.each do |warning|
      result << [warning.problem, warning.value, warning.extra_info]
    end

    assert_equal [[Warnings::NO_PERMISSION, 'a', 'aa'], [Warnings::NO_PERMISSION, 'b', 'bb'], [Warnings::DUPLICATE_ASSAY, 'c', 'cc']], result
  end

  test 'merge' do
    @warnings.add(Warnings::DUPLICATE_ASSAY, 'a', 'aa')
    warnings2 = Seek::Templates::Extract::Warnings.new
    warnings2.add(Warnings::DUPLICATE_ASSAY, 'a', 'aa')
    warnings2.add(Warnings::DUPLICATE_ASSAY, 'b', 'bb')

    @warnings.merge(warnings2)

    assert_equal 2, @warnings.count

    result = []
    @warnings.each do |warning|
      result << [warning.problem, warning.value, warning.extra_info]
    end

    assert_equal [[Warnings::DUPLICATE_ASSAY, 'a', 'aa'], [Warnings::DUPLICATE_ASSAY, 'b', 'bb']], result
  end

  test 'any? and empty?' do
    assert @warnings.empty?
    refute @warnings.any?
    @warnings.add(Warnings::DUPLICATE_ASSAY, 'aa')
    refute @warnings.empty?
    assert @warnings.any?
  end
end
