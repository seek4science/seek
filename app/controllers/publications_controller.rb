class PublicationsController < ApplicationController
  
  require 'pubmed_query_tool'
  
  before_filter :login_required
  before_filter :fetch_publication, :only => [:show, :edit, :update, :destroy]
  before_filter :associate_authors, :only => [:edit, :update]

  ADMIN_EMAIL = "bacallf7@cs.man.ac.uk"
  
  # GET /publications
  # GET /publications.xml
  def index
    @publications = Publication.paginate :page=>params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @publications }
    end
  end

  # GET /publications/1
  # GET /publications/1.xml
  def show

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @publication }
    end
  end

  # GET /publications/new
  # GET /publications/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml 
    end
  end

  # GET /publications/1/edit
  def edit
    #This is necessary due to weirdness with acts_as_resource
    @publication.project_id = @publication.asset.project_id
  end

  # POST /publications
  # POST /publications.xml
  def create
    @publication = Publication.new()
    pubmed_id = params[:publication][:pubmed_id]
    pubmed_id = nil if pubmed_id.blank?
    doi = params[:publication][:doi]
    doi = nil if doi.blank?
    result = get_data(@publication, pubmed_id, doi)
    @publication.contributor = current_user    
    respond_to do |format|
      if @publication.save
        result.authors.each do |author|
          pa = PublicationAuthor.new()
          pa.publication = @publication
          pa.first_name = author.first_name
          pa.last_name = author.last_name
          pa.save
        end
        
        #Make a policy
        policy = Policy.create(:name => "publication_policy", :sharing_scope => 3, :access_type => 1, :use_custom_sharing => true)
        @publication.asset.policy = policy
        @publication.asset.save
        #add managers (authors + contributor)
        @publication.asset.creators.each do |author|
          policy.permissions << Permission.create(:contributor => author, :policy => policy, :access_type => 4)
        end
        #Add contributor
        @publication.asset.policy.permissions << Permission.create(:contributor => @publication.contributor.person, :policy => policy, :access_type => 4)
        
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
    params[:author].each_key do |author_id|
      author_assoc = params[:author][author_id]
      unless author_assoc.blank?
        to_remove << PublicationAuthor.find_by_id(author_id)
        p = Person.find(author_assoc)
        if @publication.asset.creators.include?(p)
          @publication.errors.add_to_base("Multiple authors cannot be associated with the same SEEK person.")
          valid = false
        else
          to_add << p
        end
      end
    end
    
    #Check for duplicate authors
    if valid && (to_add.uniq.size != to_add.size)
      @publication.errors.add_to_base("Multiple authors cannot be associated with the same SEEK person.")
      valid = false
    end

    respond_to do |format|
      if valid && @publication.update_attributes(params[:publication]) 
        to_add.each {|a| @publication.asset.creators << a}
        to_remove.each {|a| a.destroy}
        
        #Create policy if not present (should be)
        if @publication.asset.policy.nil?
          @publication.asset.policy = Policy.create(:name => "publication_policy", :sharing_scope => 3, :access_type => 1, :use_custom_sharing => true)
          @publication.asset.save
        end
        
        #Update policy so current authors have manage permissions
        @publication.asset.creators.each do |author|
          @publication.asset.policy.permissions.clear
          @publication.asset.policy.permissions << Permission.create(:contributor => author, :policy => @publication.asset.policy, :access_type => 4)
        end      
        #Add contributor
        @publication.asset.policy.permissions << Permission.create(:contributor => @publication.contributor.person, :policy => @publication.asset.policy, :access_type => 4)
        
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
      format.html { redirect_to(publications_url) }
      format.xml  { head :ok }
    end
  end
  
  def fetch_preview
    @publication = Publication.new
    key = params[:key]
    protocol = params[:protocol]
    pubmed_id = nil
    doi = nil
    if protocol == "pubmed"
      pubmed_id = key
    elsif protocol == "doi"
      doi = key
    end
    
    result = get_data(@publication, pubmed_id, doi)

    respond_to do |format|
      format.html { render :partial => "publications/publication_preview", :locals => { :publication => @publication, :authors => result.authors} }
    end
  end
  
  #Try and relate non_seek_authors to people in SEEK based on name and project
  def associate_authors
    publication = @publication
    project = publication.project || current_user.person.projects.first
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
        project_matches = matches.select{|p| p.projects.include?(project)}
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
    @publication.asset.creators.clear #get rid of author links
    @publication.non_seek_authors.clear
    
    #Query pubmed article to fetch authors
    result = nil
    pubmed_id = @publication.pubmed_id
    doi = @publication.doi
    if pubmed_id
      query = PubmedQuery.new("sysmo-seek",ADMIN_EMAIL)
      results = query.fetch([pubmed_id])
      unless results.empty?
        result = results.first
      end
    elsif doi
      query = DoiQuery.new(ADMIN_EMAIL)
      result = query.fetch(pubmed_id)
    end      
    unless result.nil?
      result.authors.each do |author|
        pa = PublicationAuthor.new()
        pa.publication = @publication
        pa.first_name = author.first_name
        pa.last_name = author.last_name
        pa.save
      end
    end
    respond_to do |format|
      format.html { redirect_to(edit_publication_url(@publication)) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def fetch_publication
    begin
      publication = Publication.find(params[:id])            
      
      if Authorization.is_authorized?(action_name, nil, publication, current_user)
        @publication = publication
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to publications_path  }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the publication"
        format.html { redirect_to publications_path }
      end
      return false
    end
  end
  
  def get_data(publication, pubmed_id, doi=nil)
    if !pubmed_id.nil?
      query = PubmedQuery.new("sysmo-seek",ADMIN_EMAIL)
      results = query.fetch([pubmed_id])
      result = nil
      unless results.empty?
        result = results.first
        publication.extract_pubmed_metadata(result) unless result.nil?
        return result
      else
        raise "Error - No publication could be found with that PubMed ID"
      end    
    elsif !doi.nil?
      query = DoiQuery.new(ADMIN_EMAIL)
      result = query.fetch(doi)
      unless result.nil?
        publication.extract_doi_metadata(result)
        return result
      else 
        raise "Error - No publication could be found with that DOI"
      end  
    end
  end
end