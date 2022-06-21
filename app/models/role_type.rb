class RoleType
  attr_accessor :id, :key, :scope

  def initialize(id:, key:, scope: nil)
    @id = id
    @key = key
    @scope = scope
  end

  DATA = {
    admin: RoleType.new(id: 1, key: 'admin'),
    pal: RoleType.new(id: 2, key: 'pal', scope: 'Project'),
    project_administrator: RoleType.new(id: 4, key: 'project_administrator', scope: 'Project'),
    asset_housekeeper: RoleType.new(id: 8, key: 'asset_housekeeper', scope: 'Project'),
    asset_gatekeeper: RoleType.new(id: 16, key: 'asset_gatekeeper', scope: 'Project'),
    programme_administrator: RoleType.new(id: 32, key: 'programme_administrator', scope: 'Programme')
  }.freeze

  def title
    I18n.t(key)
  end

  def self.all
    data.values
  end

  def self.for_system
    data.select { |k, v| v.scope.nil? }.values
  end

  def self.for_projects
    data.select { |k, v| v.scope == 'Project' }.values
  end

  def self.for_programmes
    data.select { |k, v| v.scope == 'Programme' }.values
  end

  def self.find_by_key(key)
    data[key.to_sym]
  end

  def self.find_by_key!(key)
    role = find_by_key(key)
    raise Seek::Roles::UnknownRoleException, "Unknown role '#{key}'" unless role
    role
  end

  def self.find_by_id(id)
    by_id[id.to_i]
  end

  def self.data
    return @data if @data
    load_data
    @data
  end

  def self.by_id
    return @data_by_id if @data_by_id
    load_data
    @data_by_id
  end

  def self.load_data
    @data = {}
    @data_by_id = {}
    DATA.each do |k, rt|
      @data[k.to_sym] = rt
      @data_by_id[rt.id.to_i] = rt
    end
  end
end
