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
  
  def self.episodes(search_term)
    begin
      links = []
      puts "#{search_term}\n"
      # source = open("http://awesomedl.ru/?s=#{URI::encode(search_term)}&x=0&y=0", &:read)
      
      (1..6).each { |num|
        source = open("http://awesomedl.ru/page/#{num}", &:read)
      
        search_term = search_term.gsub(/'/, "&#8217;")

        source.gsub(/<h2 class="title"><a href="(.*?)" title="Permalink to #{search_term}.* rel="bookmark">.*<\/a><\/h2>/i) {
          links << self::extract_rg_links($1)
        }
      }
#      links.flatten!
#      Clipboard::to_clipboard(links.join(" , "))
    rescue OpenURI::HTTPError
      puts "HTTP Error"
    end
    
  end
  
  def self.extract_rg_links(link)
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
    links = TVMaze.get_by_air_date.each do |episode| 
      next if episode.show == nil
      title = episode.show.gsub(/\(\d+\)/, "")
      title.gsub!(/\((\w+)\)/) { $1 }
      title.gsub!(/\s{1,}/, " ")
      title.rstrip!
      search_term = "#{title} Season #{episode.season.to_i}, Episode #{episode.episode_no.to_i}"
      self.episodes(search_term)
    end
    TVMaze.delete!
  end
  
  def self.main
    opts = GetoptLong.new([ "--show", "-s", GetoptLong::REQUIRED_ARGUMENT],
    [ "--today", "-t", GetoptLong::NO_ARGUMENT])

    opts.each do |opt, arg|
      case opt
      when "--show"
        AwesomeDL::episodes(arg)
      when "--today"
        AwesomeDL::today
      end
    end
  end
  
end

if __FILE__ == $0
  AwesomeDL::main
end