class HackerNewsPost < ActiveRecord::Base
	validates :hn_id, uniqueness: true

	after_create :upload_file

	def upload_file
		# Worker here to upload the file
		HackerNewsUploaderWorker.perform_async(self.hn_id) 
	end

	def search_hacker_news
		HackerNewsWorker.perform_async
	end

end