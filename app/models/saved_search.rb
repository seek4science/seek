class SavedSearch < ActiveRecord::Base
  belongs_to :user

  #generates the title, for the Favourite tooltip for example.
  def title
    "Search: '#{search_query}' (#{search_type})"
  end
end
