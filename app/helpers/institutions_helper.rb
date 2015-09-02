module InstitutionsHelper
  def can_create_institutions?
    Institution.can_create?
  end
end
