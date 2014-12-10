#encoding: utf-8
class PublicationsController < ApplicationController
  
  include IndexPager
  include DotGenerator
  include Seek::AssetsCommon
  include Seek::BioExtension

  before_filter :publications_enabled?

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :only => [:show, :edit, :update, :destroy]
  before_filter :associate_authors, :only => [:edit, :update]

  include Seek::BreadCrumbs
    
  # GET /publications/1
  # GET /publications/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml
      format.rdf { render :template=>'rdf/show'}
      format.enw { send_data @publication.endnote, :type => "application/x-endnote-refer", :filename => "#{@publication.title}.enw" }
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
  def edit
  end

  # POST /publications
  # POST /publications.xml
  def create
    @publication = Publication.new(params[:publication])
    @publication.pubmed_id=nil if @publication.pubmed_id.blank?
    @publication.doi=nil if @publication.doi.blank?
    pubmed_id,doi = preprocess_doi_or_pubmed @publication.pubmed_id,@publication.doi
    @publication.doi = doi
    @publication.pubmed_id = pubmed_id
    result = get_data(@publication, @publication.pubmed_id, @publication.doi)
    assay_ids = params[:assay_ids] || []

      if @publication.save
        update_scales @publication
        result.authors.each_with_index do |author, index|
          pa = PublicationAuthor.new()
          pa.publication = @publication
          pa.first_name = author.first_name
          pa.last_name = author.last_name
          pa.author_index = index
          pa.save
        end

        create_or_update_associations assay_ids, "Assay", "edit"
        if !@publication.parent_name.blank?
          render :partial=>"assets/back_to_fancy_parent", :locals=>{:child=>@publication, :parent_name=>@publication.parent_name}
        else
          respond_to do |format|
            flash[:notice] = 'Publication was successfully created.'
            format.html { redirect_to(edit_publication_url(@publication)) }
            format.xml  { render :xml => @publication, :status => :created, :location => @publication }
          end
        end
      else
        respond_to do |format|
          format.html { render :action => "new" }
          format.xml  { render :xml => @publication.errors, :status => :unprocessable_entity }
        end
      end
  end

  # PUT /publications/1
  # PUT /publications/1.xml
  def update
    valid = true
    unless params[:author].blank?
      person_ids = params[:author].values.reject {|id_string| id_string == ""}
      if person_ids.uniq.size == person_ids.size
        params[:author].keys.sort.each do |author_id|
          author_assoc = params[:author][author_id]
          unless author_assoc.blank?
            @publication.publication_authors.detect{|pa| pa.id == author_id.to_i}.person = Person.find(author_assoc)
          end
        end
      else
      @publication.errors[:base] << "Multiple authors cannot be associated with the same SEEK person."
        valid = false
      end
    end

    update_annotations @publication

    assay_ids = params[:assay_ids] || []
    data_file_ids = params[:data_file_ids] || []
    model_ids = params[:model_ids] || []

    respond_to do |format|
      publication_params = params[:publication]||{}
      if valid && @publication.update_attributes(publication_params)

        # Update association
        create_or_update_associations assay_ids, "Assay", "edit"

        data_file_ids = data_file_ids.collect{|data_file_id| data_file_id.split(',').first}
        create_or_update_associations data_file_ids, "DataFile", "view"

        create_or_update_associations model_ids, "Model", "view"

        #Create policy if not present (should be)
        if @publication.policy.nil?
          @publication.policy = Policy.create(:name => "publication_policy", :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)
          @publication.save
        end
        
        #Update policy so current authors have manage permissions
        @publication.creators.each do |author|
          @publication.policy.permissions.clear
          @publication.policy.permissions << Permission.create(:contributor => author, :policy => @publication.policy, :access_type => Policy::MANAGING)
        end      
        #Add contributor
        @publication.policy.permissions << Permission.create(:contributor => @publication.contributor.person, :policy => @publication.policy, :access_type => Policy::MANAGING)

        update_scales @publication

        flash[:notice] = 'Publication was successfully updated.'
        format.html { redirect_to(@publication) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @publication.errors, :status => :unprocessable_entity }
      end
    end
  end

  def fetch_preview
    #trim the PubMed or Doi Id
    params[:key] = params[:key].strip() unless params[:key].blank?
    params[:publication][:project_ids].reject!(&:blank?).map! { |id| id.split(',') }.flatten!
    @publication = Publication.new(params[:publication])
    key = params[:key]
    protocol = params[:protocol]
    pubmed_id = nil
    doi = nil
    if protocol == "pubmed"
      pubmed_id = key
    elsif protocol == "doi"
      doi = key
    end
    pubmed_id,doi = preprocess_doi_or_pubmed pubmed_id,doi
    result = get_data(@publication, pubmed_id, doi)
    if !result.error.nil?
      if protocol == "pubmed"
        @error_text = result.error
      elsif protocol == "doi"
        if key.match(/[0-9]+(\.)[0-9]+.*/).nil?
          @error_text = "There was a problem with #{result.doi} - please ensure the DOI is entered in the correct format, e.g. <i>10.1093/nar/gkl320</i>"
        else
          @error_text = "There was a problem with #{result.doi} - #{result.error} ."
        end
      end

      render :update do |page|
        page[:publication_preview_container].hide
        page[:publication_error].show
        page[:publication_error].replace_html(render(:partial => "publications/publication_error", :locals => {:publication => @publication, :error_text => @error_text}, :status => 500 ))
      end

    else
      render :update do |page|
        page[:publication_error].hide
        page[:publication_preview_container].show
        page[:publication_preview_container].replace_html(render(:partial => "publications/publication_preview", :locals => {:publication => @publication, :authors => result.authors}))
      end
    end

  end
  
  #Try and relate non_seek_authors to people in SEEK based on name and project
  def associate_authors
    publication = @publication
    projects = publication.projects
    projects = current_user.person.projects if projects.empty?
    association = {}
    publication.publication_authors.each do |author|
      unless author.person
        matches = []
        #Get author by last name
        last_name_matches = Person.find_all_by_last_name(author.last_name)
        matches = last_name_matches
        #If no results, try searching by normalised name, taken from grouped_pagination.rb
        if matches.size < 1
          text = author.last_name
          #handle the characters that can't be handled through normalization
          %w[ØO].each do |s|
            text.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
          end

          codepoints = text.mb_chars.normalize(:d).split(//u)
          ascii=codepoints.map(&:to_s).reject { |e| e.length > 1 }.join

          last_name_matches = Person.find_all_by_last_name(ascii)
          matches = last_name_matches
        end

        #If more than one result, filter by project
        if matches.size > 1
          project_matches = matches.select { |p| p.member_of?(projects) }
          if project_matches.size >= 1 #use this result unless it resulted in no matches
            matches = project_matches
          end
        end

        #If more than one result, filter by first initial
        if matches.size > 1
          first_and_last_name_matches = matches.select { |p| p.first_name.at(0).upcase == author.first_name.at(0).upcase }
          if first_and_last_name_matches.size >= 1 #use this result unless it resulted in no matches
            matches = first_and_last_name_matches
          end
        end

        #Take the first match as the guess
        association[author.id] = matches.first
      else
        association[author.id] = author.person
      end
    end
    
    @author_associations = association
  end
  
  def disassociate_authors
    @publication = Publication.find(params[:id])
    @publication.creators.clear #get rid of author links
    @publication.publication_authors.clear
    
    #Query pubmed article to fetch authors
    result = fetch_pubmed_or_doi_result @publication.pubmed_id, @publication.doi

    unless result.nil?
      result.authors.each_with_index do |author, index|
        pa = PublicationAuthor.new()
        pa.publication = @publication
        pa.first_name = author.first_name
        pa.last_name = author.last_name
        pa.author_index = index
        pa.save
      end
    end
    respond_to do |format|
      format.html { redirect_to(edit_publication_url(@publication)) }
      format.xml  { head :ok }
    end
  end

  def fetch_pubmed_or_doi_result pubmed_id,doi
    result = nil
    if pubmed_id
      begin
        result = Bio::MEDLINE.new(Bio::PubMed.efetch(pubmed_id).first).reference
      rescue => exception
        result ||= Bio::Reference.new({})
        result.error = "There was an problem contacting the pubmed query service. Please try again later"
        if Seek::Config.exception_notification_enabled
          ExceptionNotifier.notify_exception(exception,:data=>{:message=>"Problem accessing ncbi using pubmed id #{pubmed_id}"})
        end
      end
    elsif doi
      query = DoiQuery.new(Seek::Config.crossref_api_email)
      result = query.fetch(doi)
    end
    result
  end

  def get_data(publication, pubmed_id, doi=nil)
    result = fetch_pubmed_or_doi_result(pubmed_id,doi)
    publication.extract_metadata(result) unless result.error
    result
  end
        
  private

  def preprocess_doi_or_pubmed pubmed_id,doi
    doi = doi.sub(%r{doi\.*:}i,"").strip unless doi.nil?
    doi.strip! unless doi.nil?
    pubmed_id.strip! unless pubmed_id.nil? || pubmed_id.is_a?(Fixnum)
    return pubmed_id,doi
  end



  def create_or_update_associations asset_ids, asset_type, required_action
    asset_ids.each do |id|
      asset = asset_type.constantize.find_by_id(id)
      if asset && asset.send("can_#{required_action}?")
        unless Relationship.where(:subject_type => asset_type, :subject_id => asset.id, :predicate => Relationship::RELATED_TO_PUBLICATION, :other_object_type => "Publication", :other_object_id => @publication.id).first
          Relationship.create(:subject_type => asset_type, :subject_id => asset.id, :predicate => Relationship::RELATED_TO_PUBLICATION, :other_object_type => "Publication", :other_object_id => @publication.id)
        end
      end
    end
    #Destroy asset relationship that aren't needed
    associate_relationships = Relationship.where(["other_object_id = ? and subject_type = ?",@publication.id,asset_type]).all
    associate_relationships.each do |associate_relationship|
      asset = associate_relationship.subject
      if asset.send("can_#{required_action}?") && !asset_ids.include?(asset.id.to_s)
        associate_relationship.destroy
      end
    end
  end
end
