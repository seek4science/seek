# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # Only allow resources from the same origin by default
    policy.default_src :self

    # Scripts: allow self + nonce (for inline scripts like Piwik).
    # NOTE: 'unsafe-inline' is included as a fallback for:
    #   - google-analytics-rails gem (analytics_init generates its own <script> tag without nonce support)
    #   - Seek::Config.custom_analytics_snippet (arbitrary admin-configured JS)
    # When those are removed or refactored, drop 'unsafe-inline' here.
    policy.script_src :self, :unsafe_inline,
                      'https://www.google-analytics.com',
                      'https://www.googletagmanager.com'

    # Styles: allow self + inline (Bootstrap, jQuery UI inject inline styles via JS)
    policy.style_src :self, :unsafe_inline

    # Images: allow self, data URIs (avatars, thumbnails) and any HTTPS source
    # (external model/data images may come from arbitrary URLs)
    policy.img_src :self, :data, :https

    # Fonts: allow self and data URIs (icon fonts embedded as base64)
    policy.font_src :self, :data

    # Disallow <object>, <embed>, <applet>
    policy.object_src :none

    # Restrict <base> tag to same origin
    policy.base_uri :self

    # Form submissions must go to same origin
    policy.form_action :self

    # Prevent clickjacking – only allow framing from same origin
    policy.frame_ancestors :self

    # Report violations to our endpoint (logged, not enforced in report-only mode)
    policy.report_uri '/csp-violation-report'
  end

  # Use a per-request random nonce for script-src.
  # Access the nonce in views via: content_security_policy_nonce
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Start in report-only mode so violations are logged without breaking the app.
  # Switch to false (enforced) after reviewing violation reports.
  config.content_security_policy_report_only = true
end
