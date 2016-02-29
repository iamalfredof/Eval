class DocumentWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :documents

  def perform(foreign_document_url, foreign_document_id)
    processor = DocumentProcessor.new(foreign_document_url, foreign_document_id)
    html_url = processor.start_routine
  end
  
end