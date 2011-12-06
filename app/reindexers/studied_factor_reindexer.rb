class StudiedFactorReindexer < ReindexerObserver
  observe :studied_factor

  def consequences studied_factor
    [studied_factor.data_file]
  end
end