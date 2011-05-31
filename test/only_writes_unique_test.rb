require 'test_helper'
#Authorization tests that are specific to public access
class AnonymousAuthorizationTest < ActiveSupport::TestCase
  def setup
    User.current_user = Factory :user
    @item = Factory :event
  end

  def teardown
    User.current_user = nil
  end

  test 'should remove duplicates when setting collection with =' do
    @item.data_files = data_files_with_duplicates
    assert_equal data_files_with_duplicates.uniq, @item.data_files
  end

  test 'should ignore duplicates in a collection added with push' do
    @item.data_files.push data_files_with_duplicates
    assert_equal data_files_with_duplicates.uniq, @item.data_files
  end

  test 'should ignore duplicates in a collection added with <<' do
    @item.data_files << data_files_with_duplicates
    assert_equal data_files_with_duplicates.uniq, @item.data_files
  end

  test 'should ignore duplicates in a collection added with concat' do
    @item.data_files.concat data_files_with_duplicates
    assert_equal data_files_with_duplicates.uniq, @item.data_files
  end

  test 'should ignore elements which are already associated with this item in the database when added with push' do
    df = Factory(:data_file)
    @item = Factory :event, :data_files => [df]
    @item.data_files.push df
    assert_equal [df], @item.data_files
  end

  test 'should ignore elements which are already associated with this item in the database when added with <<' do
    df = Factory(:data_file)
    @item = Factory :event, :data_files => [df]
    @item.data_files << df
    assert_equal [df], @item.data_files
  end

  test 'should ignore elements which are already associated with this item in the database when added with concat' do
    df = Factory(:data_file)
    @item = Factory :event, :data_files => [df]
    @item.data_files.concat df
    assert_equal [df], @item.data_files
  end


  private

  def data_files_with_duplicates
    df = Factory :data_file
    [Factory(:data_file), Factory(:data_file), df, df]
  end

end