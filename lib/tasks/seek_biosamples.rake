#Some tasks specifically for parsing and inserting biosamples and treatements, from a specific custom template

namespace :seek_biosamples do

  include SysMODB::SpreadsheetExtractor

  SAMPLE_HEADINGS = ["id", "title", "lab internal id", "providers id", "provider name", "belongs to parsed specimen", "contributor name", "organism part", "sampling date", "age at sampling (hours)", "comments", "orginating data file id", "associated assays id's", "associated sop id's"]
  SPECIMEN_HEADINGS = ["id", "title", "lab internal id", "start date / born date", "provider name", "providers id", "contributor name", "project name(s)", "institution name", "growth type", "belongs to parsed strain"]
  STRAIN_HEADINGS = ["id", "title", "contributor name", "project name(s)", "organism", "ncbi", "provider name", "providers id", "comments", "genotypes-gene", "genotypes-modification", "phenotypes"]
  TREATMENT_HEADINGS = ["treatment type", "substance", "value", "unit", "belongs to parsed sample"]

  task :parse,[:template_name]=>:environment do |t,args|
    template_name = args[:template_name]
    puts "Working from the template #{template_name}"

    pp "Reading strain data"
    strain_csv = spreadsheet_to_csv open(template_name),1,true
    pp "Parsing strain csv"
    strains = parse_strain_csv(strain_csv)
    pp strains.last

    pp "Reading specimen data"
    spec_csv = spreadsheet_to_csv open(template_name),2,true
    pp "Parsing specimen data"
    specimens = parse_specimen_csv(spec_csv)
    pp specimens.last

    pp "Reading sample data"
    sample_csv = spreadsheet_to_csv open(template_name),3,true
    pp "Parsing samples"
    samples = parse_sample_csv(sample_csv)
    pp samples.last

    pp "Reading treatement data"
    treatment_csv = spreadsheet_to_csv open(template_name),4,true
    treatments = parse_treatment_csv(treatment_csv)
    pp treatments.last



  end

  private

  def parse_treatment_csv csv

    keys = [:treatment_type,:substance,:value,:unit,:sample]
    result = CSV.parse(csv).collect.with_index do |row,x|
      if x==0 #skip the first row but test
        check_treatment_headings row
      else
        Hash[row.map.with_index do |val,i|
          [keys[i],val]
        end]
      end
    end
    result.compact
  end

  def parse_sample_csv csv
    keys = [:key, :title, :lab_internal_id, :provider_id, :provider_name, :specimen, :contributor, :organism_part, :sampling_date, :age_at_sampling, :comments, :data_file_ids, :assay_ids, :sop_ids]
    x=0
    result = CSV.parse(csv).collect.with_index do |row,x|
      if x==0
        check_sample_headings row
      else
        Hash[row.map.with_index do |val,i|
          [keys[i],val]
        end]
      end
    end
    result.compact
  end

  def parse_strain_csv csv
    keys = [:key,:title,:contributor,:projects,:organism,:provider_name,:provider_id,:comments,:genotypes,:genotype_modification,:phenotypes]
    x=0
    result = CSV.parse(csv).collect.with_index do |row,x|
      if x==0
        check_strain_headings row
      else
        Hash[row.map.with_index do |val,i|
          [keys[i],val]
        end]
      end
    end
    result.compact
  end

  def parse_specimen_csv csv
    keys = [:key,:title,:lab_internal_id,:start_date,:provider_name,:provider_id,:contributor,:projects,:institution,:growth_type,:strain]
    x=0
    result = CSV.parse(csv).collect.with_index do |row,x|
      if x==0
        check_specimen_headings row
      else
        Hash[row.map.with_index do |val,i|
          [keys[i],val]
        end]
      end
    end
    result.compact
  end

  def check_treatment_headings row
    expected = TREATMENT_HEADINGS
    check_headings "treatment",expected,row
  end

  def check_sample_headings row
    expected = SAMPLE_HEADINGS
    check_headings "sample",expected,row
  end

  def check_specimen_headings row
    expected = SPECIMEN_HEADINGS
    check_headings "specimen",expected,row
  end

  def check_strain_headings row
    expected = STRAIN_HEADINGS
    check_headings "strain",expected,row
  end

  def check_headings name,expected,actual
    unless actual == expected
      raise "Unexpected row headings for #{name} - was expected to be #{expected.inspect} but was #{actual.inspect}"
    end
  end

end
