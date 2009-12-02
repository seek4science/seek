class AssetAuthor < ActiveRecord::Base
  belongs_to :asset
  belongs_to :author, :class_name => 'Person'
  
  def self.add_or_update_author_list(resource, author_params)
    recieved_authors = (author_params.blank? ? [] : ActiveSupport::JSON.decode(author_params)).uniq
    existing_authors = resource.asset.authors
    
    recieved_author_ids = recieved_authors.collect {|i| i[1]}
    
    existing_author_ids = existing_authors.collect {|i| i.id}
    
    ids_to_add = recieved_author_ids - existing_author_ids
    ids_to_remove = existing_author_ids - recieved_author_ids
    
    changes_made = false
    
    #Remove any authors in the database but not in the list
    ids_to_remove.each do |i|
      #Get the Person object to remove. (this is much faster than doing find_by_id)
      author_to_remove = existing_authors.select {|a| a.id == i}.first 
      resource.asset.authors.delete(author_to_remove)
      changes_made = true
    end
    
    #Add any new authors
    ids_to_add.each do |i|
      resource.asset.authors << Person.find_by_id(i)
      changes_made = true
    end
    
    resource.reload if changes_made
  end
end
