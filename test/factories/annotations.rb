FactoryBot.define do
  # Annotation
  factory :annotation do
    sequence(:value) { |n| "anno #{n}" }
    association :source, factory: :person
    attribute_name { 'annotation' }
  end

  factory :tag, parent: :annotation do
    attribute_name { 'tag' }
  end

  factory :expertise, parent: :annotation do
    attribute_name { 'expertise' }
  end

  factory :funding_code, parent: :annotation do
    attribute_name { 'funding_code' }
  end

  factory :tool, parent: :annotation do
    attribute_name { 'tool' }
  end

  # TextValue
  factory :text_value do
    sequence(:text) { |n| "value #{n}" }
  end

  # Discipline
  factory :discipline do
    sequence(:title) { |n| "Discipline #{n}" }
  end

  # Worksheet
  factory :worksheet do
    content_blob { FactoryBot.build(:spreadsheet_content_blob, asset: FactoryBot.create(:data_file)) }
    last_row { 10 }
    last_column { 10 }
  end
end
