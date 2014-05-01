class ProgrammeReindexer < ReindexerObserver
  observe :programme

  def consequences programme
    programme.people | programme.institutions | programme.projects
  end
end