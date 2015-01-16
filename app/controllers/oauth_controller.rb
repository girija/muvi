class OauthController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  def auth_signup
    result_array = {}
    muvi = []
    ca = ClientApplication.find_by_name(params[:oauthApp])
    unless ca.blank?
        u = User.find_by_email(params[:email])
        unless u.blank?
          muvi << {:result => "Email already exists"}
          result_array['items'] = muvi
          render :text => "jsonpcallback_reg('#{result_array.to_json}')"
        else
          @u = User.new
          @u.email = params[:email]
          @u.password = Base64.decode64(params[:password])
          @u.registered_from = params[:register_from].strip
          @u.is_studio_admin = false
          @u.source = params[:source]
          @u.signup_ip = params[:ip_address]
          @u.studio_user_id = ""

          token = Digest::SHA1.hexdigest([Time.now, rand].join)
          @u.token = token

          @u.save
          @up = UserProfile.new
          @up.display_name = params[:name]
          @up.user_id = @u.id
          @up.save

          @u.reset_authentication_token!

          cookies[:muviuser_id] = @u.id
          cookies[:redirected] = 1

          #@final = [@u, @up]
          #####################################################################
          up = UserProfile.select("display_name").find_by_user_id(@u.id)
          ua = UserAddress.find_by_user_id(@u.id)

          user_image = ""
          user = @u
          unless user.user_profile.blank?
            unless user.user_profile.profile_image_file_name.blank?
              user_image = "/system/profile_images/#{user.user_profile.id}/small/#{user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
            else
              unless user.facebook_id.blank?
                user_image = "http://graph.facebook.com/#{user.facebook_id}/picture?type=normal"
              else
                user_image = "/images/no-profile.png"
              end
            end
          else
            user_image = "/images/no-profile.png"
          end
          
          @final = [:user_info => @u, :user_profile => up, :user_address => ua, :user_image => user_image]

          #####################################################################

          #muvi << {:result => @u.id}
          muvi << {:result => @final}
          result_array['items'] = muvi
          render :text => "jsonpcallback_reg('#{result_array.to_json}')"
        end
    else
       muvi << {:result => "app not authorized"}
       result_array['items'] = muvi
       render :text => "jsonpcallback_reg('#{result_array.to_json}')"
    end
  end

  def authenticate_muviuser  #(username,password)
    result_array = {}
    muvi = []
    ca = ClientApplication.find_by_name(params[:oauthApp])
    unless ca.blank?
      username = params[:username]
      #password = params[:password]
      password = Base64.decode64(params[:password])
      user = User.select("id, email, facebook_id, encrypted_password, is_studio_admin, studio_user_id, is_developer").find_by_email(username)
      if user && user.valid_password?(password)
        token = Digest::SHA1.hexdigest([Time.now, rand].join)
        user.update_attribute(:token, token)
        #user
        #up = user.user_profile
        up = UserProfile.select("display_name").find_by_user_id(user.id)
        ua = UserAddress.find_by_user_id(user.id)

        user_image = ""
        unless user.user_profile.blank?
          unless user.user_profile.profile_image_file_name.blank?
            user_image = "/system/profile_images/#{user.user_profile.id}/small/#{user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
          else
            unless user.facebook_id.blank?
              user_image = "http://graph.facebook.com/#{user.facebook_id}/picture?type=normal"
            else
              user_image = "/images/no-profile.png"
            end
          end
        else
          user_image = "/images/no-profile.png"
        end

        @final = [:user_info => user, :user_profile => up, :user_address => ua, :user_image => user_image]

        muvi << {:result => @final}
        result_array['items'] = muvi
        if params[:is_rem] == "on"
          cookies[:muviuser_id] = user.id
          cookies[:redirected] = 1
          cookies[:sign_in_chk] = {:value => "1", :expires => 20.days.from_now}
        end
        render :text => "jsonpcallback('#{result_array.to_json}')"
        #render :text => result_array.to_json
      else
        #render :text => "incorrect login"
        muvi << {:result => "incorrect login"}
        result_array['items'] = muvi
        render :text => "jsonpcallback('#{result_array.to_json}')"
        #render :text => result_array.to_json
      end
    else
      #render :text => "app not authorized"
      muvi << {:result => "app not authorized"}
      result_array['items'] = muvi
      render :text => "jsonpcallback('#{result_array.to_json}')"
      #render :text => result_array.to_json
    end
  end

  def logout_muvi
    #cookies[:sign_in_chk] = {:value => "0", :expires => Time.now - 3600}
    cookies[:sign_in_chk] = 0
    result_array = {}
    muvi = []

    muvi << {:result => "muvi logged out"}
    result_array['items'] = muvi
    render :text => "jsonpcallback_logout('#{result_array.to_json}')"
  end

  def update_user_address
    result_array = {}
    muvi = []
    ca = ClientApplication.find_by_name(params[:oauthApp])
    unless ca.blank?
      user = User.find_by_id_and_token(params[:user_id], "#{params[:token]}")
      unless user.blank?
        profile = user.user_profile
        unless profile.blank?
          profile.display_name = params[:name]
          profile.save
        else
          profile = UserProfile.new
          profile.user_id = params[:user_id]
          profile.display_name = params[:name]
          profile.save
        end

        addr = user.user_address
        unless addr.blank?
          addr.address1 = params[:address1]
          addr.city = params[:city]
          addr.state = params[:state]
          addr.country = params[:country]
          addr.phone = params[:phone]
          addr.zip = params[:zip]
          addr.save
        else
          addr = UserAddress.new
          addr.user_id = params[:user_id]
          addr.address1 = params[:address1]
          addr.city = params[:city]
          addr.state = params[:state]
          addr.country = params[:country]
          addr.phone = params[:phone]
          addr.zip = params[:zip]
          addr.save
        end
        muvi << {:result => "user address updated"}
        result_array['items'] = muvi
        render :text => "jsonpcallback_addr('#{result_array.to_json}')"
      else
        muvi << {:result => "user token mismatch"}
        result_array['items'] = muvi
        render :text => "jsonpcallback_addr('#{result_array.to_json}')"
      end
    else
      muvi << {:result => "app not authorized"}
      result_array['items'] = muvi
      render :text => "jsonpcallback_addr('#{result_array.to_json}')"
    end
  end

  def update_user_password
    result_array = {}
    muvi = []
    ca = ClientApplication.find_by_name(params[:oauthApp])
    unless ca.blank?
      user = User.find_by_id_and_token(params[:user_id], "#{params[:token]}")
      unless user.blank?
        password = Base64.decode64(params[:password])
        user.password = password
        user.save

        muvi << {:result => "user password updated"}
        result_array['items'] = muvi
        render :text => "jsonpcallback_pass('#{result_array.to_json}')"
      else
        muvi << {:result => "user token mismatch"}
        result_array['items'] = muvi
        render :text => "jsonpcallback_pass('#{result_array.to_json}')"
      end

    else
      muvi << {:result => "app not authorized"}
      result_array['items'] = muvi
      render :text => "jsonpcallback_pass('#{result_array.to_json}')"
    end
  end

  def get_user_pass_token
    result_array = {}
    muvi = []

    ca = ClientApplication.find_by_name(params[:oauthApp])
    unless ca.blank?
      user = User.find_by_email(params[:email])
      unless user.blank?
        reset_password_token = Digest::SHA1.hexdigest([Time.now, rand].join)
        user.update_attribute(:reset_password_token, reset_password_token)

        @final = [:user_id => user.id, :reset_password_token => reset_password_token]
        muvi << {:result => @final}
        result_array['items'] = muvi
        render :text => "jsonpcallback_pass_token('#{result_array.to_json}')"
      else
        muvi << {:result => "user does not exist"}
        result_array['items'] = muvi
        render :text => "jsonpcallback_pass_token('#{result_array.to_json}')"
      end
    else
      muvi << {:result => "app not authorized"}
      result_array['items'] = muvi
      render :text => "jsonpcallback_pass_token('#{result_array.to_json}')"
    end
  end

  def reset_user_password
    result_array = {}
    muvi = []

    ca = ClientApplication.find_by_name(params[:oauthApp])
    unless ca.blank?
      user = User.find_by_id_and_reset_password_token(params[:user_id], params[:reset_password_token])
      unless user.blank?
        password = Base64.decode64(params[:password])
        user.password = password
        user.save

        muvi << {:result => "user password has been reset"}
        result_array['items'] = muvi
        render :text => "jsonpcallback_reset_pass('#{result_array.to_json}')"

      else
        muvi << {:result => "Token doesnot match"}
        result_array['items'] = muvi
        render :text => "jsonpcallback_reset_pass('#{result_array.to_json}')"
      end
    else
      muvi << {:result => "app not authorized"}
      result_array['items'] = muvi
      render :text => "jsonpcallback_reset_pass('#{result_array.to_json}')"
    end
  end

  protected
  # Override this to match your authorization page form
  # It currently expects a checkbox called authorize
   def user_authorizes_token?
     params[:authorize] == '1'
   end

  # should authenticate and return a user if valid password.
  # This example should work with most Authlogic or Devise. Uncomment it
   def authenticate_user(username,password)
     user = User.find_by_email params[:username]
     if user && user.valid_password?(params[:password])
       user
     else
       nil
     end
   end


end

