class ProcessMobilePagesWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(foreign_document_url, foreign_document_id, random_hex)
		dpm = DocumentProcessorMobile.new(
						foreign_document_url,
						foreign_document_id,
						random_hex, 
						50
					)
		dpm.start_routine
  end

end