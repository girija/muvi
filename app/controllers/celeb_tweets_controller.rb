class CelebTweetsController < ApplicationController  
skip_before_filter :authenticate_user!  
layout 'website'

def index
if !params[:by].blank?
      @celebrity ||= Celebrity.find(params[:id])
      if params[:by] == "user"
        twitter_query = "((select 'celebrity_tweet' as model, content,rating,review,twitter_screen_name as twitter_name,tweeted_on from celeb_tweets tweets WHERE  (tweets.fan_tweet = 't')  AND (tweets.review = 'pos' or tweets.review = 'neg' ) AND (tweets.celebrity_id = #{@celebrity.id}) ) order by twitter_name asc) as temp"
      else
        twitter_query = "((select 'celebrity_tweet' as model, content,rating,review,twitter_screen_name as twitter_name,tweeted_on from celeb_tweets tweets WHERE  (tweets.fan_tweet = 'f')  AND (tweets.review = 'pos' or tweets.review = 'neg' ) AND (tweets.celebrity_id = #{@celebrity.id}) ) order by twitter_name asc) as temp"
      end

      total_twitter_entries = ActiveRecord::Base.connection.execute("select count(*) as count from #{twitter_query}").first['count'].to_i

      result_twitter = ActiveRecord::Base.connection.select_rows("select * from #{twitter_query}")
      @celebrity_tweets =  result_twitter.paginate(:page => params[:page], :per_page =>  4)


      respond_to do |format|
        format.html { render :layout => false}
        format.js {}
      end
    end

end

  def for_user
    @celeb_tweets = CelebTweet.latest.where(:twitter_screen_name => params[:twitter_name]).paginate(:page => params[:page], :per_page => 12)
  end

end
