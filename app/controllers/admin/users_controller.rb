class Admin::UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin?
  layout 'admin'

  def index
    #@search =  User.all_without_admin.includes([:user_profile]).search(params[:search])
    #@search =  User.all_without_admin.where("(users.email IS NOT NULL and users.email NOT ILIKE '%reply%') or (users.email IS NOT NULL and users.facebook_id IS NOT NULL)").joins("inner join user_tokens on users.id = user_tokens.user_id").includes([:user_profile]).search(params[:search])
    unless params[:search].blank?
      @search =  User.all_without_admin.where("(users.email IS NOT NULL and users.email NOT ILIKE '%reply%' and users.email NOT ILIKE '%replay%') or (users.email IS NOT NULL and users.facebook_id IS NOT NULL)").includes([:user_profile]).search(params[:search])

      @users = @search.paginate(:page => params[:page], :per_page => 50)
    end
  end

  def export
    unless params[:email].blank?
      @users =  User.all_without_admin.enabled_users.includes([:user_profile]).search(:email_contains => params[:email])
    else
      #@users =  User.all_without_admin.where("(users.email IS NOT NULL and users.email NOT ILIKE '%reply%') or (users.email IS NOT NULL and users.facebook_id IS NOT NULL)").joins("inner join user_tokens on users.id = user_tokens.user_id").includes([:user_profile]).search()
      @users =  User.all_without_admin.where("(users.email IS NOT NULL and users.email NOT ILIKE '%reply%' and users.email NOT ILIKE '%replay%') or (users.email IS NOT NULL and users.facebook_id IS NOT NULL)").includes([:user_profile]).search()
    end
    @outfile = "users_" + Time.now.strftime("%m-%d-%Y") + ".csv"
    require 'csv'

    file = CSV.generate do |csv|
      csv << [
        "First Name",
        "Last Name",
        "Email",
      ]
      @users.each do |user|
        user_arr = user.display_name.split(" ")
        first_name = user_arr[0]
        last_name = user_arr[1]
        csv << [
          first_name,
          last_name,
          user.email
        ]
      end
    end

    send_data file, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment;filename=#{@outfile}"

  end

  def delete_users
    #User.where('id in (?)', params[:user_ids]).destroy_all unless params[:user_ids].blank?
    unless params[:user_ids].blank?
      User.where('id in (?)', params[:user_ids]).each do |user|
        ActiveRecord::Base.connection.execute("UPDATE users SET email = '' , is_disabled = true WHERE id =  #{user.id}")
        user.user_tokens.destroy_all
        #user.destroy
      end
    end
    redirect_to admin_users_path
  end

  def autocomplete
    #user_names = UserProfile.where("display_name ILIKE '#{params[:term].strip}%'").search.all.collect do |user|
    user_names = UserProfile.where("user_profiles.user_id IS NOT NULL and display_name ILIKE ?","#{params[:term].strip}%").joins("inner join user_tokens on user_profiles.user_id = user_tokens.user_id").order("display_name").search.all.collect do |user|
      {"id" => user.id, "label" => user.display_name}
    end
    render :json => user_names.to_json
  end

end

