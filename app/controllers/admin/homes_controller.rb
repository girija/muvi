class Admin::HomesController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :admin?
  layout 'admin'

  # For movie home page
    #page_no = 1
    #For Movie: subject_type_id = 1, 
    #For celebrity: subject_type_id = 2
    #For User: subject_type_id = 3

  def index
    @muvimeter = HomePageSetting.where("page_no = 1 and item_id = 1 and item_name='muvimeter' and subject_type_id=1").find(:all)  

    @tweeterbuzz = HomePageSetting.where("page_no = 1 and item_id = 2 and item_name='tweeterbuzz' and subject_type_id=1").find(:all)

    @trendingnow = HomePageSetting.where("page_no = 1 and item_id = 3 and item_name='trendingnow' and subject_type_id=1").find(:all)

    #@hot_today = HomePageSetting.where("page_no = 1 and item_id = 4 and subject_type_id = 1").find(:all)

    @featured_celebrity = HomePageSetting.where("item_id = 5 and item_name='featured_celebrity' and subject_type_id=2").find(:all).first
   
    @celebrity_tweet = HomePageSetting.where("item_id = 7 and item_name='celebrity_tweet' and subject_type_id=2").find(:all)
  
    @featured_member = HomePageSetting.where("item_id = 9 and item_name='featured_member' and subject_type_id=3").find(:all).first

    @featured_movie = HomePageSetting.where("item_id = 10 and item_name='featured_movie' and subject_type_id=1").find(:all).first

    @featured_topten =  HomePageSetting.where("item_id = 11 and item_name='featured_topten' and subject_type_id=4").find(:all).first

  end

  def create_settings
    #page_no: 1=Movie, 2=Celebrity
    #subject_type_id: 1=Movie; 2=Celebrity
    #HomePageSetting.save_settings(params)
    HomePageSetting.save_movie_settings(params)
    HomePageSetting.save_celebrity_settings(params)
    HomePageSetting.save_user_settings(params)
    HomePageSetting.save_featured_movie(params)   
    HomePageSetting.save_featured_topten(params)
    redirect_to admin_homes_path
  end

end
