require 'test_helper'

class AssetDoiLogTest < ActiveSupport::TestCase

  test "was_doi_minted_for?" do
    df = Factory :data_file
    another_df = Factory :data_file
    AssetDoiLog.create(:asset_type => df.class.name, :asset_id => df.id, :asset_version => df.version, :action => AssetDoiLog::MINT)
    assert AssetDoiLog.was_doi_minted_for?(df.class.name, df.id, df.version)
    assert !AssetDoiLog.was_doi_minted_for?(another_df.class.name, another_df.id, df.version)
  end

end
