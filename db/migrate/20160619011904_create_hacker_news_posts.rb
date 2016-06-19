class CreateHackerNewsPosts < ActiveRecord::Migration
  def change
    create_table :hacker_news_posts do |t|
    	t.integer :hn_id
    	t.string :title
    	t.string :url
    end
  end
end
