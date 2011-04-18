class PublicationsController < ApplicationController
  
  include IndexPager
  include DotGenerator
  include Seek::TaggingCommon
  
  require 'pubmed_query_tool'
  
  #before_filter :login_required
  before_filter :find_assets, :only => [ :index ]
  before_filter :fetch_publication, :only => [:show, :edit, :update, :destroy]
  before_filter :associate_authors, :only => [:edit, :update]
  
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
      format.svg { render :text=>to_svg(@publication,params[:deep]=='false',@publication)}
      format.dot { render :text=>to_dot(@publication,params[:deep]=='false',@publication)}
      format.png { render :text=>to_png(@publication,params[:deep]=='false',@publication)}
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
  end

  # POST /publications
  # POST /publications.xml
  def create
    @publication = Publication.new(params[:publication])
    @publication.pubmed_id=nil if @publication.pubmed_id.blank?
    @publication.doi=nil if @publication.doi.blank?
    
    result = get_data(@publication, @publication.pubmed_id, @publication.doi)
    assay_ids = params[:assay_ids] || []
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

        assay_ids.each do |id|
          assay = Assay.find(id)
          Relationship.create_or_update_attributions(@assay,["Publication", @publication.id].to_json, Relationship::RELATED_TO_PUBLICATION) if assay.can_edit?
        end
        #Make a policy
        policy = Policy.create(:name => "publication_policy", :sharing_scope => 4, :access_type => 1, :use_custom_sharing => true)
        @publication.policy = policy
        @publication.save
        #add managers (authors + contributor)
        @publication.creators.each do |author|
          policy.permissions << Permission.create(:contributor => author, :policy => policy, :access_type => 4)
        end
        #Add contributor
        @publication.policy.permissions << Permission.create(:contributor => @publication.contributor.person, :policy => policy, :access_type => 4)
        
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
    params[:author].keys.sort.each do |author_id|
      author_assoc = params[:author][author_id]
      unless author_assoc.blank?
        to_remove << PublicationAuthor.find_by_id(author_id)
        p = Person.find(author_assoc)
        if @publication.creators.include?(p)
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

    update_tags @publication

    assay_ids = params[:assay_ids] || []

    respond_to do |format|
      publication_params = params[:publication]||{}
      publication_params[:event_ids] = params[:event_ids]||[]
      if valid && @publication.update_attributes(publication_params)
        to_add.each {|a| @publication.creators << a}
        to_remove.each {|a| a.destroy}

        # Update relationship
        assays = Assay.find assay_ids
        assays.each do |assay|
          Relationship.create_or_update_attributions(@assay,{"Publication", @publication.id}.to_json, Relationship::RELATED_TO_PUBLICATION) if assay.can_edit? and Relationship.find_all_by_object_id(@publication.id, :conditions => "subject_id = #{assay_id}").empty?
        end
        #Destroy relationship that aren't needed
        associate_relationships = Relationship.find_all_by_object_id(@publication.id)
        associate_relationships.each do |associate_relationship|
          unless associate_relationship.subject.can_edit? and assays.include? associate_relationship.subject
             Relationship.destroy(associate_relationship.id)
          end
        end

        #Create policy if not present (should be)
        if @publication.policy.nil?
          @publication.policy = Policy.create(:name => "publication_policy", :sharing_scope => 4, :access_type => 1, :use_custom_sharing => true)
          @publication.save
        end
        
        #Update policy so current authors have manage permissions
        @publication.creators.each do |author|
          @publication.policy.permissions.clear
          @publication.policy.permissions << Permission.create(:contributor => author, :policy => @publication.policy, :access_type => 4)
        end      
        #Add contributor
        @publication.policy.permissions << Permission.create(:contributor => @publication.contributor.person, :policy => @publication.policy, :access_type => 4)
        
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
    begin
      @publication = Publication.new(params[:publication])
      @publication.project_id = params[:project_id]
      key = params[:key]
      protocol = params[:protocol]
      pubmed_id = nil
      doi = nil
      if protocol == "pubmed"
        pubmed_id = key
      elsif protocol == "doi"
        doi = key
        if doi.start_with?("doi:")
          doi = doi.gsub("doi:","")
        end
      end      
      result = get_data(@publication, pubmed_id, doi)
    rescue
      if protocol == "pubmed"
        if key.match(/[0-9]+/).nil?
          @error_text = "Please ensure the PubMed ID is entered in the correct format, e.g. <i>16845108</i>"
        else
          @error_text = "No publication could be found on PubMed with that ID"  
        end
      elsif protocol == "doi"
        if key.match(/[0-9]+(\.)[0-9]+.*/).nil?
          @error_text = "Please ensure the DOI is entered in the correct format, e.g. <i>10.1093/nar/gkl320</i>"
        else
          @error_text = "No valid publication could be found with that DOI"
        end
      end          
      respond_to do |format|
        format.html { render :partial => "publications/publication_error", :locals => { :publication => @publication, :error_text => @error_text}, :status => 500}
      end
    else
      respond_to do |format|
        format.html { render :partial => "publications/publication_preview", :locals => { :publication => @publication, :authors => result.authors} }
      end
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
    @publication.creators.clear #get rid of author links
    @publication.non_seek_authors.clear
    
    #Query pubmed article to fetch authors
    result = nil
    pubmed_id = @publication.pubmed_id
    doi = @publication.doi
    if pubmed_id
      query = PubmedQuery.new("seek",Seek::Config.pubmed_api_email)
      result = query.fetch(pubmed_id)      
    elsif doi
      query = DoiQuery.new(Seek::Config.crossref_api_email)
      result = query.fetch(doi)
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
      
      if publication.can_perform? translate_action(action_name)
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
      query = PubmedQuery.new("sysmo-seek",Seek::Config.pubmed_api_email)
      result = query.fetch(pubmed_id)
      unless result.nil?
        publication.extract_pubmed_metadata(result)
        return result
      else
        raise "Error - No publication could be found with that PubMed ID"
      end    
    elsif !doi.nil?
      query = DoiQuery.new(Seek::Config.crossref_api_email)
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
