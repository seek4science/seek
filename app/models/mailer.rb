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
         subject: "#{Seek::Config.application_name} Feedback provided - #{topic}",
         reply_to: reply_to)
  end

  def file_uploaded(uploader, receiver, file)
    @uploader = uploader.person
    @receiver = receiver
    @data_file = file
    mail(from: Seek::Config.noreply_sender,
         to: [uploader.person.email_with_name, receiver.email_with_name],
         subject: "#{Seek::Config.application_name} - File Upload",
         reply_to: uploader.person.email_with_name)
  end

  def request_publishing(owner, publisher, resources)
    @owner = owner
    publish_notification owner, publisher, resources, "A #{Seek::Config.application_name} member requests you make some items public"
  end

  def request_publish_approval(gatekeeper, publisher, resources)
    @gatekeeper = gatekeeper
    publish_notification gatekeeper, publisher, resources, "A #{Seek::Config.application_name} member requested your approval to publish some items."
  end

  def gatekeeper_approval_feedback(requester, gatekeeper, items_and_comments)
    gatekeeper_response 'approved', requester, gatekeeper, items_and_comments
  end

  def gatekeeper_reject_feedback(requester, gatekeeper, items_and_comments)
    gatekeeper_response 'rejected', requester, gatekeeper, items_and_comments
  end

  def request_resource(user, resource, details)
    @owners = resource.managers
    @requester = user.person
    @resource = resource
    @details = details
    mail(from: Seek::Config.noreply_sender,
         to: resource.managers.collect(&:email_with_name),
         reply_to: user.person.email_with_name,
         subject: "A #{Seek::Config.application_name} member requested a protected file: #{resource.title}")
  end

  def request_contact(user, resource, details)
    @owners = (resource.creators.count > 0) ? resource.creators : [resource.contributor]
    @requester = user.person
    @resource = resource
    @details = details
    mail(from: Seek::Config.noreply_sender,
         to: @owners.collect(&:email_with_name),
         reply_to: user.person.email_with_name,
         subject: "A #{Seek::Config.application_name} member requests to discuss with you regarding #{resource.title}")
  end

  def signup(user)
    @username = user.login
    @name = user.person.name
    @admins = admins
    @activation_code = user.activation_code
    mail(from: Seek::Config.noreply_sender,
         to: user.person.email_with_name,
         subject: "#{Seek::Config.application_name} account activation")
  end

  def forgot_password(user)
    @username = user.login
    @name = user.person.name
    @reset_code = user.reset_password_code
    mail(from: Seek::Config.noreply_sender,
         to: user.person.email_with_name,
         subject: "#{Seek::Config.application_name} - Password reset")
  end

  def welcome(user)
    @name = user.person.name
    @person = user.person
    mail(from: Seek::Config.noreply_sender,
         to: user.person.email_with_name,
         subject: "Welcome to #{Seek::Config.application_name}")
  end

  def contact_admin_new_user(params, user)
    new_member_details = Seek::Mail::NewMemberAffiliationDetails.new(params)
    @details = new_member_details.message
    @person = user.person
    @user = user
    @projects = new_member_details.projects
    @projects_with_admins = @projects.select{|p| p.project_administrators.any?}

    mail(from: Seek::Config.noreply_sender,
         to: admin_emails,
         reply_to: user.person.email_with_name,
         subject: "#{Seek::Config.application_name} member signed up")
  end

  def project_changed(project)
    @project = project
    recipients = admin_emails | @project.project_administrators.collect{|m| m.email_with_name}
    subject = "The #{Seek::Config.application_name} #{t('project')} #{@project.title} information has been changed"

    mail(:from=>Seek::Config.noreply_sender,
         :to=>recipients,
         :subject=>subject
    )
  end

  def contact_project_administrator_new_user(project_administrator, params, user)
    new_member_details = Seek::Mail::NewMemberAffiliationDetails.new(params)
    @details = new_member_details.message
    @other_institutions = params[:other_institutions]
    @person = user.person
    @projects = new_member_details.projects.select{|project| project_administrator.is_project_administrator?(project)}
    @user = user
    mail(from: Seek::Config.noreply_sender,
         to: project_administrator_email(project_administrator),
         reply_to: user.person.email_with_name,
         subject: "#{Seek::Config.application_name} member signed up, please assign this person to the #{I18n.t('project').pluralize.downcase} of which you are #{I18n.t('project')} Administrator")
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
    # FIXME: this should really be part of the site_announcements plugin
    @site_announcement  = site_announcement
    @notifiee_info = notifiee_info
    mail(from: Seek::Config.noreply_sender,
         to: notifiee_info.notifiee.email_with_name,
         subject: "#{Seek::Config.application_name} Announcement: #{site_announcement.title}")
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
         subject: "You have been assigned to a #{Seek::Config.application_name} project")
  end

  def programme_activation_required(programme, creator)
    @programme = programme
    @creator = creator

    mail(from: Seek::Config.noreply_sender,
         to: admin_emails,
         subject: "The #{Seek::Config.application_name} #{t('programme')} #{programme.title} was created and needs activating"
    )
  end

  def programme_activated(programme)
    @programme = programme

    mail(from: Seek::Config.noreply_sender,
         to: programme.programme_administrators.map(&:email_with_name),
         subject: "The #{Seek::Config.application_name} #{t('programme')} #{programme.title} has been activated"
    )
  end

  def programme_rejected(programme, reason)
    @programme = programme
    @reason = reason
    mail(from: Seek::Config.noreply_sender,
         to: programme.programme_administrators.map(&:email_with_name),
         subject: "The #{Seek::Config.application_name} #{t('programme')} #{programme.title} has been rejected"
    )
  end

  def request_membership(user, project, details)
    @owners = project.project_administrators
    @requester = user.person
    @resource = project
    @details = details
    mail(from: Seek::Config.noreply_sender,
         to: project.project_administrators.collect(&:email_with_name),
         reply_to: user.person.email_with_name,
         subject: "#{@requester.email_with_name} requested membership of project: #{@resource.title}")
  end

  private

  def admin_emails
    admins.map(&:email_with_name)
  rescue
    Rails.logger.error('Error determining admin email addresses')
    ['sowen@cs.man.ac.uk']
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
         subject: "A #{Seek::Config.application_name} gatekeeper #{response} your publishing requests.",
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

  def admins
    Person.admins
  end
end
