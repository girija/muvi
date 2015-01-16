class CriticsReviewsController < ApplicationController
  skip_before_filter :authenticate_user!
  layout 'website'
  #caches_page :index

  def index
    @movie ||= Movie.find(params[:id])
    #sort = params[:sort] || 'review_date'
    #@critics_review_search = CriticsReview.published.search({:movie_id_eq => @movie.id, :meta_sort => "#{sort}.desc"})
    if params[:sort] == "pos"
      @critics_review_search = CriticsReview.where("movie_id = ?", @movie.id).positive_rating.published.latest.search
    elsif params[:sort] == "neg"
      @critics_review_search = CriticsReview.where("movie_id = ?", @movie.id).negative_rating.published.latest.search({:movie_id_eq => @movie.id})
    else
      @critics_review_search = CriticsReview.where("movie_id = ?", @movie.id).published.latest.search({:movie_id_eq => @movie.id})
    end
    unless @critics_review_search.blank?
      if params[:block] == "inside"
        @critics_reviews = @critics_review_search.all.paginate(:page => params[:page], :per_page => 5)
      else
        @critics_reviews = @critics_review_search.all.paginate(:page => params[:page], :per_page => 15)
      end
    end
    #if !params[:page].nil?
      #render :partial=>"shared/critics_reviews_page"
    #else
      #render :partial=>"shared/critics_reviews"
    #end

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def show
    @critics_review = CriticsReview.find(params[:id])
  end
  def vote_review
    @review = params[:cls].constantize.find_by_id(params[:id])
    #@like_status = Discussion.check_like(current_user,@review)
    #if !@like_status
      @review.vote :voter =>current_user, :vote => params[:vote]
      @vote = Vote.where("votable_id = #{@review.id} AND votable_type = '#{@review.class.to_s}' AND voter_id = #{current_user.id}").first
    #end
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end
  def autosuggest
    critics_names = FilmCritic.where("name ILIKE '#{params[:term].strip}%'").search.all.collect do |critics|
      {"id" => critics.id, "label" => critics.name}
    end
    render :json => critics_names.to_json
  end
end

