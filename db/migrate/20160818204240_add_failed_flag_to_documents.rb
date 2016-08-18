class AddFailedFlagToDocuments < ActiveRecord::Migration
  def change
  	add_column :documents, :failed_processing, :boolean, :default => false
  end
end
