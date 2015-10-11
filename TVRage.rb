require 'uri'
require 'open-uri'
require 'rss'
require 'rexml/document'
require 'yaml'
require 'date'
require_relative 'Episode.rb'
require_relative 'FileExt.rb'

USER = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17"

module TVRage
  
  $block = Proc.new do |key, issues|
    all = (issues.min..issues.max).to_a
    missing_issues = all - issues
    arr = (1..all.min-1).to_a 
    str = "#{key}: "
    str << (arr.length >= 2 ? "#{arr[0]}-#{arr[-1]}" : "#{arr[0]}") unless arr.empty?
    str << "," unless missing_issues.empty?
    str << "#{missing_issues.join(",")}" unless missing_issues.empty?
    puts str unless arr.empty? and missing_issues.empty?
  end

  def self.load_configuration
    config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.txt'))
    @api_key = config['API_KEY']
    @tv_rage_rss = config['TV_RAGE_RSS'] 
  end
    
  def self.get_info(show, title, regex)
    url = "http://services.tvrage.com/tools/quickinfo.php?show=#{show.gsub(" ", "%20")}&ep=#{title}"
    open(url, "UserAgent" => USER).each_line { |i| 
      return $1 if i =~ /#{regex}@(\d+)/ }
  end
  
  def self.show_id(show) 
    id = self::get_info(show.gsub(" ", "+"), "", "Show ID")
    return id if not id.class == StringIO
  end
  
  def self.episode_info(episode)
    show = show_id episode.show
    url = "http://services.tvrage.com/myfeeds/episodeinfo.php?key=#{@api_key}&sid=#{show}&ep=#{episode.x_format}"
    regex = ".*<episode>.*<summary>(.*)</summary>.*"
    open(url, "UserAgent" => USER).each_line { |i| return $1 if i =~ /#{regex}/ }
  end
  
  def self.episode_name(episode)
    show = episode.show
    title = episode.x_format
    url = "http://services.tvrage.com/tools/quickinfo.php?show=#{show.gsub(" ", "%20")}&ep=#{title}"
    open(url, "UserAgent" => USER).each_line { |i| return $1.to_s if i =~ /.*\^(.*)\^.*/ }
  end

  def self.get_feed(feed) 
    rss_content = ""
    arr = []
    open(feed) { |f| rss_content = f.read }
    rss = RSS::Parser.parse(rss_content, false)

    rss.items.each do |item| 
        arr << Episode.new($1, $2, $3, item.description) if item.description != nil and item.title =~ /-\s(.*)\s\((\d\d)x(\d\d)\)/
    end
    arr
  end
  
  def self.episodes(show)
     episodes = []
     url = "http://services.tvrage.com/feeds/episode_list.php?sid=#{TVRage::show_id(show.gsub(" ", "%20"))}"
     rss_content = ""
     open(url, "UserAgent" => USER) { |f| rss_content = f.read }
     doc = REXML::Document.new(rss_content)
     doc.elements.each("Show/Episodelist/Season/episode") do |e| 
        season = e.parent.attributes["no"].to_i
        children = e.children
        s = children[3].text
        begin
          d = Date.parse(s)
          e = Episode.new(show, "0#{season}", children[1].text, $1)
          episodes << e if d <= Date.today
        rescue  
          puts 'rescued.'  
        end
     end
     episodes
   end
   
  def self.show_missing(dir)
     show = dir.split("/")[-1]
     downloaded = []
     Dir.glob("#{dir}/**/*") do |file|
       downloaded << Episode.new($1, $2, $3) if file =~ /(.*)\sS(\d\d)E(\d\d).*/ 
     end
     return self::missing(show, downloaded)
   end
   
  def self.missing(show, downloaded)
    all_episodes = self::episodes show
    return all_episodes.select { |episode| not downloaded.include? episode }
  end
   
  def self.search_all(dir) 
    missing_episodes = []
    Dir.glob("#{dir}/**") do |file|
        missing_episodes << self::show_missing(file) if File.directory? file
    end
     missing_episodes
   end
  
  def self.export(path, show=true) 
  	if show 
  		missing = TVRage::show_missing path
  		file = "#{path}/#{missing[0].show}-missing.txt"
  	else 
  		missing = TVRage::search_all path
  		file = "#{path}/TV-missing.txt"
  	end
  	File.delete(file) if File.exists? file
  	return if missing.empty? 
    doc = ""
    missing.each { |e| doc << "#{e.to_s}\n" }
    File.open(file, 'w') { |f| f.write(doc) }
  end
  
  def self.file_scan(path)
    hash = Hash.new
    File.open(path).each_line do |line|
      if line =~ /(.+)\sS(\d\d)E(\d\d).(.+)/
        show = $1
        season = $2
        ep_no = $3
        episode = Episode.new(show, season, ep_no)
        hash[show] ||= []
        hash[show] << episode
      end
    end
    hash
  end
  
  def self.scan_from_txt(txt_file, dl_dir)
    shows_hash = TVRage.file_scan(txt_file)
    downloads = TVRage.read_folder(dl_dir)
    downloads.each { |ep| shows_hash[ep.show] << ep }
    shows_hash.each do |show, eps| 
      puts "#{show}"
      TVRage::missing(show, eps).each { |ep| puts "\t#{ep}" }
    end
  end
   
   def self.read_folder(path)
      eps = []
      current = Dir.new(path)
      current.each { |cur| eps << Episode.new($1, $2, $3) if cur =~ /(.*)\sS(\d\d)E(\d\d).*/ }
      eps
   end
   
   def self.scan_tv(dir)
     TVRage::get_shows(dir).each do |show, seasons| 
       seasons.each { |key, season| $block.call("#{show} Season #{key}", season.map { |i| i.episode_no.to_i }) }
     end
   end
   
   def self.scan_tv2(dir)
     TVRage::get_shows(dir).each do |show, seasons| 
       eps = MyMoviesAPI::episodes(show)
       seasons.each { |key, episodes| eps.values.flatten.sort.each { |e| puts e if not episodes.include? e } }
     end
   end
   
   def self.get_shows(dir)
     shows = Hash.new
     Dir.glob("#{dir}/**/*") do |file|
       if file =~ /(.*)\/((.*?)S(\d\d)E(\d\d))/
         show = $3.strip()
         season = $4.to_i
         ep = $5.to_i
         episode = Episode.new(show, season, ep)
         shows[show] ||= Hash.new
         shows[show][season] ||= []
         shows[show][season] << episode
       end
     end
     shows     
   end
     
end
  
TVRage::load_configuration

if __FILE__ == $0
  TVRage.scan_tv("/users/dominiccarr/Content/TV+Movies/")  
end