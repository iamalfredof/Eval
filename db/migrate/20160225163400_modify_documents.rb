class ModifyDocuments < ActiveRecord::Migration
  def change
  	rename_column :documents, :document_url, :foreign_document_url
  end
end
