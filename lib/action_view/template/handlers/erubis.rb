# This is a stupid hack needed for haml to work.
#   haml is used by rdf-rdfa, which is a dependency of linkeddata.
#   linkeddata is locked to an old version because of rdf-virtuoso
class ActionView::Template::Handlers::Erubis
  def initialize(*args, &blk)

  end
end
