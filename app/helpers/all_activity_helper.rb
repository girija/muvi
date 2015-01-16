module AllActivityHelper
        def self.get_movie_notification(cur_user_id,movie_id)
          @all_activity = []
          if !cur_user_id.blank?
            ##### Check for deleted activity by the user
            act_del = ""
            del_act = ListOfMovie.select("activity_deleted").find_by_user_id(cur_user_id)
            #if del_act.activity_deleted
            #  activity_deleted = ActiveSupport::JSON.decode(del_act.activity_deleted)
            #  activity_deleted = activity_deleted.join(",")
            #  act_del = "and id NOT IN (#{activity_deleted})";
            #end
            ############################################
            activity_qry = AllActivity.find(:all,
                                            :conditions => ["((((user_id NOT IN (#{cur_user_id}) or target_user_id = #{cur_user_id}) or (user_id = '#{cur_user_id}' and activity_type = 'rated')) and movie_id = #{movie_id}) and (activity_type IN ('has not recommended', 'has recommended', 'saw', 'added movie to list')))  #{act_del}"],
                                            :order => ["created_at asc"])
          else
            activity_qry = AllActivity.find(:all,
                                            :conditions => ["movie_id = #{movie_id} and (activity_type IN ('has not recommended', 'has recommended', 'saw', 'added movie to list'))"],
                                            :order => ["created_at asc"])
          end
        end

	
	
	def self.get_notification_list(flag, cur_user_id, wanna_id, seen_id)
		@all_activity = []
		@activity_id = []
		mov_id = []
		
		#From discovery button
		if flag == 1
			wanna_id = AllActivity.get_current_user_wanna_list(cur_user_id)
			seen_id = AllActivity.get_current_user_seen_list(cur_user_id)
		end
		wanna_arr = wanna_id
                seen_arr = seen_id
		
		mov_id = wanna_id.concat(seen_id)
		puts mov_id.size
		
		wanna_id = wanna_id.join(',')
		seen_id = seen_id.join(',')
		all_mov_id = mov_id.join(',')
		
		unless all_mov_id.blank?
			
			
			
			activity_qry = AllActivity.find(:all, 
								:conditions => ["
												(
												  ( 
													(
													  (user_id NOT IN (#{cur_user_id}) and target_user_id = #{cur_user_id}) or (user_id = '#{cur_user_id}' and activity_type = 'rated')
													)
													and movie_id IN (#{all_mov_id})
												  )
												  or
													(
													  activity_type IN ('follow', 'added list', 'invited', 'saw', 'added movie to list', 'follow filmography', 'next movie')
													)
												) 
												and viewed = 'f'"										
												],
								:order => ["created_at asc"]
							)
			unless activity_qry.blank?
				activity_qry.each do |a|	
					if !a.notification_added
						@notification_data = add_notification(0, cur_user_id, a)			
					end					
				end
				AllActivityHelper.display_notification(flag, cur_user_id)
			end
		end	
	end
	
	def self.display_notification(flag, cur_user_id)
		all_activity = []
		
		#notification_qry = AllNotification.find(:all, :conditions => ["feed_user = #{cur_user_id}"], :limit => ["30"], :order => ["id desc"])
                notification_qry = AllNotification.where("feed_user = #{cur_user_id}").limit(30).order("id desc")
		
		unless notification_qry.blank?
			notification_qry.each do|notify|
				no_1 = ActiveSupport::JSON.decode(notify.notification)
				unless no_1.blank?
					no_1.each do |no|

						###########change user's profile page url
						pos = no["actor"]["url"].scan(/\b(profile)\b/)
						unless pos.blank?
						  u = User.find_by_id(no["actor"]["id"])
						  unless u.blank?
  						    up = u.user_profile
						    no["actor"]["url"] = "/#{up.permalink}"
  						  end
						end
						##############ends
						if no["notification_id"].nil? or no["notification_id"].blank?
							no["notification_id"] = notify.id
						end

						no["release_date"] = "" 
							mo = Movie.find_by_id(no["object"]["id"])
							unless mo.blank?
								unless mo.release_date.blank?
  		 						  no["release_date"] = mo.release_date
								end
							else
								no["release_date"] = ""
							end

						if notify.activity_type == "new movie added"
						  m = Movie.find_by_id(no["object"]["id"])
						  unless m.blank?
  						    img = POSTER_URL + m.banner_image
						    no["object"]["image"]["url"] = img
						  end
						end
						all_activity << no
					end
				end
			end
		end
		
		all_activity = all_activity.reverse
		if flag == 1
			DisplayHelper.notify(all_activity, cur_user_id)
		else
			return all_activity
		end
	end

	def self.add_list_notification(flag, cur_user_id, a, new_object_id)
	    unless cur_user_id.blank?
               #if a.activity_type == "want to see"
                 notification_id = ""
                 act = ActiveSupport::JSON.decode(a.activity)
		 actor_id = ""
                 actor_name = ""
                 actor_url = ""
                 actor_image = ""

                 object_node_id = ""
                 object_name = ""
                 object_url = ""
                 object_image = ""

                 target_id = ""
                 target_name = ""
                 target_url = ""
                 target_image = ""

                 movie_id = ""
                 list_id = ""
                 celebrity_id = ""
                 notification_action = ""
                 object_type = ""
                 action_text = ""
                 where_to_display = ""

                 list_creator_url = ""
                 list_image = ""
                 list_url = ""
                 list_name = ""
                 list_id = ""

		 next_movie_id = ""
                 next_movie_name = ""
                 next_movie_url = ""
                 next_movie_image = ""
                 destination_url = ""
                 release_date = ""
		 
		 not_add = 0

		 #@chk_duplicate  = AllNotification.find_by_feed_user_and_activity_type_and_object_id("#{cur_user_id.to_i}", a.activity_type, act[0]["object"]["id"])

                 #if @chk_duplicate.blank? or @chk_duplicate.nil?

                   begin
                     actor_id = act[0]["actor"]["id"]
                     actor_name = act[0]["actor"]["displayName"]
                     actor_url = act[0]["actor"]["url"]
                     actor_image = act[0]["actor"]["image"]["url"]
                   rescue
                   end

		   if act[0]["object"]["objectType"] == "movie"
                     object_url = act[0]["object"]["url"]
                     destination_url = act[0]["object"]["destination_url"] if act[0]["object"]["destination_url"]
                   elsif act[0]["object"]["objectType"] == "list"
                     if a.activity_type == "next movie"
                       object_url = act[0]["object"]["url"]
                     else
                       object_url = act[0]["actor"]["url"]+ "/" +act[0]["object"]["id"]
                     end
                   end

                   begin
                     object_name = act[0]["object"]["displayName"]
                     object_node_id = act[0]["object"]["id"]
                     object_image = act[0]["object"]["image"]["url"]


                     target_name = act[0]["target"]["displayName"]
                     target_id = act[0]["target"]["id"]
                     target_url = act[0]["target"]["url"]
                     target_image = act[0]["target"]["image"]["url"]
                   rescue
                   end

		   #m = Movie.find_by_id(act[0]["object"]["id"])
		   if a.activity_type == "want to see" or a.activity_type == "saw"
		     @chk_duplicate  = AllNotification.find_by_feed_user_and_activity_type_and_object_id("#{cur_user_id.to_i}", "saw to follow list", act[0]["object"]["id"])

                     if @chk_duplicate.blank? or @chk_duplicate.nil?
                       li = UserMovieList.find_by_id(new_object_id)

    	    	       m = Movie.find_by_id(object_node_id)
                       unless m.nil?
                         list_image = m.banner_image
  
                         list_url = "/movies/#{m.permalink}"
                         list_name = m.name
                         list_id = m.id
                       end

          	       block_type = "follow_new_list"
          	       notification_action = "Follow <a href='/movie_list/#{li.id}/#{li.tag}'>#{li.tag}</a>".html_safe
	               object_type = "list"
	               object_name = li.tag
	               #object_node_id = li.id
	               object_url = "/movie_list/#{li.id}/#{li.tag}"

             	       action_text = "<a href='#{list_url}'>#{m.name}</a> is in a list <a href='/movie_list/#{li.id}/#{li.tag}'>#{li.tag}</a>. Follow the list to discover similar movies".html_safe
		       where_to_display = "wanna_see"
		       list_id = li.id

		       activity_type = "saw to follow list"

		       notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,release_date )
		    end

		  elsif a.activity_type == "follow"
		    # point no 17 in google doc
		    ulist = UserMovieList.find_by_id(object_node_id)
		    unless ulist.blank?
  		      block_type = "update_list"
		      notification_action = "started following"
		      object_type = "list"
		      #action_text = "Update List"
		      action_text = ""
		      where_to_display = "wanna_see"
		      list_id = object_node_id

		      lu = User.find_by_id(ulist.user_id)
		      #object_url = "/movie_list/#{ulist.id}/#{ulist.tag}"
		      object_url = "/list/#{ulist.permalink}"

		      chk_list = UserMovieList.find_by_id(object_node_id)
		      mov = ActiveSupport::JSON.decode(chk_list.movie_id)
		      m = Movie.find_by_id(mov[0])
		      list_image = m.banner_image
		      list_url = "/movies/#{m.permalink}"
		      list_name = m.name
		      list_id = m.id

		      unless lu.blank?
		        if lu.id != cur_user_id.to_i
		          notification_id = save_notification(ulist.user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,release_date )
	  	        end
		      end
		    end
	 	 elsif a.activity_type == "added movie to list"
		   block_type = "added_movie_to_list"
                   notification_action = a.activity_type
                   object_type = "movie"
                   action_text = ""
                   where_to_display = "seen"
                   movie_id = object_node_id
                
                   notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url, destination_url )
	
		 elsif a.activity_type == "new movie added"
		   block_type = "new_movie_added"
                   notification_action = a.activity_type
                   object_type = "celeb"
                   action_text = ""
                   where_to_display = "seen"
                   movie_id = object_node_id

                   notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url, destination_url )  

		 end  # end of activity type check "if"
	       #end  # end of chk_duplicate if
  	       #end
            end  # end of first if
	end
	
	def self.add_notification(flag, cur_user_id, a)
		unless cur_user_id.blank?
			if a.activity_type != "want to see"
				notification_id = ""
				act = ActiveSupport::JSON.decode(a.activity)
				
				actor_id = ""
				actor_name = ""
				actor_url = ""
				actor_image = ""
				
				object_node_id = ""
				object_name = ""
				object_url = ""
				object_image = ""
				
				target_id = ""
				target_name = ""
				target_url = ""
				target_image = ""
				
				movie_id = ""
				list_id = ""
				celebrity_id = ""
				
				notification_action = ""
				object_type = ""
				action_text = ""
				where_to_display = ""
				list_creator_url = ""
				
				list_image = ""
				list_url = ""
				list_name = ""
				list_id = ""
				
				next_movie_id = ""
				next_movie_name = ""
				next_movie_url = ""
				next_movie_image = ""
                                destination_url = ""
				not_add = 0
				
				@chk_duplicate  = AllNotification.find_by_feed_user_and_activity_type_and_object_id("#{cur_user_id.to_i}", a.activity_type, act[0]["object"]["id"])
				
				
				if	@chk_duplicate.blank? or @chk_duplicate.nil?
					
					begin
						actor_id = act[0]["actor"]["id"]
						actor_name = act[0]["actor"]["displayName"]
						actor_url = act[0]["actor"]["url"]
						actor_image = act[0]["actor"]["image"]["url"]
					rescue
					end
					
					if act[0]["object"]["objectType"] == "movie"
						object_url = act[0]["object"]["url"]
						destination_url = act[0]["object"]["destination_url"] if act[0]["object"]["destination_url"]
					elsif act[0]["object"]["objectType"] == "list"
						if a.activity_type == "next movie"	
							object_url = act[0]["object"]["url"]
						else						
							object_url = act[0]["actor"]["url"]+ "/" +act[0]["object"]["id"]
						end
					end		
					
					begin
						object_name = act[0]["object"]["displayName"]
						object_node_id = act[0]["object"]["id"]
						object_image = act[0]["object"]["image"]["url"] 
					
					
						target_name = act[0]["target"]["displayName"]
						target_id = act[0]["target"]["id"]
						target_url = act[0]["target"]["url"]
						target_image = act[0]["target"]["image"]["url"] 
					rescue
					end		
						
					
					if a.activity_type == "saw"			
					
						if cur_user_id.to_i == act[0]["actor"]["id"].to_i
							if !Review.find_by_movie_id_and_user_id(object_node_id, cur_user_id).nil?
								not_add = 1
							end
							if not_add == 0
								block_type = "rate_it"
								notification_action = a.activity_type
								object_type = "movie"
								where_to_display = "seen"
								action_text = "Rate it"
								movie_id = object_node_id
								
								notification_id = save_notification(act[0]["actor"]["id"].to_i, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
							
							end
						end
																	
						@users = User.where(last_sign_in_at: 5.days.ago..0.days.from_now).find(:all, :conditions => ["id != #{act[0]["actor"]["id"].to_i}"])
						@users.each do |u|
							@m_id = AllActivity.get_current_user_wanna_list(u.id)
							
							# if movie is in user's wanna see list, then send "ask for recommendation" notification
														
							if @m_id.include?(object_node_id.to_s)								
								block_type = "ask_for_recommendation"
								notification_action = a.activity_type
								object_type = "movie"
								where_to_display = "wanna_see"							
								action_text = "Ask for recommendation"						
								movie_id = object_node_id	
								
								notification_id = save_notification(u.id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url, destination_url)
							end	
							
						end
						
						
					elsif a.activity_type == "asked"	
						if flag == 0
							# From page refresh
							if target_id != cur_user_id
								not_add = 1
							end
						end
						
						block_type = "asked"
						notification_action = a.activity_type
						object_type = "movie"
						action_text = "Do you want to recommend?"
						where_to_display = "seen"
						movie_id = object_node_id
						
						if not_add == 0
							notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url, destination_url )
						end
						
					elsif a.activity_type == "has recommended" or a.activity_type == "has not recommended"
						if target_id.to_i != cur_user_id.to_i
							not_add = 1
						end
						
						block_type = "answered_the_ask"
						notification_action = a.activity_type
						object_type = "movie"
						action_text = ""
						where_to_display = "wanna_see"
						movie_id = object_node_id
						
						if not_add == 0
							notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
						end
						
					elsif a.activity_type == "thanked"
						if target_id.to_i != cur_user_id.to_i
							not_add = 1
						end
						
						block_type = "answered_the_thank"
						notification_action = a.activity_type
						object_type = "movie"
						action_text = "you for your recommendation"
						where_to_display = "seen"
						movie_id = object_node_id
						
						if not_add == 0
							notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
						end
						
					elsif a.activity_type == "invited"
						if actor_id.to_i == cur_user_id.to_i
							not_add = 1
						end
						block_type = "invited_to_follow_list"
						notification_action = a.activity_type + " to follow"
						object_type = "list"
						action_text = "Do you want to follow it"
						where_to_display = "seen"
						list_id = object_node_id						
						
						@list_first_movie = UserMovieList.find_by_id(object_node_id)
						unless 	@list_first_movie.blank?
							@list_movie = Movie.find_by_id(ActiveSupport::JSON.decode(@list_first_movie.movie_id)[0])
							target_name = @list_movie.name
							target_id = @list_movie.id
							target_url = "/movies/#{@list_movie.permalink}"
							target_image = POSTER_URL + @list_movie.banner_image

							#lu = User.find_by_id(@list_first_movie.user_id)
							#unless lu.blank?
							#	list_creator_url = "/profile/#{@list_first_movie.user_id}/#{User.convert_to_seo_url(lu.display_name)}/#{object_node_id}"
							#end
                                                        list_creator_url = "/movie_list/#{object_node_id}/#{@list_first_movie.tag}"
						end
						object_url = "/movie_list/#{object_node_id}/#{@list_first_movie.tag}"

						if not_add == 0
							notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
						end
                                        elsif a.activity_type == "list_rated_movie"
                                                if actor_id.to_i == cur_user_id.to_i
                                                        not_add = 1
                                                end
                                                user = User.find_by_id(cur_user_id)
                                                if not_add == 0
                                                  block_type = "list_rated_movie"
                                                  notification_action = a.activity_type
                                                  object_type = "movie"
                                                  #action_text = "Rate it"
						  action_text = ""
                                                  where_to_display = "seen"
                                                  movie_id = object_node_id

						  @m_id = AllActivity.get_current_user_wanna_list(cur_user_id)
						  @seen_m_id = AllActivity.get_current_user_seen_list(cur_user_id)

						  if !@m_id.include?(object_node_id.to_s) and !@seen_m_id.include?(object_node_id.to_s)
                                                    notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url, destination_url )
						  end

                                                end
                                        elsif a.activity_type == "kudos"
						if actor_id.to_i == cur_user_id.to_i
                                                        not_add = 1
                                                end
                                                user = User.find_by_id(cur_user_id)
                                                if not_add == 0
                                                  #list = UserMovieList.find_by_id(params[:list_id]) 
                                                  block_type = "kudos"
                                                  notification_action = a.activity_type
                                                  object_type = "movie"
                                                  action_text = ""
                                                  where_to_display = "seen"
                                                  movie_id = object_node_id 
                                                  notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url, destination_url )
                                                end



					elsif a.activity_type == "follow"
						list = UserMovieList.find_by_id(object_node_id)
						user = User.find_by_id(cur_user_id)

						if actor_id.to_i == cur_user_id.to_i
							#not_add = 1
							list_arr = UserMovieList.where("id != #{object_node_id} and tag IS NOT NULL").find(:all, :order => ["id desc"])
							unless list_arr.blank?
								list_arr.each do |li|
									chk_creator_of_list = UserMovieList.find_by_user_id_and_id(cur_user_id, li.id)
									if chk_creator_of_list.nil?
										if !li.followed_by?(user)
											@check_notification_entry = AllNotification.where("object_type='list' and object_id=#{li.id}").find(:all)
											if @check_notification_entry.blank? or @check_notification_entry.nil?
												block_type = "follow_another_list"
												notification_action = "You followed <a href='/movie_list/#{list.id}/#{list.tag}'>#{list.tag}</a>".html_safe
												object_type = "list"
												object_name = li.tag
												object_node_id = li.id
												object_url = "/movie_list/#{li.id}/#{li.tag}"
											
												action_text = "Do you want to follow the next list <a href='#{object_url}'>#{li.tag}</a>?".html_safe
												where_to_display = "wanna_see"
												list_id = li.id
											
											
											
												chk_list = UserMovieList.find_by_id(li.id)
												mov = ActiveSupport::JSON.decode(chk_list.movie_id)
												m = Movie.find_by_id(mov[0])
												list_image = m.banner_image
												list_url = "/movies/#{m.permalink}"
												list_name = m.name
												list_id = m.id

												notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,release_date )
									
									
												break
											end
										end
									end	
								end
							end
							#end							
						end
						

						if actor_id.to_i != cur_user_id.to_i
								
								unless list.blank?
									chk_creator_of_list = UserMovieList.find_by_user_id_and_id(cur_user_id, object_node_id)
									if chk_creator_of_list.nil?
										if !list.followed_by?(user)
											block_type = "follow_list"
											notification_action = "started following"
											object_type = "list"
											action_text = "Do you want to follow it ?"
											where_to_display = "wanna_see"
											list_id = object_node_id

											lu = User.find_by_id(list.user_id)
											object_url = "/movie_list/#{list.id}/#{list.tag}"
											
											chk_list = UserMovieList.find_by_id(object_node_id)
											mov = ActiveSupport::JSON.decode(chk_list.movie_id)
											m = Movie.find_by_id(mov[0])
											list_image = m.banner_image
											list_url = "/movies/#{m.permalink}"
											list_name = m.name
											list_id = m.id
		
											unless lu.blank?
												if lu.id != cur_user_id.to_i
													notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,release_date )
												end	
											end	
										end
									   	
									end  # end of "chk_creator_of_list" if	
								end
						end
							
					elsif a.activity_type == "follow filmography"
						celeb = Celebrity.find_by_id(object_node_id)
						user = User.find_by_id(cur_user_id)
						
						if actor_id.to_i == cur_user_id.to_i 
							not_add = 1
						else
							if celeb.followed_by?(user)
								not_add = 1
							end
						end
						
						block_type = "follow_filmography"
						notification_action = "followed filmography of"
						object_type = "filmography"
						action_text = ""
						where_to_display = "wanna_see"	
						
						
						unless celeb.blank?
							object_image = celeb.image
							object_name = celeb.name
							object_url = "/stars/#{celeb.permalink}"
							object_node_id = celeb.id
						end
						
						celebrity_id = object_node_id
						
						if not_add == 0
							notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
						end
						
					elsif a.activity_type == "next movie"						
						if actor_id.to_i != cur_user_id.to_i
							not_add = 1
						end
						block_type = "celebs_next_movie"
						notification_action = " next movie is "
						object_type = "movie"
						action_text = ""
						where_to_display = "wanna_see"	
						
						actor_id = target_id
						actor_name = target_name
						actor_image = target_image
						actor_url = target_url
						
						@m_id = AllActivity.get_current_user_wanna_list(cur_user_id)
						@seen_m_id = AllActivity.get_current_user_seen_list(cur_user_id)
						
							
						if not_add == 0
							if !@m_id.include?(object_node_id.to_s)	and !@seen_m_id.include?(object_node_id.to_s)
								notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
							end
						end
						
					elsif a.activity_type == "added list"
						if actor_id.to_i != cur_user_id.to_i
							not_add = 1
						end
						
						block_type = "added_list"
						notification_action = "created"
						object_type = "list"
						action_text = "Invite friends to follow your list"
						where_to_display = "seen"
						list_id = object_node_id
					
						@list_first_movie = UserMovieList.find_by_id(object_node_id)
                                                unless  @list_first_movie.blank?
                                                        @list_movie = Movie.find_by_id(ActiveSupport::JSON.decode(@list_first_movie.movie_id)[0])
                                                        target_name = @list_movie.name
                                                        target_id = @list_movie.id
                                                        target_url = "/movies/#{@list_movie.permalink}"
                                                        target_image = POSTER_URL + @list_movie.banner_image

							#lu = User.find_by_id(@list_first_movie.user_id)
                                                        #unless lu.blank?
                                                        #        list_creator_url = "/profile/#{@list_first_movie.user_id}/#{User.convert_to_seo_url(lu.display_name)}/#{object_node_id}"
                                                        #end
                                                        list_creator_url = "/movie_list/#{object_node_id}/#{@list_first_movie.tag}"
                                                end
                                                object_url = "/movie_list/#{object_node_id}/#{@list_first_movie.tag}"
	
						if not_add == 0
							notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
						end
						
						
					elsif a.activity_type == "rated"
						if actor_id.to_i != cur_user_id.to_i
							not_add = 1
						end
						
						
						if not_add == 0
							@rate_arr = UserMovieList.create_rate_json(cur_user_id, a.movie_id, a.id)
						
							unless @rate_arr["next_movie_name"].blank?
								block_type = "rated"
								notification_action = "rated"
								object_type = "movie"

								next_movie_id = @rate_arr["next_movie_id"]
								next_movie_name = @rate_arr["next_movie_name"]
								next_movie_url = @rate_arr["next_permalink"]
								next_movie_image = @rate_arr["next_movie_image"]

								action_text = "Do you want to rate the next movie <a href='#{next_movie_url}'>#{next_movie_name}</a>?"
								where_to_display = "seen"		
								movie_id = object_node_id
							end
							
							notification_id = save_notification(cur_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
						end
						
					end
					
				end
				
				return notification_id
			end	
		end
	end	


	def self.add_admin_notification(flag, feed_user_id, a)
		not_add = 0
		
		unless feed_user_id.blank?
			notification_id = ""
			act = ActiveSupport::JSON.decode(a.activity)
			
			actor_id = ""
			actor_name = ""
			actor_url = ""
			actor_image = ""
			
			object_node_id = ""
			object_name = ""
			object_url = ""
			object_image = ""
			
			
			target_id = ""
			target_name = ""
			target_url = ""
			target_image = ""
			target_user_id = ""
			
			movie_id = ""
			list_id = ""
			celebrity_id = ""
			
			notification_action = ""
			object_type = ""
			action_text = ""
			where_to_display = ""
			list_creator_url = ""
			
			list_image = ""
			list_url = ""
			list_name = ""
			list_id = ""
			
			next_movie_id = ""
			next_movie_name = ""
			next_movie_url = ""
			next_movie_image = ""
		        destination_url = ""	
			not_add = 0
			
			if act["object"]["objectType"] == "movie"
				object_url = act["object"]["url"]
				
			elsif act["object"]["objectType"] == "list"
				if a.activity_type == "next movie"	
					object_url = act["object"]["url"]
				else						
					object_url = act["actor"]["url"]+ "/" +act["object"]["id"]
				end
			end		
			
			begin
				object_name = act["object"]["displayName"]
				object_node_id = act["object"]["id"]
				object_image = act["object"]["image"]["url"] 				
			
			rescue
			end	
			
			if a.activity_type == "follow celeb filmography"		
				
				celeb = Celebrity.find_by_id(object_node_id)
				user = User.find_by_id(feed_user_id)
				
				if celeb.followed_by?(user)
					not_add = 1
				end

				block_type = "follow_admin_filmography"
				notification_action = "Follow filmography of "
				object_type = "admin filmography feed"
				action_text = ""
				where_to_display = "wanna_see"	
				
				
				unless celeb.blank?
					object_image = celeb.image
					#object_name = celeb.name
					object_url = "/stars/#{celeb.permalink}"
					object_node_id = celeb.id
				end
				object_name = act["object"]["displayName"]
				celebrity_id = object_node_id
				
				if not_add == 0
					notification_id = save_notification(feed_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
				end	
					
			elsif a.activity_type == "follow this list"		
				if not_add == 0 	
					
					user = User.find_by_id(feed_user_id)
					list = UserMovieList.find_by_id(object_node_id)
					
					unless list.blank?
						if !list.followed_by?(user)
							
							where_to_display = "wanna_see"
							list_id = object_node_id
							lu = User.find_by_id(list.user_id)
							#unless lu.blank?
							#	object_url = "/profile/#{list.user_id}/#{User.convert_to_seo_url(lu.display_name)}/#{list.id}"
							#end
							object_url = "/movie_list/#{list.id}/#{list.tag}"	
							block_type = "follow_list_a"
							notification_action = "Follow the awesome list " 
							
							object_type = "admin list feed"

							#action_text = " created by <a href='/profile/#{list.user_id}/#{User.convert_to_seo_url(lu.display_name)}'>#{lu.display_name}</a>".html_safe
							up = lu.user_profile
							action_text = " created by <a href='/#{up.permalink}'>#{lu.display_name}</a>".html_safe
							
							chk_list = UserMovieList.find_by_id(object_node_id)
							mov = ActiveSupport::JSON.decode(chk_list.movie_id)
							m = Movie.find_by_id(mov[0])
							unless m.blank?
								list_image = m.banner_image
								list_url = "/movies/#{m.permalink}"
								list_name = m.name
								list_id = m.id
								
								if not_add == 0
									notification_id = save_notification(feed_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
								end
							end	
						end
					end
						
					
				end	
				
			elsif a.activity_type == "released movie"
				
				@seen_id = AllActivity.get_current_user_seen_list(feed_user_id)
				@m_id = AllActivity.get_current_user_wanna_list(feed_user_id)
				
				
				if !@seen_id.include?(object_node_id.to_s) and !@m_id.include?(object_node_id.to_s)
					
					block_type = "released_movie"
					notification_action = "Have you seen?"
					object_type = "admin movie feed"
					where_to_display = "wanna_see"							
					action_text = ""						
					movie_id = object_node_id	
					
					
					notification_id = save_notification(feed_user_id, a.user_id, a.target_user_id, a.movie_id, a.id, a.activity_type, actor_url, actor_id, actor_image, actor_name, object_url, object_type, object_node_id, object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_id, list_id, celebrity_id,list_creator_url,destination_url )
				end		
			end
		end	
	end
	
	
	def self.save_notification(feed_user, user_id, target_user_id, movie_id, activity_id, activity_type, actor_url, 	
							actor_id, actor_image, actor_name, object_url, object_type, object_node_id,
							object_image, object_name, target_url, target_id, target_image, target_name, block_type, notification_action, next_movie_id, next_movie_name, next_movie_url, next_movie_image, action_text, where_to_display, list_image, list_name, list_url, movie_field_id, list_id, celebrity_id, list_creator_url,destination_url )
		
		add = 1
		
		if activity_type == "saw"
			@dup_notification = AllNotification.find(:all, :conditions => ["feed_user = #{feed_user} and next_movie_id = #{object_node_id} and created_at > '#{Date.today} - 5' "])
			
			unless @dup_notification.blank?
				add = 0
			end
		elsif activity_type == "rated"
			if feed_user.to_i == actor_id.to_i
			
				@dup_notification_1 = AllNotification.find(:all, :conditions => ["feed_user = #{feed_user} and activity_type = 'saw' and object_id = #{next_movie_id}  and created_at > '#{Date.today} - 5'"])
				
				unless @dup_notification_1.blank?
					add = 0
				end
				
				
				#@dup_notification = AllNotification.find(:all, :conditions => ["feed_user = #{feed_user} and next_movie_id = #{next_movie_id} and created_at > '#{Date.today} - 5'"])
                                @dup_notification = AllNotification.find(:all, :conditions => ["feed_user = #{feed_user} and next_movie_id = #{next_movie_id} and created_at > '#{(Date.today - 5).to_s}'"])
				
				unless @dup_notification.blank?
					add = 0
				end
			end
		end
		
		if add == 1 
			n = AllNotification.new					
			n.feed_user = feed_user
			n.user_id = user_id
			n.target_user_id = target_user_id
			
			n.activity_id = activity_id
			n.activity_type = activity_type
			n.object_id = object_node_id
  			n.object_type = object_type
			
			if object_type == "movie"
				n.movie_id = object_node_id		
			else	
				n.list_id = object_node_id
			end
			
			n.list_id = list_id
			n.celebrity_id = celebrity_id
			
			n.next_movie_id = next_movie_id

			@final_arr = []
			actor = ""
			verb = ""
			object = ""
			target = ""
			
			actor = { :url => "#{actor_url}",
				:objectType => "user",
				:id => "#{actor_id}",
				:image => {:url => "#{actor_image}", :width => 250, :height => 250},
				:displayName => "#{actor_name}"
			}

			verb = "#{notification_action}"
			
			object = {:url => "#{object_url}", :objectType => "#{object_type}", :id => "#{object_node_id}",
				:image => {:url => "#{object_image}", :width => 250, :height => 250},
				:displayName => "#{object_name}",
                                :destination_url => "#{destination_url}"
			}
			
			target = { :url => "#{target_url}",
					:objectType => "user",
					:id => "#{target_id}",
					:image => {:url => "#{target_image}", :width => 250, :height => 250},
					:displayName => "#{target_name}"
				  }
			
			
			if n.save
				notification_id = n.id
				no = AllNotification.find_by_id(notification_id)
				@final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target, :block_type => block_type, :notification_action => notification_action, :object_type => object_type, :movie_id => movie_id, :list_id => object_node_id, :next_movie_id => next_movie_id, :next_movie_name => next_movie_name, :next_movie_url => next_movie_url, :next_movie_image => next_movie_image, :action_text => action_text, :where_to_display => where_to_display, :list_image => list_image, :list_name => list_name, :list_url => list_url, :notification_id => notification_id, :list_creator_url => list_creator_url}	
				
				no.update_attribute("notification", @final_arr.to_json)
				
				notification_id = n.id
				
				DisplayHelper.notify(@final_arr, feed_user)
			end
		end	
		
		return notification_id
	end

	
end





