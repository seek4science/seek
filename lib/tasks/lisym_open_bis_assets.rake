require 'set'
require 'rubygems/text'

namespace :seek_publ_export do

  task(list_openbis_assets: :environment) do


    @all_assays_set = Set.new
    @all_data_files_set = Set.new

    @nb_openbis_studies = 1
    @nb_openbis_assays = 1
    @nb_openbis_data_files = 1

    include ApplicationHelper
    include OpenbisHelper
    include Gem::Text

    fileAllAssets = File.join(Rails.root, 'tmp', "#{Seek::Config.project_name.parameterize.underscore}_all_openbis_elements.txt")

    all_authors_report = File.open(fileAllAssets, 'w')

    # go through all project
    Project.all.each do |one_project|

      warn("In project #{one_project.title}")

      all_authors_report.write("\n--- #{one_project.title}\n")

      # Study & dependants
      studies_in_a_project = one_project.studies

      studies_in_a_project.all.each do |one_study|

        # check the study by itself
        warn("Checking study #{one_study.title}")

        shown_study = false

        if one_study.external_asset

          warn("Study has an external asset")

          asset = one_study.external_asset

          if asset.is_a?(OpenbisExternalAsset)
            entity = asset.content

            warn("Study is OpenBis")
            shown_study = true

            all_authors_report.write("\n\n * #{@nb_openbis_studies} One study from OpenBis: #{one_study.title}  --")
            @nb_openbis_studies = @nb_openbis_studies + 1
            show_entity_openBis_infos(all_authors_report, entity)
          end
        end
        # then the dependant data_types
        shown_study = find_all_open_bis_assays_in_study(all_authors_report, one_study, shown_study, one_study.title)
        # And assays
        find_all_open_bis_data_files_in_study(all_authors_report, one_study, shown_study, one_study.title)
      end

      all_authors_report.write("\n* Assays from the project:\n")

      # Assays & dependants not dependants of Study (is that possible?)
      assays_in_a_study = one_project.assays

      assays_in_a_study.all.each do |one_assay|

        # check the assay by itself
        check_one_assay_for_open_bis(all_authors_report, one_assay, true, "Not in a study")
      end

      all_authors_report.write("\n* Data files from the project:\n")

      # Datatypes not dependants
      data_files_in_an_study = one_project.data_files

      data_files_in_an_study.all.each do |one_data_file|
        warn("Checking #{one_data_file.title}")
        check_if_data_file_is_open_bis(all_authors_report, one_data_file, true, "Not in an study")
      end

    end

    all_authors_report.close
  end

  def text_or_not_specified(desc, text)
    return "" unless text.nil?

    desc + text
  end

  def find_all_open_bis_assays_in_study(all_authors_report, one_study, shown_study, study_title)
    assays_in_a_study = one_study.assays

    assays_in_a_study.all.each do |one_assay|

      # check the study by itself
      if check_one_assay_for_open_bis(all_authors_report, one_assay, shown_study, study_title)
        shown_study = true
      end
    end
  end


  def check_one_assay_for_open_bis(all_authors_report, one_assay, shown_study, study_title)
    warn("Checking assay #{one_assay.title}")

    if @all_assays_set.include?(one_assay)
      warn("Assay already listed, ignoring")
    elsif one_assay.external_asset

      warn("Assay has an external asset")

      asset = one_assay.external_asset

      if asset.is_a?(OpenbisExternalAsset)
        entity = asset.content

        warn("Assay is OpenBis")

        @all_assays_set << one_assay

        unless shown_study
          all_authors_report.write("\n\n ** In study: #{study_title}  --")
          shown_study = true
        end

        all_authors_report.write("\n   - #{@nb_openbis_assays} One assay from OpenBis: #{one_assay.title}  --")
        @nb_openbis_assays = @nb_openbis_assays + 1
        show_entity_openBis_infos(all_authors_report, entity)
      end
    end

    data_files_in_an_assay = one_assay.data_files

    data_files_in_an_assay.all.each do |one_data_file|

      check_if_data_file_is_open_bis(all_authors_report, one_data_file, shown_study, study_title)
    end

    shown_study
  end

  def find_all_open_bis_data_files_in_study(all_authors_report, one_study, shown_study, study_title)
    #data_files_in_an_study = one_study.data_file_versions

    #data_files_in_an_study.all.each do |one_data_file|

    #  check_if_data_file_is_open_bis(all_authors_report, one_data_file)
    #end
    shown_study
  end

  def check_if_data_file_is_open_bis(all_authors_report, one_data_file, shown_study, study_title)

    if @all_data_files_set.include?(one_data_file)

      warn("Data file already listed, ignoring")
    elsif one_data_file.openbis? # one_data_file.can_download? &&
      entity = one_data_file.openbis_dataset

      warn("Data_file is OpenBis")
      @all_data_files_set << one_data_file

      unless shown_study
        all_authors_report.write("\n\n ** In study: #{study_title}  --")
        shown_study = true
      end

      all_authors_report.write("\n   - #{@nb_openbis_data_files} One data_file from OpenBis: #{one_data_file.title}  --")
      @nb_openbis_data_files = @nb_openbis_data_files + 1
      show_entity_openBis_infos(all_authors_report, entity)
    else
      warn("Data file is #{one_data_file} and openBis: #{one_data_file.openbis?}, can_download: #{one_data_file.can_download?} ")
    end

    shown_study
  end

  def show_entity_openBis_infos(all_authors_report, entity)
    all_authors_report.write("Open Bis perm id #{entity.perm_id} -- ")
    all_authors_report.write(text_or_not_specified("type code ", entity.type_code))
    all_authors_report.write(text_or_not_specified("Type desc ", entity.type_description))
    all_authors_report.write(text_or_not_specified("Registered at ", date_as_string(entity.registration_date, true)))
    all_authors_report.write(text_or_not_specified("Registered by ", entity.registrator))
    if entity.registration_date != entity.modification_date
      all_authors_report.write(text_or_not_specified("Modified at ", date_as_string(entity.modification_date, true)))
      all_authors_report.write(text_or_not_specified(" By ", entity.modifier))
    end
    entity.vetted_properties.each do |key, value|
      all_authors_report.write( ' ' + key + ': ' + openbis_rich_content_sanitizer(value))
    end
  end
end
