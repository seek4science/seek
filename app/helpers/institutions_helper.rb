module InstitutionsHelper
  def can_create_institutions?
    Institution.can_create?
  end

  def ror_link(ror_id)
    text_or_not_specified("https://ror.org/#{ror_id}", :external_link => true)
  end
end
