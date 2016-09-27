class OfficeWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :office

  def perform(foreign_document_url, foreign_document_id, random_hex)
    begin
      processor = DocumentProcessor.new(foreign_document_url, foreign_document_id, random_hex)
      html_url = processor.start_routine
      logger.info html_url
    rescue => ex
      logger.error ex.message
    end
  end
  
end