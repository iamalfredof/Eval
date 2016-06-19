class HackerNewsPostsController < ApplicationController

	def index
		@posts = HackerNewsPost.all
	end

end