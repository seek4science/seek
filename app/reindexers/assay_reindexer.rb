class AssayReindexer < ReindexerObserver

  observe :assay

  def consequences assay
    assay.assay_assets.collect{|a| a.asset}
  end

end