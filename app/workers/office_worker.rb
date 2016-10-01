class OfficeWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include ApiHelper
  
  sidekiq_options :queue => :office

  def perform(foreign_document_url, foreign_document_id, random_hex)
    begin
      processor = DocumentProcessor.new(foreign_document_url, foreign_document_id, random_hex)
      html_url = processor.start_routine
      logger.info html_url
    rescue => ex
      html_callback('html_conversion_fail', 'Office conversion fails', '', foreign_document_id)
      processor.remove_on_fail
      logger.error ex.message
    end
  end
  
end