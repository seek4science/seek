module Scrapers
  module Util
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
        bot = bot_account
        bot.add_to_project_and_institution(project, bot_institution)
        bot.is_project_administrator = true, project
        disable_authorization_checks { bot.save! }
      end
      project
    end
  end
end