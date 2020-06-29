class HumanDiseasesSweeper < ActionController::Caching::Sweeper
  include CommonSweepers

  observe HumanDisease

  def after_create(_o)
    expire_human_disease_gadget
  end

  def after_update(_o)
    expire_human_disease_gadget
  end

  def after_destroy(_o)
    expire_human_disease_gadget
  end
end
