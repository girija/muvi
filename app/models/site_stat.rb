class SiteStat < ActiveRecord::Base

  def self.update_site_stat
    st = SiteStat.first || SiteStat.new
    st.movies_count = Movie.count
    st.reviews_count = (CriticsReview.count + Review.count + Tweet.pos_or_neg.count + FacebookFeed.posts.count)
    st.celebrities_count = Celebrity.count
    st.save
  end


end

