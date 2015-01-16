class Admin::PostcardsController < ApplicationController

  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :admin?
  layout 'admin'

  def index
    @card_requests = Postcard.all.paginate(:page => params[:page], :per_page => 50)
  end

end
