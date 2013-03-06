  class AssayReindexer < ReindexerObserver

  observe :assay

  def consequences assay
    # FIXME: the pending_related_assays is a temporary solution to finding assets for an assay, where AssayAsset is not visible after_save.
    # This I suspect is due to the transaction not yet being committed - although I would expect this operation to occur within
    # the same transaction. Needs revisiting when there a bit more time.
    assay.assay_assets.collect{|a| a.asset} | (assay.pending_related_assets || [])
  end

end