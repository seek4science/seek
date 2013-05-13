class PublicationsController < ApplicationController
  
  include IndexPager
  include DotGenerator
  include Seek::AssetsCommon
  
  require 'pubmed_query_tool'
  
  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_auth, :only => [:show, :edit, :update, :destroy]
  before_filter :associate_authors, :only => [:edit, :update]

  include Seek::BreadCrumbs

  def preview
    element=params[:element]
    @publication = Publication.find_by_id(params[:id])
    render :update do |page|
      if @publication
        page.replace_html element,:partial=>"publications/resource_preview",:locals=>{:resource=>@publication}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end    
    
  # GET /publications/1
  # GET /publications/1.xml
  def show

    respond_to do |format|
      format.html # show.html.erb
      format.xml
      format.rdf { render :template=>'rdf/show'}
      format.svg { render :text=>to_svg(@publication,params[:deep]=='false',@publication)}
      format.dot { render :text=>to_dot(@publication,params[:deep]=='false',@publication)}
      format.png { render :text=>to_png(@publication,params[:deep]=='false',@publication)}
      format.enw { send_data @publication.endnote, :type => "application/x-endnote-refer", :filename => "#{@publication.title}.enw" }
    end
  end

  # GET /publications/new
  # GET /publications/new.xml
  def new
    @publication = Publication.new
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
    respond_to do |format|
      if @publication.save
        create_non_seek_authors result.authors

        create_or_update_associations assay_ids, "Assay", "edit"

        flash[:notice] = 'Publication was successfully created.'
        format.html { redirect_to(edit_publication_url(@publication)) }
        format.xml  { render :xml => @publication, :status => :created, :location => @publication }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @publication.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /publications/1
  # PUT /publications/1.xml
  def update
    valid = true
    to_add = []
    to_remove = []
    unless params[:author].blank?
      params[:author].keys.sort.each do |author_id|
        author_assoc = params[:author][author_id]
        unless author_assoc.blank?
          to_remove << PublicationAuthor.find_by_id(author_id)
          p = Person.find(author_assoc)
          if @publication.creators.include?(p)
            @publication.errors[:base] << "Multiple authors cannot be associated with the same SEEK person."
            valid = false
          else
            to_add << p
          end
        end
      end
    end
    
    #Check for duplicate authors
    if valid && (to_add.uniq.size != to_add.size)
      @publication.errors[:base] << "Multiple authors cannot be associated with the same SEEK person."
      valid = false
    end

    update_annotations @publication

    assay_ids = params[:assay_ids] || []
    data_file_ids = params[:data_file_ids] || []
    model_ids = params[:model_ids] || []

    respond_to do |format|
      publication_params = params[:publication]||{}
      if valid && @publication.update_attributes(publication_params)
        to_add.each_with_index do |a,i|
          @publication.creators << a
          removing_non_seek_author = to_remove[i]
          updating_publication_author_order = PublicationAuthorOrder.find(:all, :conditions => ["publication_id=? AND author_id=? AND author_type=?", @publication.id, removing_non_seek_author.id, 'PublicationAuthor' ]).first
          updating_publication_author_order.author = a
          updating_publication_author_order.save
        end
        to_remove.each {|a| a.destroy}

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
        
        flash[:notice] = 'Publication was successfully updated.'
        format.html { redirect_to(@publication) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @publication.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /publications/1
  # DELETE /publications/1.xml
  def destroy
    @publication.destroy

    respond_to do |format|
      format.html { redirect_to(publications_path) }
      format.xml  { head :ok }
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
        if key.match(/[0-9]+/).nil?
          @error_text = "Please ensure the PubMed ID is entered in the correct format, e.g. <i>16845108</i>"
        else
          @error_text = "No publication could be found on PubMed with that ID"
        end
      elsif protocol == "doi"
        if key.match(/[0-9]+(\.)[0-9]+.*/).nil?
          @error_text = "There was a problem with #{result.doi} - please ensure the DOI is entered in the correct format, e.g. <i>10.1093/nar/gkl320</i>"
        else
          @error_text = "There was a problem with #{result.doi} - #{result.error} ."
        end
      end

      respond_to do |format|
        format.html { render :partial => "publications/publication_error", :locals => {:publication => @publication, :error_text => @error_text}, :status => 500 }
      end

    else
      respond_to do |format|
        format.html { render :partial => "publications/publication_preview", :locals => {:publication => @publication, :authors => result.authors} }
      end
    end

  end
  
  #Try and relate non_seek_authors to people in SEEK based on name and project
  def associate_authors
    publication = @publication
    projects = publication.projects
    projects = current_user.person.projects if projects.empty?
    association = {}
    publication.non_seek_authors.each do |author|
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
        ascii=codepoints.map(&:to_s).reject{|e| e.length > 1}.join
  
        last_name_matches = Person.find_all_by_last_name(ascii)
        matches = last_name_matches
      end
      
      #If more than one result, filter by project
      if matches.size > 1
        project_matches = matches.select{|p| p.member_of?(projects)}
        if project_matches.size >= 1 #use this result unless it resulted in no matches
          matches = project_matches
        end
      end      
      
      #If more than one result, filter by first initial
      if matches.size > 1
        first_and_last_name_matches = matches.select{|p| p.first_name.at(0).upcase == author.first_name.at(0).upcase}
        if first_and_last_name_matches.size >= 1  #use this result unless it resulted in no matches
          matches = first_and_last_name_matches
        end
      end

      #Take the first match as the guess
      association[author.id] = matches.first
    end
    
    @author_associations = association
  end
  
  def disassociate_authors
    @publication = Publication.find(params[:id])
    @publication.creators.clear #get rid of author links
    @publication.non_seek_authors.clear
    @publication.publication_author_orders.clear
    
    #Query pubmed article to fetch authors
    result = fetch_pubmed_or_doi_result @publication.pubmed_id, @publication.doi

    unless result.nil?
      create_non_seek_authors result.authors
    end
    respond_to do |format|
      format.html { redirect_to(edit_publication_url(@publication)) }
      format.xml  { head :ok }
    end
  end

  def fetch_pubmed_or_doi_result pubmed_id,doi
    result = nil
    if pubmed_id
      query = PubmedQuery.new("seek",Seek::Config.pubmed_api_email)
      result = query.fetch(pubmed_id)
    elsif doi
      query = DoiQuery.new(Seek::Config.crossref_api_email)
      result = query.fetch(doi)
    end
    result
  end

  def create_non_seek_authors authors,publication=@publication
    authors.each_with_index do |author,index|
      pa = PublicationAuthor.new()
      pa.publication = publication
      pa.first_name = author.first_name
      pa.last_name = author.last_name
      pa.save
      pao = PublicationAuthorOrder.new()
      pao.publication = publication
      pao.order = index
      pao.author = pa
      pao.save
    end
  end

  private

  def preprocess_doi_or_pubmed pubmed_id,doi
    doi = doi.sub(%r{doi\.*:}i,"").strip unless doi.nil?
    doi.strip! unless doi.nil?
    pubmed_id.strip! unless pubmed_id.nil? || pubmed_id.is_a?(Fixnum)
    return pubmed_id,doi
  end

  def get_data(publication, pubmed_id, doi=nil)
    if !pubmed_id.nil?
      query = PubmedQuery.new("sysmo-seek",Seek::Config.pubmed_api_email)
      result = query.fetch(pubmed_id)
      unless result.nil? || !result.error.nil?
        publication.extract_pubmed_metadata(result)
      end
      return result
    elsif !doi.nil?
      query = DoiQuery.new(Seek::Config.crossref_api_email)
      result = query.fetch(doi)
      unless result.nil? || !result.error.nil?
        publication.extract_doi_metadata(result)
      end
      return result
    end
  end

  def create_or_update_associations asset_ids, asset_type, required_action
    asset_ids.each do |id|
      asset = asset_type.constantize.find_by_id(id)
      if asset && asset.send("can_#{required_action}?")
        unless Relationship.find(:first, :conditions => { :subject_type => asset_type, :subject_id => asset.id, :predicate => Relationship::RELATED_TO_PUBLICATION, :object_type => "Publication", :object_id => @publication.id })
          Relationship.create(:subject_type => asset_type, :subject_id => asset.id, :predicate => Relationship::RELATED_TO_PUBLICATION, :object_type => "Publication", :object_id => @publication.id)
        end
      end
    end
    #Destroy asset relationship that aren't needed
    associate_relationships = Relationship.find(:all,:conditions=>["object_id = ? and subject_type = ?",@publication.id,asset_type])
    associate_relationships.each do |associate_relationship|
      asset = associate_relationship.subject
      if asset.send("can_#{required_action}?") && !asset_ids.include?(asset.id.to_s)
        associate_relationship.destroy
      end
    end
  end
end
