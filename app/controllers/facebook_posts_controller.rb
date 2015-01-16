class FacebookPostsController < ApplicationController
  skip_before_filter :authenticate_user!, :only => [:index, :facebookcover]
  layout 'website'
  #caches_page :index

  def index
    @movie ||= Movie.find(params[:id])
    @facebook_posts = if current_user && current_user.facebook_omniauth
      @movie.facebook_feeds.posts.friends_ids(current_user.facebook_friends_ids).latest.paginate(:page => params[:page], :per_page => 4)
    else
       []
    end
    respond_to do |format|
      format.html { render :layout => false}
      format.js {}
    end
  end


  def new
    @post = FacebookFeed.find(params[:id])
  end


  def create
    if current_user && !current_user.facebook_omniauth.blank?
      post = FacebookFeed.find(params[:id])
      begin
        client = Mogli::Client.new(current_user.facebook_token)
        @myself  = Mogli::User.find(post.fbid, client)
        post = Mogli::Post.new({:message => params[:reply].to_s + "\n" +'"'+ post.value.to_s + '"', :actions => {"name" =>  "Go to Muvi.com", "link" => "#{SITE_URL}"}})
        @myself.feed_create(post)
      rescue Mogli::Client::OAuthException
        #getting this strange exception. (#506) Duplicate status message
        #TODO handle this exception
      end
    end
  end
  def facebookcover

  end
end

