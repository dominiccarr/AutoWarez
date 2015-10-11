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

class String
  
  def clean!
    gsub!(".#{ext}", '')
    gsub!("AwesomeDL.com_", '')
    gsub!(/\_|\[|\]|\(|\)|\#|\+/, " ")
    strip!
  	gsub!(/\s+/, "\s")
  	gsub!("-", " ") if is_tv?
  	gsub!("&#x27;", "'")
  	gsub!("&#x26;", "&")
  	gsub!("&\s39;", "'")
  	gsub!("[\W&&[^\s-\.]]", "")
  	gsub!(/^(.)/) { |m| $1.capitalize }
    gsub!(/\s(.)/) { |m| "\s#{$1.capitalize}" }
  end
  
  def conform!
    extension = ext
    puts extension
    if is_tv?
      gsub!(/\./, " ")
      gsub!(/\s(.)/) { |m| "\s#{$1.capitalize}" }
      long_lormat!
      regex!
    elsif is_comic?
      gsub!(/(.*?\d{2,}).*/) { $1 }
      gsub!(/\s(\d{2,3})/) do |match|
        length = 3 - match.to_i.to_s.length
              " #{"0" * length}#{match.to_i}"
      end
      capitalize!
      filter!
    end
  end
  
  def long_lormat!
  	gsub!('Season ', 'S0')
  	gsub!(' Episode ', 'E')
  	gsub!('EP', 'E');
  	[ 'season', 'episode', 'SERIES', 'EPISODE' ].each { |e| gsub!(e, '') }
  	(1960..Time.new.year).each { |val| gsub!(val.to_s, '') }
  end
  
  def regex!
    puts "llS"
    gsub!(/((\d\d)(\d\d))/) { " S#{$2}E#{$3}" }
  	gsub!(/((\d\d)x(\d\d))/) { " S#{$2}E#{$3}" }
  	gsub!(/((\d)x(\d\d))/) { " S0#{$2}E#{$3}" }
  	gsub!(/(\s(\d)(\d\d))/) { " S0#{$2}E#{$3}" }
    gsub!(/(.*?)[Ss](\d\d.*)/) { "#{$1}S#{$2}" }  
    gsub!(/(.*?\s[Ee])\s(.*)/) { "#{$1}#{$2}" }   	
   	gsub!(/(.*?)([EeSs])(\d\d)/) { "#{$1}#{$2.capitalize}#{$3}" }
   	gsub!(/(.*[Ee]\d\d).*/) { $1 }
   	gsub!(/(.*[Ss]\d\d)(\d\d).*/) { "#{$1}E#{$2}" }
   	gsub!(/(.*)([Ss]\d[^\s].*)/) { "#{$1} #{$2}" }   	
   	gsub!(/(.*)[Xx]([Ee].*)/) { "#{$1}#{$2}" }
   	gsub!(/(.*\d\d)[Ee](\d\d.*)/) { "#{$1}E#{$2}" }  
   	gsub!(/\s\s+/, "\s"); 
   	gsub!(/(S\d\d)\s(E\d\d.*)/) { "#{$1}#{$2}" }    	
   	gsub!(self, $1) if (self =~ /(.*?\sS\d\dE\d\d)(.*)/)
  end
  
  def filter!
    File.open(File.join(File.dirname(__FILE__), 'filters.txt'), "r").each_line do |line|
      data = line.split(/=/)
      unwanted = data.first
      replacement = data.last.gsub("\n","")
      substitute = (replacement == "REMOVE" ? "" : replacement)
      gsub!(unwanted, substitute)
    end
  end
  
end

module ComicRenamer
  
  def self.handle(arr, dir, args)
    arr.each do |title| 
      comic = Content.new(title, dir, args.unwanted, args.replacement)
      comic.name.conform!
      self::rename comic, args
    end
  end
  
  def self.rename(content, args) 
    return if not (content.name =~ /(.*)\s(\d{2})/) or not args.rename
    name = "#{content.name.strip}.#{content.orig_name.ext.downcase}"
    dir = content.directory
    orig = content.orig_name
    if args.create and not args.move
      FileUtils.mkdir_p("#{dir}/#{$1}")
      AutoWarez::rename(content, "#{dir}/#{orig}", "#{dir}/#{$1}/#{name}") 
    elsif args.create and args.move
      FileUtils.mkdir_p("#{args.comics}/#{$1}")
      AutoWarez::rename(content, "#{dir}/#{orig}", "#{args.comics}/#{$1}/#{name}")
    elsif not args.create and args.move 
      AutoWarez::rename(content, "#{dir}/#{orig}", "#{args.comics}/#{name}")
    elsif not args.create and not args.move
      AutoWarez::rename(content, "#{dir}/#{orig}", "#{dir}/#{name}")
    end
  end
  
end

module TVRenamer
  
  def self.handle(tv_arr, dir, args)
    tv_arr.each do |title| 
      tv = Content.new(title, dir)
      tv.name.gsub!(args.unwanted, args.replacement)
      tv.name.conform!
      self::rename tv, args
    end
  end
  
  def self.rename(tv, args) 
    return unless (tv.name =~ /(.*)\sS(\d{2})E(\d{2})/) and args.rename
    directory = $1
    season = $2.to_i
    if args.episode_name 
      episode = Episode.new($1, $2, $3)
      episode.episode_name
      tv.name = "#{episode}"
    end 
    dir = tv.directory
    orig = tv.orig_name
    name = "#{tv.name}.#{tv.ext}"
    
    if args.create and not args.move
      FileUtils.mkdir_p("#{dir}/#{directory}/Season #{season}");
      AutoWarez::rename(tv, "#{dir}/#{orig}", "#{dir}/#{directory}/Season #{season}/#{name}") 
    elsif args.create and args.move
      FileUtils.mkdir_p("#{@tv}/#{directory}/Season #{season}")
      AutoWarez::rename(tv, "#{dir}/#{orig}", "#{args.tv}/#{directory}/Season #{season}/#{name}")
    elsif not args.create and args.move
      AutoWarez::rename(tv, "#{dir}/#{orig}", "#{args.tv}/#{name}")    
    elsif not args.create and not args.move
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