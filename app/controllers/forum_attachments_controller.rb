class ForumAttachmentsController < ApplicationController
  
  before_filter :login_required
  #before_filter :is_user_admin_auth, :except => [:download]
  
  def download
    @forum_attachment = ForumAttachment.find(params[:id])
    send_data @forum_attachment.db_file.data, :filename => @forum_attachment.filename, :content_type => @forum_attachment.content_type, :disposition => 'attachment'
  end

  def create
    @post = Post.find(params[:forum_attachment][:post_id])
    @forum_attachment = ForumAttachment.new(params[:forum_attachment])
    if @forum_attachment.save
      @error_text = []
    else
      @error_text = @forum_attachment.errors.full_messages
    end
    responds_to_parent do
      render :update do |page|
        page.replace_html 'attachment_list', :partial => "posts/attachment_list", :locals => { :attachments => @post.attachments, :error_text => @error_text}
        page.visual_effect :highlight, 'attachment_list'
        page.hide 'attachment_spinner'
        page.replace_html "post-body-#{@post.id}", :partial => 'posts/post', :object => @post
        page.visual_effect :highlight, "post-body-#{@post.id}", :duration => 1.5
      end
    end    
  end
  
  def destroy
    @forum_attachment = ForumAttachment.find(params[:id])
    @post = @forum_attachment.post
    @forum_attachment.destroy
    render :update do |page|
      page.replace_html 'attachment_list', :partial => "posts/attachment_list", :locals => { :attachments => @post.attachments, :error_text => @error_text}
      page.visual_effect :highlight, 'attachment_list'
      page.replace_html "post-body-#{@post.id}", :partial => 'posts/post', :object => @post
      page.visual_effect :highlight, "post-body-#{@post.id}", :duration => 1.5
    end
  end
  
end