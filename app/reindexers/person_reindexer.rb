class PersonReindexer < ReindexerObserver
  observe :person

  def consequences person
    person.assets_creators.map(&:asset)
  end
end