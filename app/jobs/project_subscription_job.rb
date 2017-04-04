class ProjectSubscriptionJob < SeekJob
  attr_reader :project_subscription_id

  def initialize(project_subscription_id)
    @project_subscription_id = project_subscription_id
  end

  def perform_job(ps)
    all_in_project(ps.project).each do |item|
      item.subscriptions << Subscription.new(person: ps.person, project_subscription_id: project_subscription_id) unless item.subscribed?(ps.person)
    end
  end

  def gather_items
    [ProjectSubscription.find_by_id(project_subscription_id)].compact
  end

  def default_priority
    2
  end

  def default_delay
    15.seconds
  end

  def allow_duplicate_jobs?
    false
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
    names.reject { |name| name == 'Assay' || name == 'Study' }
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
