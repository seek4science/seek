class SynonymReindexer < ReindexerObserver

  observe :synonym

  def consequences synonym
    res = synonym.data_files | synonym.sops
    res = res | synonym.substance.data_files if synonym.substance.respond_to?(:data_files)
    res = res | synonym.substance.sops if synonym.substance.respond_to?(:sops)
    res.uniq
  end

end