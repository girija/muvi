class Admin::NewTweetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin?
  layout 'admin'


  def index
    movie_id = ""
    @search = Movie.released.search(params[:search])
    if !params[:search].blank?
      if !params[:search][:name_contains].blank?
        @search = Movie.released.search(params[:search])
        unless @search.blank?
          @search.each do |movie|
            if movie_id.blank?
              movie_id = movie.id.to_s
            else
              movie_id += movie_id.to_s + ","+ movie.id.to_s
            end
          end
          #movie_id = movie_id.chop
         
          @new_tweets = Tweet.reviews.find(:all,:conditions => ["movie_id IN (#{movie_id}) AND review in('pos','neg') AND curated ='f'"])
        end
      else
        @new_tweets = Tweet.reviews.find(:all,:conditions => ["movie_id IS NOT NULL AND review in('pos','neg') AND curated ='f'"]).paginate(:page => params[:page], :per_page => 100)
      end
    else
      @new_tweets = Tweet.reviews.find(:all,:conditions => ["movie_id IS NOT NULL AND review in('pos','neg') AND curated ='f'"]).paginate(:page => params[:page], :per_page => 100)
    end

  end

  def celeb_tweets
    if !params[:celeb].blank?
      if !params[:celeb][:name_contains].blank?
        @search = Celebrity.search(params[:celeb])
        unless @search.blank?
          celeb_id = ""
          @search.each do |celeb|
            if celeb_id.blank?
              celeb_id = celeb.id.to_s
            else
              celeb_id += celeb_id.to_s + ","+ celeb.id.to_s
            end
          end
          #celeb_id = celeb_id.chop
          @new_tweets = CelebTweet.find(:all,:conditions => ["celebrity_id IN (#{celeb_id}) AND review in('pos','neg') AND curated ='f'"])
        end
      else
        @new_tweets = CelebTweet.find(:all, :conditions => ["celebrity_id IS NOT NULL AND review in('pos','neg') AND curated = 'f'"]).paginate(:page => params[:page], :per_page => 100)
    end

    else
      @new_tweets = CelebTweet.find(:all, :conditions => ["celebrity_id IS NOT NULL AND review in('pos','neg') AND curated = 'f'"]).paginate(:page => params[:page], :per_page => 100)
    end
  end

  def tweet_updates
    if params[:commit] == "Positive"
      review = "pos"
    elsif params[:commit] == "Nagative"
      review = "neg"
    elsif params[:commit] == "Neutral"
      review = "neu"
    elsif params[:commit] == "Ignore"
      review = "ign"
    end

    
    if request.env["HTTP_REFERER"] =~ /celeb_tweets/
      unless params[:tweet_ids].blank?
        CelebTweet.where('id in (?)', params[:tweet_ids]).each do |tweet|
          tweet.update_attribute("review", review )
          tweet.update_attribute("curated", "t" )
        end
      end
       #redirect_to(celeb_tweets_admin_new_tweets_path)
       redirect_to(request.env["HTTP_REFERER"])
    else
      unless params[:tweet_ids].blank?
        Tweet.where('id in (?)', params[:tweet_ids]).each do |tweet|
          tweet.update_attribute("review", review )
          tweet.update_attribute("curated", "t" )
          Movie.update_one_movie_percentage(tweet.movie)
        end
      end        
      #redirect_to(admin_new_tweets_path)
      redirect_to(request.env["HTTP_REFERER"])
    end
    
  end

end

