require 'test_helper'

class RegistrationInfoTest < ActiveSupport::TestCase

  def setup
    @reg_info = Seek::Openbis::RegistrationInfo.new
  end

  test 'setup works' do
    assert @reg_info
    assert_equal [], @reg_info.issues
    assert_equal [], @reg_info.created
    assert_nil @reg_info.primary
    assert_nil @reg_info.assay
    assert_nil @reg_info.study
    assert_nil @reg_info.datafile
  end

  test 'merge works' do
    df = Factory :data_file
    assay = Factory :assay
    study = Factory :study

    other = Seek::Openbis::RegistrationInfo.new([study], ['err1'])
    val = @reg_info.merge(other)
    assert_same val, @reg_info

    assert_equal [study], @reg_info.created
    assert_equal ['err1'], @reg_info.issues

    other = Seek::Openbis::RegistrationInfo.new([df, assay], ['err2'])
    @reg_info.merge(other)

    assert_equal [study, df, assay], @reg_info.created
    assert_equal ['err1', 'err2'], @reg_info.issues

  end

  test 'add_issues adds' do
    val = @reg_info.add_issues ['b', 'c']
    assert_same val, @reg_info
    assert_equal ['b','c'], @reg_info.issues
    @reg_info.add_issues 'a'
    assert_equal ['b','c', 'a'], @reg_info.issues
  end

  test 'add_created adds' do
    df = Factory :data_file
    val = @reg_info.add_created df
    assert_same val, @reg_info
    assert_equal [df], @reg_info.created
    @reg_info.add_created [Factory(:data_file), Factory(:data_file)]
    assert_equal 3, @reg_info.created.count
  end

end
