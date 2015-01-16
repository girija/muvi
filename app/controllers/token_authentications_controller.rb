class TokenAuthenticationsController < ApplicationController 
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  def create
    @user = User.find(params[:user_id])
    @user.reset_authentication_token!
    redirect_to edit_user_registration_path(@user)
  end

  def destroy
    @user = User.criteria.id(params[:id]).first
    @user.authentication_token = nil
    @user.save
    redirect_to edit_user_registration_path(@user)
  end

end
