require 'uri'
require 'open-uri'
require 'fileutils'

class HackerNewsUploaderWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :default

  def perform(hn_id)
    folder_path = Time.now.to_s + '-HN-' + SecureRandom.hex
    post = HackerNewsPost.where(:hn_id => hn_id).first
    file_path = post.title

    # Download File
    open(file_path, 'wb') do |file|
      file << open(post.url).read
    end

    # Create dir
    %x( mkdir #{folder_path} )
    unless $?.exitstatus == 0
      Rails.logger.error "Failed at making directory."
    end

    # Move file to dir
    %x( cp #{file_path} #{folder_path}/#{file_path} )
    unless $?.exitstatus == 0
      Rails.logger.error "Failed at copying file to folder. Command: cp #{file_path} #{folder_path}/#{file_path}"
      return false
    end

    # Upload Folder and File inside
    uploader = S3FolderUpload.new(folder_path)
    uploader.upload!(2, 'uploads/book/raw/')

    # Send request to udocz
    response = HTTParty.post('https://www.udocz.com/api/v1/create_document',
                :body => {
                  "user_id" => 149,
                  "original_document_url" => "https://ubooks.s3.amazonaws.com/uploads%2Fbook%2Fraw%2F" + folder_path + "%2F" + file_path,
                  "title" => post.title,
                  "filesize" => "0",
                  "doc_type" => "application/pdf",
                  "unique_id" => hn_id.to_s
                }.to_json
              )

  end
  
end