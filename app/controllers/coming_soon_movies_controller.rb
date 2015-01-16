class ComingSoonMoviesController < ApplicationController
  skip_before_filter :authenticate_user!
  layout 'website'

  def index
    @search = Movie.comming_soon_movies.search(params[:search])
    #params[:sort] ||= 'latest_update'
    params[:sort] ||= 'release_date'
    @search = case params[:sort]
    when 'latest_update'
      @search.relation.sort_by_media_updated_date
    when 'user_interest'
      @search.relation.sort_by_tweet_percent_desc
    when 'release_date'
      @search.relation.sort_by_release_date_asc
    end
    @latest_trailers = Movie.latest_trailers
    @movies = @search.paginate(:page => params[:page], :per_page => 12)
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def show
    @movie = Movie.find_using_id(params[:id]).first
    unless @movie.release_date.blank? || @movie.release_date > Date.today
      redirect_to movie_path(@movie) and return
    end
    #test ppppppppppppp
    #@movie_tweets = @movie.tweets.latest.paginate(:page => 1, :per_page => 4)
   # @facebook_posts = @movie.facebook_feeds.posts.friends_ids(current_user.facebook_friends_ids).latest.paginate(:page => params[:page], :per_page => 4) if current_user && current_user.facebook_omniauth
    @actors = []
    @movie.movie_casts.includes(:celebrity).each do |cast|
      case cast.cast_type
      when 'actor' then @actors << cast
      when 'director' then @director = cast
      when 'producer' then @producer = cast
      when 'writer' then @writer = cast
      when 'musics' then @music = cast
      end
    end
  end

end

