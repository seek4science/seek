class SpecimensController < ApplicationController
  # To change this template use File | Settings | File Templates.

  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :update, :edit, :destroy]

  include IndexPager

  def new_object_based_on_existing_one
    @existing_specimen =  Specimen.find(params[:id])
    @specimen = @existing_specimen.clone_with_associations

     @existing_specimen.sop_masters.each do |s|
       if !s.sop.can_view?
       flash.now[:notice] = "Some or all sops of the existing specimen cannot be viewed, you may specify your own!"
        break
      end
     end

    render :action=>"new"

  end

  def new
    @specimen = Specimen.new
    respond_to do |format|

      format.html # new.html.erb
    end
  end

  def create
    @specimen = Specimen.new(params[:specimen])
    sop_ids = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?))||[]
    @specimen.policy.set_attributes_with_sharing params[:sharing], @specimen.projects

    #Add creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])
    respond_to do |format|
      if @specimen.save
        sop_ids.each do |sop_id|
          sop= Sop.find sop_id
          SopSpecimen.create!(:sop_id => sop_id,:sop_version=> sop.version,:specimen_id=>@specimen.id)
        end

        #strain
        if params[:create_strain] == '1' || params[:create_strain] == '2'
          strain = create_or_update_strain
        else
          strain = default_strain_for params[:specimen][:organism_id]
        end
        @specimen.strain = strain

        flash[:notice] = 'Specimen was successfully created.'
        format.html { redirect_to(@specimen) }
        format.xml  { head :ok }
      else
       # Policy.create_or_update_policy(@specimen, current_user, params)
        format.html { render :action => "new" }
      end
    end
  end

  def update
    sop_ids = (params[:specimen_sop_ids].nil?? [] : params[:specimen_sop_ids].reject(&:blank?)) ||[]

    @specimen.attributes = params[:specimen]

    @specimen.policy.set_attributes_with_sharing params[:sharing], @specimen.projects

    #update creators
    AssetsCreator.add_or_update_creator_list(@specimen, params[:creators])
     respond_to do |format|
      if @specimen.save
          sop_ids.each do |sop_id|
            sop= Sop.find sop_id
            existing = @specimen.sop_masters.select{|ss|ss.sop == sop}
            if existing.blank?
               SopSpecimen.create!(:sop_id => sop_id,:sop_version=> sop.version,:specimen_id=>@specimen.id)
            end
          end

          #strain
          if params[:create_strain] == '1' || params[:create_strain] == '2'
            strain = create_or_update_strain
            @specimen.strain = strain
          elsif params[:create_strain] == '0'
             strain = default_strain_for params[:specimen][:organism_id]
            @specimen.strain = strain
          end
          flash[:notice] = 'Specimen was successfully updated.'
          format.html { redirect_to(@specimen) }
          format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
      end

    end
  end

  def destroy
    respond_to do |format|
      if @specimen.destroy
        format.html { redirect_to(specimens_path) }
        format.xml { head :ok }
      else
        flash.now[:error]="Unable to delete the specimen" if !@specimen.institution.nil?
        format.html { render :action=>"show" }
        format.xml { render :xml => @specimen.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create_or_update_strain
    strain = @specimen.strain || Strain.new()
        strain.attributes = params[:strain]

        phenotype = strain.phenotype || Phenotype.new()
        phenotype.attributes = params["phenotype"]
        if phenotype['description'].blank?
          strain.phenotype = nil
          phenotype.destroy
        else
          strain.phenotype = phenotype
        end

        genotypes_params = params["genotypes"]
        #destroy first the genotypes of strain
        strain.genotypes.each do |genotype|
          genotype.destroy
        end
        unless genotypes_params.blank?
          genotypes_params.each_value do |value|

            genotype = Genotype.new()
            gene = Gene.find_by_title(value['gene']['title']) || (Gene.create(:title => value['gene']['title']) unless value['gene']['title'].blank?)
            modification = Modification.find_by_title(value['modification']['title']) || (Modification.create(:title => value['modification']['title']) unless value['modification']['title'].blank?)
            genotype.gene = gene
            genotype.modification = modification
            strain.genotypes << genotype unless gene.blank?
          end
        end
        if strain.save
          strain
        else
          flash[:error] = "Unable to create/update strain '#{strain.title}', '#{strain.errors}'"
        end

  end

  def default_strain_for organism_id
    strain = Strain.find(:all, :conditions => ['organism_id=? and title=?', organism_id, 'default']).first
    unless strain
      strain = Strain.new(:title => 'default', :organism_id => organism_id)
      gene = Gene.find_by_title('wild-type') || Gene.create(:title => 'wild-type')
      genotype = Genotype.new(:gene => gene)
      phenotype = Phenotype.new(:description => 'wild-type')
      strain.genotypes = [genotype]
      strain.phenotype = phenotype
      strain.save
    end
    strain
  end
end

