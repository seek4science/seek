class PermissionsPreview
  def self.before_validation(*args); end
  def self.has_many(*args); end

  include Seek::Permissions::PublishingPermissions

  attr_accessor :resource, :projects, :creators
  delegate_missing_to :@resource

  def initialize(params, policy_params)
    resource_class = params[:resource_name].camelize.constantize
    @resource = resource_class.find_by_id(params[:resource_id]) if params[:resource_id]
    @resource ||= resource_class.new
    @projects = if params.key?(:project_ids)
                  Project.where(id: (params[:project_ids] || '').split(','))
                else
                  @resource.projects
                end
    @creators = Person.find((params[:creators] || '').split(',').compact.uniq)
    @was_published = resource.is_published?
    resource.policy.set_attributes_with_sharing(policy_params)
    @will_be_published = resource.is_published?
  end

  def contributor
    new_record? ? User.current_user.person : resource.contributor&.person
  end

  def send_request_publish_approval
    !is_waiting_approval?(User.current_user)
  end

  def grouped_permissions
    permissions = policy.permissions
                        .reject { |p| p.access_type <= policy.access_type }
                        .sort_by { |p| Permission::PRECEDENCE.index(p.contributor_type) }
    # Group "download" permissions (i.e. from a default policy) in with "view" permissions if the resource is not downloadable
    grouped = permissions.group_by do |p|
      if !is_downloadable? && p.access_type == Policy::ACCESSIBLE
        Policy::VISIBLE
      else
        p.access_type
      end
    end.transform_values do |perms|
      perms.map(&:contributor)
    end

    grouped[Policy::EDITING] ||= []
    grouped[Policy::EDITING] |= creators.reject { |c| c == contributor }

    grouped[Policy::MANAGING] ||= []
    grouped[Policy::MANAGING].unshift(contributor)

    grouped
  end

  def is_published?
    @was_published
  end

  def show_gatekeeper_notice?
    requires_gatekeeper_approval? && policy.access_type_changed? && @will_be_published
  end
end
