class BackfillAllMobilePagesWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform
		documents = Document.where(:backfilled => false).order('random()')
		offset = 0

		Rails.logger.info( 'Documents Pending: ' + (documents.size.to_s) + '/' + Document.all.count.to_s )

		documents.each do |d|
			random_hex = d.html_url.split('/')[4].split('-').last
			dpm = DocumentProcessorMobile.new(
							d.foreign_document_url,
							d.foreign_document_id,
							random_hex
						)

			d.update_attribute(:backfilled, dpm.start_routine)
		end

  end

end