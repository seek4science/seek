# frozen_string_literal: true

module ISATagsTestHelper
  def create_all_isa_tags
    Seek::ISA::TagType::ALL_TYPES.each do |type|
      FactoryBot.create(:default_isa_tag, title: type)
    end
  end
end
