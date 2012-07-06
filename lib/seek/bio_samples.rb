require "libxml"

module Seek

  class BioSamples
    def initialize file, xml=nil, to_populate=true
      @file = file
      @assay = nil
      @treatment_objs = {}
      @sample_comments = {}
      @creator = nil
      @errors = ""
      @to_populate = to_populate

      @specimen_names = {}
      @sample_names = {}
      @treatments = {}
      @rna_extractions = {}
      @sequencing = {}
      if xml
        begin
          doc = LibXML::XML::Parser.string(xml).parse
        rescue Exception => e
          doc = nil
          Rails.logger.warn "Invalid xml encountered. - #{e.message}"

        end
        if doc
          extract_from_document doc, @file.original_filename
        end
      end
    end


    private
    def extract_from_document doc, filename
      doc.root.namespaces.default_prefix = "ss"
      template_sheet = find_template_sheet doc
      samples_sheet = find_samples_sheet doc
      if template_sheet
        set_creator template_sheet
        @file.creators << @creator unless @file.creators.include?(@creator) || @creator.nil?
        populate_assay template_sheet, filename if @to_populate
      end
      if samples_sheet
        populate_bio_samples samples_sheet
      end
    end

    def find_template_sheet doc
      sheet = doc.find_first("//ss:sheet[@name='IDF']")
      sheet = doc.find_first("//ss:sheet[@name='idf']") if sheet.nil?
      sheet = doc.find_first("//ss:sheet[@name='Idf']") if sheet.nil?
      sheet = hunt_for_sheet(doc, "IDF") if sheet.nil?
      sheet
    end

    def find_samples_sheet doc
      sheet = doc.find_first("//ss:sheet[@name='SDRF']")
      sheet = doc.find_first("//ss:sheet[@name='sdrf']") if sheet.nil?
      sheet = doc.find_first("//ss:sheet[@name='Sdrf']") if sheet.nil?
      sheet = hunt_for_sheet(doc, "SDRF") if sheet.nil?
      sheet
    end

    def hunt_for_sheet doc, keyword
      doc.find("//ss:sheet").find do |sheet|
        sheet_name=sheet.attributes["name"]
        possible_cells = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row='1']")
        match = possible_cells.find do |cell|
          cell.content.match(/"*#{keyword}".*/i)
        end
        !match.nil?
      end
    end

    def populate_assay sheet, filename
      investigation_title = hunt_for_horizontal_field_value sheet, "Investigation Title"
      assay_type_title = hunt_for_horizontal_field_value sheet, "Experiment Class"
      study_title = hunt_for_horizontal_field_value sheet, "Experiment Description"

      investigation = Investigation.find_all_by_title(investigation_title).detect{|i|i.can_view? User.current_user}

      unless investigation
        investigation = Investigation.new :title => investigation_title
        investigation.projects = User.current_user.person.projects
        investigation.policy = Policy.private_policy
        investigation.save!
      end

      #create new assay and study
      study = Study.find_by_title study_title
      unless study && study.contributor==User.current_user
              study = Study.new :title => study_title
              study.policy = Policy.private_policy
      end
      study.investigation = investigation
      study.save!

      assay_class = AssayClass.find_by_title("Experimental Assay")
      assay_class = AssayClass.create :title => "Experimental Assay" unless assay_class
      assay_type =  AssayType.find_by_title(assay_type_title)
      assay_type = AssayType.create :title=> assay_type_title unless assay_type

      assay_title = filename.nil? ? "dummy assay" : filename.split(".").first
      @assay = Assay.all.detect{|a|a.title == assay_title and a.study_id == study.id and a.assay_class_id == assay_class.try(:id) and a.assay_type == assay_type and a.owner_id == User.current_user.person.id}
      unless @assay
        @assay = Assay.new :title => assay_title
        @assay.policy = Policy.private_policy
      end
      @assay.assay_class = assay_class
      @assay.assay_type = assay_type
      ### unknown technology type
      @assay.technology_type = TechnologyType.first
      @assay.study = study
      @assay.save!
      @assay.relate @file
    end

    def populate_bio_samples sheet

      # population order should NOT change, DB is populated only if @to_populate is set to be true

      #populate treatments
      treatment_protocols = hunt_for_field_values sheet, "Treatment"
      treatment_attributes = []
      treatment_attributes = get_attribute_names sheet, treatment_protocols.first.attributes["row"].to_i - 2, treatment_protocols.first.attributes["column"].to_i, "Treatment" unless treatment_protocols.blank?
      treatment_protocols.each do |treatment_protocol|
        if  @to_populate
          populate_treatment sheet, treatment_protocol
        end
        set_treatments sheet, treatment_protocol, treatment_attributes
      end


      #extract specimen and sample names from the file
      specimen_name_cells = hunt_for_field_values sheet, "Specimen"
      set_specimen_names specimen_name_cells

      sample_name_cells = hunt_for_field_values sheet, "Sample Name"
      set_sample_names sample_name_cells
      @sample_comments = hunt_for_field_values sheet, "Optional"


      #populate specimens and samples
      if @to_populate
        specimen_name_cells.each do |specimen|
          populate_specimen sheet, specimen
        end

        sample_name_cells.each do |sample|
          populate_sample sheet, sample
        end
      end

      #extract RNA and sequencing from the file
      rna_protocols = hunt_for_field_values sheet, "RNA Extraction"
      sequencing_protocols = hunt_for_field_values sheet, "Sequencing"
      rna_attribute_names= []
      sequencing_attribute_names =[]

      rna_attribute_names = get_attribute_names sheet, rna_protocols.first.attributes["row"].to_i, rna_protocols.first.attributes["column"].to_i, "RNA Extraction" unless rna_protocols.blank?
      sequencing_attribute_names = get_attribute_names sheet, sequencing_protocols.first.attributes["row"].to_i, sequencing_protocols.first.attributes["column"].to_i, "Sequencing" unless sequencing_protocols.blank?

      rna_protocols.each do |rna_p|
        set_rna_extractions sheet, rna_p, rna_attribute_names unless rna_p == rna_protocols[0] || rna_p == rna_protocols[1]
      end
      sequencing_protocols.each do |sq|
        set_sequencing sheet, sq, sequencing_attribute_names unless sq == sequencing_protocols[0] || sq == sequencing_protocols[1]
      end

    end

    def set_creator sheet
      creator_email = hunt_for_horizontal_field_value sheet, "Person Email"
      creator_last_name = hunt_for_horizontal_field_value sheet, "Person Last Name"
      creator_first_name = hunt_for_horizontal_field_value sheet, "Person First Name"
      creator_name = "#{creator_first_name} #{creator_last_name}"
      @creator = Person.find_by_first_name_and_last_name_and_email(creator_first_name,creator_last_name,creator_email)
      unless @creator
        @errors << "Warning: Person #{creator_name}(#{creator_email}) cannot be found. Please register in SEEK.<br/>"
        raise @errors
      end
    end

    def set_treatments sheet, treatment_protocol, treatment_attribute_names
      sheet_name = sheet.attributes["name"]

      row = treatment_protocol.attributes["row"].to_i
      col = treatment_protocol.attributes["column"].to_i
      end_col = get_end_column sheet, get_next_table_name(sheet, "Treatment")

      row_value = {}
      start_row = row
      sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = #{start_row} and @column >= #{col} and @column <= #{end_col}]").collect do |cell|
        cell_col = cell.attributes["column"].to_i
        row_value[treatment_attribute_names[cell_col]] = cell.content.tr('""', "")
      end
      @treatments[start_row] = row_value
    end

    def set_rna_extractions sheet, rna_extraction_protocol, rna_attribute_names
      sheet_name = sheet.attributes["name"]

      row = rna_extraction_protocol.attributes["row"].to_i
      col = rna_extraction_protocol.attributes["column"].to_i
      end_col = get_end_column sheet, get_next_table_name(sheet, "RNA Extraction")

      row_value = {}
      start_row = row
      sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = #{start_row} and @column >= #{col} and @column <= #{end_col}]").collect do |cell|
        cell_col = cell.attributes["column"].to_i
        row_value[rna_attribute_names[cell_col]] = cell.content.tr('""', "")
      end
      @rna_extractions[start_row] = row_value
    end

    def set_sequencing sheet, sequencing_protocol, sequencing_attribute_names
      sheet_name = sheet.attributes["name"]

      row = sequencing_protocol.attributes["row"].to_i
      col = sequencing_protocol.attributes["column"].to_i
      end_col = get_end_column sheet, get_next_table_name(sheet, "Sequencing")

      row_value = {}
      start_row = row
      sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = #{start_row} and @column >= #{col} and @column <= #{end_col}]").collect do |cell|
        cell_col = cell.attributes["column"].to_i
        row_value[sequencing_attribute_names[cell_col]] = cell.content.tr('""', "")
      end
      @sequencing[start_row] = row_value
    end

    def populate_treatment sheet, treatment_protocol
      sheet_name = sheet.attributes["name"]
      row = treatment_protocol.attributes["row"].to_i
      col = treatment_protocol.attributes["column"].to_i
      treatment_protocol = treatment_protocol.content.tr('""', "")
      substance = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+1}]").first.content.tr('""', "") }
      concentration = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+2}]").first.content.tr('""', "") }
      unit_symbol = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+3}]").first.content.tr('""', "")  }


      unit = Unit.find_by_symbol unit_symbol
      unit = Unit.create :symbol => unit_symbol, :factors_studied => false unless unit

      treatment = Treatment.all.detect { |t| t.treatment_protocol == treatment_protocol and
          t.unit_id == unit.id and
          t.substance == substance and
          t.concentration.to_s == concentration }

      treatment = Treatment.new :substance => substance, :concentration => concentration, :unit_id => unit.id, :treatment_protocol => treatment_protocol unless treatment

      treatment.save!
      @treatment_objs[row] = treatment
    end

    def populate_specimen sheet, specimen_name_cell
      sheet_name=sheet.attributes["name"]
      row = specimen_name_cell.attributes["row"].to_i
      col = specimen_name_cell.attributes["column"].to_i
      specimen_title = specimen_name_cell.try :content
      organism_title = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+1}]").first.content.tr('""', "") }
      strain_title = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+2}]").first.content.tr('""', "")  }
      sex = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+3}]").first.content.tr('""', "")   }

      case sex
        when "female"
          sex = 0
        when "male"
          sex = 1
        when "hermaphrodite"
          sex = 2
        when "unknown"
          sex = nil
        else
          sex = nil
      end

      age = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+4}]").first.content.tr('""', "").to_i}
      age_time_unit = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+5}]").first.content.tr('""', "")}


      organism = Organism.find_by_title organism_title
      strain = Strain.find_by_title strain_title

      culture_growth_type = CultureGrowthType.find_by_title "in vivo"
      unless organism
        organism = Organism.new :title => organism_title
        organism.save!
      end

      strain = Strain.new :title => strain_title unless strain
      strain.organism = organism
      strain.save!

      specimen = Specimen.find_by_title specimen_title

      unless specimen
        specimen = Specimen.new :title => specimen_title, :lab_internal_number => specimen_title
        specimen.sex = sex
        specimen.age = age
        specimen.age_unit = age_time_unit
        specimen.institution = @creator.institutions.first
        specimen.strain = strain
        specimen.culture_growth_type= culture_growth_type
        specimen.policy = @file.policy.deep_copy
        specimen.save!
      else
        unless specimen.organism == organism &&
            specimen.strain == strain &&
            specimen.sex == sex &&
            specimen.age == age &&
            specimen.age_unit == age_time_unit &&
            specimen.can_view?(User.current_user)
          @errors << "Warning: specimen with the name '#{specimen_title}' in row #{row} is already created in SEEK."
          @errors << "But you are not authorized to view it." if !specimen.can_view?(User.current_user)
          @errors << "You may rename it and upload the file as new version!<br/>"
        end
      end
    end

    def populate_sample sheet, sample_name_cell
      sheet_name=sheet.attributes["name"]
      row = sample_name_cell.attributes["row"].to_i
      col = sample_name_cell.attributes["column"].to_i

      sample_title = sample_name_cell.content
      #samples.sample_type
      sample_type =try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+1}]").first.content.tr('""', "")   }
      tissue_and_cell_type_title = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+3}]").first.content.tr('""', "") }
      sop_title = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+4}]").first.content.tr('""', "") }
      sop_title = nil if sop_title=="NO STORAGE"
      donation_date = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+5}]").first.content.tr('""', "")}
      institution_name = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+6}]").first.content.tr('""', "")}

      tissue_and_cell_type = TissueAndCellType.find_by_title tissue_and_cell_type_title
      tissue_and_cell_type = TissueAndCellType.create :title => tissue_and_cell_type_title if !tissue_and_cell_type && tissue_and_cell_type_title
      sop = Sop.find_by_title sop_title
      institution = Institution.find_by_name institution_name

      specimen_title = @specimen_names[row]
      specimen = Specimen.find_by_title specimen_title

      comments = @sample_comments.detect { |comments| comments.attributes["row"].to_i == row }.try(:content)

      sample = Sample.find_by_title sample_title
      unless sample
        sample = Sample.new :title => sample_title,
                            :lab_internal_number => sample_title
        sample.projects = User.current_user.person.projects
        treatment = ""
        @treatments[row].try(:each) do |k, v|
          treatment << k.to_s + ":" + v.to_s
          treatment << "," unless k == @treatments[row].keys.last
        end

        sample.sample_type = sample_type
        sample.donation_date = donation_date
        sample.institution = institution
        sample.tissue_and_cell_types << tissue_and_cell_type if tissue_and_cell_type.try(:id) && !sample.tissue_and_cell_types.include?(tissue_and_cell_type)
        sample.associate_sop sop if sop
        sample.specimen = specimen if specimen
        sample.comments = comments
        sample.treatment = treatment
        sample.policy = @file.policy.deep_copy
        sample.save!
      else
        unless sample.sample_type == sample_type &&
            sample.institution == institution &&
            sample.comments == comments &&
            sample.can_view?(User.current_user)
          @errors << "Warning: sample with the name '#{sample_title}' in row #{row} is already created in SEEK."
          @errors << "But you are not authorized to view it." if !sample.can_view?(User.current_user)
          @errors << "You may rename it and upload the file as new version!<br/>"
        end

      end
      unless @assay.samples.include?(sample)
        @assay.samples << sample
        @assay.save!
      end
    end


    def set_sample_names sample_name_cells
      sample_name_cells.each do |sample_name_cell|
        row = sample_name_cell.attributes["row"].to_i
        sample_title = sample_name_cell.content
        @sample_names[row] = sample_title
      end
    end

    def set_specimen_names specimen_name_cells
      specimen_name_cells.each do |specimen_name_cell|
        row = specimen_name_cell.attributes["row"].to_i
        specimen_title = specimen_name_cell.content
        @specimen_names[row] = specimen_title
      end
    end

    def hunt_for_horizontal_field_value sheet, field_name
      sheet_name=sheet.attributes["name"]
      field_cell = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell").find do |cell|
        cell.content.match(/#{field_name}.*/i)
      end
      unless field_cell.nil?
        #find the next column for this row that contains content
        row = field_cell.attributes["row"].to_i
        col = field_cell.attributes["column"].to_i
        field_cell = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+1}]").first
      end
      field_cell.nil? ? nil : field_cell.content
    end

    def hunt_for_field_values sheet, field_name
      sheet_name=sheet.attributes["name"]

      field_cell = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell").find do |cell|
        cell.content.match(/#{field_name}.*/i)
      end
      unless field_cell.nil?
        #find the next column for this row that contains content
        row = field_cell.attributes["row"].to_i
        col = field_cell.attributes["column"].to_i

        start_row = row + 1
        start_row = row if ["RNA Extraction", "Sequencing"].include? field_name
        start_row = row + 2 if ["Treatment", "Optional"].include? field_name
        #row +1 is source name or sample name that is hidden in the file
        field_values = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row > #{start_row} and @column=#{col}]").select do |cell|
          !cell.content.blank?
        end
      end
      field_values
    end

    def get_attribute_names sheet, row, col, table_name
      sheet_name = sheet.attributes["name"]
      end_col = get_end_column sheet, get_next_table_name(sheet, table_name)

      attribute_names = {}
      sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = #{row} and @column >= #{col} and @column <= #{end_col}]").collect do |cell|
        cell_col = cell.attributes["column"].to_i
        attribute_names[cell_col] = cell.content
      end

      return attribute_names
    end

    def get_end_column sheet, next_table_name=nil
      sheet_name = sheet.attributes["name"]
      if next_table_name
        field_cell = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell").find do |cell|
          cell.content.match(/#{next_table_name}.*/i)
        end
        unless field_cell.nil?
          #find the next column for this row that contains content
          end_col = field_cell.attributes["column"].to_i - 1
        end
      else
        end_col = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = 1 and @column > 0]").collect.last.attributes["column"].to_i}
      end

      return end_col
    end

    def get_next_table_name sheet, current_table_name
      sheet_name = sheet.attributes["name"]
      table_name_row = 3
      table_names = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = #{table_name_row} and @column > 0]").select do |cell|
        !cell.content.blank?
      end

      current_table_cell = table_names.detect { |t| t.content == current_table_name }
      index = table_names.index current_table_cell

      return table_names[index+1].content
    end
  end
end