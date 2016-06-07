class NonOptimizedWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(foreign_document_url, foreign_document_id, random_hex)
    processor = DocumentProcessor.new(foreign_document_url, foreign_document_id, random_hex)
		processor.process_plain_text_ocr!
  end
  
end