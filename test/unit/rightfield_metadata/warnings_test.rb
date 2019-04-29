require 'test_helper'

class WarningsTest < ActiveSupport::TestCase
  def setup
    @warnings = Seek::Templates::Extract::Warnings.new
  end

  test 'add' do
    assert_equal 0, @warnings.count
    @warnings.add(:no_permission, 'aa', 'aaa')
    @warnings.add(:no_study, 'bb', 'bbb')
    assert_equal 2, @warnings.count

    # rejects duplicates
    @warnings.add(:no_study, 'bb', 'bbb')
    assert_equal 2, @warnings.count
  end

  test 'warning equality' do
    a = Seek::Templates::Extract::Warnings::Warning.new(:no_permission, 'aa', 'extra')
    a2 = Seek::Templates::Extract::Warnings::Warning.new(:no_permission, 'aa', 'extra')

    assert a == a2
    assert a.eql? a2
    refute a.equal? a2

    b = Seek::Templates::Extract::Warnings::Warning.new(:not_in_db, 'aa', 'extra')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    b = Seek::Templates::Extract::Warnings::Warning.new(:no_permission, 'bb', 'extra')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    b = Seek::Templates::Extract::Warnings::Warning.new(:no_permission, 'aa', 'extra different')

    refute a == b
    refute a.eql?(b)
    refute a.equal?(b)

    assert_equal a.hash, a2.hash
    refute_equal a.hash, b.hash
  end

  test 'iterate' do
    @warnings.add(:no_permission, 'a', 'aa')
    @warnings.add(:no_permission, 'b', 'bb')
    @warnings.add(:duplicate_assay, 'c', 'cc')

    result = []
    @warnings.each do |warning|
      result << [warning.problem, warning.value, warning.extra_info]
    end

    assert_equal [[:no_permission, 'a', 'aa'], [:no_permission, 'b', 'bb'], [:duplicate_assay, 'c', 'cc']], result
  end

  test 'merge' do
    @warnings.add(:duplicate_assay, 'a', 'aa')
    warnings2 = Seek::Templates::Extract::Warnings.new
    warnings2.add(:duplicate_assay, 'a', 'aa')
    warnings2.add(:duplicate_assay, 'b', 'bb')

    @warnings.merge(warnings2)

    assert_equal 2, @warnings.count

    result = []
    @warnings.each do |warning|
      result << [warning.problem, warning.value, warning.extra_info]
    end

    assert_equal [[:duplicate_assay, 'a', 'aa'], [:duplicate_assay, 'b', 'bb']], result
  end

  test 'any? and empty?' do
    assert @warnings.empty?
    refute @warnings.any?
    @warnings.add(:duplicate_assay, 'aa')
    refute @warnings.empty?
    assert @warnings.any?
  end
end
