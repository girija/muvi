class Admin::MovieTweetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin?
  before_filter :find_movie, :except => [:tweet_update]
  layout 'admin'

  def index
   @tweets =  @movie.tweets.latest.paginate(:page => params[:page], :per_page => 5000)
  end

  def show
    @tweet = @movie.tweets.find(params[:id])
  end

  def new
    @tweet = @movie.tweets.new
  end

  def edit
    @tweet = @movie.tweets.find(params[:id])
  end

  def create
    @tweet = @movie.tweets.new(params[:tweet])

    respond_to do |format|
      if @tweet.save
        format.html { redirect_to(edit_admin_movie_movie_tweet_path(@movie, @tweet), :notice => 'Tweet was successfully created.') }
        format.xml  { render :xml => @tweet, :status => :created, :location => @tweet }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tweet.errors, :status => :unprocessable_entity }
      end
    end
  end


  def update
    @tweet = @movie.tweets.find(params[:id])

    respond_to do |format|
      if @tweet.update_attributes(params[:tweet])
        format.html { redirect_to(admin_movie_movie_tweet_path(@movie, @tweet), :notice => 'tweet was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tweet.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @movie.tweets.find(params[:id]).destroy
    redirect_to admin_movie_movie_tweets_path(@movie)
  end


  def tweet_review_update
   tweet = Tweet.find(params[:id])
   tweet.update_attributes({:review => params[:option]})
   render :nothing => true
  end


  def delete_tweets
    unless params[:tweet_ids].blank?
      Tweet.where('id in (?)', params[:tweet_ids]).each do |tweet|
        #TweetIgnNeu.create(tweet.attributes.except("id", "updated_at", "created_at"))
        tweet.destroy
      end
      @movie.update_tweets_count_after_tweet_delete
    end
    redirect_to admin_movie_movie_tweets_path(@movie)
  end


  private
  def find_movie
    @movie = Movie.find_using_id(params[:movie_id]).includes([:tweets]).first
  end

end

