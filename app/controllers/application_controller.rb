require 'email_check.rb'

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!
  #layout :specify_layout
  after_filter :set_access_control_headers
  before_filter :after_token_authentication

  before_filter :check_for_muvi_cookie


  def check_for_muvi_cookie
    unless cookies[:sign_in_chk].blank?
      if cookies[:sign_in_chk].to_i == 0
        sign_out :user
      elsif cookies[:sign_in_chk] == 0
        sign_out :user
      end
    end
  end

  def after_token_authentication
    if params[:authentication_key].present?
      @user = User.find_by_authentication_token(params[:authentication_key])
      sign_in @user if @user
      redirect_to root_path
    end
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  def specify_layout
    devise_controller? ? "registration" : "application"
  end

  include Facebooker2::Rails::Controller

  def admin?
    redirect_to "/muvi/admin" unless current_user.is_admin == true
  end

  def studio_admin?
    redirect_to root_path unless current_user.is_super_admin == true
  end

  def is_critic?
    redirect_to root_path unless current_user.is_critic == true
  end

  def render_404
    render :file => 'public/404.html', :status => 404
  end

  def check
    #params[:msn_embed] == "msn_embed" ? "msn" : ((params[:controller] == "movies" || params[:controller] == "celebrities") ? "home" : "website")

    #params[:msn_embed] == "msn_embed" ? "msn" : ((params[:controller] == "user_profiles" || params[:controller] == "celebrities" || params[:controller] == "movies" || params[:action] == "show_feed" || params[:controller] == "home" || params[:controller] == "search") ? "new_home" : "home")

    params[:msn_embed] == "msn_embed" ? "msn" : "new_home"
  end

  def msn_redirect
    if request.fullpath !~ /\/msn_embed/
      if request.env["HTTP_REFERER"] =~ /\/msn_embed/
        request.env["HTTP_HOST"] = request.env["HTTP_HOST"]+"/msn_embed"
        url = "http://"+request.env["HTTP_HOST"]+request.fullpath
        redirect_to url
      end
    end
  end

end

