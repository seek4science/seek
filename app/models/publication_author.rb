class PublicationAuthor < ActiveRecord::Base
  belongs_to :publication
  belongs_to :person

  default_scope(:order => 'author_index')
end
