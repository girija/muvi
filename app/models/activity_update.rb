class ActivityUpdate < ActiveRecord::Base
  scope :latest, order('created_at desc nulls last')
  scope :today_new_movie, where('activity_type =? and activity_date = ?', 'New Movie', Date.today.to_s)
  scope :today_edited_movie, where('activity_type =? and activity_date = ?', 'Edit Movie Info', Date.today.to_s)
  scope :new_poster, where('activity_type =? and activity_date = ?', 'New Poster', Date.today.to_s)
  scope :new_trailer, where('activity_type =? and activity_date = ?', 'New Trailer', Date.today.to_s)
  scope :todays_tweet, where('activity_type =? and activity_date = ?', 'tweet', Date.today.to_s)
  scope :todays_facebook_post, where('activity_type =? and activity_date = ?', 'facebook post', Date.today.to_s)
  scope :todays_critics_reviews, where('activity_type =? and activity_date = ?', 'critic review', Date.today.to_s)
  scope :admin_updates, where('actor = ?', 'admin')
  scope :scheduler_updates, where('actor = ?', 'scheduler')

  def self.create_histories
    ActivityUpdate.tweet_histroy
    ActivityUpdate.facebook_posts_histroy
    ActivityUpdate.critics_reviews_histroy
    ActivityUpdate.new_movie_histroy
    ActivityUpdate.edit_movie_histroy
    ActivityUpdate.new_poster_histroy
    ActivityUpdate.new_trailer_histroy
  end


  def self.tweet_histroy
    ActivityUpdate.todays_tweet.first.destroy unless ActivityUpdate.todays_tweet.first.blank?
    unless Tweet.todays_tweets.count == 0
      movie_ids = Tweet.todays_tweets.collect(&:movie_id).uniq!
      names = Movie.where('id in (?)', movie_ids).collect(&:name).to_sentence
      ActivityUpdate.create_histroy('tweet', names, Tweet.todays_tweets.count, 'Got tweets for movies ', 'scheduler')
    end
  end

  def self.facebook_posts_histroy
    ActivityUpdate.todays_facebook_post.first.destroy unless ActivityUpdate.todays_facebook_post.first.blank?
    unless FacebookFeed.all_posts.todays.count == 0
      movie_ids = FacebookFeed.all_posts.todays.collect(&:movie_id).uniq!
      names = Movie.where('id in (?)', movie_ids).collect(&:name).to_sentence
      ActivityUpdate.create_histroy('facebook post', names, FacebookFeed.all_posts.todays.count, 'Got FB posts for movies ', 'scheduler')
    end
  end

  def self.critics_reviews_histroy
    ActivityUpdate.todays_critics_reviews.first.destroy unless ActivityUpdate.todays_critics_reviews.first.blank?
    unless CriticsReview.todays.count == 0
      movie_ids = CriticsReview.todays.collect(&:movie_id).uniq!
      names = Movie.where('id in (?)', movie_ids).collect(&:name).to_sentence
      ActivityUpdate.create_histroy('critic review', names, CriticsReview.todays.count, 'Got critic review for movies ', 'scheduler')
    end
  end

  def self.new_movie_histroy
    ActivityUpdate.today_new_movie.first.destroy unless ActivityUpdate.today_new_movie.first.blank?
    count = Movie.todays_new_movies.count
    unless count == 0
      names = Movie.todays_new_movies.collect(&:name).to_sentence
      ActivityUpdate.create_histroy('New Movie', names, count, "Added #{count} new movies ", 'admin')
    end
  end

  def self.edit_movie_histroy
    ActivityUpdate.today_edited_movie.first.destroy unless ActivityUpdate.today_edited_movie.first.blank?
    count = Movie.todays_updated_movies.count
    unless count == 0
      names = Movie.todays_updated_movies.collect(&:name).to_sentence
      ActivityUpdate.create_histroy('Edit Movie Info', names, count, "Edited Movie information ", 'admin')
    end
  end

  def self.new_poster_histroy
    ActivityUpdate.new_poster.first.destroy unless ActivityUpdate.new_poster.first.blank?
    count = Movie.todays_poster.count
    unless count == 0
      names = Movie.todays_poster.collect(&:name).to_sentence
      ActivityUpdate.create_histroy('New Poster', names, count, "Added posters for #{count} movies ", 'admin')
    end
  end

  def self.new_trailer_histroy
    ActivityUpdate.new_trailer.first.destroy unless ActivityUpdate.new_trailer.first.blank?
    count = Video.todays_trailer.count
    unless count == 0
      movie_ids = Video.todays_trailer.collect(&:movie_id)
      names = Movie.where('id in (?)', movie_ids).collect(&:name).to_sentence
      ActivityUpdate.create_histroy('New Trailer', names, count, "Added trailers for #{count} movies ", 'admin')
    end
  end

  def self.create_histroy(type, names, number, description, actor)
    self.create({:activity_date => Date.today,:activity_type => type, :number => number, :description => description + names, :actor => actor })
  end

end

