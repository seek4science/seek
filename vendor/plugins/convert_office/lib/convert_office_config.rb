module ConvertOffice
  class ConvertOfficeConfig
    @@options = {
      :java_bin => "java",
      :nailgun=> false,
      :soffice_port=>8100
    }
    cattr_accessor :options
  end
end
