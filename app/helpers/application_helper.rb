# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def is_nil_or_empty? thing
    thing.nil? or thing.empty?
  end
end
