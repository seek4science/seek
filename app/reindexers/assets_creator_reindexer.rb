class AssetsCreatorReindexer < ReindexerObserver

  observe :assets_creator

  def consequences assets_creator
    [assets_creator.asset]
  end

end