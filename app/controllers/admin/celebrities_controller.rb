class Admin::CelebritiesController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :admin?
  layout 'admin'

  def index
    unless params[:search].blank?
      @search = Celebrity.order_by_name.search(params[:search])
      @celebrities = @search.paginate(:page => params[:page], :per_page => 50)
    end
  end

  def show
    @celebrity = Celebrity.find_using_id(params[:id]).first
  end

  def new
   @celebrity = Celebrity.new
   @celebrity.build_celebrity_meta_detail
  end

  def edit
    @celebrity = Celebrity.find_using_id(params[:id]).first
  end

  def create
    @celebrity = Celebrity.new(params[:celebrity])
    @celebrity.name = params[:celebrity][:name].strip

    @celebrity.language = params[:celebrity][:language].to_json

    respond_to do |format|
      if @celebrity.save
        format.html { redirect_to([:admin, @celebrity], :notice => 'Celebrity was successfully created.') }
        format.xml  { render :xml => @celebrity, :status => :created, :location => @celebrity }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @celebrity.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @celebrity = Celebrity.find_using_id(params[:id]).first

    if !params[:flag].blank? and @celebrity.flag != params[:flag]
      if params[:flag] == "Happy Birthday"
        flag_code = 4
      else
        flag_code = 3
      end
      @celebrity.update_attributes(:flag => params[:flag], :flag_set_at => Time.now)
    end
    if params[:flag].blank? && !@celebrity.flag.blank?
      @celebrity.update_attributes(:flag => params[:flag], :flag_set_at => "")
    end
    respond_to do |format|
      params[:celebrity][:name] = params[:celebrity][:name].strip
      params[:celebrity][:language] = params[:celebrity][:language].to_json

      #home_page = HomePageSetting.where("subject_type = 'Celebrity' and subject_id = '#{@celebrity.id}'")
      #if home_page.blank? && @video.updated_at < Date.today
        #params[:celebrity][:history_score] = @celebrity.score
        #params[:celebrity][:diff_score] = '0' 
      #end
      if @celebrity.update_attributes(params[:celebrity])
        unless params[:add_score].blank?
          new_score = @celebrity.score+params[:add_score].to_i
          @celebrity.update_attribute('score', new_score)
          @activity = Activity.new
          @user = UserProfile.find_by_user_id(current_user.id)
          @activity.user_id = current_user.id
          @activity.secondary_subject_type = "Celebrity"
          @activity.subject_type = "Admin Score"
          @activity.secondary_subject_id = @celebrity.id
          @activity.save(false)
        end
        format.html { redirect_to(edit_admin_celebrity_path(@celebrity), :notice => 'Celebrity was successfully updated.'    ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @celebrity.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    #@celebrity = Celebrity.find(params[:id])
    @celebrity = Celebrity.find_using_id(params[:id]).first
    @celebrity.destroy
    redirect_to(admin_celebrities_url)
  end

  def delete_celebrities
    Celebrity.where('id in (?)', params[:celebrity_ids]).destroy_all unless params[:celebrity_ids].blank?
    redirect_to admin_celebrities_path
  end


  def autocomplete
    celebrity_names = Celebrity.where("name ILIKE '#{params[:term].strip}%'").search.all.collect do |user|
      { "label" => user.name, "value" => user.id }
    end
    render :json => celebrity_names.to_json
  end

  def home_autocomplete
    celebrity_names = Celebrity.where("name ILIKE '#{params[:term].strip}%'").search.all.collect do |user|
      {"id" => user.id, "label" => user.name}
    end
    render :json => celebrity_names.to_json
  end

end

