require 'test_helper'

class DataSharePackTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
    @pack = DataSharePack.new(title: "Test DataSharePack", description: "DataSet generated in experiment AT0089.\\nIncluded raw and processed data files")
  end

  test "should be valid" do
    assert @pack.valid?
  end

  test "title should be present" do
    @pack.title = "     "
    assert !@pack.valid?
  end

  test "description should be present" do
    @pack.description = "     "
    assert !@pack.valid?
  end

end
