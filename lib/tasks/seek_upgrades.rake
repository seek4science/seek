#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'
require 'colorize'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :resynchronise_assay_types,
            :resynchronise_technology_types,
            :increase_sheet_empty_rows,
            :clear_filestore_tmp,
            :remove_non_seek_authors,
            :clean_up_sop_specimens,
            :repopulate_auth_lookup_tables,
            :drop_solr_index
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","db:sessions:clear","tmp:clear"]) do

    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  task(:drop_solr_index=>:environment) do
    dir = File.join(Rails.root,"solr","data")
    if File.exists?(dir)
      FileUtils.remove_dir(dir)
    end
  end

  task(:clean_up_sop_specimens=>:environment) do
    broken = SopSpecimen.all.select{|ss| ss.sop.nil? || ss.specimen.nil?}
    disable_authorization_checks do
      broken.each{|b| b.destroy}
    end
  end


  desc("Increase the min rows from 10 to 35")
  task(:increase_sheet_empty_rows => :environment) do
    worksheets = Worksheet.all.compact
    min_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS
    worksheets.each do |ws|
      if ws.last_row < min_rows
        ws.last_row = min_rows
        ws.save
      end
    end
  end

  desc("Synchronised the assay types assigned to assays according to the current ontology")
  task(:resynchronise_assay_types => :environment) do

    label_map = read_label_map(:assay_types)

    Assay.record_timestamps = false

    Assay.all.each do |assay|
      assay_type_label_hash = assay.assay_type_reader.class_hierarchy.hash_by_label

      label = assay[:assay_type_label].try(:downcase)

      unless label.nil?
        #check to see if the label can resolve to a uri
        resolved_uri = assay_type_label_hash[label].try(:uri).try(:to_s)

        #if the resolved uri is nil try a mapped label
        resolved_uri ||= assay_type_label_hash[label_map[label]].try(:uri).try(:to_s)

        #if the uri is resolved, update the stored uri and remove the label
        unless resolved_uri.nil?
          if assay.assay_type_uri != resolved_uri
            assay.assay_type_uri = resolved_uri
            puts "the assay type URI for Assay #{assay.id} updated to #{resolved_uri.inspect} based on the label #{label.inspect}".green
          end
          assay.assay_type_label = nil
        end

      end

      unless assay.valid_assay_type_uri?
        #if the uri is still invalid, we need to set it to the default
        uri = assay[:assay_type_uri]
        puts "the assay type label and URI for Assay #{assay.id} cannot be resolved, so resetting the URI to the default, but keeping the stored label.\n\t the original label was #{label.inspect} and URI was #{uri.inspect}".red
        assay.use_default_assay_type_uri!
      end

      unless assay.suggested_assay_type_label.nil?
         puts "The Assay #{assay.id} has a suggested assay type label of #{assay.assay_type_label.inspect}, currently attached to the parent URI #{assay.assay_type_uri.inspect}".yellow
      end

      disable_authorization_checks do
        assay.save if assay.changed?
      end

    end
    Assay.record_timestamps = true
  end

  desc("Synchronised the technology types assigned to assays according to the current ontology")
  task(:resynchronise_technology_types => :environment) do
    Assay.record_timestamps = false

    tech_type_label_hash = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label

    label_map = read_label_map(:technology_types)

    Assay.all.each do |assay|
      unless assay.is_modelling?
        label = assay[:technology_type_label].try(:downcase)
        unless label.nil?

          resolved_uri = tech_type_label_hash[label].try(:uri).try(:to_s)

          #if the resolved uri is nil try a mapped label
          resolved_uri ||= tech_type_label_hash[label_map[label]].try(:uri).try(:to_s)

          #if the uri is resovled, update the stored uri and remove the label
          unless resolved_uri.nil?
            if assay.technology_type_uri != resolved_uri
              assay.technology_type_uri = resolved_uri
              puts "the technology type URI for Assay #{assay.id} updated to #{resolved_uri.inspect} based on the label #{label.inspect}".green
            end
            assay.technology_type_label = nil
          end

        end
      else
        assay.technology_type_uri = nil
      end
      unless assay.valid_technology_type_uri?
        uri = assay[:technology_type_uri]
        puts "the technology type label and URI for Assay #{assay.id} cannot be resolved, so resetting the URI to the default, but keeping the stored label.\n\t the original label was #{label.inspect} and URI was #{uri.inspect}".red
        assay.use_default_technology_type_uri!
      end

      disable_authorization_checks do
        assay.save if assay.changed?
      end
      unless assay.suggested_technology_type_label.nil?
        puts "The Assay #{assay.id} has a suggested technology type label of #{assay.technology_type_label.inspect}, currently attached to the parent URI #{assay.technology_type_uri.inspect}".yellow
      end
    end
    Assay.record_timestamps = true
  end

  desc("Some publication authors are associated with seek_authors, but the original authors are still in non_seek_authors")
  task(:remove_non_seek_authors=>:environment) do
    #get the publications where the seek_authors are associated but still full non_seek_authors
    p1 = Publication.all.select{|p| !p.seek_authors.empty?}
    p2 = Publication.all.select{|p| p.publication_author_orders.size == p.non_seek_authors.size}

    #Improve the matching algorithm to solve the remaining unmatched names
    (p1&p2).each do |publication|
      non_seek_authors = publication.non_seek_authors
      seek_authors = publication.seek_authors
      non_seek_authors.each do |author|

        #Get author by last name
        matches = seek_authors.select{|seek_author| seek_author.last_name == author.last_name}

        #If more than one result, filter by first initial
        if matches.size > 1
          first_and_last_name_matches = matches.select{|p| p.first_name.at(0).upcase == author.first_name.at(0).upcase}

          if first_and_last_name_matches.size >= 1  #use this result unless it resulted in no matches
            matches = first_and_last_name_matches
          end
        end

        #If no results, match by normalised name, taken from grouped_pagination.rb
        if matches.empty?
          seek_authors.each do |seek_author|
            ascii1 = normalize_name(author.last_name)
            ascii2 = normalize_name(seek_author.last_name)
            matches << seek_author if (ascii1 == ascii2)
          end
        end

        #special normalization case for umlaut: e.g. ü match ue
        if matches.empty?
          seek_authors.each do |seek_author|
            ascii1 = normalize_name(author.last_name, false, true)
            ascii2 = normalize_name(seek_author.last_name, false, true)
            matches << seek_author if (ascii1 == ascii2)
          end
        end

        #if no results, match by parts of last name
        if matches.empty?
          matches = seek_authors.select{|seek_author| Regexp.new(seek_author.last_name, Regexp::IGNORECASE).match(author.last_name) ||
                                                      Regexp.new(author.last_name, Regexp::IGNORECASE).match(seek_author.last_name)}
        end

        match = matches.first
        unless match.nil?
          updating_publication_author_order = PublicationAuthorOrder.where(["publication_id=? AND author_id=? AND author_type=?", publication.id, author.id, 'PublicationAuthor' ]).first
          updating_publication_author_order.author = match
          updating_publication_author_order.save
          author.delete
        end
      end
    end
  end

  private

  def read_label_map type
    file = "#{type.to_s}_label_mappings.yml"
    file = File.join(Rails.root,"config","default_data",file)
    YAML::load_file(file)
  end

  def normalize_name(name, remove_special_character=true, replace_umlaut=false)
    #handle the characters that can't be handled through normalization
    %w[ØO].each do |s|
      name.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
    end

    codepoints = name.mb_chars.normalize(:d).split(//u)
    if remove_special_character
      ascii=codepoints.map(&:to_s).reject{|e| e.bytesize > 1}.join
    end
    if replace_umlaut
      ascii=codepoints.map(&:to_s).collect {|e| e == '̈' ? 'e' : e}.join
    end
    ascii
  end
end
