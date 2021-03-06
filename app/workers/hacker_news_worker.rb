class HackerNewsWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :crawler

  def perform
    current_top_ids = HTTParty.get("https://hacker-news.firebaseio.com/v0/topstories.json")

    current_top_ids.each do |id|
      item = HTTParty.get( "https://hacker-news.firebaseio.com/v0/item/" + id.to_s  + ".json"  )
      if item['url'].present?
        if item['url'].include? '.pdf'
          HackerNewsPost.create(:hn_id => item['id'],
                                :title => item['title'],
                                :url => item['url'])
        end
      end
    end

    HackerNewsPost.new.schedule_hn
  end
  
end