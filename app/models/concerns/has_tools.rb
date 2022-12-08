module HasTools
  extend ActiveSupport::Concern

  included do
    has_many :bio_tools_links, as: :resource, dependent: :destroy, autosave: true

    has_filter tool: Seek::Filtering::Filter.new(
      value_field: 'bio_tools_links.bio_tools_id',
      label_field: 'bio_tools_links.name',
      joins: [:bio_tools_links]
    )
  end

  def tools_attributes=(attributes)
    annotations = []

    attributes.each do |attrs|
      bio_tools_id = attrs[:bio_tools_id] || attrs['bio_tools_id']
      existing = bio_tools_links.detect { |a| a.bio_tools_id == bio_tools_id }
      if existing
        annotations << existing.tap { |e| e.assign_attributes(attrs) }
      else
        annotations << bio_tools_links.build(attrs)
      end
    end

    self.bio_tools_links = annotations
  end
end
