class MappingReindexer < ReindexerObserver
  observe :mapping

  def consequences mapping
    mapping.mapping_links.collect{|ml| [ml.substance.data_files,ml.substance.sops]}.flatten
  end
end