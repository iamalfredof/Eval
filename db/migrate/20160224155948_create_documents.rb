class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
    	t.integer :foreign_document_id
    	t.string :document_url
    	t.string :html_url
    end
  end
end
