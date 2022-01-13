# encoding: utf-8

class PublicationsController < ApplicationController
  include Seek::IndexPager
  include Seek::AssetsCommon
  include Seek::PreviewHandling

  include Seek::UploadHandling::DataUpload

  before_action :publications_enabled?
  before_action :find_assets, only: [:index]
  before_action :find_and_authorize_requested_item, only: %i[show edit manage update destroy download upload_fulltext upload_pdf soft_delete_fulltext]
  before_action :suggest_authors, only: [:manage]
  before_action :find_display_asset, :only=>[:show, :download]

  include Seek::IsaGraphExtensions
  include PublicationsHelper

  api_actions :index, :show

  def export
    @query = Publication.ransack(params[:query])
    @publications = @query.result(distinct: true)
                        .includes(:publication_authors, :projects)
    # @query.build_condition
    @query.build_sort if @query.sorts.empty?

    respond_to do |format|
      format.html
      format.any(*Publication::EXPORT_TYPES.keys) do
        send_data(
          @publications.collect { |publication| publication.export(request.format.to_sym) }.join("\n\n"),
          type: request.format.to_sym,
          filename: "publications.#{request.format.to_sym}"
        )
      end
    end
  end

  # GET /publications/1
  # GET /publications/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml
      format.rdf { render template: 'rdf/show' }
      format.json {render json: @publication, include: [params[:include]]}
      format.any( *Publication::EXPORT_TYPES.keys ) do
        begin
          send_data @publication.export(request.format.to_sym), type: request.format.to_sym, filename: "#{@publication.title}.#{request.format.to_sym}"
        rescue StandardError => exception
          Seek::Errors::ExceptionForwarder.send_notification(exception, env:request.env, data:{ message: "Error exporting publication as #{request.format}" })

          flash[:error] = "There was a problem communicating with PubMed to generate the requested #{request.format.to_sym.to_s.upcase}."
          redirect_to @publication
        end
      end
    end
  end

  # GET /publications/new
  # GET /publications/new.xml
  def new
    @publication = Publication.new
    @publication.parent_name = params[:parent_name]
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end

  # GET /publications/1/edit
  def edit; end

  # GET /publications/1/manage
  def manage; end

  # GET /publications/1/upload_fulltext
  def upload_fulltext
    # @publication = Publication.find(params[:id])
    # publication is found via find_and_authorize_requested_item and return is authorized!
  end

  # POST /publications
  # POST /publications.xml
  def create
    @subaction = params[:subaction] || 'Register'

    case @subaction
    when 'Import'
      return import_publication
    when 'ImportMultiple'
      return import_publication_multiple
    end

    @publication = Publication.new(publication_params)
    @publication.pubmed_id = nil if @publication.pubmed_id.blank?
    @publication.doi = nil if @publication.doi.blank?
    pubmed_id, doi = preprocess_pubmed_or_doi @publication.pubmed_id, @publication.doi
    @publication.doi = doi
    @publication.pubmed_id = pubmed_id

    case @subaction
    when 'Register' # Register publication from doi or pubmedid
      register_publication
    when 'Create' # Create publication from all fields
      create_publication
    end
  end

  # PUT /publications/1
  # PUT /publications/1.xml
  def update
    update_annotations(params[:tag_list], @publication) if params.key?(:tag_list)
    update_sharing_policies @publication

    if @publication.update_attributes(publication_params)
      respond_to do |format|
        flash[:notice] = 'Publication was successfully updated.'
        format.html { redirect_to(@publication) }
        format.xml  { head :ok }
        format.json { render json: @publication, status: :ok, include: [params[:include]]}
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.xml  { render xml: @publication.errors, status: :unprocessable_entity }
        format.json { render json: @publication.errors, status: :unprocessable_entity }
      end
    end
  end

  def upload_pdf
    blob_params = params[:content_blobs]
    if !blob_params || blob_params.empty? || blob_params.none? { |p| check_for_data_or_url(p) }
      redirect_to @publication
    elsif handle_upload_data(true)
      comments = params[:revision_comments]

      respond_to do |format|
        create_new_version comments
        format.html { redirect_to @publication }
      end
    else
      flash[:error] = flash.now[:error]
      redirect_to @publication
    end
  end

  def create_new_version comments
    if @publication.save_as_new_version(comments)
      flash[:notice]="New full text uploaded #{@publication.version}"
    else
      flash[:error]="Unable to save new fulltext"
    end
  end

  def soft_delete_fulltext
    # replace this version as a new empty version
    if @publication.can_soft_delete_full_text?
      # create an empty version
      respond_to do |format|
        create_new_version 'Soft delete'
        format.html { redirect_to @publication }
      end
    else
      flash[:error]=flash.now[:error]
      redirect_to @publication
    end
  end

  def fetch_preview
    # trim the PubMed or Doi Id
    params[:key] = params[:key].strip unless params[:key].blank?

    @publication = Publication.new(publication_params)
    key = params[:key]
    protocol = params[:protocol]

    if params[:publication][:publication_type_id].blank?
      @error = "Please choose a publication type."
    else
      doi = nil
      pubmed_id = nil
      if protocol == 'pubmed' && key.present?
        pubmed_id = key
      elsif protocol == 'doi' && key.present?
        doi = key
      end
      pubmed_id, doi = preprocess_pubmed_or_doi pubmed_id, doi
      result = get_data(@publication, pubmed_id, doi)
    end
    @error =  @publication.errors.full_messages.join('<br>') if @publication.errors.any?
    if !@error.nil?
      @error_text = @error
      respond_to do |format|
        format.js { render status: 500 }
      end
    else
      @authors = result.authors
      respond_to do |format|
        format.js
      end
    end
  end

  def update_metadata

    @publication = Publication.find(params[:publication][:id])
    publication_type_id= params[:publication][:publication_type_id]
    doi= params[:publication][:doi]
    pubmed_id = params[:publication][:pubmed_id]
    if publication_type_id.blank?
      @error = "Please choose a publication type."
    else
      get_data(@publication, pubmed_id, doi)
    end
    @error =  @publication.errors.full_messages.join('<br>') if @publication.errors.any?
    if !@error.nil?
      @error_text = @error
      respond_to do |format|
        format.js { render status: 500 }
      end
    else
      respond_to do |format|
        format.js
      end
    end
  end

  def query_authors
    # query authors by first and last name each
    authors_q = params[:authors]

    unless authors_q
      error = 'require query parameter authors'
      respond_to do |format|
        format.json { render json: { error: error }, status: 422 }
        format.xml  { render xml: { error: error }, status: 422 }
      end

      return
    end

    authors = []
    authors_q.each do |_author_i, author_q|
      params = {}
      if author_q.key?('full_name')
        first_name, last_name = PublicationAuthor.split_full_name author_q['full_name']
        params = { first_name: first_name, last_name: last_name }
      else
        params = { first_name: author_q['first_name'], last_name: author_q['last_name'] }
      end

      authors_db = PublicationAuthor.where(params)
                                    .group(:person_id, :first_name, :last_name, :author_index)
                                    .count
                                    .collect do |groups, count|
        {
          person_id: groups[0],
          first_name: groups[1],
          last_name: groups[2],
          count: count
        }
      end

      if !authors_db.empty? # found at least one author
        authors << authors_db[0]
      else # no author found
        users_db = Person.where(params)
        if !users_db.empty? # is there a person with that name
          user = users_db[0]
          authors << { name: user.name }
        else # just add the queried name as author
          authors << { person_id: nil, first_name: params[:first_name], last_name: params[:last_name], count: 0 }
        end
      end
    end

    respond_to do |format|
      format.json { render json: authors.to_json }
      format.xml  { render xml: authors }
    end
  end

  def query_authors_typeahead
    full_name = params[:full_name]
    unless full_name
      error = 'require query parameter full_name'
      respond_to do |format|
        format.json { render json: { error: error }, status: 422 }
        format.xml  { render xml: { error: error }, status: 422 }
      end

      return
    end

    first_name, last_name = PublicationAuthor.split_full_name full_name

    # all authors
    authors = PublicationAuthor.where('first_name LIKE :fnquery', fnquery: "#{first_name}%")
                               .where('last_name LIKE :lnquery', lnquery: "#{last_name}%")
                               .group(:person_id, :first_name, :last_name, :author_index)
                               .count
                               .collect do |groups, count|
      {
        person_id: groups[0],
        first_name: groups[1],
        last_name: groups[2],
        count: count
      }
    end
    authors.delete_if { |author| author[:first_name].empty? && author[:last_name].empty? }
    author = PublicationAuthor.where(first_name: first_name, last_name: last_name).limit(1)

    respond_to do |format|
      format.json { render json: authors.to_json }
      format.xml  { render xml: authors }
    end
  end

  # Try and relate non_seek_authors to people in SEEK based on name and project
  def suggest_authors
    @publication.publication_authors.each do |author|
      author.suggested_person = find_person_for_author(author, @publication.projects,false)
    end
  end

  def disassociate_authors
    @publication = Publication.find(params[:id])

    if @publication.pubmed_id.present? || @publication.doi.present?
      @publication.creators.clear # get rid of author links
      @publication.publication_authors.clear

      # Query pubmed article to fetch authors
      result = @publication.fetch_pubmed_or_doi_result @publication.pubmed_id, @publication.doi

      unless result.nil?
        result.authors.each_with_index do |author, index|
          pa = PublicationAuthor.new(publication: @publication,
                                     first_name: author.first_name,
                                     last_name: author.last_name,
                                     author_index: index)
          pa.save
        end
      end
    else
      @publication.publication_authors.each do |author|
        author.update_attributes(person_id: nil) unless author.person_id.nil?
      end
      @error = 'Please enter either a DOI or a PubMed ID for the publication.'
    end


    respond_to do |format|
      format.html {redirect_to(manage_publication_url(@publication))}
      format.xml {head :ok}
    end
  end

  def get_data(publication, pubmed_id, doi = nil)
    result = publication.extract_metadata(pubmed_id, doi)
    result
  end

  private

  def publication_projects_params
    params.require(:publication).permit(project_ids: [])
  end

  def publication_params
    params.require(:publication).permit(:publication_type_id, :pubmed_id, :doi, :parent_name, :abstract, :title, :journal, :citation,:url,:editor,
                                        :published_date, :bibtex_file, :registered_mode, :publisher, :booktitle, { project_ids: [] }, { event_ids: [] }, { model_ids: [] },
                                        { investigation_ids: [] }, { study_ids: [] }, { assay_ids: [] }, { presentation_ids: [] },
                                        { data_file_ids: [] }, { scales: [] }, { human_disease_ids: [] }, { workflow_ids: [] },
                                        { misc_links_attributes: [:id, :url, :label, :_destroy] },
                                        { publication_authors_attributes: [:person_id, :id, :first_name, :last_name ] }).tap do |pub_params|
      filter_association_params(pub_params, :assay_ids, Assay, :can_edit?)
      filter_association_params(pub_params, :study_ids, Study, :can_view?)
      filter_association_params(pub_params, :investigation_ids, Investigation, :can_view?)
      filter_association_params(pub_params, :data_file_ids, DataFile, :can_view?)
      filter_association_params(pub_params, :model_ids, Model, :can_view?)
      filter_association_params(pub_params, :presentation_ids, Presentation, :can_view?)
    end
  end

  def filter_association_params(params, key, type, check)
    if params.key?(key)
      # Strip out anything that the user does not have permission to add
      params[key].select! { |id| type.find_by_id(id).try(check) }

      # Re-add anything that the user does not have permission to remove
      if @publication
        missing = @publication.send(key).map(&:to_i) - params[key].map(&:to_i)
        missing.reject! { |id| type.find_by_id(id).try(check) }

        params[key] += missing
      end
    end

    params[key]
  end

  # the original way of creating a publication by either doi or pubmedid, where all data is set server-side
  def register_publication
    get_data(@publication, @publication.pubmed_id, @publication.doi)

    if @publication.save
      if !@publication.parent_name.blank?
        render partial: 'assets/back_to_fancy_parent', locals: { child: @publication, parent_name: @publication.parent_name }
      else
        respond_to do |format|
          flash[:notice] = 'Publication was successfully created. You can edit the additional information now or later'

          # newly_created Change the buttons in the manage page-> Cancel will become Skip, ...
          format.html { redirect_to(manage_publication_url(@publication, newly_created: true)) }
          format.xml  { render xml: @publication, status: :created, location: @publication }
          format.json  { render json: @publication, status: :created, location: @publication, include: [params[:include]] }
        end
      end
    else # Publication save not successful
      respond_to do |format|
        format.html { render action: 'new' }
        format.xml  { render xml: @publication.errors, status: :unprocessable_entity }
      end
    end
  end

  # create a publication from a form that contains all the data
  def create_publication

    @publication.registered_mode = @publication.registered_mode || Publication::REGISTRATION_MANUALLY
    assay_ids = params[:assay_ids] || []
    # create publication authors
    plain_authors = params[:publication][:publication_authors]
    plain_authors.each_with_index do |author, index| # multiselect
      next if author.empty?
      first_name, last_name = PublicationAuthor.split_full_name author
      pa = PublicationAuthor.new(publication: @publication,
                                 first_name: first_name,
                                 last_name: last_name,
                                 author_index: index)
      @publication.publication_authors << pa
    end

    if @publication.save
      upload_blob

      create_or_update_associations assay_ids, 'Assay', 'edit'
      if !@publication.parent_name.blank?
        render partial: 'assets/back_to_fancy_parent', locals: { child: @publication, parent_name: @publication.parent_name }
      else
        respond_to do |format|
          flash[:notice] = 'Publication was successfully created.'
          format.html { redirect_to(manage_publication_url(@publication)) }
          format.xml  { render xml: @publication, status: :created, location: @publication }
          format.json { render json: @publication, status: :created, location: @publication, include: [params[:include]] }
        end
      end
    else # Publication save not successful
      respond_to do |format|
        format.html { render action: 'new' }
        format.xml  { render xml: @publication.errors, status: :unprocessable_entity }
        format.json { render json: @publication.errors, status: :unprocessable_entity }
      end
    end
  end

  def upload_blob
    blob_params = params[:content_blobs]
    if !blob_params || blob_params.empty? || blob_params.none? { |p| check_for_data_or_url(p) }
      nil # Empty content is allowed for full text publication.
    elsif handle_upload_data(true)
      comments = params[:revision_comments]
      create_new_version comments
    else
      flash[:error] = flash.now[:error]
    end
  end

  # create a publication from a reference file, at the moment supports only bibtex
  # only sets the @publication and redirects to the create_publication with content from the bibtex file
  def import_publication

    @publication = Publication.new(publication_projects_params)

    require 'bibtex'
    if !params.key?(:publication) || !params[:publication].key?(:bibtex_file)
      flash[:error] = 'Please upload a bibtex file!'
    else
      bibtex_file = params[:publication].delete(:bibtex_file)
      #TODO:hu check the encoding problem here, when exception due to encoding, add an error message
      data = bibtex_file.read.force_encoding('UTF-8')
      bibtex = BibTeX.parse(data,:filter => :latex)
      if bibtex[0].nil?
        flash[:error] =  'The bibtex file should contain at least one item.'
      else
        # warning if there are more than one article
        if bibtex.length > 1
          flash[:error] = "The bibtex file did contain #{bibtex.length} items; only the first one is parsed."
        end
        @publication.extract_bibtex_metadata(bibtex[0])
      end
    end

    if @publication.errors.any?
      respond_to do |format|
        format.html { render action: 'new' }
        format.xml  { render xml: @publication.errors, status: :unprocessable_entity }
        format.json { render json: @publication.errors, status: :unprocessable_entity }
      end
    else
      @subaction = 'Create'
        respond_to do |format|
          format.html { render action: 'new' }
          format.json { render json: @publication, status: :ok, include: [params[:include]] }
        end
    end
  end

  # create publications from a reference file, at the moment supports only bibtex
  def import_publication_multiple
    @publication = Publication.new(publication_projects_params)

    require 'bibtex'
    if !params.key?(:publication) || !params[:publication].key?(:bibtex_file)
      flash[:error] =  'Please upload a bibtex file!'
    else
      bibtex_file = params[:publication].delete(:bibtex_file)
      data = bibtex_file.read.force_encoding('UTF-8')
      bibtex = BibTeX.parse(data,:filter => :latex)


      if bibtex[0].nil?
        flash[:error] = 'The bibtex file should contain at least one item.'
      else
        articles = bibtex
        publications = []
        publications_with_errors = []

        # create publications from articles
        articles.each do |article|
          current_publication = Publication.new(publication_params)
          unless current_publication.extract_bibtex_metadata(article)
            publications_with_errors << current_publication
          else
            if current_publication.save
              Rails.logger.info(current_publication.id.inspect+":"+current_publication.citation)
              publications << current_publication
              associsate_authors_with_users(current_publication)
              current_publication.creators = current_publication.seek_authors.map(&:person)
            else
              publications_with_errors << current_publication
            end
          end
        end

        if publications.any?
          flash[:notice] = "Successfully imported #{publications.length} publications. <br>"
          publications.each_with_index do |publication, index|
            flash[:notice]+= "<br>"+(index+1).to_s+": "+ publication.title + "<br>"
          end
          flash[:notice] = flash[:notice].html_safe
        else
          flash[:error] = 'No article could be imported successfully'
        end

        if publications_with_errors.any?
          flash[:error] = "There are #{publications_with_errors.length} publications that could not be saved"
          publications_with_errors.each_with_index do |publication, index|
            flash[:error]+= "<br>"
            if publication.title.nil?
              flash[:error]+= "<br>"+(index+1).to_s+": No title.<br>"+ "Please check your bibtex files, each publication should contain a title or a chapter name."
            else
              flash[:error]+= "<br>"+(index+1).to_s+": "+ publication.title + "<br>"+ publication.errors.full_messages.join('<br>')
            end
          end
          flash[:error] = flash[:error].html_safe
        end
      end
    end

    if @publication.errors.any?
      @subaction = 'Import'
      respond_to do |format|
        format.html { render action: 'new' }
        format.xml  { render xml: @publication.errors, status: :unprocessable_entity }
        format.json  { render json: @publication.errors, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.html { redirect_to(action: :index) }
        format.xml  { render xml: publications, status: :created, location: @publication }
        format.json  { render json: publications, status: :created, location: @publication }
      end
    end
  end

  def associsate_authors_with_users(current_publication)
    current_publication.publication_authors.each do |author|
      author.suggested_person = find_person_for_author(author, current_publication.projects, true)
      unless author.suggested_person.nil?
        author.person_id = author.suggested_person.id
        author.save
      end
    end
  end

  def preprocess_pubmed_or_doi(pubmed_id, doi)
    doi = doi.sub(/doi\.*:/i, '').strip unless doi.nil? # handle DOI: prefix
    doi = doi.gsub(/(https?:\/\/)?(dx\.)?doi\.org\//i,'').strip unless doi.nil? # handle https://doi.org/ prefix (with our without http(s))
    pubmed_id.strip! unless pubmed_id.nil? || pubmed_id.is_a?(Integer)
    [pubmed_id, doi]
  end

  def create_or_update_associations(asset_ids, asset_type, required_action)
    asset_ids.each do |id|
      asset = asset_type.constantize.find_by_id(id)
      if asset && asset.send("can_#{required_action}?")
        @publication.associate(asset)
      end
    end

    # Destroy asset relationship that aren't needed
    @publication.relationships.where(subject_type: asset_type).each do |associate_relationship|
      asset = associate_relationship.subject
      if asset.send("can_#{required_action}?") && !asset_ids.include?(asset.id.to_s)
        associate_relationship.destroy
      end
    end
  end

  # given an author, the can be associated with a Person in SEEK
  # this method tries to find a Person by last_name
  # if this fails, it normalizes the last name and searches again
  # if there are too many matches, they will be narrowed down by the given projects
  # if there are still too many matches, they will be narrowed down by the first name initials
  # @param author [PublicationAuthor] the author to find a matching person for
  # @param projects [Array<Project>] projects to narrow matches is necessary
  # @param  exact [Boolean] if the match should be exact match or not
  # @return [Person] the first match is returned or nil
  def find_person_for_author(author, projects, exact)

    matches = []
    # Get author by last name
    last_name_matches = Person.where(last_name: author.last_name)
    matches = last_name_matches

    if matches.empty?
      # if no results, try replacing umlaut to non_umlaut
      if has_umlaut(author.last_name)
        replaced_name = replace_to_non_umlaut(author.last_name)
        #if no results, try replacing non_umlaut to umlaut
      elsif has_non_umlaut(author.last_name)
        replaced_name = replace_to_umlaut(author.last_name)
      end
      last_name_matches = Person.where(last_name: replaced_name) unless replaced_name.blank?
      matches = last_name_matches
    end

    # if no results, try searching by normalised name, taken from grouped_pagination.rb
    if matches.empty?
      text = author.last_name
      # handle the characters that can't be handled through normalization
      %w[ØO].each do |s|
        text.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
      end

      codepoints = text.mb_chars.normalize(:d).split(//u)
      ascii = codepoints.map(&:to_s).reject { |e| e.length > 1 }.join

      last_name_matches = Person.where(last_name: ascii)
      matches = last_name_matches
    end
    # when importing multiple bibtex file, the name matching need to be exact
    if exact
      unless  matches.empty?
        first_and_last_name_matches = matches.select { |p| p.first_name.casecmp(author.first_name.upcase).zero? }
        unless first_and_last_name_matches.empty?
          return first_and_last_name_matches.first
        else
          return nil
        end
      else
        return nil
      end
  end

    # If more than one result, filter by project
    if matches.size > 1
      project_matches = matches.select { |p| p.member_of?(projects) }
      matches = project_matches if project_matches.size >= 1 # use this result unless it resulted in no matches
    end

    # If more than one result, filter by first initial
    if matches.size > 1
      first_and_last_name_matches = matches.select { |p| p.first_name.at(0).casecmp(author.first_name.at(0).upcase).zero? }
      if first_and_last_name_matches.size >= 1 # use this result unless it resulted in no matches
        matches = first_and_last_name_matches
      end
    end

    # Take the first match as the guess
    matches.first
  end

  #ToDo move it to somewhere else
  def has_umlaut(str)
    !!(str =~ /[öäüÖÄÜß]/)
  end

  def has_non_umlaut(str)
    ["ae","oe","ue","ss"].any? {|non_umlaut| str.include? non_umlaut}
  end

  def replace_to_non_umlaut (str)
    replace_str = str.gsub(/[äöüß]/) do |match|
      case match
      when "ä" then 'ae'
      when "ö" then 'oe'
      when "ü" then 'ue'
      when "ß" then 'ss'
      end
    end
    replace_str
  end

  def replace_to_umlaut (str)
    replace_str = str.gsub(/(ae|oe|ue|ss)/) do |match|
      case match
      when "ae" then 'ä'
      when "oe" then 'ö'
      when "ue" then 'ü'
      when "ss" then 'ß'
      end
    end
    replace_str
  end
end
