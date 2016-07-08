require 'uri'
require 'open-uri'
require 'fileutils'

class PeruQuioscoUploaderWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :queue => :default

  def perform(pq_id)
    pq_pub                  = PeruQuioscoPub.find(pq_id)
    pdf_page_base_url       = "http://pro.visor.peruquiosco.pe/m/setpdfws/"
    title                   = pq_pub.title
    product                 = pq_pub.product
    folder_path             = 'PQ-' + SecureRandom.hex
    file_path               = pq_pub.title.gsub(/[^0-9A-Za-z.\-]/, '_') + '.pdf'
    file_size               = 0

    product_tag = case product
    when 'El Comercio' # elcomercio
      elcomercio
    when 'Diario Correo' # correo
      correo
    when 'Per\u00fa' # peru21
      peru21
    when 'Gesti\u00f3n' # gestion
      gestion
    when 'Depor' # depor
      depor
    end

    pdf = CombinePDF.new
    for i in 0..(pq_pub.pub_size - 1)
      pre_url         = pdf_page_base_url + (pq_pub.pq_firstpage_id + i).to_s
      page_path       = product_tag + "_page_" + (i+1).to_s + ".pdf"
      pdf_url         = JSON.parse( HTTParty.get(pre_url).body )['url_pdf']

      # Download Files
      open(page_path, 'wb') do |file|
          file << open(pdf_url).read
      end

      # Append PDF
      pdf << CombinePDF.load( page_path )
    end

    # Save Appended PDF
    pdf.save file_path

    # Clean Pages
    for i in 0..(pq_pub.pub_size - 1)
      page_path       = "page_" + (i+1).to_s + ".pdf"
      File.delete( page_path )
    end

    # Create dir
    FileUtils.mkdir folder_path

    # Move file to dir
    FileUtils.mv file_path, folder_path

    # Upload Folder and File inside
    uploader = S3FolderUpload.new(folder_path)
    uploader.upload!(2, 'uploads/book/raw/')

    # Clean files
    File.delete( folder_path + '/' + file_path )
    FileUtils.rm_rf( folder_path )

    user_id = case product
    when 'El Comercio' # elcomercio
      150
    when 'Diario Correo' # correo
      151
    when 'Per\u00fa' # peru21
      152
    when 'Gesti\u00f3n' # gestion
      153
    when 'Depor' # depor
      155
    end

    # Send request to udocz
    response = HTTParty.post('https://www.udocz.com/api/v1/create_document',
                :body => {
                  "user_id" => user_id,
                  "original_document_url" => "https://ubooks.s3.amazonaws.com/uploads%2Fbook%2Fraw%2F" + folder_path + "%2F" + file_path,
                  "title" => pq_pub.title,
                  "filesize" => file_size,
                  "doc_type" => "application/pdf",
                  "unique_id" => pq_pub.pq_firstpage_id.to_s,
                  "category_id" => 13, # News and Politics Category
                  "secret" => "64zNYufgM8dL1x506FY092uKbms23tT7"
                }
              )

  end
  
end