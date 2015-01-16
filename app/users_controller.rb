class UsersController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  layout:check


  def show
  end

  ######## Old way starts #####
  def sign_up
    unless current_user.blank?
      redirect_to "/"
    end
  end
  
  def base64_url_decode str
    encoded_str = str.gsub('-','+').gsub('_','/')
    encoded_str += '=' while !(encoded_str.size % 4).zero?
    Base64.decode64(encoded_str)
  end
  
  def register
    str = params[:signed_request]
    encoded_sig, payload = str.split('.')
    data = ActiveSupport::JSON.decode base64_url_decode(payload)

    #Save user
    @u = User.new
    @u.email = data["registration"]["email"]
    @u.password = data["registration"]["password"] 
    unless data["user_id"].blank?
      @u.facebook_id = data["user_id"]
    end
    @u.save

    #Save user token
    unless data["user_id"].blank?
      @ut = UserToken.new
      @ut.user_id = @u.id
      @ut.provider = "facebook"
      @ut.uid = data["user_id"]
      @ut.token = data["oauth_token"]
      @ut.save
    end

    #Save user profile
    @up = UserProfile.new
    @up.display_name = data["registration"]["name"]
    @up.user_id = @u.id
    @up.save

    sign_in_and_redirect(:user, @ut.user)
  end
  ####### Old way ends ######
  
  
  def check_user_login
    unless current_user.blank?
      respond_to do |format|
        format.js
      end
    else
      user_token = UserToken.find_by_uid(params[:user_id])
      if user_token
        sign_in(:user, user_token.user)
        respond_to do |format|
          format.js
        end    
      else
        render :text => 0
      end
    end
  end
  
  
  ####### New way starts ######
  def user_signup
    unless current_user.blank?
      redirect_to "/"
    end
  end 
    
  def user_register
    #Save user
    @u = User.new
    @u.email = params[:email]
    @u.password = params[:password]
    @u.save

    #Save user profile
    @up = UserProfile.new
    @up.display_name = params[:name]
    @up.user_id = @u.id
    @up.save

    sign_in_and_redirect(:user, @up.user)
  end

  def fb_register
    #Save user
    @u = User.new
    @u.email = params[:user_email]
    @u.password = params[:password]
    @u.facebook_id = params[:user_user_tokens_attributes_0_uid]
    @u.save

    #Save user token
    @ut = UserToken.new
    @ut.user_id = @u.id
    @ut.provider = "facebook"
    @ut.uid = params[:user_user_tokens_attributes_0_uid]
    @ut.token = params[:user_user_tokens_attributes_0_token]
    @ut.save

    #Save user profile
    @up = UserProfile.new
    @up.display_name = params[:user_user_profile_attributes_display_name]
    @up.user_id = @u.id
    @up.save

    sign_in_and_redirect(:user, @ut.user)

  end


end

