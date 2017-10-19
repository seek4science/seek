class OrganismsSweeper < ActionController::Caching::Sweeper
  include CommonSweepers

  observe Organism

  def after_create(_o)
    expire_organism_gadget
  end

  def after_update(_o)
    expire_organism_gadget
  end

  def after_destroy(_o)
    expire_organism_gadget
  end
end
