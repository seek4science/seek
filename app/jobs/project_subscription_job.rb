class ProjectSubscriptionJob < SeekJob
  queue_with_priority 2

  def perform(project_subscription)
    disable_authorization_checks do
      all_in_project(project_subscription.project).reject { |item| item.subscribed?(project_subscription.person) }.each do |item|
        item.subscriptions << Subscription.new(person: project_subscription.person, project_subscription_id: project_subscription.id)
      end
    end
  end

  def default_delay
    15.seconds
  end

  # all direct assets in the project, but related_#{asset_type} includes also assets from descendants
  def all_in_project(project)
    # assay and study dont have project association table
    project.studies | project.assays | assets_with_association_table(project)
  end

  def assets_with_association_table(project)
    subscribable_types_with_association_table.collect do |type|
      # e.g.: 'data_files_projects'
      assets_projects_table = ["#{type.underscore.gsub('/', '_').pluralize}", 'projects'].sort.join('_')
      assets_for_project project, type, assets_projects_table
    end.flatten.uniq
  end

  def subscribable_types_with_association_table
    # assay and study dont have project association table
    names = Seek::Util.persistent_classes.select(&:subscribable?).collect(&:name)
    names.reject { |name| name == 'Assay' || name == 'Study' || name == 'OpenbisAssay' }
  end

  def assets_for_project(project, asset_type, assets_projects_table)
    asset_id = (asset_type.underscore + '_id').split('/').last
    klass =  asset_type.constantize
    table = assets_projects_table
    sql = "select #{asset_id} from #{table}"
    sql << " where #{table}.project_id = #{project.id}"
    ids = ActiveRecord::Base.connection.select_all(sql).collect { |k| k["#{asset_id}"] }
    klass.where(id: ids)
  end
end
