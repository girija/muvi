class News < ActiveRecord::Base
  set_table_name 'feeds'
  attr_accessor :tag_list
  acts_as_commentable
  acts_as_votable
  acts_as_taggable
  scope :diff_score_nonzero, where("diff_score > 0")
  has_many :like_votes, :conditions => [ "vote_flag = ?", 'true' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :dislike_votes, :conditions => [ "vote_flag = ?", 'false' ], :dependent => :destroy, :class_name => 'Vote',:foreign_key => "votable_id"
  has_many :activities , :conditions => [ "secondary_subject_type = ?", 'News' ], :dependent => :destroy,:foreign_key => "secondary_subject_id"
  def self.get_latest_news
    feed_arr = []
    feed = Feed.find(:all, :conditions => ["(rank != 0 or rank IS NULL)"], :order => ["created_at desc,  rank asc"],:limit => 4)
    unless feed.blank?
      feed.each do |f|
        news = f.taggings
        unless news.blank?
          feed_arr << f
        end
      end
    end
    return feed_arr
  end

  def self.save_comment(news, comment)
    @comment = news.comments.new({:comment =>  comment,:user_id => '1385'})
    @comment.save
  end

  def self.save_vote(news,type)
    news.vote :voter =>User.find_by_id('1385'), :vote => type
  end
  def self.get_item_news(type)
    @item_news = []
    Tagging.where("taggable_type = 'Feed' and tagger_type = '#{type}'").find(:all).each do |tag|
      news = News.find_by_id(tag.taggable_id)
      @item_news << news unless news.blank?
    end
    return @item_news
  end
  def self.get_news(tagger_id, tagger_type)
    @news = []
    Tagging.where("taggable_type = 'Feed' and tagger_id = '#{tagger_id}' and tagger_type = '#{tagger_type}'").find(:all).each do |tag|
      news = Feed.find_by_id(tag.taggable_id)
      @news << news unless news.blank?
    end
    unless @news.blank?
      @news.sort!{|a,b| (a.rank) <=> (b.rank)}
    end
    @news = @news.uniq
    return @news
  end

end
