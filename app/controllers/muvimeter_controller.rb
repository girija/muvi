class MuvimeterController < ApplicationController
  skip_before_filter :authenticate_user!
  layout nil
  #session :off

  def index
    @movie = Movie.find_using_id(params[:id]).includes([:comments]).first
    #@movie = Movie.find_by_name(params[:id])
    respond_to do |format|
        format.js
        format.html
    end
  end
 
end
