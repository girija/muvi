class Devise::SessionsController < DeviseController
  prepend_before_filter :require_no_authentication, :only => [ :new, :create ]
  prepend_before_filter :allow_params_authentication!, :only => :create
  prepend_before_filter { request.env["devise.skip_timeout"] = true }

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    #respond_with(resource, serialize_options(resource))

    if params[:home_refer_type].nil? and params[:login_for].nil? and params[:login].nil? and params[:refer_type].nil? and params[:act_refer_type].nil?
      render :partial => "new"
    end
  end

  # POST /resource/sign_in
  def create
    #pos = request.env["HTTP_REFERER"].scan(/\b(muvi.com)\b/)
    #pos1 = request.env["HTTP_REFERER"].scan(/\b(meme)\b/)
    pos = request.env["HTTP_REFERER"].index("muvi.com")
    pos1 = request.env["HTTP_REFERER"].index("meme")

    pos2 = request.env["HTTP_REFERER"].index("54.84.118.3")

    if !pos.blank? and !pos1.blank? and pos2.blank?
      params[:user][:password] = Base64.decode64(params[:user][:password])
      self.resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
      redirect_to "/users/sign_in?authentication_key=#{resource.authentication_token}"

    elsif pos.blank? and pos1.blank? and pos2.blank?
      params[:user][:password] = Base64.decode64(params[:user][:password])
      self.resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
      cookies[:sign_in_chk] = {:value => "1", :expires => 20.days.from_now}
      cookies[:sign_in] = {:value => "1", :expires => 20.days.from_now}

      redirect_to "/users/sign_in?authentication_key=#{resource.authentication_token}" 

    
    else
      params[:user][:password] = Base64.decode64(params[:user][:password])
      #self.resource = warden.authenticate!(auth_options)
      self.resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
      set_flash_message(:notice, :signed_in) if is_navigational_format?
      #sign_in(resource_name, resource)
      #respond_with resource, :location => after_sign_in_path_for(resource)

      cookies[:sign_in_chk] = {:value => "1", :expires => 20.days.from_now}    
      cookies[:sign_in] = {:value => "1", :expires => 20.days.from_now}

      respond_to do |format|
        format.html  {redirect_to root_path}
        format.js
      end
    end
  end

  def failure
    respond_to do |format|
        format.html  {redirect_to root_path}
        format.js
      end

  end

  # DELETE /resource/sign_out
  def destroy_new
    sign_out(resource_name)
    #render :template => "/devise/sessions/destroy"
      #respond_to do |format|
      #  format.html  {redirect_to root_path}
      #  format.js
      #end

    #sign_out(resource_name)
  end

  def destroy
    signed_in = signed_in?(resource_name)
    begin
      unless current_user.blank?
        cookies.delete("user_#{current_user.id}")
      end
    rescue
    end

    cookies[:sign_in] = {:value => "1", :expires => Time.now - 3600}
    cookies[:sign_in_chk] = 0
    if params[:msn_embed] == "msn_embed"
      sign_out(resource_name)
      redirect_to "/msn_embed/home"
    else
      sign_out_and_redirect(resource_name)
    end
    set_flash_message :notice, :signed_out if signed_in
  end
  
  def destroy_old
    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_navigational_format?

    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) { redirect_to redirect_path }
    end
  end

  protected

  def sign_in_params
    devise_parameter_sanitizer.for(:sign_in)
  end

  def serialize_options(resource)
    methods = resource_class.authentication_keys.dup
    methods = methods.keys if methods.is_a?(Hash)
    methods << :password if resource.respond_to?(:password)
    { :methods => methods, :only => [:password] }
  end

  def auth_options
    { :scope => resource_name, :recall => "#{controller_path}#new" }
    #{ :scope => resource_name, :recall => "#{controller_path}#failure" }
  end
end
