require_relative 'metadata_builder'

module DataCite
  class Metadata
    include ActiveModel::Model
    include ActiveModel::Attributes

    # From DataCite spec
    REQUIRED_FIELDS = %i[title identifier publisher year creators resource_type].freeze
    GENERAL_TYPES = %w(Audiovisual Collection DataPaper Dataset Event Image InteractiveResource Model PhysicalObject
                       Service Software Sound Text Workflow Other).freeze

    attribute :title, :string
    attribute :description, :string
    attribute :identifier, :string
    attribute :publisher, :string
    attribute :year, :integer
    attribute :creators, array: true, default: []
    attribute :resource_type, :string
    attribute :resource_type_general, :string

    validates *REQUIRED_FIELDS, presence: true
    validates :resource_type_general, inclusion: { in: GENERAL_TYPES }
    validate :creators_valid?

    def build
      DataCite::MetadataBuilder.new(self).build
    end

    def serialize
      build.to_s
    end

    private

    def creators_valid?
      creators.each do |creator|
        if !creator.respond_to?(:first_name) || creator.first_name.blank?
          errors.add(:creators, 'missing first name')
        end
        if !creator.respond_to?(:last_name) || creator.last_name.blank?
          errors.add(:creators, 'missing last name')
        end
      end
    end
  end
end
