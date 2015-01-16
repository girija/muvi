class StudioController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  #before_filter :msn_redirect, :only => [:show]
  layout :false

  def index

  end
end


