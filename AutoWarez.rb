require_relative 'TVRage.rb'
require_relative 'Strings.rb'
require_relative 'FileExt.rb'
require_relative 'Content.rb'
require_relative 'Unrar.rb'
require_relative 'UnZip.rb'
require_relative 'Options.rb'
require 'rubygems'
require 'fssm'
require "ftools"
require 'getoptlong'
require 'fileutils'
require 'yaml'

class File
   def self.hidden?(arg)
      return true if arg =~ /^\..*/
      false
   end
end

class Dir
  def name
    name = path.split("/")[-1]
  end
end

module ComicRenamer
  
  def self.handle(comic_arr, dir, args)
    @opts = args
    comic_arr.each do |title| 
      content = Content.new(title, dir, @opts.unwanted, @opts.replacement)
      comic = content.name
      comic.gsub!(/(.*?\d{2,}).*/) { $1 }
      comic.gsub!(/\s(\d{2,3})/) do |match|
        length = 3 - match.to_i.to_s.length
              " #{"0" * length}#{match.to_i}"
      end
      content.name = comic
      AutoWarez::filter(comic)
      self::rename content
    end
  end
  
  def self.rename(content) 
    return if not (content.name =~ /(.*)\s(\d{2})/) or not @opts.rename
    name = "#{content.name.strip}.#{content.orig_name.ext.downcase}"
    dir = content.directory
    orig = content.orig_name
    if @opts.create and not @opts.move
      FileUtils.mkdir_p("#{dir}/#{$1}")
      AutoWarez::rename(content, "#{dir}/#{orig}", "#{dir}/#{$1}/#{name}") 
    elsif @opts.create and @opts.move
      FileUtils.mkdir_p("#{@opts.comics}/#{$1}")
      AutoWarez::rename(content, "#{dir}/#{orig}", "#{@opts.comics}/#{$1}/#{name}")
    elsif not @opts.create and @opts.move 
      AutoWarez::rename(content, "#{dir}/#{orig}", "#{@opts.comics}/#{name}")
    elsif not @opts.create and not @opts.move
      AutoWarez::rename(content, "#{dir}/#{orig}", "#{dir}/#{name}")
    end
  end
  
end

