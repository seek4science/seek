require 'doi_record'

module PublicationsHelper

  def publication_type_text type
    if type==DoiRecord::PUBLICATION_TYPES[:conference]
      "Conference"
    elsif type == DoiRecord::PUBLICATION_TYPES[:book_chapter]
      "Book"
    else
      "Journal"
    end
  end

  def authorised_publications projects=nil
    authorised_assets(Publication,projects)
  end

  def author_display_list publication
    if publication.publication_author_orders.empty?
       "<span class='none_text'>Not specified</span>"
    else
      author_list = []
      publication.publication_author_orders.sort_by(&:order).collect(&:author).each do |author|
        if author.kind_of?(Person) && author.can_view?
          author_list << link_to(get_object_title(author), show_resource_path(author))
        else
          author_list << author.first_name + " " + author.last_name
        end
      end
      author_list.join(', ')
    end
  end
end
