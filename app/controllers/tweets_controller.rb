class TweetsController < ApplicationController
  skip_before_filter :authenticate_user!
  layout 'website'

  def index
    if params[:by].blank?
      @movie ||= Movie.find(params[:id]) rescue ''
      unless @movie.blank? 
         if !params[:user].blank?
           reviews_query = "((select 'movie_review' as model,id,user_id,description,rating,'' as review,'' as twitter_name,created_at from reviews where reviews.movie_id=#{@movie.id} order by reviews.created_at desc) ) as temp"
           total_entries = ActiveRecord::Base.connection.execute("select count(*) as count from #{reviews_query}").first['count'].to_i
          total_user_entries = ActiveRecord::Base.connection.execute("select count(*) as count from #{reviews_query}").first['count'].to_i
           result_review = ActiveRecord::Base.connection.select_rows("select * from #{reviews_query}")
           @movie_user_reviews = result_review.paginate(:page => params[:page], :per_page =>  15)
         else
           if @movie.release_date.blank?
             twitter_query = "((select 'movie_tweet' as model,id,user_id,content,rating,review,twitter_screen_name as twitter_name,tweeted_on from tweets WHERE ( tweets.interest = true) AND (tweets.review = 'pos' or tweets.review = 'neg'
 ) AND (tweets.movie_id = #{@movie.id}) ) order by tweets.tweeted_on desc) as temp"
           elsif @movie.release_date > Date.today
             twitter_query = "((select 'movie_tweet' as model,id,user_id,content,rating,review,twitter_screen_name as twitter_name,tweeted_on from tweets WHERE ( tweets.interest = true ) AND (tweets.review = 'pos' or tweets.review = 'neg'
 ) AND (tweets.movie_id = #{@movie.id}) ) order by tweets.tweeted_on desc) as temp"
           else
             twitter_query = "((select 'movie_tweet' as model,id,user_id,content,rating,review,twitter_screen_name as twitter_name,tweeted_on from tweets WHERE ( tweets.interest = false) AND (tweets.review = 'pos' or tweets.review = 'neg' ) AND (tweets.movie_id = #{@movie.id}) ) order by tweets.tweeted_on desc) as temp"
           end
       
          total_twitter_entries = ActiveRecord::Base.connection.execute("select count(*) as count from #{twitter_query}").first['count'].to_i
      
          result_twitter = ActiveRecord::Base.connection.select_rows("select * from #{twitter_query}")
          @movie_tweets =  result_twitter.paginate(:page => params[:page], :per_page =>  15)
        end
      end
      respond_to do |format|
        format.html { render :layout => false}
        format.js {}
      end
    end
   
    if !params[:by].blank?
      @celebrity ||= Celebrity.find(params[:id]) rescue ''
      unless @celebrity.blank?
        if params[:by] == "user"
          twitter_query = "((select 'celebrity_tweet' as model,id, content,rating,review,twitter_screen_name as twitter_name,tweeted_on from celeb_tweets tweets WHERE  (tweets.fan_tweet = 't')  AND (tweets.review = 'pos' or tweets.review = 'neg' ) AND (tweets.celebrity_id = #{@celebrity.id}) ) order by tweets.tweeted_on desc) as temp"
        else
          twitter_query = "((select 'celebrity_tweet' as model,id, content,rating,review,twitter_screen_name as twitter_name,tweeted_on from celeb_tweets tweets WHERE  (tweets.fan_tweet = 'f')  AND (tweets.celebrity_id = #{@celebrity.id}) ) order by tweets.tweeted_on desc) as temp"
        end

        total_twitter_entries = ActiveRecord::Base.connection.execute("select count(*) as count from #{twitter_query}").first['count'].to_i

        result_twitter = ActiveRecord::Base.connection.select_rows("select * from #{twitter_query}")
        @celebrity_tweets =  result_twitter.paginate(:page => params[:page], :per_page =>  15)
      end

      respond_to do |format|
        format.html { render :layout => false}
        format.js {}
      end
    end

  end

  def for_user
    @movie_tweets = Tweet.latest.where(:twitter_screen_name => params[:twitter_name]).paginate(:page => params[:page], :per_page => 12)
  end

  def vote
    @tweet = CelebTweet.find_by_id(params[:id])
    @tweet.vote :voter =>current_user, :vote => params[:vote]
    render :text=>"true"  
  end
end