module TVRenamer
  
  def self.handle(tv_arr, dir, args)
    @opts = args
    tv_arr.each do |a| 
      tv = Content.new(a, dir)
      a.gsub!(@opts.unwanted, @opts.replacement)
      tv.name.gsub!(/\./, " ")
      tv.name.gsub!(/\s(.)/) { |m| "\s#{$1.capitalize}" }
      self::long_lormat tv.name
      self::regexes tv.name
      # AutoWarez::conformToRegex tv
      self::rename tv
    end
  end
  
  def self.long_lormat(episode)
  	episode.gsub!('Season ', 'S0')
  	episode.gsub!(' Episode ', 'E')
  	episode.gsub!('EP', 'E');
  	[ 'season', 'episode', 'SERIES', 'EPISODE' ].each { |e| episode.gsub!(e, '') }
  	(1960..Time.new.year).each { |val| episode.gsub!(val.to_s, '') }
  end
  
  def self.regexes(episode)
    episode.gsub!(/((\d\d)(\d\d))/) { " S#{$2}E#{$3}" }
  	episode.gsub!(/((\d\d)x(\d\d))/) { " S#{$2}E#{$3}" }
  	episode.gsub!(/((\d)x(\d\d))/) { " S0#{$2}E#{$3}" }
  	episode.gsub!(/(\s(\d)(\d\d))/) { " S0#{$2}E#{$3}" }
    episode.gsub!(/(.*?)[Ss](\d\d.*)/) { "#{$1}S#{$2}" }  
    episode.gsub!(/(.*?\s[Ee])\s(.*)/) { "#{$1}#{$2}" }   	
   	episode.gsub!(/(.*?)([EeSs])(\d\d)/) { "#{$1}#{$2.capitalize}#{$3}" }
   	episode.gsub!(/(.*[Ee]\d\d).*/) { $1 }
   	episode.gsub!(/(.*[Ss]\d\d)(\d\d).*/) { "#{$1}E#{$2}" }
   	episode.gsub!(/(.*)([Ss]\d[^\s].*)/) { "#{$1} #{$2}" }   	
   	episode.gsub!(/(.*)[Xx]([Ee].*)/) { "#{$1}#{$2}" }
   	episode.gsub!(/(.*\d\d)[Ee](\d\d.*)/) { "#{$1}E#{$2}" }  
   	episode.gsub!(/\s\s+/, "\s"); 
   	episode.gsub!(/(S\d\d)\s(E\d\d.*)/) { "#{$1}#{$2}" }    	
   	episode.gsub!(episode, $1) if (episode =~ /(.*?\sS\d\dE\d\d)(.*)/)
  end
  
  def self.conform_to_regex(file)
  	episode = Episode.new(file)
  	season = "0#{season.to_i}" if season.to_i < 10
  	temp = @opts.regex
  	temp.gsub!("\(season\)", episode.season)
  	temp.gsub!("\(episode\)", episode.episodeNo)
  	temp.gsub!("show", episode.show)
  	file = temp
  end
  
  def self.rename(tv) 
    return unless (tv.name =~ /(.*)\sS(\d{2})E(\d{2})/) and @opts.rename
    directory = $1
    season = $2.to_i
    if @opts.episode_name 
      episode = Episode.new($1, $2, $3)
      episode.episode_name
      tv.name = "#{episode}"
    end 
    dir = tv.directory
    orig = tv.orig_name
    name = "#{tv.name}.#{tv.ext}"
    
    if @opts.create and not @opts.move
      FileUtils.mkdir_p("#{dir}/#{directory}/Season #{season}");
      AutoWarez::rename(tv, "#{dir}/#{orig}", "#{dir}/#{directory}/Season #{season}/#{name}") 
    elsif @opts.create and @opts.move
      FileUtils.mkdir_p("#{@tv}/#{directory}/Season #{season}")
      AutoWarez::rename(tv, "#{dir}/#{orig}", "#{@opts.tv}/#{directory}/Season #{season}/#{name}")
    elsif not @opts.create and @opts.move
      AutoWarez::rename(tv, "#{dir}/#{orig}", "#{@opts.tv}/#{name}")    
    elsif not @opts.create and not @opts.move
      AutoWarez::rename(tv, "#{dir}/#{orig}", "#{dir}/#{name}")
    end
  end
  
end

