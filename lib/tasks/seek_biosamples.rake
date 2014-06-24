#Some tasks specifically for parsing and inserting biosamples and treatements, from a specific custom template

namespace :seek_biosamples do

  include SysMODB::SpreadsheetExtractor

  SAMPLE_HEADINGS = ["id", "title", "lab internal id", "providers id", "provider name", "belongs to parsed specimen", "contributor name", "organism part", "sampling date", "age at sampling (hours)", "comments", "orginating data file id", "associated assays id's", "associated sop id's"]
  SPECIMEN_HEADINGS = ["id", "title", "lab internal id", "start date / born date", "provider name", "providers id", "contributor name", "project name(s)", "institution name", "growth type", "belongs to parsed strain"]
  STRAIN_HEADINGS = ["id", "title", "contributor name", "project name(s)", "organism", "ncbi", "provider name", "providers id", "comments", "genotypes-gene", "genotypes-modification", "phenotypes"]
  TREATMENT_HEADINGS = ["treatment type", "substance", "value", "unit", "belongs to parsed sample"]

  SAMPLE_KEYS = [:key, :title, :lab_internal_number, :provider_id, :provider_name, :specimen, :contributor, :organism_part, :sampling_date, :age_at_sampling, :comments, :data_files, :assays, :sops]
  SPECIMEN_KEYS = [:key,:title,:lab_internal_number,:born,:provider_name,:provider_id,:contributor,:projects,:institution,:culture_growth_type,:strain]
  STRAIN_KEYS = [:key,:title,:contributor,:projects,:organism,:ncbi,:provider_name,:provider_id,:comment,:genes,:genotype_modification,:phenotypes]
  TREATMENT_KEYS = [:treatment_type,:substance,:value,:unit,:sample]

  class Array
    def find_by_key(key)
      self.find do |x|
        x[:key]==key
      end
    end
  end

  task :parse,[:template_name]=>:environment do |t,args|
    template_name = args[:template_name]
    puts "Working from the template #{template_name}"

    pp "Reading strain data"
    strain_csv = spreadsheet_to_csv open(template_name),1,true
    pp "Parsing strain csv"
    strains = parse_strain_csv(strain_csv)

    pp "Reading specimen data"
    spec_csv = spreadsheet_to_csv open(template_name),2
    pp "Parsing specimen data"
    specimens = parse_specimen_csv(spec_csv)

    pp "Reading sample data"
    sample_csv = spreadsheet_to_csv open(template_name),3,true
    pp "Parsing samples"
    samples = parse_sample_csv(sample_csv)


    pp "Reading treatement data"
    treatment_csv = spreadsheet_to_csv open(template_name),4,true
    treatments = parse_treatment_csv(treatment_csv)

    pp "Making concrete"
    make_concrete strains,specimens,samples,treatments

    pp "Tying things together"
    tie_together strains,specimens,samples,treatments

    pp "Inserting"
    insert_data strains

    pp "Finished"
  end

  private

  def insert_data strains
    ActiveRecord::Base.transaction do
      disable_authorization_checks do
        strains.each do |strain_hash|
          strain = insert_strain strain_hash
          strain_hash[:specimens].each do |specimen_hash|
            specimen_hash[:strain]=strain
            specimen = insert_specimen specimen_hash
            specimen_hash[:samples].each do |sample_hash|
              sample_hash[:specimen]=specimen
              insert_sample sample_hash
            end
          end

        end
      end
      raise ActiveRecord::Rollback
    end
  end

  def insert_sample sample_hash
    raise "Was expecting a contributor" if sample_hash[:contributor].nil?
    raise "Was expecting a specimen" if sample_hash[:specimen].nil?
    raise "Specimen should already be saved" unless sample_hash[:specimen].is_a?(Specimen)
    raise "Handling assays not yet implemented" if !sample_hash[:assays].blank?
    sample = Sample.all.detect do |sample|
      sample.title == sample_hash[:title] && sample.specimen == sample_hash[:specimen]
    end
    if sample.nil?
      sample = Sample.new sample_hash.slice(:title, :lab_internal_number, :provider_id, :provider_name, :specimen, :contributor, :organism_part, :sampling_date, :comments)
      #FIXME: need to handle :age_at_sampling
      sample.projects = sample_hash[:projects] || sample_hash[:specimen].projects
      (Array(sample_hash[:data_files]) & Array(sample_hash[:sops])).each do |asset|
        sample.associate_asset asset
      end
    else
      pp "Sample found: #{sample.inspect}"
    end
    sample.save!
    sample
  end

  def insert_specimen specimen_hash
    raise "Was expecting 1 project for specimen" if specimen_hash[:projects].count!=1
    raise "Was expecting a contributor" if specimen_hash[:contributor].nil?
    raise "Was expecting a strain" if specimen_hash[:strain].nil?
    raise "Strain should already be saved" unless specimen_hash[:strain].is_a?(Strain)
    specimen = Specimen.all.detect do |spec|
      spec.title == specimen_hash[:title] && spec.projects.sort==specimen_hash[:projects].sort && spec.strain==specimen_hash[:strain]
    end
    if specimen.nil?
      specimen = Specimen.new specimen_hash.slice(:title,:lab_internal_number,:born,:provider_name,:provider_id,:contributor,:projects,:institution,:culture_growth_type,:strain)
    else
      pp "Specimen found: #{specimen.inspect}"
    end
    specimen.save!
    specimen
  end

  def insert_strain strain_hash
    title = strain_hash[:title]
    organism = strain_hash[:organism]
    projects = strain_hash[:projects]
    project = projects[0]
    contributor = strain_hash[:contributor]

    gene_titles = strain_hash[:genes].split(",")
    gene_modifications = strain_hash[:gene_modifications]


    raise "Should be at least 1 project" if projects.count<1
    raise "More than one project encountered, with although possible wasn't anticipated" if projects.count>1
    raise "There must be a contributor for the strain" if contributor.nil?
    raise "Still need to handle gene modifications (not implemented)" unless gene_modifications.nil? #don't need to handle these yet, since they are not in the data

    strain = Strain.all.detect do |str|
      match = str.title==title && str.projects.include?(project) && gene_titles.count==str.genotypes.count
      if match
        match = str.genotypes.detect do |gt|
          !gene_titles.include?(gt.gene.title)
        end.nil?
      end
      match
    end

    if strain.nil?
      new_strain_attributes = strain_hash.slice(:title,:lab_internal_id,:provider_id,:provider_name,:comment)
      strain = Strain.new new_strain_attributes
      strain.contributor = contributor
      strain.organism = organism
      strain.projects = [project]
      gene_titles.each do |gene_title|
        strain.genotypes << Genotype.new(:gene=>Gene.new(:title=>gene_title),:strain=>strain)
      end
    else
      puts "Strain found: #{strain.inspect}"
      raise "Organism doesn't match strain" if strain.organism != organism
      raise "Project doesn't match strain" if !strain.projects.include?(project)
    end

    strain.save!

    strain
  end

  def tie_together strains,specimens,samples,treatments
    treatments.each do |treatment|
      sample_key = treatment[:sample]
      sample = samples.find_by_key(sample_key)
      raise "Unable to find sample for key '#{sample_key}'" if sample.nil?
      treatment[:sample]=sample
      sample[:treatments]||=[]
      sample[:treatments] << treatment
    end
    samples.each do |sample|
      spec_key = sample[:specimen]
      spec = specimens.find_by_key(spec_key)
      raise "Unable to find specimen for key '#{spec_key}'" if spec.nil?
      sample[:specimen]=spec
      spec[:samples]||=[]
      spec[:samples] << sample
    end
    specimens.each do |spec|
      strain_key = spec[:strain]
      strain = strains.find_by_key(strain_key)
      raise "Unable to find strain for key '#{strain_key}'" if strain.nil?
      spec[:strain]=strain
      strain[:specimens]||=[]
      strain[:specimens] << spec
    end
  end

  def make_concrete *definitions
    people = Person.all
    definitions.each do |definition|
      definition.each do |element|

        #make born date a datetime
        if element.has_key?(:born) && !element[:born].nil?
          element[:born]=DateTime.parse(element[:born])
        end

        #make sampling date a datetime
        if element.has_key?(:sampling_date) && !element[:sampling_date].nil?
          element[:sampling_date]=DateTime.parse(element[:sampling_date])
        end

        #the culture growth type
        if element.has_key?(:culture_growth_type) && !element[:culture_growth_type].nil?
          type = CultureGrowthType.find_by_title(element[:culture_growth_type])
          raise "Unable to find culture growth type for #{element[:culture_growth_type]}" if type.nil?
          element[:culture_growth_type]=type
        end

        #institution
        if element.has_key?(:institution) && !element[:institution].nil?
          institution = Institution.find_by_title(element[:institution])
          raise "Unable to find institution for #{element[:institution]}" if institution.nil?
          element[:institution]=institution
        end

        #do project
        if element.has_key?(:projects) && !element[:projects].nil?
          project_titles = element[:projects].split(",")
          projects = project_titles.collect do |project_title|
            project = Project.find_by_title(project_title)
            project ||= Project.where("lower(title) LIKE ?","%#{project_title.downcase}%").first
            raise "Unable to find project to match '#{project_title}'" if project.nil?
            project
          end
          element[:projects]=projects
        end

        #do contributor
        if element.has_key?(:contributor) && !element[:contributor].nil?
          contributor_name = element[:contributor].strip
          person = people.find do |person|
            person.name =~ /#{contributor_name}/i
          end
          raise "Unable to find person to match '#{contributor_name}'" if person.nil?
          element[:contributor]=person
        end

        #data files
        if element.has_key?(:data_files) && !element[:data_files].nil?
          ids = element[:data_files].split(",")
          data_files = ids.collect do |id|
            df = DataFile.find_by_id(id)
            raise "Unable to find data file for id #{id}" if df.nil?
            df
          end
          element[:data_files]=data_files
        end

        #sops
        if element.has_key?(:sops) && !element[:sops].nil?
          ids = element[:sops].split(",")
          sops = ids.collect do |id|
            sop = Sop.find_by_id(id)
            raise "Unable to find SOP for id #{id}" if sop.nil?
            sop
          end
          element[:sops]=sops
        end

        #assays
        if element.has_key?(:assays) && !element[:assays].nil?
          ids = element[:assays].split(",")
          assays = ids.collect do |id|
            assay = Assay.find_by_id(id)
            raise "Unable to find Assay for id #{id}" if assay.nil?
            assay
          end
          element[:assays]=assays
        end

        #organism
        if element.has_key?(:organism) && element.has_key?(:ncbi)
          title = element[:organism]
          title = title.gsub("_"," ")
          title = "Lactococcus lactis" if title.downcase == "lactococus lactis"
          organism = Organism.where("lower(title) LIKE ?","%#{title.downcase}%").first
          raise "Unable to find Organism for '#{title}'" if organism.nil?
          raise "NCBI doesn't match organism - '#{organism.title} , #{organism.ncbi_id} != #{element[:ncbi]}" if organism.ncbi_id.to_i != element[:ncbi].to_i
          element[:organism]=organism
        end

      end
    end
  end

  def parse_treatment_csv csv

    result = CSV.parse(csv).collect.with_index do |row,x|
      if x==0 #skip the first row but test
        check_treatment_headings row
      else
        Hash[row.map.with_index do |val,i|
          [TREATMENT_KEYS[i],val]
        end]
      end
    end
    result.compact
  end

  def parse_sample_csv csv
    x=0
    result = CSV.parse(csv).collect.with_index do |row,x|
      if x==0
        check_sample_headings row
      else
        Hash[row.map.with_index do |val,i|
          [SAMPLE_KEYS[i],val]
        end]
      end
    end
    result.compact
  end

  def parse_strain_csv csv
    x=0
    result = CSV.parse(csv).collect.with_index do |row,x|
      if x==0
        check_strain_headings row
      else
        Hash[row.map.with_index do |val,i|
          [STRAIN_KEYS[i],val]
        end]
      end
    end
    result.compact
  end

  def parse_specimen_csv csv
    x=0
    result = CSV.parse(csv).collect.with_index do |row,x|
      if x==0
        check_specimen_headings row
      else
        Hash[row.map.with_index do |val,i|
          [SPECIMEN_KEYS[i],val]
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
