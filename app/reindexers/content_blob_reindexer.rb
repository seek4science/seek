class ContentBlobReindexer < ReindexerObserver

  observe :content_blob

  def consequences content_blob
    [content_blob.asset]
  end

end