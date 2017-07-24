class Ability

  def initialize(user)
    @person = (user.is_a?(User) ? user.try(:person) : user)
  end

  def can?(action, item)
    return false if @person.nil?

    if [:manage, :delete, :edit, :download, :view].include?(action)
      @person.is_asset_housekeeper_of?(item) && item.asset_housekeeper_can_manage?
    elsif action == :publish
      if @person.is_asset_gatekeeper_of?(item)
        if item.can_manage?(@person.user) && !item.is_published?
          true
        elsif !item.is_published? && item.is_waiting_approval?(nil, 5.years.ago)
          true
        else
          false
        end
      else
        false
      end
    end
  end

  def cannot?(action, item)
    !can?(action, item)
  end

end