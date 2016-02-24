json.array!(@documents) do |document|
  json.extract! document, :id, :foreign_document_id, :foreign_user_id, :document_url, :html_url
 	json.url document_url(document, format: :json)
end