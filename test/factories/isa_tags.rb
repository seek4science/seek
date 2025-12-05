FactoryBot.define do
  # source ISA tag
  factory(:source_isa_tag, class: ISATag) do
    title { "source" }
  end

  # sample ISA tag
  factory(:sample_isa_tag, class: ISATag) do
    title { "sample" }
  end

  # protocol ISA tag
  factory(:protocol_isa_tag, class: ISATag) do
    title { "protocol" }
  end

  # source characteristic ISA tag
  factory(:source_characteristic_isa_tag, class: ISATag) do
    title { "source_characteristic" }
  end

  # sample characteristic ISA tag
  factory(:sample_characteristic_isa_tag, class: ISATag) do
    title { "sample_characteristic" }
  end

  # other material ISA tag
  factory(:other_material_isa_tag, class: ISATag) do
    title { "other_material" }
  end

  # other material characteristic ISA tag
  factory(:other_material_characteristic_isa_tag, class: ISATag) do
    title { "other_material_characteristic" }
  end

  # data file ISA tag
  factory(:data_file_isa_tag, class: ISATag) do
    title { "data_file" }
  end

  # data file comment ISA tag
  factory(:data_file_comment_isa_tag, class: ISATag) do
    title { "data_file_comment" }
  end

  # parameter value ISA tag
  factory(:parameter_value_isa_tag, class: ISATag) do
    title { "parameter_value" }
  end

  factory(:default_isa_tag, class: ISATag) do
    title { "input" }
  end

  # default ISA tag
  factory(:default_isa_tag, class: ISATag) do
    title { "default isa-tag" }
  end

end
