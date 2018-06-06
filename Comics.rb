require 'net/http'
require 'rubygems'
require 'googleajax'
require 'openssl'
require_relative 'Comic.rb'
require_relative 'Strings.rb'
require_relative 'ComicWarez.rb'

module Comics
  @@chan_search = "http://rs.4chan.org/?s="
  @@co = "http://boards.4chan.org/co/"
  @@comic_link = "https://www.previewsworld.com/shipping/newreleases.txt"
  
  def self.read_in(url) 
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
	data = http.get(uri.request_uri)
	return data.body
  end

  def self.new_comics
    comics = Hash.new
    publisher = 'DC COMICS'
    array = self::read_in(@@comic_link).split("\n")
    array.each do |elem|
        if elem =~ /^\w\w\w\d{4,}\s{1,}(.*?)(\s#\d{1,4})(\.\d)?(.*)\s\$/
            raw = $1
            title = $1.swapcase
            info = $4
            fractional = $3
            number = "#{$2.gsub!('#', '0').strip!}#{fractional}"
            title.gsub!(/\b\w/) { $&.upcase }
            comic = Comic.new(title, publisher, number)
            comic.info = info.strip!
            comics[publisher] ||= []
            comics[publisher] << comic
        elsif elem =~ /^([(^\$)\&a-z\.A-Z\s]){2,}$/
          publisher = elem.rstrip
        end
    end
    comics.values.each { |publisher| publisher.uniq! { |comic| comic.display } }
    comics
  end

  def self.get_images(item)
    GoogleAjax.referer = "http://google.com"
    GoogleAjax::Search.images(item)[:results].each { |i| puts i.values[7] }
  end

  def self.download_link(title, provider)
    str = read_in("#{@@chan_search}#{title.gsub(" ", "+")}&rss=1")
    arr = []

    str.gsub(/<link>(http:\/\/www.#{provider}.com\/?\w+)<\/link><description>Title:\s(.+)Where:/) {
      link = $1
      puts "#{link} for #{$2}" 
      # if $2 =~ /(.+)\s(\d{2,})\..+/
    }
    arr
  end
    
  def self.ensure_consistency(dir, rename)
    directory = Dir.new(dir)
    puts "Directory #{dir}"
    directory.each do |temp|
      if !(File.hidden? temp) and temp.is_comic? and temp =~ /(.*)\s(\d{2,}.*)/
        if ($1.strip <=> directory.name) != 0
          puts "#{temp} renamed to #{directory.path}/#{directory.name} #{$2}"
          File.rename("#{directory.path}/#{temp}","#{directory.path}/#{directory.name} #{$2}") if rename
        end
      end
    end
  end
      
  def self.consistency_loop(arg, rename=true) 
    dir = Dir.new(arg)
    dir.each { |file| ensure_consistency("#{arg}/#{file}", rename) if File.directory? "#{arg}/#{file}" }
  end
  
  def Comics.print
    Comics::new_comics.each do |publisher, issues|
      puts "\n#{publisher}\n"
      puts issues
    end
  end
  
  def self.scan(dir)
    $counter = 0    
    block = Proc.new do |key, issues|
      all = (issues.min..issues.max).to_a
      missing_issues = all - issues
      arr = (1..all.min-1).to_a 
      str = "#{key}: "
      str << (arr.length >= 2 ? "#{arr[0]}-#{arr[-1]}" : "#{arr[0]}") unless arr.empty?
      str << "," unless missing_issues.empty? or arr.empty?
      str << "#{missing_issues.join(",")}" unless missing_issues.empty?
      puts str unless arr.empty? and missing_issues.empty?
      $counter += 1 unless arr.empty? and missing_issues.empty?
    end
    hash = Hash.new
    Dir.glob("#{dir}/**/*") do |file|
      if file =~ /(.*)\/((.*?)(\d+))[.cbr|.cbz]/
        comic = $3.strip()
        hash[comic] ||= [] 
        hash[comic] << $4.to_i
      end
    end
    hash.each &block 
    puts "Series effected = #{$counter}"    
  end
    
  def self.download_check(dir)
	Comics::run_warez(dir)
    res = {}
    Comics::new_comics.each do |pub, values|
      books = values
      books.select! { |i| not i.reprint? }
      downloads = Dir.new(dir).entries.select { |file| file.is_comic? }
      downloads.map! do |comic| 
        comic = comic.split(".")[0...-1].join("")
        Comics::replace(comic) 
      end
      books = books.select { |comic| not downloads.include? Comics::replace(comic.display) }
      res[pub] = books
    end
	res.delete("MERCHANDISE")
	res.delete("MAGAZINES")
	res.delete("IDW PUBLISHING")
    return res
  end
  
  def self.run_warez(dir)
	warez = Warez.new
    warez.options.print = false
    warez.options.dir = dir
    warez.run(ComicRenamer.new, false)
  end
  
  def self.dowload_check_printer(dir)    
    comics = self::download_check(dir)
    comics.each do |pub, list| 
      puts "#{"-" * 15 } #{pub} #{"-" * 15 } "
      list.each { |comic| puts "-- #{comic}" }
    end 
    puts "No Downloads!" if comics.empty?
    puts "#{"-" * 30 }"
  end
  
  def self.replace(arg)
    arg.downcase!
    arg.gsub!(/(\s[Vv]\d)|[Tt]he|\_|\-|,/, "")
    arg.gsub!(/\s+/, "\s")
    arg.gsub!(/\s/, "")
    arg.gsub!(/\./, "")
    arg.strip!
    arg
  end
    
  def self.win
    Comics::search('co', 'win')
  end
  
  def self.search(board, term)
    puts "Searching"
    url = "http://boards.4chan.org/#{board}/"
    (0..10).each do |page|
      page = (page == 0 ? "" : page)
      string = Comics::read_in("#{url}#{page}")  
      # puts page  
          
      string.gsub(/\[<a href="thread\/(.*?)" class="replylink">Reply<\/a>\]<\/span><\/span><\/div><blockquote class="postMessage"/m) {
        link = $1
        if link.include? term
          puts "#{url}thread/#{link}" 
          # return "#{url}thread/#{link}"
        end
      }
    end
  end
  
end

if __FILE__ == $0
  # Comics::dowload_check_printer("/Users/dominiccarr/Downloads")
  # Comics::search('co', 'win')
    Comics::new_comics
end