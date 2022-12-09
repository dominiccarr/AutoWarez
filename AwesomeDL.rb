require 'open-uri'
require 'net/http'
require 'rubygems'
require 'json'
require 'getoptlong'
require_relative "Episode.rb"
require_relative "TVMaze.rb"
require_relative "Clipboard.rb"

module AwesomeDL
  include Clipboard
  
  def self.episodes(searches)
    begin   
      # gather the 6 most recent pages
      source = []   
      (1..6).each do |num|
        source << open("https://www.scnsrc.me/category/tv/page/#{num}", &:read)
      end
      # puts source[0]
      # search for each show
      searches.each do |search_term|
        search_term = search_term.gsub(/'/, "&#8217;")
        
        source.each do |page|
          page.gsub(/<h2><a href="(.*?)" rel="bookmark" title="Go to #{search_term}.*>/i) {
            links = self::extract_rg_links($1)
          }
        end
      end
    rescue OpenURI::HTTPError => e
      puts e
    end
    
  end
  
  def self.extract_rg_links(link)
    puts(link)
    re = /"(http:\/\/rapidgator.net\/file\/\w+\/.+?)">RapidGator<\/a>/m
    extract_links(link, re)
  end
  
  def self.extract_links(link, re)
    # puts "LINK: #{link}"
    links = []
    source = open(link, &:read)
    source.gsub(re) {
      puts "LINK: #{$1}"
      links << $1
      `open -a "Firefox" #{$1}`
    }
    links
  end
  
  def self.today()
    searches = []
    res = TVMaze.get_by_air_date
    puts res
    
    res.each do |episode| 
      next if episode.show == nil
      title = episode.show.gsub(/\(\d+\)/, "")
      title.gsub!(/\((\w+)\)/) { $1 }
      title.gsub!(/\s{1,}/, " ")
      title.rstrip!
      searches << search_term = "#{title} Season #{episode.season.to_i}, Episode #{episode.episode_no.to_i}"
    end
    self.episodes(searches)
    TVMaze.delete!
  end
  
  def self.main
    AwesomeDL::episodes(["So Help Me Todd"])
  #   opts = GetoptLong.new([ "--show", "-s", GetoptLong::REQUIRED_ARGUMENT],
  #   [ "--today", "-t", GetoptLong::NO_ARGUMENT])
  #
  #   opts.each do |opt, arg|
  #     case opt
  #     when "--show"
  #       AwesomeDL::episodes(arg)
  #     when "--today"
  #       AwesomeDL::today
  #     end
  #   end
  end
end

if __FILE__ == $0
  AwesomeDL::main
end