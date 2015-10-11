require 'mechanize'
require 'uri'
require_relative 'TVRage.rb'
require_relative "Comic.rb"
require_relative "Comics.rb"
require_relative "Clipboard.rb"
require 'cgi'

class Topic
  
  attr_accessor :title, :link
  
  def initialize(title, link)
    @title = title
    @link = link
  end
  
  def to_s
    "#{@title} #{@link}"
  end
  
end

class Forum
  attr_accessor :user, :pass, :agent, :url
  
  @@WAREZSEARCH = "search.php?" 
  @@COMICTHREAD = "viewtopic.php?t=461523" 
  @@LOGIN = "login.php" 
  @@MEDIAFIRE = /(http:\/\/www.mediafire.com\/\?\w{2,})/
  @@PUTLOCKER = /(http(s?)(&#58;|:)\/\/www.putlocker.com\/file\/(\d|\w)*)/
  @@UPLOADED = /(http(s?)(&#58;|:)\/\/uploaded.net\/file\/(\d|\w)*)/
  @@WAREZSEARCH = "/search.php?" 
  @@SEARCHFORUM = "&search_forum=" 
  @@SEARCHKEYWORDS = "&search_keywords=" 
  @@SEARCH_AUTHOR = "&search_author=" 
  @@TITLEONLYSEARCH = "&search_fields=titleonly" 

  def self.comic_search(url,terms) 
  	"#{url}#{WAREZSEARCH}#{SEARCHKEYWORDS}#{terms.gsub!(/\s/, "%20")}#{RESULTFORM}&return_chars=1000&topic_id=461523" 
  end
  
  def initialize(user, pass, url="http://www.warez-bb.org")
    @user = user
    @pass = pass
    @url = url
    @agent = Mechanize.new
  end
  
  def login
    page = @agent.get "#{@url}/#{@@LOGIN}"
    @agent.user_agent_alias = 'Mac Mozilla'
    form = page.forms.first
    form['username'] = @user
    form['password'] = @pass
    page = @agent.submit form, page.forms.first.buttons.first
  end
  
  def self.search(url, terms, forum) 
  	"#{url}#{@@WAREZSEARCH}#{@@SEARCHKEYWORDS}#{terms.gsub(/\s/, "%20")}#{@@SEARCHFORUM}#{forum}#{@@TITLEONLYSEARCH}&search_author=HRA%20v3"
  end
  
  def get_topics(arg, type)
    address = Forum::search(@url, arg, 57)
    search = @agent.get(address)
    topics = []
    arr = search.links.select { |link| link.href != nil and link.href.include? "viewtopic" }
    arr.each { |link| topics << Topic.new(link.text, link.href) }
    topics
  end
  
  def get_links(url)
    page = @agent.get(url)
    links = URI.extract(CGI.unescapeHTML(page.body), "http")
    links.select! { |i| not i.include? "warez" }
    regexs = [ "ul.to" ]
    dls = []
    regexs.each { |regex| dls << links.select { |i| i.include? regex } }
    dls
  end

  def self.download
    forum = Forum.new("donsma", "we2are4")
    forum.login
    all_links = []
    TVRage::today.each do |show| 
      puts show
      topics = forum.get_topics(show.search_term, :TV)
      topics.select! { |topic| topic.title.include? show.show }
      topics[0..2].each do |topic| 
        sleep 5
        links = forum::get_links(topic.link)
        all_links << links
        puts links
        break if links.length > 0
      end
      puts "Sleep"
      sleep 35
    end
    all_links.flatten!
    Clipboard::to_clipboard(all_links.join(", "))
  end
  
  def get_comics(comics)
    topic = @agent.get "#{@url}/#{@@COMICTHREAD}"
    @@LAST_PAGE = /href="viewtopic.php\?t=461523&start=(\d{1,})">\d{1,}<\/a>&nbsp;/
    
    last_page = nil
    topic.body.gsub(@@LAST_PAGE) {
      last_page = $1.to_i
    }    
    return if not last_page
    downloads = []
    10.times {
      topic = @agent.get "#{@url}/#{@@COMICTHREAD}&start=#{last_page.to_s}"
      body = topic.body
      comics.each { |comic| downloads << get_link(body, comic) }
      last_page = last_page - 15;
    }
    
    downloads.flatten!.select! { |i| not i.empty? }
    Clipboard::to_clipboard(downloads.join(", "))
  end

def get_link(body, comic)
  links = []
  body.gsub(/#{comic.display}.*?<div class="post-block code-block"><div class="label"><strong>Code: <span class="select-all">Select all<\/span><\/strong><\/div><div class="code"><span class="inner-content">(.+?)<\/span><\/div><\/div>/mi) {
    links = URI.extract(CGI.unescapeHTML($1))
    regexs = [ "mega.co", "uploaded", "mediafire"]
    regexs.each { |regex| links << links.select { |i| i.include? regex } }
  }
  return links
end
  
  def self.search_comics
    forum = Forum.new("donsma", "we2are4")
    forum.login
    forum.get_comics(Comics::download_check("/Users/dominiccarr/Downloads/"))
  end
  
  def download_file(name, url, dir, agent=Mechanize.new)
    File.open("#{dir}/#{name}", 'w+') { |file| file << agent.get_file(url) }
  end
  
end

Forum.search_comics