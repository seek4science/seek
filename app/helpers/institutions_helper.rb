module InstitutionsHelper
  def can_create_institutions?
    Institution.can_create?
  end

  def ror_link(ror_url)
    ror_url.blank? ? text_or_not_specified(nil) : link_to(ror_url, ror_url, target: "_blank", rel: "noopener")
  end

  def other_departments(institution)
    Institution.where(title: institution.title).where.not(department: institution.department)
  end

end
