class PNOWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :default

  def perform(foreign_document_url, foreign_document_id, random_hex)
    processor = DocumentProcessor.new(foreign_document_url, foreign_document_id, random_hex)
		processor.process_non_optimized!
  end
  
end