class Admin::FilmCriticsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin?
  layout 'admin'

  def index
     #@film_critics = FilmCritic.includes(:user).all
     unless params[:search].blank?
       params[:search][:name_contains] = params[:search][:name_contains].strip
       @search = FilmCritic.includes(:user).search(params[:search])
       @film_critics = @search.paginate(:page => params[:page], :per_page => 50)
     end
  end

  def show
    @film_critic = FilmCritic.find(params[:id])
  end

  def new
   #@film_critic = FilmCritic.new
   @user = User.new
   @user.build_film_critic
  end

  def edit
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      redirect_to(admin_film_critics_path, :notice => 'Film Critic was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(admin_film_critics_path, :notice => 'Film Critic was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to(admin_film_critics_url)
  end
end

