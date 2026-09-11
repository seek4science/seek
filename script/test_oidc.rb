#!/usr/bin/env ruby
# Simulates the OIDC login flow exercised by custom_sessions.rb.
# Mirrors assign_oidc_projects + default_oidc_institution exactly.
# Run inside the container:
#   bundle exec ruby /seek/script/test_oidc_final.rb
puts "OIDC simulation starting"
require_relative '../config/environment'

# ---------------------------------------------------------------------------
# Helpers (mirrors custom_sessions.rb private methods)
# ---------------------------------------------------------------------------

def sim_default_oidc_institution
  title   = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION', 'Default Institution')
  country = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_COUNTRY', 'GB')
  city    = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_CITY', '')
  web     = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_WEB', '')

  disable_authorization_checks do
    Institution.find_or_create_by(title: title) do |inst|
      inst.country  = country
      inst.city     = city
      inst.web_page = web.presence
    end
  end
end

def sim_assign_oidc_projects(person, raw_groups)
  groups = case raw_groups
           when Array  then raw_groups
           when String then raw_groups.split(/[,;\s]+/)
           else []
           end
  groups = groups.map(&:to_s).reject(&:blank?)

  return puts("  No groups supplied – skipping project mapping") if groups.empty?

  institution = sim_default_oidc_institution
  return puts("  ERROR: could not find/create institution") unless institution

  admin_keywords = ENV.fetch('OMNIAUTH_OIDC_ADMIN_KEYWORDS', 'admin,administrator,owner,admins,owners')
                      .split(/[,;\s]+/)
                      .map { |k| Regexp.new(Regexp.escape(k), Regexp::IGNORECASE) }

  groups.each do |group|
    project_title = group.split(%r{[:/\#@]}).last.to_s.strip
    project_title = group.strip if project_title.blank?

    disable_authorization_checks do
      project = Project.find_or_create_by(title: project_title) do |p|
        p.description = "Auto-created from OIDC group: #{group}"
      end

      unless person.member_of?(project)
        person.add_to_project_and_institution(project, institution)
        person.save!
        puts "  + Added person to project '#{project_title}'"
      else
        puts "  = Already member of project '#{project_title}'"
      end

      if admin_keywords.any? { |pat| group =~ pat }
        unless project.project_administrators.include?(person)
          project.project_administrators << person
          project.save!
          puts "  ^ Promoted to admin of '#{project_title}'"
        else
          puts "  = Already admin of '#{project_title}'"
        end
      end
    end
  end
end

# ---------------------------------------------------------------------------
# Test data – mimics what an OIDC provider might return in the groups claim
# ---------------------------------------------------------------------------
TEST_EMAIL  = 'oidc-sim@example.com'
TEST_GROUPS = [
  'urn:example:project:ResearchTeam',   # regular member
  'workspace:DataAdmins',               # contains 'admin' -> project admin
  'plain-group'                         # regular member, simple name
]

begin
  # 1. Institution
  institution = sim_default_oidc_institution
  puts "Institution: '#{institution.title}' (id=#{institution.id}, country=#{institution.country})"

  # 2. Person (simulates find_or_initialize_by in create_user_from_omniauth)
  person = nil
  disable_authorization_checks do
    person = Person.find_or_initialize_by(email: TEST_EMAIL)
    person.first_name = 'OIDC'
    person.last_name  = 'Simulator'
    person.save!
  end
  puts "Person: #{person.first_name} #{person.last_name} <#{person.email}> (id=#{person.id})"

  # 3. New-user flow: assign projects from groups claim
  puts "\n--- First login (new user) ---"
  sim_assign_oidc_projects(person, TEST_GROUPS)

  # 4. Returning-user flow: same groups, should be idempotent
  puts "\n--- Second login (returning user, groups unchanged) ---"
  sim_assign_oidc_projects(person, TEST_GROUPS)

  # 5. Summary
  puts "\nProject memberships for person #{person.id}:"
  person.reload.projects.each do |proj|
    role = proj.project_administrators.include?(person) ? 'admin' : 'member'
    puts "  - #{proj.title} [#{role}]"
  end

  puts "\nOIDC simulation finished successfully"
rescue => e
  puts "\nERROR: #{e.class}: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  exit 1
end

