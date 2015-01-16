class MyReviewsController < ApplicationController
  before_filter :is_critic?
  layout 'website'

  def index
    if current_user.film_critic.blank?
      FilmCritic.create(:user_id => current_user.id)
      current_user.reload
    end
    movie_ids = CriticsReview.where('film_critic_id = ?', current_user.film_critic.id.to_s).all.collect(&:movie_id)
    movie_ids.compact! unless movie_ids.blank?
    movie_ids = [0] if movie_ids.blank?
    @search = Movie.name_is_not_blank.released.latest.where('id not in (?)', movie_ids).search(params[:search])
    @movies = @search.paginate(:page => params[:page], :per_page => 5)
  end

  def create
   ct = CriticsReview.new(params[:critics_review])
   ct.save
   redirect_to my_reviews_path
  end


  def update
     ct =  CriticsReview.find(params[:id])
     ct.update_attributes(params[:critics_review])
     redirect_to critics_my_reviews_path
  end
end

