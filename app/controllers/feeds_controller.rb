class FeedsController < ApplicationController
  layout 'website'
  def index
    @tagging = Tagging.find_by_id(params[:tagging_id])
    if params[:type] == "celebrity"
      @celebrity = Celebrity.find_by_id(@tagging.tagger_id)
    else
      @movie = Movie.find_by_id(@tagging.tagger_id)
    end    
    @feed = Feed.find_by_id(@tagging.taggable_id)    
  end
end
