class AssayAssetReindexer < ReindexerObserver

  observe :assay_asset

  def consequences assay_asset
    assay_asset.asset
  end

end