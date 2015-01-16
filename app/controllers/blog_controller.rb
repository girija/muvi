class BlogController < ApplicationController
 skip_before_filter :authenticate_user!
 skip_before_filter :verify_authenticity_token
 before_filter :msn_redirect, :only => [:show]
 #layout 'website'
 layout:check

  def index
 
  end
end
