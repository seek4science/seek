require 'csv'
require 'rubygems/text'

namespace :seek_publ_export do

  task(list_supposed_pi_for_lowscore_publ: :environment) do

    include ApplicationHelper
    include Gem::Text

    file_all_peoples = File.join(Rails.root, 'tmp', Seek::Config.project_name.parameterize.underscore + '_all_peoples.txt')

    all_peoples_hash = Hash.new # to find a matched person
    all_peoples_array = Array.new # to fuzzy-match persons

    file_all_authors = File.join(Rails.root, 'tmp', Seek::Config.project_name.parameterize.underscore + '_all_authors.txt')
    file_all_publ = File.join(Rails.root, 'tmp', Seek::Config.project_name.parameterize.underscore + '_all_publ.txt')

    all_authors_report = File.open(file_all_authors, 'w')
    all_publ_report = File.open(file_all_publ, 'w')
    all_people_report = File.open(file_all_peoples, 'w')

    file = File.join(Rails.root, 'tmp', Seek::Config.project_name.parameterize.underscore + '_low_score_report.txt')

    File.open(file, 'w') do |low_score_report|
      # go through all project
      # projects_instance = Project.constantize
      Project.all.each do |one_project|

        warn("In project " + one_project.title)

        # find and keep the biggest "publisher" from the Seek authors in this project
        all_people_report.write("--- " + one_project.title + "\n")

        persons_in_a_project = one_project.people

        seek_persons_with_nb_of_publ = {}

        persons_in_a_project.all.each do |one_person|
          nb_of_publication = 0

          # now count the nb of publication of this project for this person
          publications_for_one_person = one_person.publication_authors

          publications_for_one_person.all.each do |one_publication_authors_for_a_person|

            publication_for_this_author = one_publication_authors_for_a_person.publication

            unless publication_for_this_author.projects.where(id: one_project.id).empty?
              nb_of_publication += 1
            end

          end

          seek_persons_with_nb_of_publ[one_person] = nb_of_publication

        end

        sortedSeekPersons = seek_persons_with_nb_of_publ.sort_by { |person, nb_of_publ| -nb_of_publ }

        sortedSeekPersons.each do |one_person|
          found_person = one_person.at(0)
          all_peoples_hash[found_person.id] = found_person
          all_peoples_array << found_person

          warn("\n" + found_person.first_name + ' ' + found_person.last_name + " - Nb of publ in this project: " + one_person.at(1).to_s)

          all_people_report.write(found_person.first_name + ' ' + found_person.last_name + "\n" +
                                    found_person.email + " - Nb of publ in this project: " + +one_person.at(1).to_s + "\n\n");

        end
        warn("\n")

        # most important persons of this project (publication in this project)

        low_score_report.write("\n***********\n" + one_project.title + "\n\n")

        # now sort by nb of publication and get the top 1 to 3 persons
        sortedPersons = seek_persons_with_nb_of_publ.sort_by { |person, nb_of_publ| -nb_of_publ }

        nb_to_return = [sortedPersons.size, 3].min - 1

        (0..nb_to_return).each do |i_person|
          onePerson = sortedPersons[i_person].at(0)

          warn('Would contact ' + onePerson.first_name + ' ' + onePerson.last_name)

          low_score_report.write(onePerson.first_name + ' ' + onePerson.last_name + "\n" +
                                   onePerson.email + "\n\n");
        end

        # find a score for each publication, keep the one bellow a thresold
        publications = one_project.publications

        publications_with_low_score = []

        publications.all.order(:created_at).each do |one_publication|

          # count the nb of related elements
          # we could do it using related_relationships but cutting it would allow us to change the weight of each
          nb_of_relation = one_publication.data_files.size
          nb_of_relation += one_publication.models.size
          nb_of_relation += one_publication.assays.size
          nb_of_relation += one_publication.studies.size
          nb_of_relation += one_publication.investigations.size
          nb_of_relation += one_publication.presentations.size

          # has_many :related_relationships, -> { where(predicate: Relationship::RELATED_TO_PUBLICATION) },
          #          class_name: 'Relationship', as: :other_object, dependent: :destroy, inverse_of: :other_object
          #
          # has_many :data_files, through: :related_relationships, source: :subject, source_type: 'DataFile'
          # has_many :models, through: :related_relationships, source: :subject, source_type: 'Model'
          # has_many :assays, through: :related_relationships, source: :subject, source_type: 'Assay'
          # has_many :studies, through: :related_relationships, source: :subject, source_type: 'Study'
          # has_many :investigations, through: :related_relationships, source: :subject, source_type: 'Investigation'
          # has_many :presentations, through: :related_relationships, source: :subject, source_type: 'Presentation'
          #
          warn("Nb of relation is " + nb_of_relation.to_s + " for publication " + one_publication.title)

          link_to_publication = URI.join(Seek::Config.site_base_host + '/', "#{one_publication.class.name.tableize}/", one_publication.id.to_s).to_s

          date_of_publ = ""

          unless one_publication.published_date.nil?
            date_of_publ = one_publication.published_date.strftime("#{one_publication.published_date.day.ordinalize} %b %Y")
          end
          all_publ_report.write("\n" + one_publication.title + "\n" +
                                  date_of_publ + "\n" +
                                  link_to_publication.to_s + "\n\n--- Authors\n");

          # keep all non-persons authors in a hashset
          # look at distance between people and authors name
          # gives all authors with a * for persons
          all_authors = one_publication.publication_authors

          authors_with_nb_for_this_publ = {} # to find a matched person

          all_authors.each do |oneAuthor|

            current_last_name = oneAuthor.last_name
            current_first_name = oneAuthor.first_name

            if oneAuthor.person_id.nil?
              all_publ_report.write("\n  Non-Seek author: " + current_first_name + " " + current_last_name)
              all_authors_report.write("\n  Non-Seek author: " + current_first_name + " " + current_last_name)
              all_peoples_array.each do |onePerson|
                last_name_person = onePerson.last_name
                if levenshtein_distance(current_last_name, last_name_person) < 3
                  warn("Last names are quite similar " + current_last_name + " - " + last_name_person + " : " +
                         levenshtein_distance(current_last_name, last_name_person).to_s)
                  # so we compare the first name too, and if the score is still good, we suggest this person
                  first_name_person = onePerson.first_name
                  if levenshtein_distance(current_first_name, first_name_person) < 3
                    warn("First names are quite similar " + current_first_name + " - " + first_name_person + " : " +
                           levenshtein_distance(current_first_name, first_name_person).to_s)
                    all_publ_report.write("  Similar to Seek person: " + first_name_person + " " + last_name_person)
                    all_authors_report.write("  Similar to Seek person: " + first_name_person + " " + last_name_person)
                  end
                end
              end
            else
              thisPerson = all_peoples_hash[oneAuthor.person_id]

              if thisPerson.nil?
                all_publ_report.write("\n  Former seek person (" + oneAuthor.person_id.to_s +
                                        "): " + current_first_name + " " + current_last_name)
                all_authors_report.write("\n  Former seek person (" + oneAuthor.person_id.to_s +
                                           "): " + current_first_name + " " + current_last_name)
              else
                all_publ_report.write("\n  Seek person (" + thisPerson.first_name + " " +
                                        thisPerson.last_name + "): " + current_first_name + " " + current_last_name)
                all_authors_report.write("\n  Seek person (" + thisPerson.first_name + " " +
                                           thisPerson.last_name + "): " +
                                           current_first_name + " " + current_last_name)
                if seek_persons_with_nb_of_publ[thisPerson].nil?
                  authors_with_nb_for_this_publ[thisPerson] = 0
                else
                  authors_with_nb_for_this_publ[thisPerson] = seek_persons_with_nb_of_publ[thisPerson]
                end
              end
            end
          end

          sorted_this_publ_persons = []

          if authors_with_nb_for_this_publ.size > 0
            warn('Trying to sort '+authors_with_nb_for_this_publ.to_s)
            sorted_this_publ_persons = authors_with_nb_for_this_publ.sort_by { |person, nb_of_publ| -nb_of_publ }
          end

          if nb_of_relation < 2

            link_to_publication = URI.join(Seek::Config.site_base_host + '/', "#{one_publication.class.name.tableize}/", one_publication.id.to_s).to_s

            date_of_publ = ""

            unless one_publication.published_date.nil?
              date_of_publ = one_publication.published_date.strftime("#{one_publication.published_date.day.ordinalize} %b %Y")
            end
            low_score_report.write("\n---------------\n" + one_publication.title + "\n" +
                                     date_of_publ + "\n" +
                                     link_to_publication.to_s + "\n");
            low_score_report.write("Score break-up\nData files: " + one_publication.data_files.size.to_s)
            low_score_report.write("\nModels: " + one_publication.models.size.to_s)
            low_score_report.write("\nAssays: " + one_publication.assays.size.to_s)
            low_score_report.write("\nStudies: " + one_publication.studies.size.to_s)
            low_score_report.write("\nInvestigations: " + one_publication.investigations.size.to_s)
            low_score_report.write("\nPresentations: " + one_publication.presentations.size.to_s + "\n")

            sorted_this_publ_persons.each do |one_seek_authors_for_this_publ|
              one_author_from_this_publ = one_seek_authors_for_this_publ.at(0)
              nb_of_publ_for_this_author = one_seek_authors_for_this_publ.at(1).to_s
              low_score_report.write("\n" + one_author_from_this_publ.try(:first_name) + ' ' +
                                       one_author_from_this_publ.try(:last_name) +
                                       ' Nb of publication in this project: ' + nb_of_publ_for_this_author)
            end
          end
        end
      end
    end

    all_publ_report.close
    all_authors_report.close
  end
end