module AutoWarez

  def self.options
    @opts
  end
      
  def self.load_configuration
    config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.txt'))
    @opts = Options.new
    @opts.regex = config['TV_REGEX']
  end
  
  def self.rename(content, orig_dir, dest_dir, type=:not_move)
    content.to_s == content.orig_name ? (printer "#{content.orig_name} was correct") : (printer "#{content.orig_name} was renamed to #{content}")
    File.rename(orig_dir, dest_dir)
  end

  def self.printer(arg)
  	puts arg if @opts.print
  end
 
  def self.to_root(current, root) 
  	Dir.new(current).entries.each do |file|
  	  path = "#{current}/#{file}"
  		if File.directory? path and not File.hidden? file
  			to_root path, root
  			FileUtils.rm_rf path
  			printer "Deleted Folder #{path}"
  		elsif File.file? path 
  		  File.rename(path, "#{root}/#{file}")
  			printer "Moved #{path} to #{root}"
  		end
  	end
  end
  
  def self.filter(file)
    File.open(File.join(File.dirname(__FILE__), 'filters.txt'), "r").each_line do |line|
      data = line.split(/=/)
      unwanted = data.first
      replacement = data.last.gsub("\n","")
      if (replacement == "REMOVE")
        file.gsub!(unwanted, "")
      else
        file.gsub!(unwanted, replacement)
      end
    end
  end

  def self.renamer(dir)
    if not dir
      puts "Please enter a directory. Usage 'ruby AutoWarez.rb --dir [path]'"
      return
    end
    AutoWarez::printer "Operating On: #{dir}"
    directory = Dir.new(dir).entries
    directory.select! { |file| not File.hidden? file }
    silly_file = "#{dir}/Thanks_You_For_Download.txt"
    FileUtils.rm silly_file if File.exists? silly_file
    archives = directory.select { |c| c.is_rar? }
    Unrar.handle(archives, @opts)
    tv = directory.select { |c| c.is_tv? }
    comics = directory.select { |c| c.is_comic? }
    ComicRenamer::handle comics, dir, @opts
    TVRenamer::handle tv, dir, @opts
    dirs = directory.select { |c| File.directory?("#{dir}/#{c}") }
    dirs.each { |x| self::renamer("#{dir}/#{x}") if @opts.recursive }
  end

  def self.parse_args
    opts = GetoptLong.new(  
    [ "--dir", "-d", GetoptLong::REQUIRED_ARGUMENT ],  
    [ "--unwanted", "-u", GetoptLong::REQUIRED_ARGUMENT ],  
    [ "--replacement", "-r", GetoptLong::REQUIRED_ARGUMENT ],  
    [ "--tv", "-a", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--comic", "-z", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--recursive", "-w", GetoptLong::NO_ARGUMENT ],  
    [ "--create", "-c", GetoptLong::NO_ARGUMENT ], 
    [ "--verbose", "-v", GetoptLong::NO_ARGUMENT ], 
    [ "--unrar", "-e", GetoptLong::NO_ARGUMENT ], 
    [ "--episodename", "-b", GetoptLong::NO_ARGUMENT ],
    [ "--regex", "-f", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--move", "-m", GetoptLong::NO_ARGUMENT ],
    [ "--root", "-p", GetoptLong::NO_ARGUMENT ],
    [ "--list", "-l", GetoptLong::NO_ARGUMENT ],
    [ "--monitor", "-g", GetoptLong::NO_ARGUMENT ]
    )
    opts.each do |opt, arg|
      case opt
      when "--list"
        @list = true
        puts "-r - replacement"
        puts "-u - unwanted"
        puts "-d - directory"
        puts "-c - create folders"
        puts "-e - unrar"
        puts "-m - move to predefined folders"
        puts "-p - move to root"
        puts "-l - list"
        puts "-b - appends names to TV episodes"
      when "--dir"
        @opts.dir = arg
      when "--unwanted"
        @opts.unwanted = arg
      when "--replacement"
        @opts.replacement = arg
      when "--recursive"
        @opts.recursive = true
      when "--move"
        @opts.move = true  
      when "--create"
        @opts.create = true
      when "--rename"
        @opts.rename = true
      when "--verbose"
        @opts.print = true
      when "--unrar"
        @opts.unrar = true
      when "--episodename"
        @opts.episode_name = true
      when "--regex"
        @opts.regex = arg
      when "--comic"
        @opts.comics = arg
      when "--tv"
        @opts.tv = arg
      when "--root"
        @opts.root = true
      when "--monitor"
        @opts.monitor = true
      end
    end
  end  
  
  def self.run
    self::parse_args
    self::to_root @opts.dir, @opts.dir if @opts.root
    if @opts.monitor
      FSSM.monitor(@opts.dir, '**/*', :directories => true) do
       update do |b, r, t|
       puts "Someone changes #{r} into #{b} which is a #{t == :directory ? 'directory' : 'file'}"
       end

       create do |b, r, t|
         AutoWarez::renamer b
         puts "Someone create #{r} into #{b} which is a #{t == :directory ? 'directory' : 'file'}"
       end

       delete do |b, r, t|
       puts "Someone delete #{r} into #{b} which is a #{t == :directory ? 'directory' : 'file'}"
       end
      end
    else
      AutoWarez::renamer @opts.dir if !@opts.list
    end
  end

  def self.prepend(dir, text)
    Dir.new(dir).each do |file| 
      puts "#{dir}/#{file}, #{dir}/#{text} #{file}" if file.is_comic?
      File.rename("#{dir}/#{file}", "#{dir}/#{text} #{file}") if file.is_comic?
    end
  end
    
end

AutoWarez::load_configuration
if __FILE__ == $0 
  AutoWarez.run
end