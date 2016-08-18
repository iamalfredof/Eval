class AddBackfilledToDocuments < ActiveRecord::Migration
  def change
  	add_column :documents, :backfilled, :boolean, :default => false
  end
end
