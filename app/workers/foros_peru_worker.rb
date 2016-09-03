class ForosPeruWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :crawler

  def perform(keyword)
    search_url                = "http://www.forosperu.net/buscar/99999999/?q=" + keyword + "&o=date"
    parse_page                = Nokogiri.HTML( HTTParty.get(search_url) )
    list                      = parse_page.css('.searchResultsList').css('li')

    list.each do |li|
      post_id          = li.attr('id')
      url              = "http://forosperu.net/" + li.css('.listBlock').css('.titleText').css('.title').css('a').attr('href').value()

      ForosPeruPost.create(:post_id => post_id,
                           :url => url,
                           :keyword => keyword)
    end

    ForosPeruPost.new.schedule_fp(keyword)
  end
  
end