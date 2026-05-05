# frozen_string_literal: true

# Receives and logs Content Security Policy violation reports sent by browsers.
# The endpoint is configured in config/initializers/content_security_policy.rb via policy.report_uri.
#
# CSP reports are POSTed as JSON with Content-Type: application/csp-report.
# No authentication is required (browsers send these directly).
class CspReportsController < ActionController::Base
  # Skip CSRF protection – browsers POST CSP reports automatically without a token.
  skip_before_action :verify_authenticity_token

  def create
    report = parse_csp_report
    if report.present?
      Rails.logger.warn("[CSP Violation] #{report.to_json}")
    else
      Rails.logger.warn('[CSP Violation] Received empty or unparseable report body')
    end
    head :no_content
  end

  private

  def parse_csp_report
    body = request.body.read
    return nil if body.blank?

    JSON.parse(body)
  rescue JSON::ParserError => e
    Rails.logger.error("[CSP Violation] Failed to parse report body: #{e.message}")
    nil
  end
end

