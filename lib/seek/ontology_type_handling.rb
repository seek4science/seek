module Seek
  #Assay related tasks related to the assay and technology types that are read from an ontology
  module OntologyTypeHandling

    def assay_type_reader
      if is_modelling?
        Seek::Ontologies::ModellingAnalysisTypeReader.instance
      else
        Seek::Ontologies::AssayTypeReader.instance
      end
    end

    def technology_type_reader
      Seek::Ontologies::TechnologyTypeReader.instance
    end

    def assay_type_label
      super || assay_type_reader.class_hierarchy.hash_by_uri[self.assay_type_uri].try(:label)
    end

    def technology_type_label
      super || technology_type_reader.class_hierarchy.hash_by_uri[self.technology_type_uri].try(:label)
    end

    def default_assay_and_technology_type
      self.use_default_assay_type_uri! if self.assay_type_uri.nil?
      if is_modelling?
        self.technology_type_uri=nil
      else
        self.use_default_technology_type_uri! if self.technology_type_uri.nil?
      end
    end

    def use_default_assay_type_uri!
      self.assay_type_uri = assay_type_reader.default_parent_class_uri.try(:to_s)
    end

    def use_default_technology_type_uri!
      if is_modelling?
        self.technology_type_uri = nil
      else
        self.technology_type_uri = technology_type_reader.default_parent_class_uri.try(:to_s)
      end
    end

    def valid_assay_type_uri?
      !assay_type_reader.class_hierarchy.hash_by_uri[self.assay_type_uri].nil?
    end

    def valid_technology_type_uri?
      if is_modelling?
        self.technology_type_uri.nil?
      else
        !technology_type_reader.class_hierarchy.hash_by_uri[self.technology_type_uri].nil?
      end
    end

    #returns the label if it is an unrecognised suggested label, otherwise return nil
    def suggested_assay_type_label
      return nil if self[:assay_type_label].nil?
      return self[:assay_type_label] if assay_type_reader.class_hierarchy.hash_by_label[self[:assay_type_label].downcase].nil?
    end

    #returns the label if it is an unrecognised suggested label, otherwise return nil
    def suggested_technology_type_label
      return nil if self.is_modelling?
      return nil if self[:technology_type_label].nil?
      return self[:technology_type_label] if technology_type_reader.class_hierarchy.hash_by_label[self[:technology_type_label].downcase].nil?
    end

  end
end