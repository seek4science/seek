class Ability

  def initialize(user)
    @person = (user.is_a?(User) ? user.try(:person) : user)
  end

  def can?(action, item)
    return false if @person.nil?

    if [:manage, :delete, :edit, :download, :view].include?(action)
      @person.is_asset_housekeeper_of?(item) && item.asset_housekeeper_can_manage?
    elsif action == :publish
      @person.is_asset_gatekeeper_of?(item) && item.asset_gatekeeper_can_publish?
    else
      false
    end
  end

  def cannot?(action, item)
    !can?(action, item)
  end

end