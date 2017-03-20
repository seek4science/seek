module Seek
  class ParserMapper
    # how to define a new parser mapping with name NEW_MAPPER
    # * create a private method NEW_MAPPER_mapping
    # * copy the hash from empty mapping to NEW_MAPPER_mapping
    # * specify data like :name, :data_offset, :probing_column etc...
    # * fill in your mapped fields
    # ** see existing mappings for examples for using different blocks to handle FIXED-data columns
    # ** or columns that share some raw data that has be extracted by a regular expression
    # * (OPTIONAL) define a (filename-pattern-to-parser-mapping-name)-mapping in filename_to_mapping_name to enable automatic detection of parser mappings by filename

    def initialize
    end

    # returns a mapping given a mapping name (convention: name of method without "_mapping")
    def mapping(mapping_name)
      mapping = send(mapping_name + '_mapping')
      if mapping
        return mapping if check_mapping mapping

        nil

      end
    end

    # this method defines a (filename-pattern-to-parser-mapping-name)-mapping
    # to add a mapping just add a when clause relating a file pattern to the name of the parser-mapping (without "_mapping")
    def filename_to_mapping_name(filename)
      case filename
      when /^jena.*/i then 'jena'
      when /^do_hengstler.*/i then 'dortmund_hengstler'
      when /^do_bcat_ko.*/i then 'dortmund_bcat_ko'
      when /^due_bode.*/i then 'duesseldorf_bode'
      when /^due_bode_surgical.*/i then 'duesseldorf_bode_surgical'
      else 'unknown'
      end
    end

    private

    def check_mapping(_mapping) # TODO: check whether all necessary fields are mapped
      true
    end

    # the default mapping entry
    # if no block is specified a simple block is defined that just returns the input
    def mapping_entry(column_name, block = nil)
      block = proc { |data| data } unless block

      { column: column_name, value: block }
    end

    # mapping for jena excel sheets
    # example file: jenage-excel_template-without-protection correct.xlsm
    def jena_mapping
      {
        name: 'jena',
        data_row_offset: 2,

        samples_mapping: {

          :samples_sheet_name => 'SDRF',

          :add_specimens => true,
          :add_treatments => true,
          :add_samples => true,

          :probing_column => :"specimens.title",

          :"organisms.title" => mapping_entry('Organism'),

          :"strains.title" => mapping_entry('Strain or Line'),

          :"specimens.sex" => mapping_entry('Sex'),
          :"specimens.title" => mapping_entry('# Specimen'),
          :"specimens.lab_internal_number" => mapping_entry('# Specimen'),
          :"specimens.age" => mapping_entry('Age'),
          :"specimens.age_unit" => mapping_entry('Age Time Unit'),
          :"specimens.comments" => mapping_entry('FIXED', proc { '' }),
          :"specimens.genotype.title" => mapping_entry('FIXED', proc { 'none' }),
          :"specimens.genotype.modification" => mapping_entry('FIXED', proc { '' }),

          :"treatment.treatment_protocol" => mapping_entry('Treatment Protocol'),
          :"treatment.type" => mapping_entry('FIXED', proc { 'concentration' }),
          :"treatment.comments" => mapping_entry('FIXED', proc { '' }),
          :"treatment.substance" => mapping_entry('Substance'),
          :"treatment.concentration" => mapping_entry('Concentration'),
          :"treatment.unit" => mapping_entry('Unit'),
          :"treatment.incubation_time" => mapping_entry('FIXED', proc { nil }),
          :"treatment.incubation_time_unit" => mapping_entry('FIXED', proc { '' }),

          :"samples.comments" => mapping_entry('Additional Information'),
          :"samples.title" => mapping_entry('Sample Name'),
          :"samples.sample_type" => mapping_entry('Material Type'),
          :"samples.donation_date" => mapping_entry('Storage Date', proc { |data| data != '' ? data : Time.now }), # the default value is certainly wrong -- but we need some donation_date
          :"samples.organism_part"  => mapping_entry('FIXED', proc { '' }),

          :"tissue_and_cell_types.title" => mapping_entry('Organism Part'),

          :"sop.title" => mapping_entry('Storage Protocol'),
          :"institution.title" => mapping_entry('Storage Location')

        },

        assay_mapping: {

          :assay_sheet_name => 'IDF',
          :parsing_direction => 'horizontal',
          :probing_column => '',

          :"investigation.title" => mapping_entry('Investigation Title'),
          :"assay_type.title" => mapping_entry('Experiment Class'),
          :"study.title" => mapping_entry('Experiment Description'),

          :"creator.email" => mapping_entry('Person Email'),
          :"creator.last_name" => mapping_entry('Person Last Name'),
          :"creator.first_name" => mapping_entry('Person First Name')

        }

      }
    end

    # mapping for dortmund excel sheets (I)
    # example file: do_hengstler_Sample Data Hengstler_corrected.xls
    def dortmund_hengstler_mapping
      age_regex = /(\d+-?\d*)\s*(day|week|month|year)s?/i
      treatment_regex = /(\d*\.?\d*)\s*(\w+\/\w+)\s*([\w\.\s,']*),?\s+([\w\.]*)/
      incubation_time_regex = /(\d+\.?\d*)(\w{1})/

      {
        name: 'dortmund_hengstler',
        data_row_offset: 1,

        samples_mapping: {

          :samples_sheet_name => 'Tabelle1',
          :add_specimens => true,
          :add_treatments => true,
          :add_samples => true,

          :probing_column => :"specimens.title",

          :"organisms.title" => mapping_entry('FIXED', proc { 'Mus musculus' }),

          :"strains.title" => mapping_entry('Mouse strain'),

          :"specimens.institution_id" => mapping_entry('Responsible Lab'),
          :"specimens.title" => mapping_entry('Lab internal number', proc { |data| data.chomp('.0') }),
          :"specimens.lab_internal_number" => mapping_entry('Lab internal number', proc { |data| data.chomp('.0') }),
          :"specimens.sex" => mapping_entry('FIXED', proc { 'unknown' }),
          :"specimens.age" => mapping_entry('Age', proc do |data|
            if data =~ age_regex
              Regexp.last_match(1) ? Regexp.last_match(1) : ''
            else
              ''
            end
          end),
          :"specimens.age_unit" => mapping_entry('Age', proc do |data|
            if data =~ age_regex
              Regexp.last_match(2) ? Regexp.last_match(2) : ''
            else
              ''
            end
          end),

          :"specimens.donation_date" => mapping_entry('date of experiment'),
          :"specimens.comments" => mapping_entry('FIXED', proc { '' }),
          :"specimens.genotype.title" => mapping_entry('FIXED', proc { 'none' }),
          :"specimens.genotype.modification" => mapping_entry('FIXED', proc { '' }),

          :"treatment.concentration" => mapping_entry('Treatment', proc do |data|
            if data =~ treatment_regex
              Regexp.last_match(1) ? Regexp.last_match(1) : ''
            else
              ''
            end
          end),
          :"treatment.unit" => mapping_entry('Treatment', proc do |data|
            if data =~ treatment_regex
              Regexp.last_match(2) ? Regexp.last_match(2) : ''
            else
              ''
            end
          end),
          :"treatment.substance" => mapping_entry('Treatment', proc do |data|
            if data =~ treatment_regex
              if Regexp.last_match(3)
                substance = Regexp.last_match(3)
                if substance.end_with?(',')
                  substance.chop
                else
                  substance
                end
              else
                ''
              end
            else
              ''
            end
          end),
          :"treatment.treatment_protocol" => mapping_entry('Treatment', proc do |data|
            if data =~ treatment_regex
              Regexp.last_match(4) ? Regexp.last_match(4) : ''
            else
              ''
            end
          end),
          :"treatment.type" => mapping_entry('FIXED', proc { 'concentration' }),
          :"treatment.comments" => mapping_entry('FIXED', proc { '' }),
          :"treatment.incubation_time" => mapping_entry('Explantation', proc do |data|
            if data =~ incubation_time_regex
              Regexp.last_match(1)
            else
              ''
            end
          end),

          :"treatment.incubation_time_unit" => mapping_entry('Explantation', proc do |data|
            if data =~ incubation_time_regex
              case Regexp.last_match(2)
              when 'd' then 'day'
              when 'h' then 'hour'
              when 'w' then 'week'
              else ''
              end
            else
              ''
            end
          end),

          :"samples.comments" => mapping_entry('Comments'),
          :"samples.title" => mapping_entry('Tissue specimen no.', proc { |data| data.chomp('.0') }),
          :"samples.sample_type" => mapping_entry('FIXED', proc { '' }),
          :"samples.donation_date" => mapping_entry('date of experiment'),
          :"samples.organism_part"  => mapping_entry('FIXED', proc { 'organ' }),

          :"tissue_and_cell_types.title" => mapping_entry('FIXED', proc { 'Liver' }),

          :"sop.title" => mapping_entry('FIXED', proc { '' }),
          :"institution.title" => mapping_entry('FIXED', proc { '' })

        },

        assay_mapping: {

          :assay_sheet_name => 'Tabelle1',
          :parsing_direction => 'vertical',
          :probing_column => :"creator.last_name",

          :"investigation.title" => mapping_entry('FIXED', proc { nil }),
          :"assay_type.title" => mapping_entry('FIXED', proc { nil }),
          :"study.title" => mapping_entry('FIXED', proc { nil }),

          :"creator.email" => mapping_entry('FIXED', proc { '' }),
          :"creator.last_name" => mapping_entry('Experimentator', proc do |data|
            data.split(/\s+/).last if data.split(/\s+/)
          end),
          :"creator.first_name" => mapping_entry('Experimentator', proc do |data|
            data.gsub(data.split(/\s+/).last, '').chop if data.split(/\s+/)
          end)

        }

      }
    end

    # mapping for dortmund excel sheets (II)
    # example file: BCat KO sample data Dortmund.xls
    def dortmund_bcat_ko_mapping
      age_regex = /(\d+-?\d*)\s*(day|week|month|year)s?/i
      treatment_substance_regex = /.*\((control|treated)\s?=\s?(.*)\)/i
      treatment_concentration_unit_regex = /(\d*[,\.]?\d*)\s*([\w\s\/]*).*$/
      treatment_protocol_regex = /.*,\s*([\w\s\.]*)$/
      genotype_modification_regex = /(WT|KO)/
      incubation_time_regex = /(\d+\.?\d*)\s+(\w*)s/

      {
        name: 'dortmund_bcat_ko',
        data_row_offset: 1,

        samples_mapping: { # TODO: which fields are really necessary?
          :samples_sheet_name => 'BCat KO',

          :add_specimens => true,
          :add_treatments => true,
          :add_samples => true,

          :probing_column => :"specimens.title",

          :"organisms.title" => mapping_entry('FIXED', proc { 'Mus musculus' }),

          :"strains.title" => mapping_entry('FIXED', proc { 'Wildtype' }),

          :"specimens.sex" => mapping_entry('Gender', proc { |data| data.downcase }),
          :"specimens.title" => mapping_entry('Sample ID'),
          :"specimens.lab_internal_number" => mapping_entry('Sample ID'),
          :"specimens.age" => mapping_entry('Age', proc do |data|
            if data =~ age_regex
              Regexp.last_match(1) ? Regexp.last_match(1) : ''
            else
              ''
            end
          end),
          :"specimens.age_unit" => mapping_entry('Age', proc do |data|
            if data =~ age_regex
              Regexp.last_match(2) ? Regexp.last_match(2) : ''
            else
              ''
            end
          end),
          :"specimens.comments" => mapping_entry('FIXED', proc { '' }),
          :"specimens.genotype.title" => mapping_entry('FIXED', proc { 'Bcat' }),
          :"specimens.genotype.modification" => mapping_entry('Genotype', proc do |data|
            if data =~ genotype_modification_regex
              case Regexp.last_match(1)
              when 'KO' then 'Knock out'
              when 'WT' then 'Wildtype'
              else 'Wildtype'
              end
            else
              'Wildtype'
            end
          end),

          :"treatment.treatment_protocol" => mapping_entry('Dose/route of adminstration', proc do |data| # sic!?
            if data =~ treatment_protocol_regex
              Regexp.last_match(1) ? Regexp.last_match(1) : ''
            else
              ''
            end
          end),
          :"treatment.type" => mapping_entry('FIXED', proc { 'concentration' }),
          :"treatment.comments" => mapping_entry('FIXED', proc { '' }),
          :"treatment.substance" => mapping_entry('Genotype', proc do |data|
            if data =~ treatment_substance_regex
              Regexp.last_match(2) ? Regexp.last_match(2) : ''
            else
              ''
            end
          end),
          :"treatment.concentration" => mapping_entry('Dose/route of adminstration', proc do |data|
            Regexp.last_match(1) ? Regexp.last_match(1) : nil if data =~ treatment_concentration_unit_regex
          end),
          :"treatment.unit" => mapping_entry('Dose/route of adminstration', proc do |data|
            if data =~ treatment_concentration_unit_regex
              Regexp.last_match(2) ? Regexp.last_match(2) : ''
            else
              ''
            end
          end),
          :"treatment.incubation_time" => mapping_entry('Time point', proc do |data|
            if data =~ incubation_time_regex
              Regexp.last_match(1)
            else
              ''
            end
          end),

          :"treatment.incubation_time_unit" => mapping_entry('Time point', proc do |data|
            if data =~ incubation_time_regex
              Regexp.last_match(2)
            else
              ''
            end
          end),

          :"samples.comments" => mapping_entry('FIXED', proc { '' }),
          :"samples.title" => mapping_entry('Sample ID'),
          :"samples.sample_type" => mapping_entry('FIXED', proc { '' }),
          :"samples.donation_date" => mapping_entry('Arrival Date'),
          :"samples.organism_part"  => mapping_entry('FIXED', proc { 'organ' }),

          :"tissue_and_cell_types.title" => mapping_entry('FIXED', proc { 'Liver' }),

          :"sop.title" => mapping_entry('FIXED', proc { '' }),
          :"institution.title" => mapping_entry('FIXED', proc { '' })
        },

        assay_mapping: nil

      }
    end

    # mapping for duesseldorf excel sheet
    # example file: due_bode_Tierbestandsliste G96 parsing format.xls
    def duesseldorf_bode_mapping
      concentration_regex = /(\d*,?\.?\d*).*/
      gene_modification_regex = /([\w\d]+)([\/+-]+)/

      {
        name: 'duesseldorf_bode',
        data_row_offset: 1,

        samples_mapping: {
          :samples_sheet_name => 'Tabelle2',
          :add_specimens => true,
          :add_treatments => true,
          :add_samples => true,

          :probing_column => :"specimens.title",

          :"organisms.title" => mapping_entry('species'),

          :"strains.title" => mapping_entry('strain'),

          :"specimens.sex" => mapping_entry('sex'),
          :"specimens.title" => mapping_entry('Animal Nr.'),
          :"specimens.lab_internal_number" => mapping_entry('Animal Nr.'),
          :"specimens.age" => mapping_entry('Age (Weeks)'),
          :"specimens.age_unit" => mapping_entry('FIXED', proc { 'week' }),
          :"specimens.comments" => mapping_entry('Specials', proc { |data| data == '-' ? '' : data }),
          :"specimens.genotype.title" => mapping_entry('Genotype', proc do |data|
            if data =~ gene_modification_regex
              Regexp.last_match(1)
            else
              'none'
            end
          end),
          :"specimens.genotype.modification" => mapping_entry('Genotype', proc do |data|
            if data =~ gene_modification_regex
              Regexp.last_match(2)
            else
              ''
            end
          end),

          :"treatment.treatment_protocol" => mapping_entry('FIXED', proc { '' }),
          :"treatment.type" => mapping_entry('FIXED', proc { 'concentration' }),
          :"treatment.comments" => mapping_entry('FIXED', proc { '' }),
          :"treatment.substance" => mapping_entry('FIXED', proc { 'LPS' }),
          :"treatment.concentration" => mapping_entry('LPS (µg/g KG)', proc do |data|
            if data =~ concentration_regex
              Regexp.last_match(1).tr(',', '.')
            else
              ''
            end
          end),
          :"treatment.unit" => mapping_entry('FIXED', proc { 'µg/g KG' }),
          :"treatment.incubation_time" => mapping_entry('Incubation period x Std.'),
          :"treatment.incubation_time_unit" => mapping_entry('FIXED', proc { 'hour' }),

          :"samples.comments" => mapping_entry('FIXED', proc { '' }),
          :"samples.title" => mapping_entry('Animal Nr.', proc { |data| data + '_liver' }),
          :"samples.sample_type" => mapping_entry('FIXED', proc { 'liver' }),
          :"samples.donation_date" => mapping_entry('Donation Date'),
          :"samples.organism_part"  => mapping_entry('FIXED', proc { 'organ' }),

          :"tissue_and_cell_types.title" => mapping_entry('FIXED', proc { 'Liver' }),

          :"sop.title" => mapping_entry('FIXED', proc { '' }),
          :"institution.title" => mapping_entry('FIXED', proc { '' })
        },

        assay_mapping: {

          :assay_sheet_name => 'Tabelle2',
          :parsing_direction => 'vertical',
          :probing_column => :"creator.last_name",

          :"investigation.title" => mapping_entry('FIXED', proc { nil }),
          :"assay_type.title" => mapping_entry('FIXED', proc { nil }),
          :"study.title" => mapping_entry('FIXED', proc { nil }),

          :"creator.email" => mapping_entry('FIXED', proc { '' }),
          :"creator.last_name" => mapping_entry('experimentator', proc do |data|
            data.split(/\s+/).last if data.split(/\s+/)
          end),
          :"creator.first_name" => mapping_entry('experimentator', proc do |data|
            data.split(/\s+/).first if data.split(/\s+/)
          end)

        }

      }
    end

    # mapping for duesseldorf excel sheet with surgical procedure
    # example file: due_bode_Tierbestandsliste G96 parsing format.xls
    def duesseldorf_bode_surgical_mapping
      gene_modification_regex = /([\w\d]+)([\/+-]+)/

      {
        name: 'duesseldorf_bode',
        data_row_offset: 3,

        samples_mapping: {
          :samples_sheet_name => 'Tabelle1',
          :add_specimens => true,
          :add_treatments => true,
          :add_samples => true,

          :probing_column => :"specimens.title",

          :"organisms.title" => mapping_entry('species'),

          :"strains.title" => mapping_entry('strain'),

          :"specimens.sex" => mapping_entry('sex'),
          :"specimens.title" => mapping_entry('Animal Nr.'),
          :"specimens.lab_internal_number" => mapping_entry('Animal Nr.'),
          :"specimens.age" => mapping_entry('Age (Weeks)'),
          :"specimens.age_unit" => mapping_entry('FIXED', proc { 'week' }),
          :"specimens.comments" => mapping_entry('Specials', proc { |data| data == '-' ? '' : data }),
          :"specimens.genotype.title" => mapping_entry('Genotype', proc do |data|
            if data =~ gene_modification_regex
              Regexp.last_match(1)
            else
              'none'
            end
          end),
          :"specimens.genotype.modification" => mapping_entry('Genotype', proc do |data|
            if data =~ gene_modification_regex
              Regexp.last_match(2)
            else
              ''
            end
          end),

          :"treatment.treatment_protocol" => mapping_entry('FIXED', proc { '' }),
          :"treatment.type" => mapping_entry('FIXED', proc { 'surgical procedure' }),
          :"treatment.comments" => mapping_entry('Treatment'),
          :"treatment.substance" => mapping_entry('FIXED', proc { '' }),
          :"treatment.concentration" => mapping_entry('FIXED', proc { '' }),
          :"treatment.unit" => mapping_entry('FIXED', proc { '' }),
          :"treatment.incubation_time" => mapping_entry('Incubation period (hours)'),
          :"treatment.incubation_time_unit" => mapping_entry('FIXED', proc { 'hour' }),

          :"samples.comments" => mapping_entry('FIXED', proc { '' }),
          :"samples.title" => mapping_entry('Animal Nr.', proc { |data| data + '_liver' }),
          :"samples.sample_type" => mapping_entry('FIXED', proc { 'liver' }),
          :"samples.donation_date" => mapping_entry('Donation Date'),
          :"samples.organism_part"  => mapping_entry('FIXED', proc { 'organ' }),

          :"tissue_and_cell_types.title" => mapping_entry('FIXED', proc { 'Liver' }),

          :"sop.title" => mapping_entry('FIXED', proc { '' }),
          :"institution.title" => mapping_entry('FIXED', proc { '' })
        },

        assay_mapping: {

          :assay_sheet_name => 'Tabelle1',
          :parsing_direction => 'vertical',
          :probing_column => :"creator.last_name",

          :"investigation.title" => mapping_entry('FIXED', proc { nil }),
          :"assay_type.title" => mapping_entry('FIXED', proc { nil }),
          :"study.title" => mapping_entry('FIXED', proc { nil }),

          :"creator.email" => mapping_entry('FIXED', proc { '' }),
          :"creator.last_name" => mapping_entry('experimentator', proc do |data|
            data.split(/\s+/).last if data.split(/\s+/)
          end),
          :"creator.first_name" => mapping_entry('experimentator', proc do |data|
            data.split(/\s+/).first if data.split(/\s+/)
          end)

        }

      }
    end

    def unknown_mapping
      nil
    end

    def empty_mapping # defines basic mapping to start with, not that useful for the real parsing business ;-)
      {
        name: '',
        data_row_offset: 1, # add this to the row of a header column to get to row with the first data element

        samples_mapping: { # TODO: which fields are really necessary?
          :samples_sheet_name => '', # required

          :add_specimens => true,
          :add_treatments => true,
          :add_samples => true,

          :probing_column => :"specimens.title", # this should map to a column that has no blank elements in between other elements

          :"organisms.title" => mapping_entry(''),

          :"strains.title" => mapping_entry(''),

          :"specimens.sex" => mapping_entry(''),
          :"specimens.title" => mapping_entry(''),
          :"specimens.lab_internal_number" => mapping_entry(''),
          :"specimens.age" => mapping_entry(''),
          :"specimens.age_unit" => mapping_entry(''),
          :"specimens.comments" => mapping_entry(''),
          :"specimens.genotype.title" => mapping_entry('FIXED', proc { 'none' }),
          :"specimens.genotype.modification" => mapping_entry('FIXED', proc { '' }),

          :"treatment.treatment_protocol" => mapping_entry(''),
          :"treatment.type" => mapping_entry('FIXED', proc { 'concentration' }),
          :"treatment.comments" => mapping_entry('FIXED', proc { '' }),
          :"treatment.substance" => mapping_entry(''),
          :"treatment.concentration" => mapping_entry(''),
          :"treatment.unit" => mapping_entry(''),
          :"treatment.incubation_time" => mapping_entry(''),
          :"treatment.incubation_time_unit" => mapping_entry(''),

          :"samples.comments" => mapping_entry(''),
          :"samples.title" => mapping_entry(''),
          :"samples.sample_type" => mapping_entry(''),
          :"samples.donation_date" => mapping_entry(''),
          :"samples.organism_part"  => mapping_entry(''),

          :"tissue_and_cell_types.title" => mapping_entry(''),

          :"sop.title" => mapping_entry(''),
          :"institution.title" => mapping_entry('')
        },

        assay_mapping: { # can be nil if no assays are mapped

          :assay_sheet_name => '',
          :parsing_direction => 'vertical',
          :probing_column => :"creator.last_name",

          :"investigation.title" => mapping_entry(''),
          :"assay_type.title" => mapping_entry(''),
          :"study.title" => mapping_entry(''),

          :"creator.email" => mapping_entry(''),
          :"creator.last_name" => mapping_entry(''),
          :"creator.first_name" => mapping_entry('')

        }

      }
    end
  end
end
