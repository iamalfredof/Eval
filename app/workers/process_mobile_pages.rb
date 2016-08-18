class ProcessMobilePagesWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(foreign_document_url, foreign_document_id, random_hex)
		dpm = DocumentProcessorMobile.new(
						foreign_document_url,
						foreign_document_id,
						random_hex, 
						5
					)
		Document.where(:foreign_document_id => foreign_document_id)
			.first
			.update_attribute(:backfilled, dpm.start_routine)
  end

end