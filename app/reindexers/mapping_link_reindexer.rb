class MappingLinkReindexer < ReindexerObserver
  observe :mapping_link

  def consequences mapping_link
    mapping_link.substance.data_files | mapping_link.substance.sops
  end
  
end
