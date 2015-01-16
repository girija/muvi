class UserMovieList < ActiveRecord::Base
  acts_as_followable
  has_permalink [:tag]
  searchable do
    text :tag
  end


  scope :find_using_id, lambda {|perm| where("permalink = ?", perm) }

  def to_param
    permalink
  end
  
  def self.find_for_sitemap
    #find(:all, :order => "id")
    find(:all, :order => "id",:conditions => "tag != '' and tag IS NOT NULL")
  end

  def self.added_movie_to_list(cur_user, movie_id, tag, list_id)
    @final_arr = []
      actor = ""
      verb = ""
      object = ""
      target = ""

      image_url = ""
      unless cur_user.user_profile.profile_image_file_name.blank?
        image_url = "/system/profile_images/#{cur_user.user_profile.id}/small/#{cur_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
      else
        unless cur_user.facebook_id.blank?
          image_url = "http://graph.facebook.com/#{cur_user.facebook_id}/picture?type=normal"
        else
          image_url = "/images/no-profile.png"
        end
      end

      up = cur_user.user_profile
      
      actor = { :url => "/#{up.permalink}",
              :objectType => "user",
              :id => "#{cur_user.id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "#{cur_user.display_name}"
           }
      verb = "added movie to list"
      m = Movie.find_by_id(movie_id)
      url = ""
      image = ""
      unless m.blank?
        url = "/movies/#{m.permalink}"
        image = POSTER_URL + m.banner_image
      end
      object = {:url => "#{url}", :objectType => "movie", :id => "#{movie_id}",
               :image => {:url => "#{image}", :width => 250, :height => 250},
               :displayName => "#{m.name}"
              }


      target = {:url => "/movie_list/#{list_id}/#{User.convert_to_seo_url(tag)}", :objectType => "list", :id => "#{list_id}",
               :image => {:url => "#{image_url}", :width => 250, :height => 250},
               :displayName => "#{tag}"
              }

      @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
      act = AllActivity.new
      act.user_id = cur_user.id
      act.movie_id = movie_id
      act.activity = @final_arr.to_json
      act.activity_type = "added movie to list"
      act.save


      list_follower = Follow.find(:all, :conditions => ["followable_id = #{list_id}"])
      unless list_follower.blank?
        list_follower.each do |lf|
	  @m_id = AllActivity.get_current_user_wanna_list(lf.follower_id)
	  @seen_m_id = AllActivity.get_current_user_seen_list(lf.follower_id)
          if !@m_id.include?(movie_id.to_s) and !@seen_m_id.include?(movie_id.to_s)
	    AllActivityHelper.add_list_notification(1, lf.follower_id, act,'')
	  end
        end
      end
  end


  def self.show_invite(cur_user, movie_id, tag, list_id)
      @final_arr = []
      actor = ""
      verb = ""
      object = ""
      target = ""

      unless cur_user.user_profile.profile_image_file_name.blank?
        image_url = "/system/profile_images/#{cur_user.user_profile.id}/small/#{cur_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
      else
        unless cur_user.facebook_id.blank?
          image_url = "http://graph.facebook.com/#{cur_user.facebook_id}/picture?type=normal"
        else
          image_url = "/images/no-profile.png"
        end
      end


      up = cur_user.user_profile
      actor = { :url => "/#{up.permalink}",
              :objectType => "user",
              :id => "#{cur_user.id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "#{cur_user.display_name}"
           }

      verb = "added list"

      object = {:url => "", :objectType => "list", :id => "#{list_id}",
               :image => {:url => "", :width => 250, :height => 250},
               :displayName => "#{tag}"
              }

      @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}

      act = AllActivity.new
      act.user_id = cur_user.id
      act.activity = @final_arr.to_json
      act.activity_type = "added list"
      act.save

  end

	
	def self.create_rate_json(current_user_id, movie_id, activity_id)
		ac = ""
		rate = ""
		next_movie_id = ""
		@rated_movie = ""
		list = ListOfMovie.find_by_user_id(current_user_id)
		act = AllActivity.find_by_id(activity_id)
		unless list.blank?
			unless list.rated_movie.blank?
				@rated_movie =  ActiveSupport::JSON.decode(list.rated_movie)
			end
			
			seen_list = ActiveSupport::JSON.decode(list.seen_lists)
			unless seen_list.blank?
				seen_list.each do |l|
					unless l.blank?
						if l["target"] == "seen it"
							if l["object"]["id"].to_i != movie_id.to_i
								if @rated_movie.blank?
									next_movie_id = l["object"]["id"]
								elsif !@rated_movie.include?(l["object"]["id"].to_i)
									next_movie_id = l["object"]["id"]
								end
							end
						end
					end
				end
			end
		end
		unless next_movie_id.blank?
		  #UserMovieList.send_rating_notification(current_user.id, current_user.display_name, params[:movie_id], next_movie_id)
		  
			m1 = Movie.find_by_id(next_movie_id)
			next_id = ""
			next_name = ""
			next_permalink = ""
                        next_movie_image = ""

			unless m1.blank?
			  next_id = m1.id
			  next_name = m1.name
			  next_permalink = User.convert_to_seo_url(m1.name)
                          next_movie_image = POSTER_URL + m1.banner_image
			end
                        if act			
          		  ac_1 = ActiveSupport::JSON.decode(act.activity)
			  unless ac_1.blank?
				ac_1.each do|ac|			
					ac["user_id"] = ac["actor"]["id"]						
					ac["cur_user_id"] = current_user_id
					ac["activity_id"] = act.id
					ac["movie_id"] = act.movie_id
					ac["action"] = "rated"
					ac["block_type"] = ac["action"]
					ac["next_movie_id"] = next_id
					ac["next_movie_name"] = next_name
					ac["next_permalink"] = "/movies/#{next_permalink}"
                                        ac["next_movie_image"] = next_movie_image
					rate = ac
				end
			  end
                      	end			
		end
		return rate
	end

    def self.save_rating(cur_user, movie_id,activity_type,target_user,list_id)
      @final_arr = []
      actor = ""
      verb = ""
      object = ""
      target = ""

      #cur_user = User.find_by_id(cur_user_id)
      image_url = ""
        unless cur_user.user_profile.profile_image_file_name.blank?
          image_url = "/system/profile_images/#{cur_user.user_profile.id}/small/#{cur_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
        else
          unless cur_user.facebook_id.blank?
            image_url = "http://graph.facebook.com/#{cur_user.facebook_id}/picture?type=normal"
          else
            image_url = "/images/no-profile.png"
          end
        end


      up = cur_user.user_profile
      actor = {:url => "/#{up.permalink}",
              :objectType => "user",
              :id => "#{cur_user.id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "You "
           }


      movie = Movie.find_by_id(movie_id)
      object = {:url => "/movies/#{movie.permalink}", :objectType => "movie", :id => "#{movie.id}",
               :image => {:url => "#{POSTER_URL}#{movie.banner_image}", :width => 250, :height => 250},
               :displayName => "#{movie.name}"
              }

      unless list_id.blank?
        list = UserMovieList.find_by_id(list_id)
        target = {:url => "/movie_list/#{list.id}/#{list.tag}", :objectType => "list", :id => "#{list_id}",
               :image => {:url => "", :width => 250, :height => 250},
               :displayName => "#{list.tag}"
              }
      end
      verb = activity_type
      @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
      act = AllActivity.new
      act.user_id = cur_user.id
      act.movie_id = movie_id
      act.target_user_id = target_user if !target_user.blank?
      act.activity = @final_arr.to_json
      act.activity_type = activity_type
      act.save
    end

    def self.send_rating_notification_not_used_anymore(cur_user_id, cur_user_display_name, prev_movie_id, next_movie_id)
    @final_arr = ""
    actor = ""
    verb = ""
    object = ""
    target = ""

    cur_user = User.find_by_id(cur_user_id)
    image_url = ""
      unless cur_user.user_profile.profile_image_file_name.blank?
        image_url = "/system/profile_images/#{cur_user.user_profile.id}/small/#{cur_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
      else
        unless cur_user.facebook_id.blank?
          image_url = "http://graph.facebook.com/#{cur_user.facebook_id}/picture?type=normal"
        else
          image_url = "/images/no-profile.png"
        end
      end

    up = cur_user.user_profile
    actor = {:url => "/#{up.permalink}",
              :objectType => "user",
              :id => "#{cur_user_id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "You "
           }

    verb = "rated"

    m = Movie.find_by_id(prev_movie_id)
    m1 = Movie.find_by_id(next_movie_id)

    next_id = ""
    next_name = ""
    next_permalink = ""
    next_movie_image = ""

    unless m1.blank?
      next_id = m1.id
      next_name = m1.name
      next_permalink = User.convert_to_seo_url(m1.name)
      next_movie_image = POSTER_URL + m1.banner_image
    end
    url = ""
    image = ""
    unless m.blank?
      url = "http://www.muvi.com/movies/#{m.permalink}"
      image = POSTER_URL + m.banner_image
    end
    object = {:url => "#{url}", :objectType => "movie", :id => "#{m.id}",
               :image => {:url => "#{image}", :width => 250, :height => 250},
               :displayName => "#{m.name}"
              }

    @final_arr = {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target, :action => "rated", :user_id => "#{cur_user_id}", :user_name => "You", :block_type => "rated", :movie_id => prev_movie_id, :movie_name => "#{m.name}", :next_movie_id => "#{next_id}", :next_movie_name => "#{next_name}", :next_permalink => "#{next_permalink}", :next_movie_image => "#{next_movie_image}"}.to_json
    @c = ActiveSupport::JSON.decode(@final_arr)


    #ApplicationHelper.broadcast("/home/index/#{cur_user_id}", @c)
  end

  def self.update_old_list_feed
    list_feed = AllNotification.find(:all, :conditions => ["activity_type = 'added list'"], :order => ["id asc"])

    unless list_feed.blank?
      list_feed.each do|l|
        list = ActiveSupport::JSON.decode(l.notification)
puts l.notification
puts "___________________"
        list.each do |li|
          if li["object"]["objectType"] == "list"
            list_id = li["object"]["id"]
            list_name = li["object"]["displayName"]
            li["object"]["url"] = "/movie_list/#{list_id}/#{list_name}"
          end
        end
        l.notification = list.to_json
puts l.notification
        l.save
      end
    end
  end


end


