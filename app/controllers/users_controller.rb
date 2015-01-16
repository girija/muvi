class UsersController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :msn_redirect, :only => [:sign_up, :user_signup]

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

    # Send email
    @email = data["registration"]["email"]
    @subject = "Welcome to MUVI!"
    @content = "Following is your MUVI username and password <br>
                username: #{data["registration"]["email"]}<br>
                password: #{data["registration"]["password"]}"

    #UserMailer.deliver_notify(@email, @subject, @content)
    UserMailer.notify(@email, @subject, @content).deliver
    # Ends

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
      if request.env["HTTP_REFERER"] =~ /\/msn_embed/
        redirect_to "/msn_embed/home"
      else
        redirect_to "/"
      end
    end
  end 
    
  def user_register
    Rails.cache.clear
    is_valid = ""

    #@is_valid = 0
    @is_allowed = 0

    u = User.find_by_email(params[:email])
    unless u.blank?
      @is_allowed = 0
    else
      @is_allowed = 1
    end

    #is_valid = User.validate_email_id(params[:email])
    #if is_valid == false
    #  	@is_valid = 0
    #else
    #  	@is_valid = 1
    #end


    if @is_allowed == 1 #and @is_allowed == 1
	    unless u.blank?
	      #sign_in_and_redirect(:user, u)
	      if request.env["HTTP_REFERER"] =~ /\/msn_embed/
	        sign_in(:user, u)
	        redirect_to "/msn_embed/home"
	      else
	        #sign_in_and_redirect(:user, u)
	        sign_in(:user, u)
	      end
	    else
	      #Save user
	      @u = User.new
	      @u.email = params[:email]
	      #@u.password = params[:password]
	      @u.password = Base64.decode64(params[:hid_password])
	      @u.save
	
	      #Save user profile
	      @up = UserProfile.new
	      @up.display_name = params[:name]
	      @up.user_id = @u.id
	      @up.save

	      # Send email
	      @email = params[:email]
	      @subject = "Welcome to MUVI!"
	      @content = "Following is your MUVI username and password <br>
	                username: #{params[:email]}<br>
	                password: #{Base64.decode64(params[:hid_password])}"
	
	      #UserMailer.deliver_notify(@email, @subject, @content)
	      # Ends
	      # Generate authentication_token
	      @u.reset_authentication_token!
              User.delay.validate_email_id(params[:email], @u.id)
	      ###############################
	      UserMailer.welcome(@u)

              cookies[:sign_in_chk] = {:value => "1", :expires => 20.days.from_now}
              cookies[:sign_in] = {:value => "1", :expires => 20.days.from_now}

	      if request.env["HTTP_REFERER"] =~ /\/msn_embed/
	        sign_in(:user, @up.user)
	        redirect_to "/msn_embed/home"
	      else
	        if !params[:act_refer_type].blank? and !params[:act_refer_type].nil?
	          sign_in(:user, @up.user)
	          #redirect_to "/home/index/#{@u.id}"
	          #redirect_to "/show_feed/#{@u.id}"
        	  
		  redirect_to "/"

	        else
        	  #sign_in_and_redirect(:user, @u)
		  #current_user = User.find_by_id(@u.id)
	          sign_in(:user, @u)
	        end

        	current_user = User.find_by_id(@u.id)
                list_of_movie = ListOfMovie.new
                list_of_movie.user_id = current_user.id
                list_of_movie.save
		#ListOfMovie.update_discovery(current_user.id)
        	#@link = "/users/sign_in?authentication_key=#{current_user.authentication_token}"
	      end
	    end
      end
  end

  def fb_register
    user = User.find_by_email(params[:fb_user_email])
    unless user.blank?
      if user.user_tokens.blank?
        #Save user token
        @ut = UserToken.new
        @ut.user_id = user.id
        @ut.provider = "facebook"
        @ut.uid = params[:user_user_tokens_attributes_0_uid]
        @ut.token = params[:user_user_tokens_attributes_0_token]
        @ut.save
      end

     #cookies[:sign_in_chk] = {:value => "1", :expires => 20.days.from_now}
     #cookies[:sign_in] = {:value => "1", :expires => 20.days.from_now}

      if request.env["HTTP_REFERER"] =~ /\/msn_embed/
        sign_in(:user, user)
        redirect_to "/msn_embed/home"
      else
        if !params[:act_refer_type].blank? and !params[:act_refer_type].nil?
          sign_in(:user, @ut.user)
          #redirect_to "/home/index/#{@u.id}"
          #redirect_to "/show_feed/#{@u.id}"
          redirect_to "/"
        else
          #sign_in_and_redirect(:user, user)
          sign_in(:user, user)
        end
      end
    else 

      #Save user
      @u = User.new
      @u.email = params[:fb_user_email]
      #@u.password = params[:fb_password]
      @u.password = Base64.decode64(params[:hid_fb_password])
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
    
      # Generate authentication_token
      @u.reset_authentication_token!
      ###############################
      UserMailer.welcome(@u)

      cookies[:sign_in_chk] = {:value => "1", :expires => 20.days.from_now}
      cookies[:sign_in] = {:value => "1", :expires => 20.days.from_now}

      if request.env["HTTP_REFERER"] =~ /\/msn_embed/
        sign_in(:user, @up.user)
        redirect_to "/msn_embed/home"
      else
        if !params[:act_refer_type].blank? and !params[:act_refer_type].nil?
          sign_in(:user, @up.user)
          #redirect_to "/show_feed/#{@u.id}"
          redirect_to "/"
        else
          #sign_in_and_redirect(:user, @ut.user)
	  #current_user = User.find_by_id(@u.id)
          sign_in(:user, @u)
        end

        current_user = User.find_by_id(@u.id)
        list_of_movie = ListOfMovie.new
        list_of_movie.user_id = current_user.id
        list_of_movie.save
	#ListOfMovie.update_discovery(current_user.id)
        #@link = "/users/sign_in?authentication_key=#{current_user.authentication_token}"
      end
    end
  end

  def check_user_login_mob
    a = []
    user_token = UserToken.find_by_uid(params[:user_id])
    if user_token
      user = user_token.user
      if user
        a << {:existing => 1, :id => user.id, :name => user.display_name, :email => user.email}
        render :json => JSON.pretty_generate(a)
      end
    else
      a << {:existing => 0}
      render :json => JSON.pretty_generate(a)
    end
  end

  def invite_contact
    params[:contacts].each do|e|
      sub = "You have been invited to join muvi."
      send_user_invitation(e, sub)
    end
  end


  def user_invitation
    if !params[:from].blank?
      sub = "You have been invited by #{current_user.display_name} to join muvi."
    else
      sub = "Your request to join Muvi is approved."
    end

    send_user_invitation(params[:email], sub)
  end

  def send_user_invitation(email, subject)
    params[:email] = email

    @email = params[:email]

    user = User.where(:email => params[:email]).first
    if !user
      @u = User.new
      size = 7
      charset = %w{ 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z}
      pw = (0...size).map{ charset.to_a[rand(charset.size)] }.join

      @u.email = @email
      @u.password = pw
      @u.password_confirmation = pw

      if @u.save
        #@subject = "Your request to join Muvi is approved."
        #@subject = "You have been invited by #{current_user.display_name} to join muvi."
        @subject = subject
        @content = "Hi,<br>
                    We are glad to welcome you to Muvi. It is a discovery platform for movies. It works like an external brain, where you<br>
                    outsource all your decisions about what to watch,whenever you get time.  Now you would be thinking, Hey I donot<br>
                    need this. I know better what I want to watch. Indeed you do. And we believe that. The problem is, to know about<br>
                    any movie, you first have to search and find out one, then figure out if it is good enough for your taste. Or if you<br>
                    already know any movie that you wanna watch, you have to spend time doing all sorts of research and then decide to<br>
                    watch or not. What happens when you come across a new movie? Again you have to do all that research, even<br>
                    though your choice and taste in the kind of movies that you watch, has remained fairly constant. This is where we<br>
                    come in. We try to  remember and develop a pattern about your taste, for every movie that you have already watched,<br>
                    or are wanting to watch. Our algorithms pull out movies exclusively for you. So all you have to do is just grab your<br>
                    bowl of popcorn, top off your soda, sit back and watch.<br>
                    <br>
                    Here is your<br>
                    Username: #{@email}<br>
                    Password: #{pw}<br>
                    <br>
                    Just go to <a href=\"http://www.muvi.com\">Muvi.com</a>. Click on login, enter these credentials and discover movies.<br>
                    And hey we forgot one last thing about Muvi, now you donot have to depend on the cookie cutter reviews from critics.<br>
                    In a single click you can ask your own buddies about the movie.<br>
                    Muvi is currently in Beta stage and open to join by invitation only. We look for your comments and feedback, please <br>
                    email us at info@muvi.com, would love to hear from you.<br>
                    <br>
                    Cheers,<br>
                    Your friends at Muvi<br>"
                     
        UserMailer.deliver_notify(@email, @subject, @content)

        @success = "<span style='color:green'>Thank you for your interest. A private invitation has been sent to your email.</span>".html_safe
        flash[:msg] = @success
        flash[:err] = ""

        respond_to do |format|
          format.js
        end
      end
    else
      flash[:msg] = "<span style='color:red'>This email already exists.<br> You can login or take help of forget password.</span>".html_safe
      flash[:err] = 1

      respond_to do |format|
        format.js
      end
    end
  end
  def follow
    list = UserMovieList.find(params["list_id"])
    user = User.find(params["user_id"])
    user.follow(list)


    unless params[:notification_id].blank?
      #chk_1 = AllActivity.find(:first, :conditions => ["id = #{params[:activity_id]}"])
      #chk_1.update_attribute('viewed', 't') unless chk_1.blank?

      AllNotification.find(:first, :conditions => ["id = #{params[:notification_id]}"]).destroy
    end

    if !list.nil? and !list.blank?
      AllActivity.create_follow_activity(list, user, "")
    end
    FeedHistory.update_history(params["user_id"], "follow", params["list_id"])

    render :partial => 'user_profiles/followers', :locals => {:@tagged => list,:@user_profile=> user.user_profile}
  end

  def follow_all
    list = ListOfMovie.find(params["list_id"])
    user = User.find(params["user_id"])
    user.follow(list)
    render :partial => 'user_profiles/followers_all_seen', :locals => {:@tagged => list}
  end
  def unfollow
    list = UserMovieList.find(params["list_id"])
    user = User.find(params["user_id"])
    user.stop_following(list)
    render :partial => 'user_profiles/followers', :locals => {:@tagged => list,:@user_profile=> user.user_profile}
  end
  def unfollow_all
    list = ListOfMovie.find(params["list_id"])
    user = User.find(params["user_id"])
    user.stop_following(list)
    render :partial => 'user_profiles/followers_all_seen', :locals => {:@tagged => list}
  end

  def email_join
    unless params[:from].blank?
      from = params[:from]
    else
      from = ""
    end
    render :partial => "email_join", :locals => {from: from}
  end

  def fb_join
    render :partial => "fb_join"
  end

  def fb_join_popup
    render :partial => "fb_join_popup"
  end
  def demo_user_login
    u = User.find_by_email("tutestuser360@rediff.com")
    unless u.blank?
      sign_in(:user, u)
    end
    redirect_to "/"
  end

  def send_invitation
    User.send_fb_invitation(params[:sender], params[:user_ids], params[:access_token], params[:permalink])
    render :text => 1
  end

  def show_onboarding_page
  end

  def check_valid_login
        user = User.find_by_email(params[:email])
        if(user)
                #is_valid = user.valid_password?(Base64.decode64(params[:password]))
                password = Base64.decode64(params[:password])
                is_valid = user.valid_password?(password)
                if is_valid == false
                        render :text => 0
                else
                        render :text => 1
                end
        else
                render :text => 0
        end

  end

  def check_dup_email
    u = User.find_by_email(params[:email])
    unless u.blank?
      render :text => 0
    else
      render :text => 1
    end
  end

  def payment
    @upi =  UserPaymentInfo.find_by_user_id(current_user.id)
    if @upi.blank?
      @upi = {}
      @upi[:credit_card_no] = ''
      @upi[:credit_card_cvv] = ''
      @upi[:credit_card_mm] = ''
      @upi[:credit_card_yyyy] = ''
      @upi[:name] = ''
    end
    render :partial => "payment_form"
  end

  def after_payment
    us = UserSubscriptions.find_by_user_id(current_user.id)
    unless us.blank?
      user_subs = UserSubscriptions.find_by_user_id(current_user.id)
    else
      user_subs = UserSubscriptions.new
    end          
    user_subs.user_id = current_user.id
    user_subs.agent = "muvi"
    user_subs.amount = "1.99"
    user_subs.start_date = Date.today
    user_subs.end_date = 30.days.from_now
    user_subs.status = true
    user_subs.plan_id = 1
    user_subs.save

    upi =  UserPaymentInfo.find_by_user_id(current_user.id)
    if upi.blank?
      user_payment_info = UserPaymentInfo.new
    else
      user_payment_info = upi
    end
    user_payment_info.user_id = current_user.id
    user_payment_info.credit_card_no = params[:card_no]
    #user_payment_info.credit_card_cvv = params[:cvv]
    user_payment_info.credit_card_mm = params[:exp_month]
    user_payment_info.credit_card_yyyy = params[:exp_year]
    user_payment_info.name = params[:name_card]
    user_payment_info.save

    UserMailer.send_payment_confirmation(current_user)
    respond_to do |format|
      format.js
    end

  end

  def cancel_subscription
    us = UserSubscriptions.find_by_user_id(params[:user_id]).destroy
    upi = UserPaymentInfo.find_by_user_id(params[:user_id]).destroy
    render :text => "1"
  end

  def update_cr_info
    upi =  UserPaymentInfo.find_by_user_id(current_user.id)
    if upi.blank?
      user_payment_info = UserPaymentInfo.new
    else
      user_payment_info = upi
    end

    user_payment_info.user_id = current_user.id
    user_payment_info.credit_card_no = params[:pay_to_credit_card]
    #user_payment_info.credit_card_cvv = params[:cvv]
    user_payment_info.credit_card_mm = params[:pay_to_expiration_mm]
    user_payment_info.credit_card_yyyy = params[:pay_to_expiration_yyyy]
    user_payment_info.name = params[:name_card]
    user_payment_info.save
    respond_to do |format|
        format.html  {redirect_to root_path}
        format.js
      end
  end

end

