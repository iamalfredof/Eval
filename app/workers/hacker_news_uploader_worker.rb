require 'uri'
require 'open-uri'
require 'fileutils'

class HackerNewsUploaderWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :default

  def perform(hn_id)
    folder_path = 'HN-' + SecureRandom.hex
    post = HackerNewsPost.where(:hn_id => hn_id).first
    file_path = post.title.gsub(/[^0-9A-Za-z.\-]/, '_') + '.pdf'
    url = post.url
    if url.include? 'github.com'
      url = url.gsub('blob','raw')
    end

    # Create dir
    FileUtils.mkdir folder_path

    file_size = 0
    # Download File
    open(file_path, 'wb',
      :content_length_proc => lambda {|content_length|
        file_size = content_length
      }) do |file|
        file << open(url).read
    end

    # Move file to dir
    FileUtils.mv file_path, folder_path

    # Upload Folder and File inside
    uploader = S3FolderUpload.new(folder_path)
    uploader.upload!(2, 'uploads/book/raw/')

    # Clean files
    File.delete( folder_path + '/' + file_path )
    FileUtils.rm_rf( folder_path )

    # Send request to udocz
    response = HTTParty.post('https://www.udocz.com/api/v1/create_document',
                :body => {
                  "user_id" => 149,
                  "original_document_url" => "https://ubooks.s3.amazonaws.com/uploads%2Fbook%2Fraw%2F" + folder_path + "%2F" + file_path,
                  "title" => post.title,
                  "filesize" => file_size,
                  "doc_type" => "application/pdf",
                  "unique_id" => hn_id.to_s,
                  "category_id" => 5, # Technology Category
                  "secret" => "64zNYufgM8dL1x506FY092uKbms23tT7"
                }
              )

  end
  
end