class SearchController < ApplicationController

  def index

    if Seek::Config.solr_enabled
      perform_search()
    else
      @results = []
    end

    #strip out nils, which can occur if the index is out of sync
    @results = @results.select{|r| !r.nil?}

    @results = select_authorised @results
    if @results.empty?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'."
    else
      flash.now[:notice]="#{@results.size} #{@results.size==1 ? 'item' : 'items'} matched '<b>#{@search_query}</b>' within their title or content."
    end
    
  end

  def perform_search
    @search_query = params[:search_query]
    @search=@search_query # used for logging, and logs the origin search query - see ApplicationController#log_event
    @search_query||=""
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?

    if @search_query.start_with?("*") || @search_query.start_with?("?")
      flash.now[:error]="You cannot start a query with a wildcard, so this was removed. You CAN however include wildcards at the end or within the query."
      @search_query=@search_query[1..-1] while @search_query.start_with?("*") || @search_query.start_with?("?")
    end

    @search_query.strip!

    #if you use colon in query, solr understands that field_name:value, so if you put the colon at the end of the search query, solr will throw exception
    #remove the : if the string ends with :
    if @search_query.ends_with?':'
      flash.now[:error]="You cannot end a query with a colon, so this was removed"
      @search_query.chop!
    end

    downcase_query = @search_query.downcase

    @results=[]
    if (Seek::Config.solr_enabled and !downcase_query.blank?)
      case (type)
        when ("people")
          @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person]).results
        when ("institutions")
          @results = Institution.multi_solr_search(downcase_query, :limit=>100, :models=>[Institution]).results
        when ("projects")
          @results = Project.multi_solr_search(downcase_query, :limit=>100, :models=>[Project]).results
        when ("sops")
          @results = Sop.multi_solr_search(downcase_query, :limit=>100, :models=>[Sop]).results
          search_in_experimental_conditions
          search_in_compounds 'sop'
          search_in_mappings 'sop'
        when ("studies")
          @results = Study.multi_solr_search(downcase_query, :limit=>100, :models=>[Study]).results
        when ("models")
          @results = Model.multi_solr_search(downcase_query, :limit=>100, :models=>[Model]).results
        when ("data files")
          @results = DataFile.multi_solr_search(downcase_query, :limit=>100, :models=>[DataFile]).results
          search_in_factors_studieds
          search_in_compounds 'data_file'
          search_in_mappings 'data_file'
        when ("investigations")
          @results = Investigation.multi_solr_search(downcase_query, :limit=>100, :models=>[Investigation]).results
        when ("assays")
          @results = Assay.multi_solr_search(downcase_query, :limit=>100, :models=>[Assay]).results
        when ("publications")
          @results = Publication.multi_solr_search(downcase_query, :limit=>100, :models=>[Publication]).results
        when ("specimens")
          @results = Specimen.multi_solr_search(downcase_query, :limit=>100, :models=>[Specimen]).results
        when ("samples")
          @results = Sample.multi_solr_search(downcase_query, :limit=>100, :models=>[Sample]).results
        else
          sources = [Person, Project, Institution, Sop, Model, Study, DataFile, Assay, Investigation, Publication,Sample,Specimen]
          unless Seek::Config.is_virtualliver
            sources.delete(Sample)
            sources.delete(Specimen)
          end
          @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>sources).results
          search_in_factors_studieds
          search_in_experimental_conditions
          search_in_compounds
          search_in_mappings
      end
    end
  end

  private  

  #Removes all results from the search results collection passed in that are not Authorised to show for the current user (if one is logged in)
  def select_authorised collection
    collection.select {|el| el.can_view?}
  end

  def search_in_factors_studieds
    downcase_query = @search_query.downcase
    factors_studies = StudiedFactor.multi_solr_search(downcase_query, :limit=>100, :models=>[StudiedFactor]).results
    unless factors_studies.blank?
      factors_studies.each do |fs|
        @results.push(fs.data_file) if !@results.include? fs.data_file
      end
    end
  end

  def search_in_experimental_conditions
    downcase_query = @search_query.downcase
    experimental_conditions = ExperimentalCondition.multi_solr_search(downcase_query, :limit=>100, :models=>[ExperimentalCondition]).results
    unless experimental_conditions.blank?
      experimental_conditions.each do |ec|
          @results.push(ec.sop) if !@results.include? ec.sop
      end
    end
  end

  def search_in_compounds return_item=nil
    downcase_query = @search_query.downcase
    compounds = Compound.multi_solr_search(downcase_query, :limit=>100, :models=>[Compound]).results
    data_files = []
    sops = []
    #retrieve the items associated with the compound
    unless compounds.blank?
        compounds.each do |c|
           c.studied_factor_links.each do |sfl|
             data_files.push sfl.studied_factor.data_file if try_block{sfl.studied_factor.data_file}
           end
           c.experimental_condition_links.each do |ecl|
             sops.push ecl.experimental_condition.sop if try_block{ecl.experimental_condition.sop}
           end
        end
    end

    if return_item == 'data_file'
      #| unions 2 arrays and removes duplicates
      @results |= data_files
    elsif return_item == 'sop'
      @results |= sops
    else
      @results |= data_files
      @results |= sops
    end
  end

  def search_in_mappings return_item=nil
    downcase_query = @search_query.downcase
    #when the query contains :, solr understands it as column:value. To avoid the problem when searching chebi_id in mappings table, the : is replaced by .
    downcase_query[/:/] = '.' if downcase_query.match('chebi:')

    mappings = Mapping.multi_solr_search(downcase_query, :limit=>100, :models=>[Mapping]).results
    data_files = []
    sops = []
    #retrieve the items associated with the mapping fields
    unless mappings.blank?
      mappings.each do |mapping|
        mapping.mapping_links.each do |ml|
          ml.substance.studied_factor_links.each do |sfl|
            data_files.push sfl.studied_factor.data_file if try_block{sfl.studied_factor.data_file}
          end
          ml.substance.experimental_condition_links.each do |ecl|
            sops.push ecl.experimental_condition.sop if try_block{ecl.experimental_condition.sop}
          end
        end
      end
    end

    if return_item == 'data_file'
      @results |= data_files
    elsif return_item == 'sop'
      @results |= sops
    else
      @results |= data_files
      @results |= sops
    end
  end
end





