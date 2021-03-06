module AllActivityHelper


  def self.get_wanna_list(flag,cur_user_id, m_id)
    @all_wanna_see_activity = []
    @all_seen_activity = []
	@activity_id = []
    
    #@conn_id = ""
    #uc = UserConnection.find_by_user_id(cur_user_id)
    #unless uc.blank?
    #  @conn = ActiveSupport::JSON.decode(uc.connections)
    #  unless @conn.blank?
    #    @conn.each do |conn|
    #      if @conn_id.blank?
    #        @conn_id = conn
    #      else
    #        @conn_id = @conn_id.to_s + "," + conn.to_s
    #      end
    #    end
    #  end
    #end
    unless m_id.blank? #and @conn_id.blank?
        check = ListOfMovie.find(:all, :conditions => ["user_id != #{cur_user_id}"]) #and user_id IN (#{@conn_id})"])
        unless check.blank?
          check.each do |c|
			if !c.wanna_see_lists.blank? or !c.seen_lists.blank?			
				list = ""
				list_1 = []
				list_2 = []
				list_1 = ActiveSupport::JSON.decode(c.seen_lists) unless c.seen_lists.blank?
				list_2 = ActiveSupport::JSON.decode(c.wanna_see_lists) unless c.wanna_see_lists.blank?
				
				list = list_1.concat(list_2)
				@act_id = ""
				unless list.blank?
				  list.each do |l|
					m_id.uniq.each do |m|
					  unless l.blank?
							unless m.blank?
								if m.to_s == l["object"]["id"].to_s
								  # Add activity for this notification
								  act_type = ""
								  if l["target"] == "wanna see"
									act_type = "want to see"
								  elsif l["target"] == "seen it"
									act_type = "saw"
								  end

								  act_chk = AllActivity.find(:first, :conditions => ["user_id = #{l["actor"]["id"]} and movie_id = #{m} and activity_type = '#{act_type}'"])
								  
									if act_chk.blank?
										if l["target"] == "seen it"
										  chk_1 = AllActivity.find(:first, :conditions => ["user_id = #{l["actor"]["id"]} and movie_id = #{m} and activity_type = 'want to see'"])
										  chk_1.update_attribute("viewed", 't') unless chk_1.blank?
										end
										act = AllActivity.new
										act.user_id = l["actor"]["id"]
										act.movie_id = m
										act.activity_type = act_type
										act.activity = AllActivity.create_json(l)
										act.save	
										@act_id = act.id	
										if l["target"] == "wanna see"
											l["action"] = "want to see"
										elsif l["target"] == "seen it"
										  l["action"] = "saw"
										end
										l["movie_id"] = m
										l["user_id"] = l["actor"]["id"]
										l["block_type"] = l["action"]
										l["cur_user_id"] = cur_user_id
										if !@act_id.blank?
										  l["activity_id"] = @act_id
										else
										  l["activity_id"] = ''
										end        
										@activity_id << @act_id
										@all_wanna_see_activity << l
									end
								end
							end
					  end
					end
				  end
				end
			end
          end
        end
      end

      qry = ""
      if flag == 0
        #qry = ""
      elsif flag == 1
        #qry = "and viewed = 'f'"
      end

      unless m_id.blank?
        mov_id_1 = ""
        m_id.uniq.each do |m1|
          if mov_id_1.blank?
              mov_id_1 = m1
            else
              mov_id_1 = mov_id_1.to_s + "," + m1.to_s
            end
        end
      end

      unless mov_id_1.blank?
        cur_user_wanna_see = AllActivity.select("movie_id").find(:all, :conditions => ["target_user_id = #{cur_user_id} and activity_type IN ('has recommended', 'has not recommended') and viewed = 'f' and movie_id IN (#{mov_id_1})"])
      else
        #cur_user_wanna_see = AllActivity.select("movie_id").find(:all, :conditions => ["target_user_id = #{cur_user_id} and activity_type IN ('has recommended', 'has not recommended') and viewed = 'f'"])
      end

      unless cur_user_wanna_see.blank?
        cur_user_wanna_see.each do |cu|
          if !cu.movie_id.blank?
            m_id << cu.movie_id
          end
        end
      end
      
      unless m_id.blank?
        mov_id = ""
        m_id.uniq.each do |m1|
          if mov_id.blank?
              mov_id = m1
            else
              mov_id = mov_id.to_s + "," + m1.to_s
            end
        end
      end
      unless mov_id.blank?
        #@all_wanna_see_activity_1 = AllActivity.find(:all, :conditions => ["movie_id IN (#{mov_id}) and user_id NOT IN (#{cur_user_id}) and user_id IN (#{@conn_id}) and viewed = 'f' and activity_type NOT IN ('want to see', 'wants to see')"], :order => ["created_at desc"])
        @all_wanna_see_activity_1 = AllActivity.find(:all, :conditions => ["movie_id IN (#{mov_id}) and user_id NOT IN (#{cur_user_id}) and viewed = 'f' and activity_type NOT IN ('want to see', 'wanna see', 'asked')"], :order => ["created_at desc"])

        unless @all_wanna_see_activity_1.blank?
          @all_wanna_see_activity_1.each do |a|
			if @activity_id.grep(a.id).blank?
				ac_1 = ActiveSupport::JSON.decode(a.activity)
				unless ac_1.blank?
				  ac_1.each do |ac|
					ac["action"] = a.activity_type
					ac["user_id"] = ac["actor"]["id"]
					ac["block_type"] = ac["action"]
					ac["cur_user_id"] = cur_user_id
					ac["activity_id"] = a.id
					ac["movie_id"] = a.movie_id
                                        unless a.viewed_list.blank?
  				          ac["viewed_list"] = ActiveSupport::JSON.decode(a.viewed_list)	
                                        else
                                          ac["viewed_list"] = ""
                                        end
					@all_wanna_see_activity << ac
					#a.update_attribute(:viewed, 't')
				  end
				end
			end
          end
        end
      end
	  
    return @all_wanna_see_activity.uniq
  end



  def self.get_seen_list(flag,cur_user_id, m_id)
     @all_seen_activity = []
	 @activity_id = []
     #m_id = AllActivity.get_current_user_seen_list(cur_user_id)
     
     #@conn_id = ""
     #uc = UserConnection.find_by_user_id(cur_user_id)
     #unless uc.blank?
     #  @conn = ActiveSupport::JSON.decode(uc.connections)
     #  unless @conn.blank?
     #    @conn.each do |conn|
     #      if @conn_id.blank?
     #        @conn_id = conn
     #      else
     #        @conn_id = @conn_id.to_s + "," + conn.to_s
     #      end
     #    end
     #  end
     #end

      unless m_id.blank?
        check = ListOfMovie.find(:all, :conditions => ["user_id != #{cur_user_id}"]) #and user_id IN (#{@conn_id})"])
        unless check.blank?
          check.each do |c|
			if !c.seen_lists.blank? or !c.wanna_see_lists.blank?
				list = ""
				list_1 = []
				list_2 = []
				list_1 = ActiveSupport::JSON.decode(c.seen_lists)  unless c.seen_lists.blank?
				list_2 = ActiveSupport::JSON.decode(c.wanna_see_lists) unless c.wanna_see_lists.blank?
				
				list = list_1.concat(list_2)
				@act_id = ""
				unless list.blank?
				  list.each do |l|
					m_id.uniq.each do |m|
					  unless l.blank?
						if m.to_s == l["object"]["id"].to_s
						  # Add activity for this notification
						  if l["target"] == "wanna see"
							act_type = "want to see"
						  elsif l["target"] == "seen it"
							act_type = "saw"
						  end

						  
						  act_chk = AllActivity.find(:first, :conditions => ["user_id = #{l["actor"]["id"]} and movie_id = #{m} and activity_type = '#{act_type}'"])
						  if act_chk.blank?
							if l["target"] == "seen it"
							  chk_1 = AllActivity.find(:first, :conditions => ["user_id = #{l["actor"]["id"]} and movie_id = #{m} and activity_type = 'want to see'"])
							  chk_1.update_attribute(:viewed,'t') unless chk_1.blank?
							end
							act = AllActivity.new
							act.user_id = l["actor"]["id"]
							act.movie_id = m
							act.activity_type = act_type
							act.activity = AllActivity.create_json(l)
							act.save
							@act_id = act.id
							###################################

							if l["target"] == "wanna see"
							  l["action"] = "wants to see"
							elsif l["target"] == "seen it"
							  l["action"] = "saw" 
							end
							l["movie_id"] = m
							l["user_id"] = l["actor"]["id"]
							l["block_type"] = "seenit"
							l["cur_user_id"] = cur_user_id
							if !@act_id.blank?
							  l["activity_id"] = @act_id
							else
							  l["activity_id"] = ''
							end  
							@activity_id << @act_id
							@all_seen_activity << l
						  end
						end
					  end
					end
				  end
				end
			end
          end
        end
      end


      seen_m_id = ""

      unless m_id.blank?
        m_id.uniq.each do |m1|
          if seen_m_id.blank?
              seen_m_id = m1
            else
              seen_m_id = seen_m_id.to_s + "," + m1.to_s
            end
        end
      end


      unless seen_m_id.blank?
        qry = "and viewed = 'f'"
      if flag == 0
        #qry = ""
      elsif flag == 1
        #qry = "and viewed = 'f'"
      end

      #@all_seen_activity_1 = AllActivity.find(:all, :conditions => ["((activity_type IN ('wanna see', 'want to see', 'asked', 'saw')  and viewed = 'f') or (target_user_id = #{cur_user_id} and viewed = 'f' )) and activity_type NOT IN ('has recommended', 'has not recommended') and user_id != #{cur_user_id}  and user_id IN (#{@conn_id})"], :order => ["created_at desc"])

      @all_seen_activity_1 = AllActivity.find(:all, :conditions => ["((activity_type IN ('asked')  and viewed = 'f') or (target_user_id = #{cur_user_id} and viewed = 'f' )) and activity_type NOT IN ('has recommended', 'has not recommended', 'saw') and user_id != #{cur_user_id}"], :order => ["created_at desc"])  #and user_id IN (#{@conn_id})"], :order => ["created_at desc"])

        unless @all_seen_activity_1.blank?
          @all_seen_activity_1.each do |a|
			if @activity_id.grep(a.id).blank?
				ac_1 = ActiveSupport::JSON.decode(a.activity)
				unless ac_1.blank?
				  ac_1.each do |ac|
					ac["action"] = a.activity_type
					ac["user_id"] = ac["actor"]["id"]
					ac["block_type"] = "seenit"
					ac["cur_user_id"] = cur_user_id
					ac["activity_id"] = a.id
					ac["movie_id"] = a.movie_id
					@all_seen_activity << ac
					#a.update_attribute(:viewed, 't')
				  end
				end
			end
          end
        end
      end
	  
      return @all_seen_activity.uniq
    end


end





