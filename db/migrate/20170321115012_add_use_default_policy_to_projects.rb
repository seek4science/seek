class AddUseDefaultPolicyToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :use_default_policy, :boolean, default: false
  end
end
