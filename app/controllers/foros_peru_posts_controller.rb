class ForosPeruPostsController < ApplicationController

	def index
		@posts = ForosPeruPost.all
	end

end