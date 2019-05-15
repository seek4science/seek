class SavedSearch < ApplicationRecord
  belongs_to :user

  acts_as_favouritable

  validates :user_id, :uniqueness => { :scope =>  [:search_query, :search_type, :include_external_search] }

  #generates the title, for the Favourite tooltip for example.
  def title
    if include_external_search
      "Search: '#{search_query}' (#{search_type} - including external sites)"
    else
      "Search: '#{search_query}' (#{search_type})"
    end
  end
end
