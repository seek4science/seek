class CompoundsController < ApplicationController

  before_action :find_requested_item, :only=>[:show,:edit,:update,:destroy]
  before_action :login_required
  before_action :is_user_admin_auth
  before_action :find_all_compounds

  include Seek::FactorStudied
  include Seek::BreadCrumbs

  def index
    respond_to do |format|
      format.html
      format.xml
    end
  end

   def create
      compound = params[:compound]
      compound_name =  compound[:title]

        unless compound_name.blank?
           unless Compound.find_by_name(compound_name)
             @compound = Compound.new(:name => compound_name)

             compound_annotation = {}
             compound_annotation['recommended_name'] = compound_name
             compound_annotation['synonyms'] = compound[:synonyms].split(';').collect{|s| s.strip}
             compound_annotation['sabiork_id'] = compound[:sabiork_id].strip.to_i unless compound[:sabiork_id].blank?
             compound_annotation['chebi_ids'] = compound[:chebi_ids].split(';').collect{|s| s.strip}
             compound_annotation['kegg_ids'] = compound[:kegg_ids].split(';').collect{|s| s.strip}

             #create new or update mappings and mapping_links
             @compound = new_or_update_mapping_links @compound, compound_annotation

             #create new or update synonyms
             @compound = new_or_update_synonyms @compound, compound_annotation

             if @compound.save
               respond_to do |format|
                 format.js
               end
             else
               render plain: @compound.errors.full_messages, status: :unprocessable_entity
             end
           else
             render js: "alert('The compound #{compound_name} already exist in SEEK. You can update it from the list of compounds below');"
           end
        else
          render js: "alert('Please input the compound name');"
        end
   end

   def show
     respond_to do |format|
       format.rdf { render :template=>'rdf/show'}
     end
   end

   def update
      compound_name =  params["#{@compound.id}_title"]

      unless compound_name.blank?
         compound_annotation = {}
         compound_annotation['recommended_name'] = compound_name
         compound_annotation['synonyms'] = params["#{@compound.id}_synonyms"].split(';').collect{|s| s.strip}
         compound_annotation['sabiork_id'] = params["#{@compound.id}_sabiork_id"].strip.to_i unless params["#{@compound.id}_sabiork_id"].blank?
         compound_annotation['chebi_ids'] = params["#{@compound.id}_chebi_ids"].split(';').collect{|s| s.strip}
         compound_annotation['kegg_ids'] = params["#{@compound.id}_kegg_ids"].split(';').collect{|s| s.strip}

         @compound.title = compound_name
         #create new or update mappings and mapping_links
         @compound = new_or_update_mapping_links @compound, compound_annotation

         #create new or update synonyms
         @compound = new_or_update_synonyms @compound, compound_annotation
         if @compound.save
           respond_to do |format|
             format.js
           end
         else
           render plain: @compound.errors.full_messages, status: :unprocessable_entity
         end
      else
        render js: "alert('Please input the compound name');"
      end
   end

  def destroy
    #destroy the factor_studied, experimental_condition and their links
    @compound.studied_factors.each{|sf| sf.destroy}
    @compound.experimental_conditions.each{|ec| ec.destroy}
    #destroy the mapping_links
    @compound.mapping_links.each{|ml| ml.destroy}
    #destroy the synonyms and their links
    @compound.synonyms.each do |s|
      s.studied_factors.each{|sf| sf.destroy}
      s.experimental_conditions.each{|ec| ec.destroy}
      s.destroy
    end

    if @compound.destroy
      render js: "$j('#compound_row_#{@compound.id}').fadeOut(); $j('#edit_compound_#{@compound.id}').fadeOut();"
    else
      render plain: @compound.errors.full_messages, status: :unprocessable_entity
    end
  end

  def search_in_sabiork
     unless params[:compound_name].blank?
       compound_annotation = Seek::SabiorkWebservices.new().get_compound_annotation(params[:compound_name])
       unless compound_annotation.blank?
           synonyms = compound_annotation['synonyms'].inject{|result, s| result.concat("; #{s}")}
           synonyms.chomp!('; ') unless synonyms.blank?
           chebi_ids = compound_annotation['chebi_ids'].inject{|result, id| result.concat("; #{id}")}
           chebi_ids.chomp!('; ') unless synonyms.blank?
           kegg_ids = compound_annotation['kegg_ids'].inject{|result, id| result.concat("; #{id}")}
           kegg_ids.chomp!('; ') unless synonyms.blank?

           @results = {
               title: compound_annotation["recommended_name"],
               sabiork_id: compound_annotation["sabiork_id"],
               synonyms: synonyms,
               chebi_ids: chebi_ids,
               kegg_ids: kegg_ids
           }

           respond_to do |format|
             format.js
           end
       else
         render js: "alert('No result found');"
       end
     else
       render js: "alert('Please input the compound name');"
     end
  end

  private  

  def find_all_compounds
     @compounds=Compound.order(:name)
  end

end
