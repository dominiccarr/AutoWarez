require 'open-uri'
require 'net/http'
require 'rubygems'
require 'json'
require 'getoptlong'
require 'fuzzystringmatch'
require 'cgi'
require 'htmlentities'

require_relative "Episode.rb"
require_relative "TVMaze.rb"
require_relative "Clipboard.rb"
require_relative "Comics.rb"
require_relative "ComicWarez.rb"

module ComicsDL
  include Clipboard
  
	def self.compare(a,b)
		jarow = FuzzyStringMatch::JaroWinkler.create(:pure)
		return jarow.getDistance(a,b)
	end
	
	def self.clean(string)
		title = HTMLEntities.new.decode(string)
		title.gsub!(/The|the/, "")
		title.gsub!("-", " ")
		title.conform!
		title.gsub!(/[^0-9a-z ]/i, '')
		title.strip!
		title.downcase!
		title.gsub!(/v\d+/, "")
		title.gsub!(/\s+/, " ")
		return title
	end
	
    def self.gather(searches)
	 String.send(:include, Strings)
	base_url = "http://comicsdownload.org/?x=0&y=0&s="
    begin   
      searches.each do |search_term|
	  search_url = "#{base_url}#{search_term.title.gsub(/\s/, "+")}"
		source = open(search_url, &:read)
		name = self::clean(search_term.display)
		puts "#{name}"
		2.times {
			source.sub!(/<a href="(.+)">.+?<div class="in_title">(.+)<\/div>/i) {
				link = $1
				title = self::clean($2)

				match = self::compare(title, name)
				puts "\t #{title} = #{match}"
				if (match == 1) 
					links = self::extract_rg_links(link)
					break
				end
			}
		}
	  end
    rescue OpenURI::HTTPError
      puts "HTTP Error"
    end
    
  end
  
  def self.extract_rg_links(link)
    re = /"(http:\/\/rapidgator.net\/file\/\w+\/.+?)"/m
    extract_links(link, re)
  end
  
  def self.extract_links(link, re)
    links = []
    source = open(link, &:read)
    source.gsub(re) {
      puts "#{$1}"
      links << $1
    }
    links
  end
  
  def self.main
	links = Comics.download_check("C:/Users/dominiccarr/Downloads")
    self.gather(links["MARVEL COMICS"])
	self.gather(links["DC COMICS"])
  end
  
end

if __FILE__ == $0
  ComicsDL::main
end