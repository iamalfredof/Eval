task :recreate_plain_text => :environment do
	documents = Document.all
	
	documents.each do |d|
		random_hex = d.html_url.split('/')[4].split('-').last
		dp = DocumentProcessor.new(d.foreign_document_url, d.foreign_document_id, random_hex)
		dp.process_plain_text_backfill!
	end

end