json.array!(@documents) do |document|
  json.extract! document, :id, :foreign_document_id, :foreign_document_url, :html_url
 	json.url url_for(document)
end