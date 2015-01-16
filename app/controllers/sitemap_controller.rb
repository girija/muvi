class SitemapController < ApplicationController
  #skip_before_filter :authenticate_user!
  def index
    @movie = Movie.find(:all, :limit => 10)
    @celebrity = Celebrity.find(:all, :limit => 10)
    
    headers['Content-Type'] = 'application/xml'
    render :layout => false
  end

end
