class AnnotationReindexer < ReindexerObserver
  observe :annotation

  def consequences annotation
    annotation.annotatable.reindexing_consequences
  end
  
end