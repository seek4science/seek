class BioToolsLink < ApplicationRecord
  belongs_to :resource, polymorphic: true, inverse_of: :bio_tools_links

  validates_presence_of :bio_tools_id, :name

  def uri
    BioTools::Client.tool_url(bio_tools_id)
  end
end
