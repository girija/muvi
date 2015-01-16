class PostCardController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  layout:check

  def index
    if current_user
      @upi =  UserPaymentInfo.find_by_user_id(current_user.id)
      if @upi.blank?
        @upi = {}
        @upi[:credit_card_no] = ''
        @upi[:credit_card_cvv] = ''
        @upi[:credit_card_mm] = ''
        @upi[:credit_card_yyyy] = ''
        @upi[:name] = ''
        @upi[:address_1]= ''
        @upi[:address_2]= ''
        @upi[:city]=''
        @upi[:state]=''
        @upi[:zip]=''
      end
      unless params[:stripeToken].blank?
        token = params[:stripeToken]
        pc = Postcard.new
        pc.poster_id = params[:poster_id]
        pc.greeting = params[:send_to_greeting]
        pc.name = params[:send_to_name]
        pc.address_1 = params[:send_to_address_1]
        pc.address_2 = params[:send_to_address_2]
        pc.city = params[:send_to_city]
        pc.state = params[:send_to_state]
        pc.zip = params[:send_to_zip]
        pc.user_id = current_user.id
        pc.status = 0
        pc.save 
        upi =  UserPaymentInfo.find_by_user_id(current_user.id)
        if upi.blank?
          user_payment_info = UserPaymentInfo.new
        else
          user_payment_info = upi
        end
        user_payment_info.user_id = current_user.id
        user_payment_info.credit_card_no = params[:pay_to_credit_card]
        user_payment_info.credit_card_cvv = params[:pay_to_security_cvv2]
        user_payment_info.credit_card_mm = params[:pay_to_expiration_mm]
        user_payment_info.credit_card_yyyy = params[:pay_to_expiration_yyyy]
        user_payment_info.name = params[:pay_to_name]
        user_payment_info.address_1 = params[:pay_to_address_1]
        user_payment_info.address_2 = params[:pay_to_address_2]
        user_payment_info.city = params[:pay_to_city]
        user_payment_info.state = params[:pay_to_state]
        user_payment_info.zip = params[:pay_to_zip]
        user_payment_info.save
        begin
          charge = Stripe::Charge.create( :amount => 75, :currency => "usd",:card => token,  :description => "")
        rescue
        end
        PostCardMailer.send_post_card(pc).deliver
        redirect_to :action => 'thankyou'
      end
    end
  end
  def thankyou
    puts "xxxxxxxxxxxxxxxxx" 
  end
  def stripe
    unless params[:stripeToken].blank?
    token = params[:stripeToken]
    charge = Stripe::Charge.create( :amount => 150, :currency => "usd",:card => token,  :description => "chitta@example.com")
    end
  end
end
