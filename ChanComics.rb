require 'open-uri'
require 'net/http'
require 'rubygems'
require 'base64'
require 'json'
require 'mechanize'
require 'execjs'
require 'uri'
require_relative "Comic.rb"
require_relative "Comics.rb"
require_relative "Clipboard.rb"

module ChanComics
  
  def self.comics(comics)
    begin
      source = open(Comics::win, &:read)
      source.gsub!('<wbr>', "")
      links_arr = []
      comics.each do |comic|
        regexes = [/(http(s)*:\/\/www\d\d.zippyshare.com\/v\/\w+\/file.html)/, /(https:\/\/userscloud.com\/\w+)/]
        links = extract(source, comic.display, regexes)
        no_links = links.empty?
        if no_links
          puts "No Links for: #{comic.display}" 
        else 
          puts "Links found for: #{comic.display}" 
          links_arr << links[0]
        end
      end
      Clipboard::to_clipboard(links_arr.join(" , "))
    rescue OpenURI::HTTPError

    end
    
  end
  
  def self.extract(data, search_term, regexes)
    links = []
    data.gsub(/(#{search_term}.+?<br><br>)/) {
      raw = $1
      raw.gsub(/(.+?<br>(.+?)<br>.+?)/){
        link = $2.gsub(/<.+?>/,"")    
        if link =~ URI::regexp 
          regexes.each do |regex|
            links << $1 if link =~ regex 
          end
        end
      }
    }
    return links
  end
  
  def self.download_comics(local_dir)
    remaining = Comics::download_check(local_dir)
    self.comics(remaining)
  end

end

if __FILE__ == $0
  ChanComics::download_comics("/Users/dominiccarr/Downloads/")
end
