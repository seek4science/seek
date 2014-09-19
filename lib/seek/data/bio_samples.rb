require "libxml"

module Seek
  module Data
    class BioSamples

    attr_reader :investigation, :study, :assay, :assay_class, :assay_type,
                :units, :treatments, :organisms, :strains, :culture_growth_type, :tissue_and_cell_types,
                :specimens, :samples,  :specimen_names, :sample_names, :treatments,:treatments_text,
                :rna_extractions, :sequencing
    attr_accessor :errors,:warnings

    def initialize file, xml=nil, to_populate=true, institution_id = nil
      @file = file

      @investigation = nil
      @study = nil
      @assay = nil
      @assay_class = nil
      @assay_type = nil

      @units = {}
      @treatments = {}

      @organisms = {}
      @strains = {}
      @culture_growth_type = nil
      @tissue_and_cell_types = {}
      @specimens = {}
      @samples = {}

      @sample_comments = {}
      @creator = nil
      @errors = ""
      @to_populate = to_populate

      @specimen_names = {}
      @sample_names = {}
      @treatments_text = {}
      @rna_extractions = {}
      @sequencing = {}

      @warnings = []     # bittkomk: missing @warnings caused some errors -- was it supposed to be injected somehow?
      @parser_mapping = nil
      @samples_mapping = nil
      @assay_mapping = nil

      @num_rows = 1000 # bittkomk: this value is used for the creation of vectors of fixed or not-mapped entries; it gets actualized with the number of rows of mapped entries during parsing
      @start_row = 1

      @mock_json_import = {}
      @assay_json = {}

      @institution_title = ""
      @institution_title = Institution.find(institution_id).try(:title) if institution_id

      if xml
        begin
          doc = LibXML::XML::Parser.string(xml).parse
        rescue Exception => e
          doc = nil
          Rails.logger.warn "Invalid xml encountered. - #{e.message}"

        end
        if doc
          template = @file.template_name
          Rails.logger.warn "Template = #{template}, Institution name = " + @institution_title
          filename = @file.content_blob.original_filename
          parser_mapper = Seek::ParserMapper.new
          @parser_mapping = parser_mapper.mapping(template.downcase != "autodetect by filename" && template.downcase != "none" ? template.downcase : parser_mapper.filename_to_mapping_name(filename))

          if @parser_mapping
            @samples_mapping = @parser_mapping[:samples_mapping]
            @assay_mapping = @parser_mapping[:assay_mapping]

            Rails.logger.warn @samples_mapping


            extract_from_document doc
          else
            Rails.logger.warn "No parser mapping found for #{filename}"
            @errors << "No parser mapping found for #{filename}"
            raise  @errors
          end

        end
      end
    end


    private
    def extract_from_document doc
      doc.root.namespaces.default_prefix = "ss"


      template_sheet = nil
      samples_sheet = nil

      if @assay_mapping
        template_sheet = find_template_sheet doc
      end

      if @samples_mapping
        samples_sheet = find_samples_sheet doc
      end

      if template_sheet.nil? && samples_sheet.nil?
          @errors << "This #{t('data_file')} does not match the given template."
        raise  @errors
      end


      if template_sheet
        @assay_json = build_assay_mock_json template_sheet
        #set_creator @assay_json
        #@file.creators << @creator unless @file.creators.include?(@creator) || @creator.nil?
        #populate_assay , filename if @to_populate
      #else
       # @errors << "This data file does not match the template."
       # raise  @errors ## bittkomk: this is ok, since not all templates contain information for populating assays
      end

      if samples_sheet
        build_all_bio_sample_json samples_sheet
      else
        @errors << "No samples sheet is found."
        raise @errors
      end


      if @to_populate
          Rails.logger.warn "MOCK JSON:"
          Rails.logger.warn build_mock_json_import
          Rails.logger.warn "Populate db"
          populate_db build_mock_json_import
      end

    end

    def find_template_sheet doc
      #sheet = doc.find_first("//ss:sheet[@name='IDF']")
      #sheet = doc.find_first("//ss:sheet[@name='idf']") if sheet.nil?
      #sheet = doc.find_first("//ss:sheet[@name='Idf']") if sheet.nil?
      #sheet = hunt_for_sheet(doc, "IDF") if sheet.nil?
      template_sheet_name = @assay_mapping[:assay_sheet_name]
      Rails.logger.warn "template_sheet_name: " + template_sheet_name

      if template_sheet_name
        #template_sheet_name.downcase!
        sheet = doc.find_first("//ss:sheet[translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = '#{template_sheet_name.downcase}']")
        sheet = hunt_for_sheet(doc, template_sheet_name) if sheet.nil?
        sheet
      else
        nil
      end
    end

    def find_samples_sheet doc
      #sheet = doc.find_first("//ss:sheet[@name='SDRF']")
      #sheet = doc.find_first("//ss:sheet[@name='sdrf']") if sheet.nil?
      #sheet = doc.find_first("//ss:sheet[@name='Sdrf']") if sheet.nil?
      #sheet = hunt_for_sheet(doc, "SDRF") if sheet.nil?
      samples_sheet_name = @samples_mapping[:samples_sheet_name]
      Rails.logger.warn "samples_sheet_name: " + samples_sheet_name

      if samples_sheet_name
        #samples_sheet_name.downcase!
        sheet = doc.find_first("//ss:sheet[translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = '#{samples_sheet_name.downcase}']")
        sheet = hunt_for_sheet(doc, samples_sheet_name) if sheet.nil?
        sheet
      else
        nil
      end
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

    def build_assay_mock_json sheet

      if @assay_mapping[:parsing_direction] == "horizontal"
        mapped_field_hunter = method(:hunt_for_horizontal_field_value_mapped)
      else
        mapped_field_hunter = method(:hunt_for_field_values_mapped)
        # probing number of rows with data in sheet
        hunt_for_field_values_mapped sheet, @assay_mapping[:probing_column], @assay_mapping, true
      end

      investigation_title =  mapped_field_hunter.call(sheet, :"investigation.title", @assay_mapping).first() ? mapped_field_hunter.call(sheet, :"investigation.title", @assay_mapping).first()[:value] : nil
      assay_type_title = mapped_field_hunter.call( sheet, :"assay_type.title", @assay_mapping).first() ? mapped_field_hunter.call( sheet, :"assay_type.title", @assay_mapping).first()[:value] : nil
      study_title = mapped_field_hunter.call( sheet, :"study.title", @assay_mapping).first() ? mapped_field_hunter.call( sheet, :"study.title", @assay_mapping).first()[:value] : nil
      creator_email = mapped_field_hunter.call( sheet, :"creator.email", @assay_mapping).first() ? mapped_field_hunter.call( sheet, :"creator.email", @assay_mapping).first()[:value] : nil
      creator_last_name = mapped_field_hunter.call( sheet, :"creator.last_name", @assay_mapping).first() ? mapped_field_hunter.call( sheet, :"creator.last_name", @assay_mapping).first()[:value] : nil
      creator_first_name = mapped_field_hunter.call( sheet, :"creator.first_name", @assay_mapping).first() ? mapped_field_hunter.call( sheet, :"creator.first_name", @assay_mapping).first()[:value] : nil

      assay = {"investigation title" => investigation_title,
               "assay type title" => assay_type_title,
               "study title" => study_title,
               "creator email" => creator_email,
               "creator last name" => creator_last_name,
               "creator first name" => creator_first_name}


    end

    def populate_assay assay_json, filename

      investigation_title = assay_json["investigation title"]
      assay_type_title = assay_json["assay type title"]
      study_title = assay_json["study title"]

      @investigation = Investigation.find_all_by_title(investigation_title).detect{|i|i.can_view? User.current_user}

      unless @investigation
        @investigation = Investigation.new :title => investigation_title
        @investigation.projects = User.current_user.person.projects
        @investigation.policy = Policy.private_policy
        investigation.save!
      end

      #create new assay and study
      @study = Study.find_all_by_title(study_title).detect{|s|s.can_edit? User.current_user}
      unless @study
        @study = Study.new :title => study_title
        @study.policy = Policy.private_policy
      end
      @study.lock!
      @study.investigation = @investigation
      study.save!

      assay_class = AssayClass.where(title: I18n.t('assays.experimental_assay')).first_or_create
      assay_type_in_ontology = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_label[assay_type_title.downcase]
      assay_type = assay_type_in_ontology || SuggestedAssayType.where(label: assay_type_title).first_or_create


      assay_title = filename.nil? ? "dummy #{t('assays.assay').downcase}" : filename.split(".").first
      @assay = Assay.all.detect{|a|a.title == assay_title  && a.study_id == study.id  && a.assay_class_id == assay_class.try(:id)  && a.assay_type_uri== assay_type.uri.try(:to_s)  && a.owner_id == User.current_user.person.id}
      unless @assay
        @assay = Assay.new :title => assay_title
        @assay.policy = Policy.private_policy
      end
      @assay.lock!
      @assay.assay_class = assay_class
      @assay.assay_type_uri = assay_type.uri.try(:to_s)
      @assay.assay_type_label = assay_type_title
      ### unknown technology type
      #@assay.technology_type_uri = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label
      @assay.study = study
      @assay.save!
      @assay.relate @file

      @assay
    end

    # population of treatments, specimens and samples if to_populate = true
    # otherwise we collect just some data for the show data file view
    # population of x happens according to this schema:
    # * check if x should be added
    # * if yes:
    # ** get the data out of the sheets (using the parser mapping)
    # ** build a nice data structure for passing to the populate_x method
    # ** call populate_x method
    # *** write data to db if it isn't already there
    def build_all_bio_sample_json sheet

      # population order should NOT change, DB is populated only if @to_populate is set to be true

      # probing number of rows with data in sheet
      hunt_for_field_values_mapped sheet, @samples_mapping[:probing_column], @samples_mapping, true

      #populate treatments

      if @samples_mapping[:add_treatments]

        treatment_concentrations = hunt_for_field_values_mapped sheet, :"treatment.concentration", @samples_mapping
        treatment_substances = hunt_for_field_values_mapped sheet, :"treatment.substance", @samples_mapping
        treatment_units = hunt_for_field_values_mapped sheet, :"treatment.unit", @samples_mapping
        treatment_protocols = hunt_for_field_values_mapped sheet, :"treatment.treatment_protocol", @samples_mapping
        treatment_incubation_time = hunt_for_field_values_mapped sheet, :"treatment.incubation_time", @samples_mapping
        treatment_incubation_time_unit = hunt_for_field_values_mapped sheet, :"treatment.incubation_time_unit", @samples_mapping
        treatment_type = hunt_for_field_values_mapped sheet, :"treatment.type", @samples_mapping
        treatment_comments = hunt_for_field_values_mapped sheet, :"treatment.comments", @samples_mapping


        Rails.logger.warn "$$$$$$$$$$$$$$ treatment_concentrations #{treatment_concentrations}"
        Rails.logger.warn "$$$$$$$$$$$$$$ treatment_substances  #{treatment_substances}"
        Rails.logger.warn "$$$$$$$$$$$$$$ treatment_units  #{treatment_units}"
        Rails.logger.warn "$$$$$$$$$$$$$$ treatment_protocols  #{treatment_protocols}"
        Rails.logger.warn "$$$$$$$$$$$$$$ treatment_incubation_time  #{treatment_incubation_time}"
        Rails.logger.warn "$$$$$$$$$$$$$$ treatment_incubation_time_unit  #{treatment_incubation_time_unit}"
        Rails.logger.warn "$$$$$$$$$$$$$$ treatment_type #{treatment_type}"
        Rails.logger.warn "$$$$$$$$$$$$$$ treatment_comments #{treatment_comments}"

        treatment_data = treatment_protocols.zip(treatment_substances, treatment_concentrations, treatment_units, treatment_incubation_time, treatment_incubation_time_unit,
                          treatment_type, treatment_comments).map do
          |protocol, substance, concentration, unit, incubation_time, incubation_time_unit, type, comments|
            {:protocol => protocol, :substance => substance, :concentration => concentration, :unit => unit, :incubation_time => incubation_time, :incubation_time_unit => incubation_time_unit,
             :type => type, :comments => comments}
        end


        Rails.logger.warn "$$$$$$$$$$$$ TREATMENT DATA (#{treatment_data.length}) #{treatment_data}"

        build_all_treatment_mock_json treatment_data

        unless @to_populate
          treatment_data.each do |t|
            treatments_hash = {}
            t.each {|k, v| treatments_hash[k] = v[:value]} #t.map {|key, value| {key => value[:value]}}
            row = t.values.first[:row]
            treatments_text[row] = treatments_hash #data.values.join.to_s
          end
        end

      end

      #treatment_protocols = hunt_for_field_values sheet, "Treatment"
      #treatment_attributes = []
      #treatment_attributes = get_attribute_names sheet, treatment_protocols.first.attributes["row"].to_i - 2, treatment_protocols.first.attributes["column"].to_i, "Treatment" unless treatment_protocols.blank?
      #treatment_protocols.each do |treatment_protocol|
      #  if  @to_populate
      #    populate_treatment sheet, treatment_protocol
      #  end
      #  set_treatments sheet, treatment_protocol, treatment_attributes
      #end

      #extract specimen and sample names from the file
      #specimen_name_cells = hunt_for_field_values sheet, "Specimen"
      #set_specimen_names specimen_name_cells

      #sample_name_cells = hunt_for_field_values sheet, "Sample Name"
      #set_sample_names sample_name_cells
      #@sample_comments = hunt_for_field_values sheet, "Optional"

      #populate specimens and samples
      #if @to_populate
      #  specimen_name_cells.each do |specimen|
      #    populate_specimen sheet, specimen
      #  end

      #  sample_name_cells.each do |sample|
      #    populate_sample sheet, sample
      #  end
      #end

      # populate specimens

      if @samples_mapping[:add_specimens]

        specimen_titles = hunt_for_field_values_mapped sheet, :"specimens.title", @samples_mapping   # required
        specimen_sexes = hunt_for_field_values_mapped sheet, :"specimens.sex", @samples_mapping
        specimen_ages = hunt_for_field_values_mapped sheet, :"specimens.age", @samples_mapping
        specimen_age_units = hunt_for_field_values_mapped sheet, :"specimens.age_unit", @samples_mapping
        specimen_comments = hunt_for_field_values_mapped sheet, :"specimens.comments", @samples_mapping
        organism_titles = hunt_for_field_values_mapped sheet, :"organisms.title", @samples_mapping
        strain_titles = hunt_for_field_values_mapped sheet, :"strains.title", @samples_mapping
        genotype_titles = hunt_for_field_values_mapped sheet, :"specimens.genotype.title", @samples_mapping
        genotype_modifications = hunt_for_field_values_mapped sheet, :"specimens.genotype.modification", @samples_mapping

        Rails.logger.warn "$$$$$$$$$$$$$$ specimen_titles #{specimen_titles}"
        Rails.logger.warn "$$$$$$$$$$$$$$ specimen_sexes  #{specimen_sexes}"
        Rails.logger.warn "$$$$$$$$$$$$$$ specimen_ages  #{specimen_ages}"
        Rails.logger.warn "$$$$$$$$$$$$$$ specimen_age_units  #{specimen_age_units}"
        Rails.logger.warn "$$$$$$$$$$$$$$ organism_titles  #{organism_titles}"
        Rails.logger.warn "$$$$$$$$$$$$$$ strain_titles  #{strain_titles}"
        Rails.logger.warn "$$$$$$$$$$$$$$ genotype_titles  #{genotype_titles}"
        Rails.logger.warn "$$$$$$$$$$$$$$ genotype_modifications  #{genotype_modifications}"

        specimen_data = specimen_titles.
        zip(specimen_sexes, specimen_ages, specimen_age_units,
            specimen_comments, organism_titles, strain_titles, genotype_titles, genotype_modifications).
        map do |specimen_title, specimen_sex, specimen_age, specimen_age_unit,
            specimen_comment, organism_title, strain_title, genotype_title, genotype_modification |
          {:specimen_title => specimen_title, :specimen_sex => specimen_sex, :specimen_age => specimen_age, :specimen_age_unit => specimen_age_unit,
           :specimen_comment => specimen_comment, :organism_title => organism_title, :strain_title => strain_title,
           :genotype_title => genotype_title, :genotype_modification => genotype_modification}
        end

        Rails.logger.warn "$$$$$$$$$$$$ SPECIMEN DATA (#{specimen_data.length}) #{specimen_data}"


        build_all_specimen_mock_json specimen_data

        unless @to_populate
          specimen_titles.each do |s|
            @specimen_names[s[:row]] = s[:value]
          end
        end

        # populate samples

        if @samples_mapping[:add_samples]

          sample_titles = hunt_for_field_values_mapped sheet, :"samples.title", @samples_mapping
          sample_types = hunt_for_field_values_mapped sheet,  :"samples.sample_type", @samples_mapping
          sample_donation_dates = hunt_for_field_values_mapped sheet, :"samples.donation_date", @samples_mapping
          sample_comments = hunt_for_field_values_mapped sheet, :"samples.comments", @samples_mapping
          sample_organism_parts = hunt_for_field_values_mapped sheet, :"samples.organism_part", @samples_mapping
          tissue_and_cell_types = hunt_for_field_values_mapped sheet, :"tissue_and_cell_types.title", @samples_mapping
          sop_titles = hunt_for_field_values_mapped sheet, :"sop.title", @samples_mapping
          institution_titles = hunt_for_field_values_mapped sheet, :"institution.title", @samples_mapping


          samples_data = sample_titles.zip(sample_types, sample_donation_dates, sample_comments, sample_organism_parts, tissue_and_cell_types, sop_titles, institution_titles, specimen_titles).map do |sample_title, sample_type, sample_donation_date, sample_comment, sample_organism_part, tissue_and_cell_type, sop_title, institution_title, specimen_title|
            {:sample_title => sample_title, :sample_type => sample_type, :sample_donation_date => sample_donation_date, :sample_comment => sample_comment, :sample_organism_part => sample_organism_part,
             :tissue_and_cell_type => tissue_and_cell_type, :sop_title => sop_title, :institution_title => institution_title, :specimen_title => specimen_title}
          end

          Rails.logger.warn "$$$$$$$$$$$$$$ samples_comments #{sample_comments}"

          Rails.logger.warn "$$$$$$$$$$$$ SAMPLES DATA (#{samples_data.length}) : ##{samples_data}"

          build_all_sample_mock_json samples_data

          unless @to_populate
            sample_titles.each do |s|
              @sample_names[s[:row]] = s[:value]
            end
          end

        end

      end




      #extract RNA and sequencing from the file
      #rna_protocols = hunt_for_field_values sheet, "RNA Extraction"
      #sequencing_protocols = hunt_for_field_values sheet, "Sequencing"
      #rna_attribute_names= []
      #sequencing_attribute_names =[]

      #rna_attribute_names = get_attribute_names sheet, rna_protocols.first.attributes["row"].to_i, rna_protocols.first.attributes["column"].to_i, "RNA Extraction" unless rna_protocols.blank?
      #sequencing_attribute_names = get_attribute_names sheet, sequencing_protocols.first.attributes["row"].to_i, sequencing_protocols.first.attributes["column"].to_i, "Sequencing" unless sequencing_protocols.blank?

      #rna_protocols.each do |rna_p|
      #  set_rna_extractions sheet, rna_p, rna_attribute_names unless rna_p == rna_protocols[0] || rna_p == rna_protocols[1]
      #end
      #sequencing_protocols.each do |sq|
      #  set_sequencing sheet, sq, sequencing_attribute_names unless sq == sequencing_protocols[0] || sq == sequencing_protocols[1]
      #end

    end


    # creates a hash map like the one we would like to get from a google refine json export
    def build_mock_json_import

      mock_json = {}
      mock_json["assay"] = @assay_json
      mock_json_rows = []

      rows = (@start_row .. @start_row+@num_rows).to_a

      rows.each do |row|

        specimen = specimens[row]
        sample = samples[row]
        treatment = treatments[row]

        mock_json_rows << {"specimen" => specimen, "sample" => sample, "treatment" => treatment}


      end

      mock_json["rows"] = mock_json_rows

      Rails.logger.warn "$$$$$$$$$$$$$$$$$$$$ JSON: #{mock_json}"

      mock_json
    end

    # takes the intermediate hash map format and populates the database with this data
    def populate_db data

      assay = nil
      assay_json = data["assay"]

      if assay_json
        if assay_json["creator last name"] && assay_json["creator first name"] #&& assay_json["creator email"]
          set_creator data["assay"]
        else
          @creator = Person.find(User.current_user.person_id)
        end
        if assay_json["investigation title"] &&
           assay_json["assay type title"] &&
           assay_json["study title"]
            assay = populate_assay data["assay"], @file.content_blob.original_filename
        end
      else
        @creator = Person.find(User.current_user.person_id)
      end

      data["rows"].each do |data_row|

        specimen_json = data_row["specimen"]
        sample_json = data_row["sample"]
        treatment_json = data_row["treatment"]

        sample = nil
        specimen = nil

        if specimen_json
          specimen = populate_specimen specimen_json
        end

        if sample_json && specimen
          sample = populate_sample sample_json, specimen, assay
        end

        if treatment_json && (specimen || sample)
          populate_treatment treatment_json, specimen, sample
        end


      end


    end



    def set_creator assay_json
      creator_email = assay_json["creator email"]
      creator_last_name = assay_json["creator last name"]
      creator_first_name = assay_json["creator first name"]
      creator_name = "#{creator_first_name} #{creator_last_name}"
      #@creator = Person.find_by_first_name_and_last_name_and_email(creator_first_name,creator_last_name,creator_email)
      @creator = Person.find_by_first_name_and_last_name(creator_first_name, creator_last_name)
      unless @creator
        @warnings << "Warning: Person #{creator_name}(#{creator_email}) cannot be found. Please register in SEEK. Will use uploader as creator.<br/>"
        @creator = Person.find(User.current_user.person_id)
        #raise @errors
      end
    end

    def set_treatments sheet, treatment_protocol, treatment_attribute_names         # not used anymore
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
      @treatments_text[start_row] = row_value
    end

    def set_rna_extractions sheet, rna_extraction_protocol, rna_attribute_names       # not used anymore
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

    def set_sequencing sheet, sequencing_protocol, sequencing_attribute_names   # not used anymore
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


    def build_all_treatment_mock_json treatment_data_list

      treatment_data_list.each do |treatment_data|
        build_treatment_mock_json treatment_data
      end

    end


    def build_treatment_mock_json treatment_data

        treatment_protocol = treatment_data[:protocol][:value]
        substance = treatment_data[:substance][:value]
        concentration = treatment_data[:concentration][:value]
        unit = treatment_data[:unit][:value]
        incubation_time = treatment_data[:incubation_time][:value]
        incubation_time_unit = treatment_data[:incubation_time_unit][:value]
        type = treatment_data[:type][:value]
        comments = treatment_data[:comments][:value]

        row = treatment_data[:protocol][:row]

        treatment = {"type" => type,
                     "start value" => concentration,
                     "end value" => nil,
                     "unit" => unit,
                     "standard deviation" => nil,
                     "comments" => comments,
                     "protocol" => treatment_protocol,
                     "incubation time" => incubation_time,
                     "incubation time unit" => incubation_time_unit,
                     "compound" => substance}


        @treatments[row] = treatment
        @treatments_text[row] = "Treatment Protocol:#{treatment_protocol}, Unit:#{unit}, Concentration:#{concentration}, Substance:#{substance}"
        Rails.logger.warn "add treatment, row = #{row} : #{treatment}"
      
        treatment
    end


    def populate_treatment treatment_json, specimen=nil, sample=nil

        start_value = treatment_json["start value"]
        end_value = treatment_json["end value"]
        standard_deviation = treatment_json["standard deviation"]
        comments = treatment_json["comments"]
        protocol = treatment_json["protocol"]

        treatment = nil

        #if start_value && start_value != ""

          treatment_type = MeasuredItem.find_by_title(treatment_json["type"].downcase)
          treatment_type = MeasuredItem.create :title => treatment_json["type"].downcase, :factors_studied => false unless treatment_type

          compound = nil

          if treatment_type.title == "concentration"
            compound_name = treatment_json["compound"]
            if compound_name != "" && compound_name != "none"
              compound = Compound.find_by_name(treatment_json["compound"].downcase)
              compound = Compound.create :name => treatment_json["compound"].downcase unless compound
            end
          end

          incubation_time = treatment_json["incubation time"]
          incubation_time_unit = nil

          if incubation_time && incubation_time != ""
            incubation_time_unit = Unit.find_by_symbol treatment_json["incubation time unit"]
            incubation_time_unit = Unit.create :symbol => treatment_json["incubation time unit"], :factors_studied => false unless incubation_time_unit
          end

          unit = Unit.find_by_symbol treatment_json["unit"]
          unit = Unit.create :symbol => treatment_json["unit"], :factors_studied => false unless unit

          #treatment = Treatment.find(:first, :conditions => ["treatment_protocol = ? and unit_id = ? and substance = ? and cast(concentration as char) = ?", treatment_json["protocol"], unit.id, treatment_json["compound"], treatment_json["start value"]])

          #treatment = Treatment.new :substance => treatment_json["compound"], :concentration =>  treatment_json["start value"], :unit_id => unit.id, :treatment_protocol =>  treatment_json["protocol"] unless treatment
          def nil_or_float o
            o.nil? ? nil : o.to_f
          end

          #rails 3
           #treatment = Treatment.where(["treatment_protocol = ? and unit_id = ? and substance = ? and cast(concentration as char) = ?", treatment_protocol, unit.id, substance, concentration]).first

          treatment = Treatment.find(:first, :conditions => ["unit_id <=> ? and treatment_protocol <=> ? and treatment_type_id <=> ? and cast(start_value as char) <=> ? and cast(end_value as char) <=> ? and
              cast(standard_deviation as char) <=> ? and comments <=> ? and cast(incubation_time as char) <=> ? and incubation_time_unit_id <=> ? and compound_id <=> ? and specimen_id <=> ?",
              unit, protocol, treatment_type, nil_or_float(start_value), nil_or_float(end_value), nil_or_float(standard_deviation), comments, nil_or_float(incubation_time), incubation_time_unit, compound, specimen])

          treatment = Treatment.new :treatment_type => treatment_type, :start_value => start_value, :end_value => end_value, :unit => unit, :standard_deviation => standard_deviation,
              :comments => comments, :treatment_protocol => protocol, :incubation_time => incubation_time, :incubation_time_unit => incubation_time_unit,
              :compound => compound, :specimen => specimen, :sample => sample unless treatment

          treatment.save!

          if specimen and !specimen.treatments.include? treatment
            specimen.treatments << treatment
          end

          if sample and !sample.treatments.include? treatment
            sample.treatments << treatment
          end

        #end

        treatment
      
    end
    
    def build_all_specimen_mock_json specimen_data_list
      specimen_data_list.each do |specimen_data|
        build_specimen_mock_json specimen_data
      end      
    end
    
    def build_specimen_mock_json specimen_data

      specimen_title = specimen_data[:specimen_title][:value]
      sex = specimen_data[:specimen_sex][:value]
      organism_title = specimen_data[:organism_title][:value]
      strain_title = specimen_data[:strain_title][:value]
      age = specimen_data[:specimen_age][:value].to_i
      age_unit = specimen_data[:specimen_age_unit][:value]
      comments = specimen_data[:specimen_comment][:value]
      genotype_title = specimen_data[:genotype_title][:value]
      genotype_modification = specimen_data[:genotype_modification][:value]

      row = specimen_data[:specimen_title][:row]
      
      
      specimen = {"title" => specimen_title,
                  "organism" => organism_title,
                  "strain" => strain_title,
                  "sex" => sex,
                  "age" => age,
                  "age unit" => age_unit,
                  "comments" => comments,
                  "genotype title" => genotype_title,
                  "genotype modification" =>  genotype_modification}

      @specimens[row] = specimen
      @specimen_names[row] = specimen_title
      Rails.logger.warn "add specimen, row = #{row} : #{specimen}"
      
      specimen

    end

    def populate_specimen specimen_json

      specimen_title = specimen_json["title"]
      sex = specimen_json["sex"]
      age = specimen_json["age"]
      age_unit = specimen_json["age unit"]
      organism_title = specimen_json["organism"]
      strain_title = specimen_json["strain"]
      comments = specimen_json["comments"]
      genotype_title = specimen_json["genotype title"]
      genotype_modification = specimen_json["genotype modification"]


      case sex
          when "male"
            sex = 0
          when "female"
            sex = 1
          when "hermaphrodite"
            sex = 2
          when "unknown"
            sex = nil
          else
            sex = nil
        end

        #age = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+4}]").first.content.tr('""', "").to_i}
        #age_time_unit = try_block{ sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+5}]").first.content.tr('""', "")}


        organism = Organism.find_by_title organism_title
        strain = Strain.find_by_title strain_title

      culture_growth_type = CultureGrowthType.find_by_title "in vivo"
        unless organism
          organism = Organism.new :title => organism_title
          organism.save!
        end

        strain = Strain.new :title => strain_title  unless strain
        strain.organism = organism
        strain.projects = @file.projects
        strain.save!



        specimen = Specimen.find_by_title specimen_title

        institution = Institution.find_by_title @institution_title

        unless specimen
          specimen = Specimen.new :title => specimen_title, :lab_internal_number => specimen_title
          specimen.sex = sex
          specimen.age = age
          specimen.age_unit = age_unit
          specimen.institution = institution #@creator.institutions.first if @creator
          specimen.strain = strain
          specimen.culture_growth_type= culture_growth_type
          specimen.policy = @file.policy.deep_copy
          specimen.projects = @file.projects
          specimen.comments = comments
          specimen.creators << @creator
          specimen.save!
        else
          unless specimen.organism == organism &&
              specimen.strain == strain &&
              specimen.sex == sex &&
              specimen.age == age &&
              specimen.age_unit == age_unit
              sleep(1)
              new_sp = specimen.dup
              now = Time.now
              new_sp.title = "#{specimen_title}-#{now}"
              new_sp.contributor = User.current_user
              new_sp.projects = specimen.projects
              new_sp.created_at = now
              new_sp.policy = @file.policy.deep_copy
              new_sp.save!
              @warnings << "Warning: #{t('biosamples.sample_parent_term')} with the name '#{h(specimen_title)}' in row #{row} is already created in SEEK.<br/>".html_safe
              @warnings << "It is renamed and saved as '#{h(new_sp.title)}'.<br/>".html_safe
              @warnings << "You may rename it and upload the file as new version!<br/>".html_safe
              Rails.logger.warn @warnings
              specimen = new_sp
          else
            if !specimen.can_view?(User.current_user)
                @warnings << "Warning: #{t('biosamples.sample_parent_term')} with the name '#{h(specimen_title)}' in row #{row_num} is already created in SEEK.<br/>".html_safe
                @warnings << "But you are not authorized to view it. You can contact '#{h(specimen.contributor.person.name)} for authorizations'<br/>".html_safe
            end
          end
        end

        unless genotype_title == "none"
          gene = Gene.find_by_title genotype_title
          gene = Gene.new :title => genotype_title, :symbol => genotype_title unless gene
          gene.save!

          modification = Modification.find_by_title genotype_modification
          modification = Modification.new :title => genotype_modification, :symbol => genotype_modification unless modification
          modification.save!

            genotype =  Genotype.where(["gene_id = ? and modification_id = ? and specimen_id = ? and strain_id = ?", gene.id, modification.id, specimen.id, strain.id]).first
          genotype  = Genotype.new :gene_id => gene.id, :modification_id => modification.id, :specimen_id => specimen.id unless genotype
          genotype.save!
        end


        specimen

        
      
    end

    
    def build_all_sample_mock_json sample_data_list
      sample_data_list.each do |sample_data|
        build_sample_mock_json sample_data
      end      
    end
    
    def build_sample_mock_json sample_data
      
      sample_title = sample_data[:sample_title][:value]
      sample_type = sample_data[:sample_type][:value]
      tissue_and_cell_type_title = sample_data[:tissue_and_cell_type][:value]
      sop_title = sample_data[:sop_title][:value]
      donation_date = sample_data[:sample_donation_date][:value]
      institution_title = sample_data[:institution_title][:value]
      comments = sample_data[:sample_comment][:value]
      organism_part = sample_data[:sample_organism_part][:value]

      row = sample_data[:sample_title][:row]
      
      sample = {"title" => sample_title,
                "type" => sample_type,
                "tissue and cell type" => tissue_and_cell_type_title,
                "sop" => sop_title,
                "donation date" => donation_date.to_s,
                "institution" => institution_title,
                "comments" => comments,
                "organism part" => organism_part}


      @samples[row] = sample
      @sample_names[row] = sample_title
      Rails.logger.warn "add sample, row = #{row}"

      sample
      
    end   
    
    
    def populate_sample sample_json, specimen, assay=nil


        sample_title = sample_json["title"]
        sample_type = sample_json["type"]
        tissue_and_cell_type_title = sample_json["tissue and cell type"]
        sop_title = sample_json["sop"]
        donation_date = sample_json["donation date"] + " UTC +00.00"
        institution_title = sample_json["institution"]
        comments = sample_json["comments"]
        organism_part = sample_json["organism part"]

        sop_title = nil if sop_title=="NO STORAGE"
        institution_title = @institution_title if (institution_title=="" || institution_title.nil?)


        #Rails.logger.warn "TISSUE AND CELL TYPE TITLE : #{tissue_and_cell_type_title}"

        tissue_and_cell_type = TissueAndCellType.find_by_title tissue_and_cell_type_title
        unless tissue_and_cell_type
          if tissue_and_cell_type_title && tissue_and_cell_type_title != ""
            tissue_and_cell_type = TissueAndCellType.create :title => tissue_and_cell_type_title
            tissue_and_cell_type.save!
          end
        end

        sop = Sop.find_by_title sop_title
        institution = Institution.find_by_title institution_title

        #specimen_title = @specimen_names[row]
        #specimen = Specimen.find_by_title specimen_title

        #comments = @sample_comments.detect { |comments| comments.attributes["row"].to_i == row }.try(:content)

        sample = Sample.find_by_title sample_title
        unless sample
          sample = Sample.new :title => sample_title,
                              :lab_internal_number => sample_title
          sample.projects = @file.projects #User.current_user.person.projects
          #treatment = ""
          #@treatments_text[row].try(:each) do |k, v|
          #  treatment << k.to_s + ":" + v.to_s
          #  treatment << "," unless k == @treatments_text[row].keys.last
          #end
          #treatment = @treatments_text[row] ? @treatments_text[row] : ""
          treatment =  "" # will be linked to 0 ... n treatments anyway

          sample.sample_type = sample_type
          sample.donation_date = Time.zone.parse(donation_date).utc
          sample.institution = institution
          sample.tissue_and_cell_types << tissue_and_cell_type if tissue_and_cell_type.try(:id) && !sample.tissue_and_cell_types.include?(tissue_and_cell_type)
          sample.associate_sop sop if sop
          sample.specimen = specimen if specimen
          sample.organism_part = organism_part if organism_part != ""
          sample.comments = comments
          sample.treatment = treatment
          sample.policy = @file.policy.deep_copy
          sample.save!
        else
          unless sample.specimen == specimen &&
              sample.sample_type == sample_type &&
              (sample.tissue_and_cell_types.member?(tissue_and_cell_type) || tissue_and_cell_type_title == "") &&
              sample.donation_date == Time.zone.parse(donation_date).utc &&
              sample.institution == institution &&
              sample.comments == comments
              sleep(1);
              sample.title =  "#{sample_title}-#{Time.now}"
              sample.save!
              Rails.logger.warn "sample update-branch".html_safe

              Rails.logger.warn "#{sample.specimen} == #{specimen} ? #{sample.specimen == specimen}".html_safe
              Rails.logger.warn "#{sample.sample_type} == #{sample_type} ? #{sample.sample_type == sample_type}".html_safe
              Rails.logger.warn "(sample.tissue_and_cell_types.member?(tissue_and_cell_type) || tissue_and_cell_type_title == "") ? #{(sample.tissue_and_cell_types.member?(tissue_and_cell_type) || tissue_and_cell_type_title == "")}".html_safe
              Rails.logger.warn "#{sample.donation_date} == #{Time.zone.parse(donation_date).utc} ? #{sample.donation_date == Time.zone.parse(donation_date).utc}".html_safe
              Rails.logger.warn "#{sample.institution} == #{institution} ? #{sample.institution == institution}".html_safe
              Rails.logger.warn "#{sample.comments} == #{comments} ? #{sample.comments == comments}".html_safe
            @warnings << "Warning: sample with the name '#{sample_title}' is already created in SEEK.".html_safe
            @warnings << "It is renamed and saved as '#{sample.title}'.<br/>".html_safe
            @warnings << "You may rename it and upload the file as new version!<br/>".html_safe
          else
            if !sample.can_view?(User.current_user)
                @warnings << "Warning: Sample with the name '#{sample_title}' in row #{row} is already created in SEEK.<br/>".html_safe
                @warnings << "But you are not authorized to view it. You can contact '#{sample.contributor.person.name} for authorizations'<br/>".html_safe
            end
          end


      end

      if assay
        unless assay.samples.include?(sample)
          assay.samples << sample
          assay.save!
        end
      else
            Rails.logger.warn "no #{t('assays.assay').downcase} defined for samples"
        @file.lock!
        unless @file.samples.include?(sample)
          @file.samples << sample
          @file.save!
        end
      end


      sample

    end


    def set_sample_names sample_name_cells        # not used anymore
      sample_name_cells.each do |sample_name_cell|
        row = sample_name_cell.attributes["row"].to_i
        sample_title = sample_name_cell.content
        @sample_names[row] = sample_title
      end
    end

    def set_specimen_names specimen_name_cells # not used anymore
      specimen_name_cells.each do |specimen_name_cell|
        row = specimen_name_cell.attributes["row"].to_i
        specimen_title = specimen_name_cell.content
        @specimen_names[row] = specimen_title
      end
    end

    def hunt_for_horizontal_field_value sheet, field_name
      sheet_name=sheet.attributes["name"]
      field_cell = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell").find do |cell|
        #cell.content.match(/#{field_name}.*/i)
        cell.content.downcase == field_name.downcase
      end
      unless field_cell.nil?
        #find the next column for this row that contains content   #bittkomk: why?
        row = field_cell.attributes["row"].to_i
        col = field_cell.attributes["column"].to_i
        field_cell = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row=#{row} and @column=#{col+1}]").first
      end
      field_cell.nil? ? nil : field_cell.content
    end


    # hunts for a vector of field values given a field name (= header of a column)
    # offset of the first data row in respect of header row is calculated using :data_row_offset given in @parser_mapping
    # probing_num_rows = true means that the number of non-blank rows contained in a specified probing column is used to get the correct value for @num_rows
    # for this purpose the probing column should not have any blank rows in between
    def hunt_for_field_values sheet, field_name , probing_num_rows = false
      sheet_name=sheet.attributes["name"]

      field_cell = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell").find do |cell|
        #cell.content.match(/^#{field_name}$/i)
        cell.content.downcase == field_name.downcase
      end
      unless field_cell.nil?
        #find the next column for this row that contains content
        row = field_cell.attributes["row"].to_i
        col = field_cell.attributes["column"].to_i

        start_row = row + @parser_mapping[:data_row_offset] - 1 # subtracting 1 here gives us a clearer semantic for data_row_offset in the parser mappings. data_row_offset means "add this number to header row to get to first data row"
        #start_row = row + 1
        #start_row = row if ["RNA Extraction", "Sequencing"].include? field_name
        #start_row = row + 2 if ["Treatment", "Optional"].include? field_name
        #row +1 is source name or sample name that is hidden in the file
        if probing_num_rows
          field_values = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row > #{start_row} and @column=#{col}]").select do |cell|
            !cell.content.blank?
          end
          @start_row = start_row + 1 #that is the first row with data, cf. the condition in the xpath @row > #{start_row}
        else # if probing_num_rows == false we assume that @num_rows has been set to the correct value
          field_values = sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row > #{start_row} and @row <= #{start_row + @num_rows} and @column=#{col}]").collect {|cell| cell }
        end
      end
      field_values
    end

    def hunt_for_horizontal_field_value_mapped sheet, field_name, mapping
      Array(mapping[field_name][:value].call((hunt_for_horizontal_field_value(sheet, mapping[field_name][:column])))).map { |it| {:value => it}}
    end

    # this is the most important method to get data out of the spreadsheet
    # basically it's just a wrapper for hunt_for_field_values using a mapping to get the correct field name (= column header) to extract data from
    # the received data is mapped to an array of hashed containing :value and :row  -- the value assigned to :value is calculated using the block specified in the mapping for this field name
    # if there are less rows in the result than specified by @num_rows then missing rows are augmented with some default value (see augment_missing rows)
    # if there are no results returned by hunt_for_field_values then this case is handled differently for columns that are specified as FIXED in the mapping and for columns that are not
    # in any case it is ensured that the method returns @num_rows hashes of :value and :row
    def hunt_for_field_values_mapped sheet, field_name, mapping, probing_num_rows = false
      field_values = hunt_for_field_values sheet, mapping[field_name][:column], probing_num_rows
      if field_values && !field_values.empty?

        if probing_num_rows
          @num_rows = field_values.length
        end

        field_values.map! { |it| {:value => mapping[field_name][:value].call(it.content.tr('""', "")), :row => it.attributes["row"].to_i}}

        if field_values.length < @num_rows
          field_values = augment_missing_rows field_values, mapping[field_name][:value].call("") # this gives us the opportunity to fill in any default values defined as proc {"something"} in the mapping
        end

        field_values

      else
        if mapping[field_name][:column] == "FIXED"
          values = [mapping[field_name][:value].call()]*@num_rows
          rows  = (@start_row .. @start_row+@num_rows).to_a
          values.zip(rows).map { |value, row| {:value => value, :row => row}}
        else
          Rails.logger.warn "Warning, empty field values list for field_name = #{field_name} returned!"
          values = [""]*@num_rows
          rows = (@start_row .. @start_row+@num_rows).to_a
          values.zip(rows).map { |value, row| {:value => value, :row => row}}
        end
      end
    end

    # this adds missing rows to the array field_values given an expected number rows as specified in @num_rows
    # added rows contain the right row number and some default value
    # finally the whole array is resorted by :row to ensure that field_values is ordered by row number
    def augment_missing_rows field_values, default_value=""
      rows = (@start_row .. @start_row+@num_rows).to_a
      rows.each do |row|
        unless field_values.find {|fv| fv[:row] == row}
          field_values << {:value => default_value, :row => row}
        end
      end
      field_values.sort {|a,b| a[:row] <=> b[:row]}
    end

    def get_attribute_names sheet, row, col, table_name  # still used?
      sheet_name = sheet.attributes["name"]
      end_col = get_end_column sheet, get_next_table_name(sheet, table_name)

      attribute_names = {}
      sheet.find("//ss:sheet[@name='#{sheet_name}']/ss:rows/ss:row/ss:cell[@row = #{row} and @column >= #{col} and @column <= #{end_col}]").collect do |cell|
        cell_col = cell.attributes["column"].to_i
        attribute_names[cell_col] = cell.content
      end

      return attribute_names
    end

    def get_end_column sheet, next_table_name=nil # still used?
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

    def get_next_table_name sheet, current_table_name # still used?
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
end