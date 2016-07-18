class ForosPeruPost < ActiveRecord::Base
	validates :post_id, uniqueness: true

	after_create :notify_carlos

	def notify_carlos
		PushoverWorker.perform_async('Keyword: ' + self.keyword, 'URL: ' + self.url) 
	end

	def schedule_fp(keyword)
		ForosPeruWorker.perform_in(1.hour, keyword)
	end

end