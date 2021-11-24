class Mailer < ActionMailer::Base

  def feedback(user, topic, details, send_anonymously)
    @anon = send_anonymously
    @anon = true if user.try(:person).nil?

    @details = details
    @topic = topic
    @person = user.try(:person)
    reply_to = user.person.email_with_name unless @anon
    mail(from: Seek::Config.noreply_sender,
         to: admin_emails,
         subject: "#{Seek::Config.instance_name} Feedback provided - #{topic}",
         reply_to: reply_to)
  end

  def file_uploaded(uploader, receiver, file)
    @uploader = uploader.person
    @receiver = receiver
    @data_file = file
    mail(from: Seek::Config.noreply_sender,
         to: [uploader.person.email_with_name, receiver.email_with_name],
         subject: "#{Seek::Config.instance_name} - File Upload",
         reply_to: uploader.person.email_with_name)
  end

  def request_publishing(owner, publisher, resources)
    @owner = owner
    publish_notification owner, publisher, resources, "A #{Seek::Config.instance_name} member requests you make some items public"
  end

  def request_publish_approval(gatekeeper, publisher, resources)
    @gatekeeper = gatekeeper
    publish_notification gatekeeper, publisher, resources, "A #{Seek::Config.instance_name} member requested your approval to publish some items."
  end

  def gatekeeper_approval_feedback(requester, gatekeeper, items_and_comments)
    gatekeeper_response 'approved', requester, gatekeeper, items_and_comments
  end

  def gatekeeper_reject_feedback(requester, gatekeeper, items_and_comments)
    gatekeeper_response 'rejected', requester, gatekeeper, items_and_comments
  end

  def request_contact(user, resource, details)
    @owners = (resource.creators.count > 0) ? resource.creators : [resource.contributor]
    @requester = user.person
    @resource = resource
    @details = details
    mail(from: Seek::Config.noreply_sender,
         to: @owners.collect(&:email_with_name),
         reply_to: user.person.email_with_name,
         subject: "A #{Seek::Config.instance_name} member requests to discuss with you regarding #{resource.title}")
  end

  def activation_request(user)
    @username = user.login
    @name = user.person.name
    @admins = admins
    @activation_code = user.activation_code
    mail(from: Seek::Config.noreply_sender,
         to: user.person.email_with_name,
         subject: "#{Seek::Config.instance_name} account activation")
  end

  def forgot_password(user)
    @username = user.login
    @name = user.person.name
    @reset_code = user.reset_password_code
    mail(from: Seek::Config.noreply_sender,
         to: user.person.email_with_name,
         subject: "#{Seek::Config.instance_name} - Password reset")
  end

  def welcome(user)
    @name = user.person.name
    @person = user.person
    mail(from: Seek::Config.noreply_sender,
         to: user.person.email_with_name,
         subject: "Welcome to #{Seek::Config.instance_name}")
  end

  def contact_admin_new_user(user)

    @person = user.person
    @user = user

    mail(from: Seek::Config.noreply_sender,
         to: admin_emails,
         reply_to: user.person.email_with_name,
         subject: "#{Seek::Config.instance_name} member signed up")
  end

  def project_changed(project)
    @project = project
    recipients = admin_emails | @project.project_administrators.collect{|m| m.email_with_name}
    subject = "The #{Seek::Config.instance_name} #{t('project')} #{@project.title} information has been changed"

    mail(:from=>Seek::Config.noreply_sender,
         :to=>recipients,
         :subject=>subject
    )
  end

  def resources_harvested(harvester_responses, user)
    @resources = harvester_resources
    @person = user.person
    subject_text = (harvester_responses.size > 1) ? 'New resources registered with SEEK' : 'New resource registered with SEEK'
    mail(from: Seek::Config.noreply_sender,
         to: user.person.email_with_name,
         subject: subject_text)
  end

  def announcement_notification(site_announcement, notifiee_info)
    @site_announcement  = site_announcement
    @notifiee_info = notifiee_info
    mail(from: Seek::Config.noreply_sender,
         to: notifiee_info.notifiee.email_with_name,
         subject: "#{Seek::Config.instance_name} Announcement: #{site_announcement.title}")
  end

  def test_email(testing_email)
    mail(from: Seek::Config.noreply_sender,
         to: testing_email,
         subject: 'SEEK Configuration Email Test')
  end

  def notify_user_projects_assigned(person,new_projects)
    @name = person.name
    @projects = new_projects

    mail(from: Seek::Config.noreply_sender,
         to: person.email_with_name,
         subject: "You have been assigned to a #{Seek::Config.instance_name} project")
  end

  def programme_activation_required(programme, creator)
    @programme = programme
    @creator = creator

    mail(from: Seek::Config.noreply_sender,
         to: admin_emails,
         subject: "The #{Seek::Config.instance_name} #{t('programme')} #{programme.title} was created and needs activating"
    )
  end

  def programme_activated(programme)
    @programme = programme

    mail(from: Seek::Config.noreply_sender,
         to: programme.programme_administrators.map(&:email_with_name),
         subject: "The #{Seek::Config.instance_name} #{t('programme')} #{programme.title} has been activated"
    )
  end

  def programme_rejected(programme, reason)
    @programme = programme
    @reason = reason
    mail(from: Seek::Config.noreply_sender,
         to: programme.programme_administrators.map(&:email_with_name),
         subject: "The #{Seek::Config.instance_name} #{t('programme')} #{programme.title} has been rejected"
    )
  end

  def request_join_project(user, project, institution_json, comments, message_log)
    @owners = project.project_administrators
    @requester = user.person
    @institution = Institution.new(JSON.parse(institution_json))
    @project = project
    @comments = comments
    @message_log = message_log
    mail(from: Seek::Config.noreply_sender,
         to: @owners.collect(&:email_with_name),
         reply_to: @requester.email_with_name,
         subject: "JOIN #{t('project')} request to #{@project.title} from #{@requester.name}")
  end

  def request_create_project_for_programme(user, programme, project_json, institution_json, message_log)
    @admins = programme.programme_administrators
    @programme = programme
    @requester = user.person
    @institution = Institution.new(JSON.parse(institution_json))
    @project = Project.new(JSON.parse(project_json))
    @message_log = message_log

    mail(from: Seek::Config.noreply_sender,
         to: @admins.collect(&:email_with_name),
         reply_to: @requester.email_with_name,
         subject: "NEW #{t('project')} request from #{@requester.name} for your #{t('programme')}: #{@project.title}")

  end

  # same as request_create_project_for_programme but to notify the site admins rather instead of programme admins
  def request_create_project_for_programme_admins(user, programme, project_json, institution_json, message_log)
    @admins = admins
    @programme = programme
    @requester = user.person
    @institution = Institution.new(JSON.parse(institution_json))
    @project = Project.new(JSON.parse(project_json))
    @message_log = message_log
    
    mail(from: Seek::Config.noreply_sender,
         to: admin_emails,
         reply_to: @requester.email_with_name,
         subject: "NEW #{t('project')} request from #{@requester.name} for your #{t('programme')}: #{@project.title}",
         template_name: :request_create_project_for_programme)
    
  end

  def request_create_project_and_programme(user, programme_json, project_json, institution_json, message_log)
    @admins = admins
    @programme = Programme.new(JSON.parse(programme_json))
    @requester = user.person
    @institution = Institution.new(JSON.parse(institution_json))
    @project = Project.new(JSON.parse(project_json))
    @message_log = message_log
    mail(from: Seek::Config.noreply_sender,
         to: admin_emails,
         reply_to: @requester.email_with_name,
         subject: "New #{t('project')} and #{t('programme')} request from #{@requester.name}: #{@project.title}")
  end

  def request_create_project(user, project_json, institution_json, message_log)
    @admins = admins
    @requester = user.person
    @institution = Institution.new(JSON.parse(institution_json))
    @project = Project.new(JSON.parse(project_json))
    @message_log = message_log
    mail(from: Seek::Config.noreply_sender,
         to: admin_emails,
         reply_to: @requester.email_with_name,
         subject: "New #{t('project')} request from #{@requester.name}: #{@project.title}",
         template_name: :request_create_project_for_programme)
  end

  def join_project_rejected(requester, project, comments)
    @requester = requester
    @project = project
    @comments = comments
    subject = "Your request to join the #{t('project')}, #{project.title}, hasn't been approved"
    mail(from: Seek::Config.noreply_sender,
         to: requester.email_with_name,
         subject: subject)
  end

  def create_project_rejected(requester,project_name,comments)
    @requester = requester
    @project_name = project_name
    @comments = comments
    subject = "Your request to create the #{t('project')}, #{project_name}, hasn't been approved"
    mail(from: Seek::Config.noreply_sender,
         to: requester.email_with_name,
         subject: subject)
  end

  private

  def admin_emails
    admins.map(&:email_with_name)
  end

  def admins
    Person.admins
  end

  def project_administrator_email(project_administrator)
    project_administrator.email_with_name
  rescue
    Rails.logger.error("Error determining #{I18n.t('project')} manager #{project_madministrator.name} email addresses")
    ['sowen@cs.man.ac.uk']
  end

  # response will be 'rejected' or 'approved'
  def gatekeeper_response(response, requester, gatekeeper, items_and_comments)
    @gatekeeper = gatekeeper
    @requester = requester
    @items_and_comments = items_and_comments

    mail(from: Seek::Config.noreply_sender,
         to: requester.email_with_name,
         subject: "A #{Seek::Config.instance_name} #{I18n.t('asset_gatekeeper').downcase} #{response} your publishing requests.",
         reply_to: gatekeeper.email_with_name)
  end

  def publish_notification(recipient, publisher, resources, subject)
    @publisher = publisher
    @resources = resources
    mail(from: Seek::Config.noreply_sender,
         to: recipient.email_with_name,
         reply_to: publisher.email_with_name,
         subject: subject)
  end
  
end
