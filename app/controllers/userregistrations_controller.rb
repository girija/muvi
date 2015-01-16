class UserregistrationsController < ApplicationController
  skip_before_filter :authenticate_user!, :only => [:create, :new]
  layout 'website'

  def new
    omniauth = request.env["omniauth.auth"]
    user_token = UserToken.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if user_token # already token is there
      user_token.update_token_and_secret(omniauth)
      user_token.user.update_user_profile(omniauth) # update or create user profile
      #user_token.user.delay.fetch_fb_feeds if omniauth['provider'] == 'facebook'
      sign_in(:user, user_token.user)
      #unless user_token.user.confirmed_at.blank? # user is confirmed or not
      #  sign_in(:user, user_token.user)
      #else
      #  @notconfirmed = true
      #end
    elsif current_user
      current_user.create_user_tokens(omniauth) if current_user.has_user_token?(omniauth['provider'], omniauth['uid'])
    else
      @user_data = get_data_from_omniauth(omniauth)
    end
  end

  def invite_new
    session[:invite_id] = params[:user_id]
    omniauth = request.env["omniauth.auth"]
    user_token = UserToken.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if user_token # already token is there
      user_token.update_token_and_secret(omniauth)
      user_token.user.update_user_profile(omniauth) # update or create user profile
      puts "*****************************************************************************"
      #user_token.user.fetch_fb_feeds if omniauth['provider'] == 'facebook'
      unless user_token.user.confirmed_at.blank? # user is confirmed or not
        sign_in(:user, user_token.user)
      else
        @notconfirmed = true
      end
    elsif current_user
      current_user.create_user_tokens(omniauth) if current_user.has_user_token?(omniauth['provider'], omniauth['uid'])
    else
      @user_data = get_data_from_omniauth(omniauth)
    end
  end

  def create
    @user = User.new(params[:user])
    @user.save
    #@user.confirm!
    #flash[:notice] = "Please make sure that, you have confirmed your Muvi registration."
    #redirect_to new_user_session_path
  end

  def show
  end



  def get_data_from_omniauth(omniauth)
    hash = {}
    #hash[:email] = (omniauth['extra']['user_hash']['email'] rescue '' )
    hash[:email] = (omniauth["info"]["email"] rescue '' )
    hash[:provider] = omniauth['provider']
    hash[:uid] = omniauth['uid']
    hash[:token] = (omniauth['credentials']['token'] rescue nil)
    hash[:secret] = (omniauth['credentials']['secret'] rescue nil)
    #hash[:name] = (omniauth['provider'] == 'facebook')? (omniauth['extra']['user_hash']['name'] rescue '') : (omniauth['extra']['user_hash']['screen_name'] rescue '')
    hash[:name] = (omniauth['provider'] == 'facebook')? (omniauth["info"]["name"] rescue '') : (omniauth['extra']['user_hash']['screen_name'] rescue '')         

    hash
        
  end

end
