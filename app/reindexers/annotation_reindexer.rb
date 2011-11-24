class AnnotationReindexer < ReindexerObserver

  observe :annotation

  def consequences annotation    
    c=[]
    c = c | annotation.annotatable.reindexing_consequences if annotation.annotatable.respond_to?(:reindexing_consequences)
    c << annotation.annotatable if annotation.annotatable.respond_to?(:solr_index!)
    c.uniq
  end

end