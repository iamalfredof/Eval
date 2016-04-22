class AddSecret < ActiveRecord::Migration
  def change
  	add_column :documents, :secret, :string
  end
end
