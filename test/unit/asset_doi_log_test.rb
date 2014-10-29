require 'test_helper'

class AssetDoiLogTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "is_doi_minted_for?" do
    df = Factory :data_file
    another_df = Factory :data_file
    AssetDoiLog.create(:asset_type => df.class.name, :asset_id => df.id, :action => AssetDoiLog::MINT)
    assert AssetDoiLog.is_doi_minted_for?(df.class.name, df.id)
    assert !AssetDoiLog.is_doi_minted_for?(another_df.class.name, another_df.id)
  end

end
