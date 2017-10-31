# Roles
Factory.define(:admin_defined_role_project, class: AdminDefinedRoleProject) do |_f|
end

Factory.define(:admin_defined_role_programme, class: AdminDefinedRoleProgramme) do |_f|
end

# ProjectPosition
Factory.define(:project_position) do |f|
  f.name 'A Role'
end

#:pal relies on Role.pal_role being able to find an appropriate role in the db.
Factory.define(:pal_position, parent: :project_position) do |f|
  f.name 'A Pal'
end
