class DataFileSerializer < BaseSerializer
  attributes :id, :title
             :description
  has_one :content_blob
  #, include_data: true  #do

end
