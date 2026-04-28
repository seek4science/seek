# frozen_string_literal: true

SEEK_SHACL_SHAPES_FILE = Rails.root.join('public/vocab/seek-healthdcat-shapes.ttl').freeze

namespace :rdf do
  desc 'Validate a Turtle file against the SEEK HealthDCAT-AP SHACL shapes. ' \
       'Usage: rake rdf:validate[path/to/data.ttl]'
  task :validate, [:file] => :environment do |_t, args|
    require 'shacl'

    file = args[:file]
    abort 'Usage: rake rdf:validate[path/to/data.ttl]' if file.blank?
    abort "File not found: #{file}" unless File.exist?(file)

    puts "Validating #{file} against #{SEEK_SHACL_SHAPES_FILE} ..."
    report = SHACL.execute(File.read(file), shapes_file: SEEK_SHACL_SHAPES_FILE.to_s)
    rdf_validate_print_report(report)
  end

  desc 'Validate all DataFiles (those with RDF support) against SEEK HealthDCAT-AP SHACL shapes.'
  task validate_fixtures: :environment do
    require 'shacl'

    puts "Loading SHACL shapes from #{SEEK_SHACL_SHAPES_FILE} ..."
    failures = rdf_validate_collect_failures
    rdf_validate_report_failures(failures)
  end
end

def rdf_validate_print_report(report)
  if report.conform?
    puts 'SHACL validation passed — no violations found.'
  else
    puts "SHACL validation FAILED — #{report.results.size} result(s):"
    report.results.each do |result|
      severity = result.severity.to_s.split('#').last
      puts "  [#{severity}] #{result.source_shape} on #{result.focus_node}: #{result.message}"
    end
    exit 1
  end
end

def rdf_validate_collect_failures
  failures = []
  DataFile.find_each do |df|
    next unless df.rdf_supported?

    report = SHACL.execute(df.to_rdf, shapes_file: SEEK_SHACL_SHAPES_FILE.to_s)
    next if report.conform?

    violations = report.results.select { |r| r.severity.to_s.include?('Violation') }
    failures << { resource: df, results: violations } if violations.any?
  end
  failures
end

def rdf_validate_report_failures(failures)
  if failures.empty?
    puts 'All DataFiles passed SHACL validation (Violation-level only).'
  else
    puts "#{failures.size} DataFile(s) failed SHACL validation:"
    failures.each do |f|
      puts "  DataFile##{f[:resource].id} (#{f[:resource].title}):"
      f[:results].each { |r| puts "    #{r.source_shape}: #{r.message}" }
    end
    exit 1
  end
end
