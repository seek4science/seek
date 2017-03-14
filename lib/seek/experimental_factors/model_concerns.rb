module Seek
  module ExperimentalFactors
    # model characteristics common to both StudiedFactors and ExperimentalConditions (and potentially treatments in the future)
    module ModelConcerns
      extend ActiveSupport::Concern

      included do
        include Seek::Taggable

        belongs_to :measured_item
        belongs_to :unit

        validates :measured_item, presence: true
        validates_presence_of :start_value, :unit, unless: proc { |fs| fs.measured_item.title == 'growth medium' || fs.measured_item.title == 'buffer' }, message: "^Value can't be a empty"
        validates_presence_of :links, if: proc { |fs| fs.measured_item.title == 'concentration' }, message: "^Substance can't be a empty"

        acts_as_annotatable name_field: :title
      end

      def substances
        links.collect(&:substance)
      end
    end
  end
end
