class Admin::MovieReviewsController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :admin?
  layout 'admin'

  before_filter :find_movie

  def index
   @reviews =  @movie.reviews.latest.paginate(:page => params[:page], :per_page => 50)
  end

  def delete_reviews
    unless params[:review_ids].blank?
      Review.where('id in (?)', params[:review_ids]).map {|review| review.destroy }
      @movie.update_tweets_count_after_tweet_delete
    end
    redirect_to admin_movie_movie_reviews_path(@movie)
    Movie.update_one_movie_percentage(@movie)
  end

  private
  def find_movie
    @movie = Movie.find_using_id(params[:movie_id]).includes([:reviews]).first
  end
end

