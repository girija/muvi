$invite_id = 0
class RegistrationsController < Devise::RegistrationsController
  before_filter :msn_redirect, :only => [:edit]
  #layout 'website'
  layout:check

  def new
    $invite_id  = params[:invite_id]
    build_resource({})
    #render_with_scope :new
    #render :layout => false
  end

  def create
    build_resource
    #if resource.save
    #  #unless resource.active?
    #  unless resource.active?
    #    expire_session_data_after_sign_in!
    #  end
    
    #  #resource.delay.fetch_fb_feeds if omniauth['provider'] == 'facebook'
    #  #sign_in_and_redirect(resource_name, resource)

    #  #set_flash_message :notice, :signed_up
    #  #after_sign_up_path_for(resource)
    #  clean_up_passwords(build_resource)
    #end
     if resource.save
       resource.facebook_id_update
      if resource.active?
        if sign_in(resource_name, resource)
          resource.update_attribute("confirmed_at", Time.now)
        end
        #respond_with resource, :location => after_sign_up_path_for(resource)
      else
        expire_session_data_after_sign_in!
        #respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords(resource)
      #respond_with_navigational(resource) { render_with_scope :new }
    end
  end

  def edit
     @country_list = ["Afghanistan","Albania","Algeria","Andorra","Angola","Anguilla","Antigua &amp; Barbuda","Argentina","Armenia","Aruba","Australia","Austria","Azerbaijan","Bahamas" ,"Bahrain","Bangladesh","Barbados","Belarus","Belgium","Belize","Benin","Bermuda","Bhutan","Bolivia","Bosnia &amp; Herzegovina","Botswana","Brazil","British Virgin Islands" ,"Brunei","Bulgaria","Burkina Faso","Burundi","Cambodia","Cameroon","Cape Verde","Cayman Islands","Chad","Chile","China","Colombia","Congo","Cook Islands","Costa Rica" ,"Cote D Ivoire","Croatia","Cruise Ship","Cuba","Cyprus","Czech Republic","Denmark","Djibouti","Dominica","Dominican Republic","Ecuador","Egypt","El Salvador","Equatorial Guinea" ,"Estonia","Ethiopia","Falkland Islands","Faroe Islands","Fiji","Finland","France","French Polynesia","French West Indies","Gabon","Gambia","Georgia","Germany","Ghana" ,"Gibraltar","Greece","Greenland","Grenada","Guam","Guatemala","Guernsey","Guinea","Guinea Bissau","Guyana","Haiti","Honduras","Hong Kong","Hungary","Iceland","India" ,"Indonesia","Iran","Iraq","Ireland","Isle of Man","Israel","Italy","Jamaica","Japan","Jersey","Jordan","Kazakhstan","Kenya","Kuwait","Kyrgyz Republic","Laos","Latvia" ,"Lebanon","Lesotho","Liberia","Libya","Liechtenstein","Lithuania","Luxembourg","Macau","Macedonia","Madagascar","Malawi","Malaysia","Maldives","Mali","Malta","Mauritania" ,"Mauritius","Mexico","Moldova","Monaco","Mongolia","Montenegro","Montserrat","Morocco","Mozambique","Namibia","Nepal","Netherlands","Netherlands Antilles","New Caledonia" ,"New Zealand","Nicaragua","Niger","Nigeria","Norway","Oman","Pakistan","Palestine","Panama","Papua New Guinea","Paraguay","Peru","Philippines","Poland","Portugal" ,"Puerto Rico","Qatar","Reunion","Romania","Russia","Rwanda","Saint Pierre &amp; Miquelon","Samoa","San Marino","Satellite","Saudi Arabia","Senegal","Serbia","Seychelles" ,"Sierra Leone","Singapore","Slovakia","Slovenia","South Africa","South Korea","Spain","Sri Lanka","St Kitts &amp; Nevis","St Lucia","St Vincent","St. Lucia","Sudan" ,"Suriname","Swaziland","Sweden","Switzerland","Syria","Taiwan","Tajikistan","Tanzania","Thailand","Timor L'Este","Togo","Tonga","Trinidad &amp; Tobago","Tunisia" ,"Turkey","Turkmenistan","Turks &amp; Caicos","Uganda","Ukraine","United Arab Emirates","United Kingdom","Uruguay","Uzbekistan","Venezuela","Vietnam","Virgin Islands (US)" ,"Yemen","Zambia","Zimbabwe"];
    super
  end

  def update
    # Devise use update_with_password instead of update_attributes.
    # This is the only change we make.
    #begin
      lang = []
      params[:language].each do |l|
        if l != "0"
          lang << l
        end
      end
      user = User.find_by_id(params[:user][:id])
      user.update_attribute("language",lang.to_s)
      if params[:user][:subscribe_newsletter] == "1"
        params[:user][:subscribe_newsletter] = true
      else
        params[:user][:subscribe_newsletter] = false
      end
      if params[:user][:subscribe_notification] == "1"
        params[:user][:subscribe_notification] = true
      else
        params[:user][:subscribe_notification] = false
      end

      user.update_attribute("subscribe_notification", params[:user][:subscribe_notification])
      user.update_attribute("subscribe_newsletter" , params[:user][:subscribe_newsletter])
      if resource.update_attributes(params[resource_name])
        set_flash_message :notice, :updated
        # Line below required if using Devise >= 1.2.0
        #sign_in resource_name, resource, :bypass => true
        #redirect_to edit_user_registration_path
        if request.env["HTTP_REFERER"] =~ /\/msn_embed/
          redirect_to "/msn_embed/users/edit"
        else
          #redirect_to edit_user_registration_path
          redirect_to "/profile_edit"
        end
      else
        clean_up_passwords(resource)
        render_with_scope :edit
      end
    #rescue
    #end
  end


  def destroy
    super
  end

  def cancel
    super
  end

  def welcome
  end

  def expire_session_data_after_sign_in!
    session.keys.grep(/^devise\./).each { |k| session.delete(k) }
  end
  
  def login
     render :layout => 'facebook'
  end

  def user_login
    #login from browser with direct url
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
    token = params[:data][:id]
    puts token
    begin
      amount = params[:amount].to_i * 100
      charge = Stripe::Charge.create( :amount => amount, :currency => "usd",:card => token,  :description => "")
      #muvi_coin = MovieCoin.find_by_user_id(current_user.id)
      #@if !muvi_coin.nil?
      #  muvi_coin.movie_coins = muvi_coin.movie_coins.to_i + params[:movie_coins].to_i
      #  muvi_coin.save
      #else
      #  muvi_coin = MovieCoin.new
      #  muvi_coin.user_id = current_user.id
      #  muvi_coin.movie_coins = params[:movie_coins]
      #  muvi_coin.save
      #end
      user_profile = current_user.user_profile
      movie_coins = user_profile.movie_coins.to_i + params[:movie_coins].to_i
      user_profile.update_attribute("movie_coins",movie_coins)
      payment_trans = PaymentTransaction.new
      payment_trans.user_id = current_user.id
      payment_trans.name_card = params[:name_card]
      payment_trans.token_no = token
      payment_trans.card_last4 = params[:data][:card][:last4]
      payment_trans.card_type = params[:data][:card][:type]
      payment_trans.exp_month = params[:data][:card][:exp_month]
      payment_trans.exp_year = params[:data][:card][:exp_year]
      payment_trans.save
      render :js => "$('#card_detail').hide();$('#avail_coins').html('Available : #{user_profile.movie_coins}');$('#payment_suc').html('Your transaction is successful!!')"

    rescue Stripe::CardError => e
      body = e.json_body
      err  = body[:error]
      render :js => "$('.payment-errors').html(\"#{err[:message]}\")"
    rescue
    end
  end
end


