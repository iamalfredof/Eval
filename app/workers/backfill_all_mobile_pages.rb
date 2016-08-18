class BackfillAllMobilePagesWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(batch)
		documents = Document.where(:backfilled => false).order('random()').limit(batch)
		offset = 0

		Rails.logger.info( 'Documents Pending: ' + (documents.size.to_s) + '/' + Document.all.count.to_s )

		documents.each do |d|
			ProcessMobilePagesWorker.perform_async(
					d.foreign_document_url,
					d.foreign_document_id,
					d.html_url.split('/')[4].split('-')[1]
				)
		end

  end

end