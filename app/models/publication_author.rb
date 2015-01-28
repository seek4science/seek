class PublicationAuthor < ActiveRecord::Base
  belongs_to :publication
  belongs_to :person

  default_scope(:order => 'author_index')

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :publication

  def full_name
    "#{first_name} #{last_name}"
  end

end
