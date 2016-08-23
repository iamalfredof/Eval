class CleanMissingDocumentsWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform
  	documents = Document.all
	
		deleted = 0
		documents.each do |doc|
			status_code = JSON.parse(
											HTTParty.get('https://www.udocz.com/api/v1/get_document/' + 
												doc.foreign_document_id.to_s + '.json')
											.body)['status']
			if status_code == 404
				doc.destroy
				deleted += 1
			end
		end

		Pusher.url = "https://d433e26b16810b708c60:41d9443db5f531f17275@api.pusherapp.com/apps/174026"
  		Pusher.trigger('api_channel', 'cross_check_done', {
	      deleted: deleted
	    })
  end
  
end