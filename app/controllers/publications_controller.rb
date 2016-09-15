#encoding: utf-8
class PublicationsController < ApplicationController
  
  include Seek::IndexPager
  include Seek::AssetsCommon
  include Seek::BioExtension
  include Seek::PreviewHandling

  before_filter :publications_enabled?

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :only => [:show, :edit, :update, :destroy]
  before_filter :associate_authors, :only => [:edit, :update]

  include Seek::BreadCrumbs

  include Seek::IsaGraphExtensions
    
  # GET /publications/1
  # GET /publications/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml
      format.rdf { render :template=>'rdf/show'}
      format.any( *Publication::EXPORT_TYPES.keys ) { send_data @publication.export(request.format.to_sym), :type => request.format.to_sym, :filename => "#{@publication.title}.#{request.format.to_sym}" }
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
    publication_params = params[:publication].dup

    @subaction = params[:subaction] || 'Register'

    # publication authors need to be added separately
    publication_params.delete(:publication_authors)

    @publication = Publication.new(publication_params)
    @publication.pubmed_id=nil if @publication.pubmed_id.blank?
    @publication.doi=nil if @publication.doi.blank?
    pubmed_id,doi = preprocess_doi_or_pubmed @publication.pubmed_id,@publication.doi
    @publication.doi = doi
    @publication.pubmed_id = pubmed_id

    if @subaction == 'Register'
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
      else # Publication save not successful
        respond_to do |format|
          format.html { render :action => "new" }
          format.xml  { render :xml => @publication.errors, :status => :unprocessable_entity }
        end
      end
    end # Register publication from doi or pubmedid

    if @subaction == 'Create'
      assay_ids = params[:assay_ids] || []
      # create publication authors
      plain_authors = params[:publication][:publication_authors]
      # plain_authors.split(',').each_with_index do |author, index| # text_field
      plain_authors.each_with_index do |author, index| # multiselect
        if author.empty?
          next
        end
        first_name, last_name = PublicationAuthor.split_full_name author
        pa = PublicationAuthor.new({
          :publication  => @publication,
          :first_name   => first_name,
          :last_name    => last_name,
          :author_index => index
        })
        @publication.publication_authors << pa
      end

      if @publication.save
        update_scales @publication

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
      else # Publication save not successful
        respond_to do |format|
          format.html { render :action => "new" }
          format.xml  { render :xml => @publication.errors, :status => :unprocessable_entity }
        end
      end
    end # Create publication from all fields
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

    update_annotations(params[:tag_list], @publication)

    investigation_ids = params[:investigation_ids] || []
    study_ids = params[:study_ids] || []
    assay_ids = params[:assay_ids] || []
    data_files = params[:data_files] || []
    model_ids = params[:model_ids] || []

    respond_to do |format|
      publication_params = params[:publication]||{}
      if valid && @publication.update_attributes(publication_params)

        # Update association
        create_or_update_associations investigation_ids, "Investigation", "view"
        create_or_update_associations study_ids, "Study", "view"
        create_or_update_associations assay_ids, "Assay", "edit"

        data_files = data_files.map { |df| df['id'] }
        create_or_update_associations data_files, "DataFile", "view"

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
    if !@error.nil?
      if protocol == "pubmed"
        @error_text = @error
      elsif protocol == "doi"
        if key.match(/[0-9]+(\.)[0-9]+.*/).nil?
          @error_text = "Couldn't retrieve DOI: #{doi} - please ensure the DOI is entered in the correct format, e.g. 10.1093/nar/gkl320"
        else
          @error_text = "Couldn't retrieve DOI: #{doi} - #{@error}"
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

  def query_authors
    # query authors by first and last name each
    authors_q = params[:authors]

    if !authors_q
      error = "require query parameter authors"
      respond_to do |format|
          format.json { render :json => { :error => error }, :status => 422 }
          format.xml  { render :xml => { :error => error }, :status => 422 }
      end
    end

    authors = []
    authors_q.each { |author_i, author_q|
      params = { :first_name => author_q['first_name'], :last_name => author_q['last_name'] }

      authors_db = PublicationAuthor.where(params)
                                    .select([:person_id, :first_name, :last_name])
                                    .group( :person_id, :first_name, :last_name)
                                    .count
                                    .collect {
        |groups, count| {
          :person_id => groups[0],
          :first_name => groups[1],
          :last_name => groups[2],
          :count => count
        }
      }

      if !authors_db.empty? # found at least one author
        authors << authors_db[0]
      else # no author found
        users_db = Person.where(params)
        if !users_db.empty? # is there a person with that name
          user = users_db[0]
          authors << { :name => user.name }
        else # just add the queried name as author
          authors << { :person_id => nil, :first_name => author_q['first_name'], :last_name => author_q['last_name'], :count => 0 }
        end
      end
    }

    respond_to do |format|
      format.json { render :json => authors }
      format.xml  { render :xml  => authors }
    end
  end

  def query_authors_typeahead
    full_name  = params[:full_name]
    if !full_name
      error = "require query parameter full_name"
      respond_to do |format|
        format.json { render :json => { :error => error }, :status => 422 }
        format.xml  { render :xml  => { :error => error }, :status => 422 }
      end
    end

    first_name, last_name = PublicationAuthor.split_full_name full_name

    # all authors
    authors = PublicationAuthor.where("first_name LIKE :fnquery", :fnquery => "#{first_name}%")
                               .where("last_name LIKE :lnquery", :lnquery => "#{last_name}%")
                               .select([:person_id, :first_name, :last_name])
                               .group( :person_id, :first_name, :last_name)
                               .count
                               .collect { 
      |groups, count| {
        :person_id => groups[0],
        :first_name => groups[1],
        :last_name => groups[2],
        :count => count
      }
    }
    authors.delete_if { |author| author[:first_name].empty? && author[:last_name].empty? }
    author = PublicationAuthor.where({ :first_name => first_name, :last_name => last_name}).limit(1)

    # add the queried author if he does not exist
    if author.empty?
      authors << { :person_id => nil, :first_name => first_name, :last_name => last_name, :count => 0 }
    end

    respond_to do |format|
      format.json { render :json => authors }
      format.xml  { render :xml  => authors }
    end
  end
  
  #Try and relate non_seek_authors to people in SEEK based on name and project
  def associate_authors
    publication = @publication
    projects = publication.projects
    projects = current_person.projects if projects.empty?
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
    @error = nil
    if pubmed_id
      begin
        result = Bio::MEDLINE.new(Bio::PubMed.efetch(pubmed_id).first).reference
        @error = result.error
      rescue => exception
        result ||= Bio::Reference.new({})
        @error = "There was a problem contacting the PubMed query service. Please try again later"
        if Seek::Config.exception_notification_enabled
          ExceptionNotifier.notify_exception(exception,:data=>{:message=>"Problem accessing ncbi using pubmed id #{pubmed_id}"})
        end
      end
    elsif doi
      begin
        query = DoiQuery.new(Seek::Config.crossref_api_email)
        result = query.fetch(doi)
      rescue RuntimeError => exception
        @error = "There was an problem contacting the DOI query service. Please try again later"
        if Seek::Config.exception_notification_enabled
          ExceptionNotifier.notify_exception(exception,:data=>{:message=>"Problem accessing crossref using DOI #{doi}"})
        end
      end
    end
    result
  end

  def get_data(publication, pubmed_id, doi=nil)
    result = fetch_pubmed_or_doi_result(pubmed_id,doi)
    publication.extract_metadata(result) unless @error
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
        @publication.associate(asset)
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
