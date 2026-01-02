FactoryBot.define do

  ##################################################################
  # Integration tests rely on a min_isa_tag and max_isa_tag to exist
  ##################################################################
  factory(:min_isa_tag, class: ISATag) do
    title { "Minimum isa tag" }
  end

  factory(:max_isa_tag, parent: :min_isa_tag) do
    title { "Maximum isa tag" }
  end
  ##################################################################

  # source ISA tag
  factory(:source_isa_tag, parent: :min_isa_tag) do
    title { "source" }
  end

  # sample ISA tag
  factory(:sample_isa_tag, parent: :min_isa_tag) do
    title { "sample" }
  end

  # protocol ISA tag
  factory(:protocol_isa_tag, parent: :min_isa_tag) do
    title { "protocol" }
  end

  # source characteristic ISA tag
  factory(:source_characteristic_isa_tag, parent: :min_isa_tag) do
    title { "source_characteristic" }
  end

  # sample characteristic ISA tag
  factory(:sample_characteristic_isa_tag, parent: :min_isa_tag) do
    title { "sample_characteristic" }
  end

  # other material ISA tag
  factory(:other_material_isa_tag, parent: :min_isa_tag) do
    title { "other_material" }
  end

  # other material characteristic ISA tag
  factory(:other_material_characteristic_isa_tag, parent: :min_isa_tag) do
    title { "other_material_characteristic" }
  end

  # data file ISA tag
  factory(:data_file_isa_tag, parent: :min_isa_tag) do
    title { "data_file" }
  end

  # data file comment ISA tag
  factory(:data_file_comment_isa_tag, parent: :min_isa_tag) do
    title { "data_file_comment" }
  end

  # parameter value ISA tag
  factory(:parameter_value_isa_tag, parent: :min_isa_tag) do
    title { "parameter_value" }
  end

  # default ISA tag
  factory(:default_isa_tag, parent: :min_isa_tag) do
    title { "default isa-tag" }
  end

end
