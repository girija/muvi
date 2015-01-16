class Admin::TopTenController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin?
  layout 'admin'

  def index
    @all_topten = TopTen.find(:all, :order => ["created_at desc"]).paginate(:page => params[:page], :per_page => 100)
  end

  def movies
    @topten_movies = TopTen.find(:all, :order => ["created_at desc"], :conditions => ["item_type = 0"]).paginate(:page => params[:page], :per_page => 100)
  end

  def celebrities
    @topten_celebrities = TopTen.find(:all, :order => ["created_at desc"], :conditions => ["item_type = 1"]).paginate(:page => params[:page], :per_page => 100)
  end  

  def edit
    @topten = TopTen.find_by_id(params[:id])
  end

  def update
    @topten = TopTen.find(params[:id])
    respond_to do |format|
      if @topten.update_attributes(params[:top_ten])
        format.html { redirect_to(edit_admin_top_ten_path(@topten), :notice => 'Top 10 was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @topten.errors, :status => :unprocessable_entity }
      end
    end

  end
  def delete
    @activity = Activity.find_by_subject_id(params[:id])
    @activity.destroy if !@activity.nil?
    TopTen.where('id = ?', params[:id]).destroy_all unless params[:id].blank?
    redirect_to "/admin/top_tens/"
  end

  def autocomplete
    topten_names = TopTen.where("name ILIKE '#{params[:term].strip}%'").search.all.collect do |topten|
      {"id" => topten.id, "label" => topten.name}
    end
    render :json => topten_names.to_json
  end

end

