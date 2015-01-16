class UserMessagesController < ApplicationController 
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  before_filter :msn_redirect, :only => [:contact_us]
  #layout 'website'
  layout:check

  def create
    @user_message = UserMessage.new(params[:user_message])
    if @user_message.save
      redirect_to(contact_us_path, :notice => 'Thank you')
    else
      render '/home/contact_us'
    end
  end
end

