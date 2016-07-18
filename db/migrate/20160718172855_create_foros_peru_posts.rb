class CreateForosPeruPosts < ActiveRecord::Migration
  def change
    create_table :foros_peru_posts do |t|
    	t.string :post_id
    	t.string :url
    	t.string :keyword
    end
  end
end
