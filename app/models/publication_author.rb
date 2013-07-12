class PublicationAuthor < ActiveRecord::Base
  belongs_to :publication

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :publication

end
