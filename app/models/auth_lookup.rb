class AuthLookup < ActiveRecord::Base
  self.abstract_class = true
  self.primary_key = [:user_id, :asset_id]
  belongs_to :user

  ABILITIES = ['view', 'download', 'edit', 'manage', 'delete'].freeze

  def self.wipe
    delete_all
    # Only need to specify user ID on insert, since all permission fields are `false` by default.
    import [:user_id], ([0] + User.pluck(:id)).map { |i| [i] },
           validate: false,
           batch_size: Seek::Util.bulk_insert_batch_size
  end

  def self.batch_update(permission, overwrite = true)
    # Turn `permission` into a 5-element array, each element being a boolean corresponding to each of the ABILITIES.
    permission = ABILITIES.map { |a| permission.allows_action?(a) } if permission.respond_to?(:allows_action?)

    # If not in "overwrite" mode, only update TRUE columns (i.e. only grant extra permissions).
    updates = {}
    ABILITIES.each_with_index do |a, index|
      updates["can_#{a}"] = permission[index] if overwrite || permission[index]
    end

    update_all(updates) unless updates.empty?
  end
end
