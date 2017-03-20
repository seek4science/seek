require 'test_helper'

class OnlyWritesOnceTest < ActiveSupport::TestCase
  def setup
    User.current_user = Factory :user
    @item = Factory :event
    @dfs_with_dups = data_files_with_duplicates
    $authorization_checks_disabled = true
  end

  def teardown
    User.current_user = nil
    $authorization_checks_disabled = false
  end

  test 'should remove duplicates when setting collection with =' do
    @item.data_files = @dfs_with_dups
    assert_equal @dfs_with_dups.uniq, @item.data_files
  end

  test 'should ignore duplicates in a collection added with push' do
    @item.data_files.push @dfs_with_dups
    assert_equal @dfs_with_dups.uniq, @item.data_files
  end

  test 'should ignore duplicates in a collection added with <<' do
    @item.data_files << @dfs_with_dups
    assert_equal @dfs_with_dups.uniq, @item.data_files
  end

  test 'should ignore duplicates in a collection added with concat' do
    @item.data_files.concat @dfs_with_dups
    assert_equal @dfs_with_dups.uniq, @item.data_files
  end

  test 'should ignore elements which are already associated with this item in the database when added with push' do
    df = Factory(:data_file)
    @item = Factory :event, data_files: [df]
    @item.data_files.push df
    assert_equal [df], @item.data_files
  end

  test 'should ignore elements which are already associated with this item in the database when added with <<' do
    df = Factory(:data_file)
    @item = Factory :event, data_files: [df]
    @item.data_files << df
    assert_equal [df], @item.data_files
  end

  test 'should ignore elements which are already associated with this item in the database when added with concat' do
    df = Factory(:data_file)
    @item = Factory :event, data_files: [df]
    @item.data_files.concat df
    assert_equal [df], @item.data_files
  end

  private

  def data_files_with_duplicates
    df = Factory :data_file
    [Factory(:data_file), Factory(:data_file), df, df]
  end
end
