class Admin::CelebritiesHomeController < ApplicationController
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
    @celeb_theater = HomePageSetting.where("page_no = 2 and item_id = 1 and item_name='celeb_theater' and subject_type_id=1").find(:all)  

    @celeb_nextweek = HomePageSetting.where("page_no = 2 and item_id = 2 and item_name='celeb_nextweek' and subject_type_id=1").find(:all)

    @celeb_trending = HomePageSetting.where("page_no = 2 and item_id = 3 and item_name='celeb_trending' and subject_type_id=1").find(:all)

  end


  def create_settings
    #page_no: 1=Movie, 2=Celebrity
    #subject_type_id: 1=Movie; 2=Celebrity
    HomePageSetting.save_celebrity_home_settings(params)
    redirect_to "/admin/celebrities_home/"
  end

end
