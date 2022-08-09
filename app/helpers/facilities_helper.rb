module FacilitiesHelper
  def can_create_facilities?
    Faciliity.can_create?
  end
end
