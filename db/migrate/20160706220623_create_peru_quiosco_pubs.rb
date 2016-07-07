class CreatePeruQuioscoPubs < ActiveRecord::Migration
  def change
    create_table :peru_quiosco_pubs do |t|
    	t.integer :pq_firstpage_id
    	t.integer :pub_size
    	t.string :title
    	t.string :product
    	t.datetime :pub_time
    end
  end
end
