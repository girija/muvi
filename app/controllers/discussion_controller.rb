class DiscussionController < ApplicationController
  skip_before_filter :authenticate_user!
  layout nil

  def save_discussion
    if params[:reference_type] == "Movie"
      @refer = Movie.find_by_id(params[:reference_id])
    else
      @refer = Celebrity.find_by_id(params[:reference_id])
    end
    params[:discussion][:user_id] = current_user.id
    @discussion = Discussion.new(params[:discussion])
    #@discussion.tag_list = params[:tags].join(",")
    if @discussion.save
      Discussion.log_discussion_activity(current_user,@discussion, "Post",@refer)
      @tag = Tag.find_by_name(@refer.name)
      if @tag.blank?
        @tag = Tag.new
        @tag.id = Tag.last.id + 1
        @tag.name =  @refer.name
        @tag.save
      end
      Tagging.create(:tag_id => @tag.id, :taggable_id => @discussion.id,:taggable_type => "Discussion",:tagger_id => @refer.id, :tagger_type =>  params[:reference_type],:context => "tags")
    end
    if params[:inner_page] == "celebrity" or params[:inner_page] == "movie"
      @p_item = params[:inner_page].capitalize.constantize.find_by_id(params[:inner_id])
    end

    if params[:inner_item] == "movie" or !params[:block_type].nil?
      @movie = @refer
    end

    respond_to do |format|
      format.html {}
      format.js { }
    end
  end
  def vote
    @user_badge =  UserBadge.new
    @user_badge.add_badge_points(current_user.id)
    @item = params[:item_class].constantize.find_by_id(params[:id])
    if params[:profile_page] == "true"
      @user_profile = UserProfile.find_by_id(params[:profile_id])
      if params[:item_class] == "Poster"
        like_posters = @user_profile.like_posters
        like_posters.each_with_index do |lp,i|
          if lp.votable_id.to_s == params[:id]
            @next_item = like_posters[i+1].nil? ? "" : Poster.find_by_id(like_posters[i+1].votable_id)
            @prev_item = Poster.find_by_id(like_posters[i-1].votable_id)
            break
          end
        end
      else
        like_videos = @user_profile.like_videos
        like_videos.each_with_index do |lv,i|
          if lv.votable_id.to_s == params[:id]
            @next_item = like_videos[i+1].nil? ? "" : Video.find_by_id(like_videos[i+1].votable_id)
            @prev_item = Video.find_by_id(like_videos[i-1].votable_id)
            break
          end
        end
      end
      @item.vote :voter =>current_user, :vote => "#{params[:type]}"
    elsif params[:inner_page] == "true"
      @p_item  = params[:p_cls].constantize.find_by_id(params[:p_id])
      @item.vote :voter =>current_user, :vote => "#{params[:type]}"
    else
      @like_status = Discussion.check_like(current_user,@item)
      if !@like_status
        @item.vote :voter =>current_user, :vote => 'like'
        @vote = Vote.where("votable_id = #{@item.id} AND votable_type = '#{@item.class.to_s}' AND voter_id = #{current_user.id}").first
        if params[:item_class] == "Discussion"
          Discussion.log_discussion_activity(current_user,@item, "Likes")
        end
      end
    end
    respond_to do |format|
      format.html {}
      format.js { }
    end
  end

  
  def discussion_detail
    @item = params[:item_class].constantize.find_by_id(params[:id])
    @tagging = Tagging.where("taggable_type = '#{params[:item_class]}' and taggable_id = '#{@item.id}' and tagger_type = '#{params[:refer_type]}'").find(:first)
    if @tagging
      if @tagging.tagger_type == "Movie"
        @refer = Movie.find_by_id(@tagging.tagger_id)
      elsif @tagging.tagger_type == "Celebrity"
        @refer = Celebrity.find_by_id(@tagging.tagger_id)
      else
        @refer = @item
      end
    else
      @refer = @item
    end
    render :partial => '/shared/discussion', :locals =>{ :item => @item}
  end
end
