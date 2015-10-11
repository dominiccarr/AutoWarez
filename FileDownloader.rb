require 'rubygems'
require 'typhoeus'

module FileDownloader

  Hydra = Typhoeus::Hydra.new(:max_concurrency => 20)
	
	def FileDownloader.write_file(filename, data)
      file = File.new(filename, "wb")
      file.write(data)
      file.close
  end
	
	def FileDownloader.download_files(urls,dir)
	  urls.each do |url_info|
        req = Typhoeus::Request.new(url_info)
        req.on_complete do |response|
          FileDownloader::write_file("#{$dir}/#{$1}", response.body) if url_info =~ /.*\/(.*)/
        end
        Hydra.queue req
    end
    Hydra.run
  end
  
end