module Scrapers
  module Util
    def self.scrape(output: STDOUT, error_output: STDERR)
      config = Seek::Config.scraper_config
      raise "Missing 'scraper_config'" unless config
      exceptions = []
      output.puts "Running #{config.length} scrapers:"
      config.each do |scraper_config|
        begin
          output.puts "#{scraper_config.inspect}"
          project = scraper_config[:project_id] ? Project.find_by_id(scraper_config[:project_id]) : nil
          raise "Missing 'project_title'" unless scraper_config[:project_title].present?
          project ||= Scrapers::Util.bot_project(title: scraper_config[:project_title])
          person = Scrapers::Util.bot_account
          scraper_class = Scrapers.const_get(scraper_config[:class])
          options = (scraper_config[:options] || {}).symbolize_keys
          options[:output] ||= output

          scraper = scraper_class.new(project, person, **options)

          scraper.scrape
          output.puts 'OK'
        rescue StandardError => e
          exceptions << { config: scraper_config, exception: e }
          output.puts 'Error'
        end
      end
      succeeded = config.length - exceptions.length
      output.puts "Succeeded: #{succeeded}"
      output.puts "Failed: #{exceptions.length}"

      exceptions.each do |data|
        config = data[:config]
        e = data[:exception]
        error_output.puts "#{config[:project_title] || '<scraper with no project title>'} failed: #{e.class.name} - #{e.message}"
        e.backtrace.each do |line|
          error_output.puts "  #{line}"
        end
        error_output.puts
      end
    end

    def self.bot_account
      @bot = Person.where(email: Seek::Config.noreply_sender).first
      unless @bot
        @bot = Person.new(first_name: Seek::Config.instance_name,
                          last_name: 'Bot',
                          email: Seek::Config.noreply_sender)
        disable_authorization_checks { @bot.save! }
        user = User.from_omniauth({ 'info' => { 'nickname' => 'scraper-bot' }})
        user.person = @bot
        user.check_email_present = false
        disable_authorization_checks { user.save! }
      end

      @bot
    end

    def self.bot_institution
      i = Institution.where(title: 'Bots').first
      unless i
        i = Institution.new(title: 'Bots')
        disable_authorization_checks { i.save! }
      end
      i
    end

    def self.bot_project(attributes)
      project = Project.where(title: attributes[:title]).first
      unless project
        project = Project.new(attributes)
        disable_authorization_checks { project.save! }
      end
      bot = bot_account
      unless project.has_member?(bot)
        bot.add_to_project_and_institution(project, bot_institution)
        bot.is_project_administrator = true, project
        disable_authorization_checks { bot.save! }
      end
      project
    end
  end
end