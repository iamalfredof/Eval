class BackfillWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(foreign_document_url, foreign_document_id, random_hex)
		dp = DocumentProcessor.new(foreign_document_url, foreign_document_id, random_hex)
		dp.process_plain_text_backfill!
  end
  
end