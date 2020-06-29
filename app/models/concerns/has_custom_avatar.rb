module HasCustomAvatar
  extend ActiveSupport::Concern

  included do
    has_many :avatars, as: :owner, dependent: :destroy # Possible avatars
    belongs_to :avatar # Selected avatar
    validates :avatar, associated: true
  end

  # "false" returned by this helper method won't mean that no avatars are uploaded for this yellow page model;
  # it rather means that no avatar (other than default placeholder) was selected for the yellow page model
  def avatar_selected?
    !avatar_id.nil?
  end

  def defines_own_avatar?
    true
  end
end
