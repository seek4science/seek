class OrganismsSweeper < ActionController::Caching::Sweeper

  include CommonSweepers

  observe Organism  

  def after_create(o)
    expire_organism_gadget
  end

  def after_update(o)
    expire_organism_gadget
  end

  def after_destroy(o)
    expire_organism_gadget
  end

  private


end
