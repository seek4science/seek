# Annotation
Factory.define :annotation do |f|
  f.sequence(:value) { |n| "anno #{n}" }
  f.association :source, factory: :person
  f.attribute_name 'annotation'
end

Factory.define :tag, parent: :annotation do |f|
  f.attribute_name 'tag'
end

Factory.define :expertise, parent: :annotation do |f|
  f.attribute_name 'expertise'
end

Factory.define :funding_code, parent: :annotation do |f|
  f.attribute_name 'funding_code'
end

Factory.define :tool, parent: :annotation do |f|
  f.attribute_name 'tool'
end

# TextValue
Factory.define :text_value do |f|
  f.sequence(:text) { |n| "value #{n}" }
end

# Discipline
Factory.define :discipline do |f|
  f.sequence(:title) { |n| "Discipline #{n}" }
end

# Worksheet
Factory.define :worksheet do |f|
  f.content_blob { Factory.build(:spreadsheet_content_blob, asset: Factory(:data_file)) }
  f.last_row 10
  f.last_column 10
end

# CellRange
Factory.define :cell_range do |f|
  f.cell_range 'A1:B3'
  f.association :worksheet
end

# Scale
Factory.define :scale do |f|
  f.sequence(:title) { |n| "scale #{n}" }
  f.sequence(:pos) { |n| n }
  f.sequence(:key) { |n| "scale_key_#{n}" }
  f.image_name { %w(airprom/small-airway.jpg airprom/aveoli.jpg airprom/lung.jpg airprom/aveoli.png
                    airprom/structural-cells.png airprom/genomics.jpg airprom/sub-cellular.jpg
                    airprom/inflammatory-cells.jpg airprom/airprom.png airprom/organism.jpg airprom/all.jpg
                    airprom/large-airway.png style_images/ui-icons_222222_256x240.png
                    style_images/ui-bg_flat_75_ffffff_40x100.png style_images/ui-icons_888888_256x240.png
                    style_images/ui-bg_glass_75_e6e6e6_1x400.png style_images/ui-icons_454545_256x240.png
                    vl-scales/cell.png vl-scales/liver.png vl-scales/all.png vl-scales/intercellular.png
                    vl-scales/organism.png vl-scales/liverLobule.jpg).sample }
end
