module ServicesHelper
  def can_create_services?
    Service.can_create?
  end
end
