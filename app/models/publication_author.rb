class PublicationAuthor < ActiveRecord::Base
  belongs_to :publication
  belongs_to :author, :class_name => 'Person'
end
