require_relative 'Strings.rb'
require_relative 'Options.rb'
require 'rubygems'
require "ftools"
require 'getoptlong'
require 'fileutils'
require 'yaml'

module Root
  
  def to_root(current, root) 
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
  
end

class GetoptLong
  attr_accessor :canonical_names
end

class Warez
  include Root
  attr_accessor :options
  
  def initialize
    config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.txt'))
    @options = Options.new
    @options.regex = config['TV_REGEX']
  end

    def rename(content, orig_dir, dest_dir, type=:not_move)
      content.to_s == content.original_name ? (printer "#{content} was correct") : (printer "#{content.original_name} was renamed to #{content}")
      File.rename(orig_dir, dest_dir)
    end

    def printer(arg)
    	puts arg if @options.print
    end

    def run(namer, args=true)
      parse_args if args
      to_root @options.dir, @options.dir if @options.root
      renamer @options.dir, namer unless @options.list
    end
    
    def renamer(dir, class_name)
      if not dir
        puts "Please enter a directory. Usage 'ruby AutoWarez.rb --dir [path]'"
        return
      end
      printer "Operating On: #{dir}"
      directory = Dir.new(dir).entries
      silly_file = "#{dir}/Thanks_You_For_Download.txt"
      FileUtils.rm silly_file if File.exists? silly_file
      class_name.handle self
      dirs = directory.select { |c| File.directory?("#{dir}/#{c}") }
      dirs.each { |x| renamer("#{dir}/#{x}", class_name) if @options.recursive }
    end
    
    def parse_args
      opts = GetoptLong.new(  
      [ "--dir", "-d", GetoptLong::REQUIRED_ARGUMENT ],  
      [ "--unwanted", "-u", GetoptLong::REQUIRED_ARGUMENT ],  
      [ "--replacement", "-r", GetoptLong::REQUIRED_ARGUMENT ],  
      [ "--tv", "-a", GetoptLong::REQUIRED_ARGUMENT ],
      [ "--recursive", "-w", GetoptLong::NO_ARGUMENT ],  
      [ "--create", "-c", GetoptLong::NO_ARGUMENT ], 
      [ "--verbose", "-v", GetoptLong::NO_ARGUMENT ], 
      [ "--unrar", "-e", GetoptLong::NO_ARGUMENT ], 
      [ "--episodename", "-b", GetoptLong::NO_ARGUMENT ],
      [ "--regex", "-f", GetoptLong::REQUIRED_ARGUMENT ],
      [ "--comic", "-t", GetoptLong::REQUIRED_ARGUMENT ],
      [ "--move", "-m", GetoptLong::NO_ARGUMENT ],
      [ "--root", "-p", GetoptLong::NO_ARGUMENT ],
      [ "--list", "-l", GetoptLong::NO_ARGUMENT ],
      [ "--monitor", "-g", GetoptLong::NO_ARGUMENT ]
      ) 
      
      opts.each do |opt, arg|
        case opt
        when "--list"
          puts opts.canonical_names.values.uniq
          exit # end the program
        when "--dir"
          @options.dir = arg
        when "--unwanted"
          @options.unwanted = arg
        when "--replacement"
          @options.replacement = arg
        when "--recursive"
          @options.recursive = true
        when "--move"
          @options.move = true  
        when "--create"
          @options.create = true
        when "--rename"
          @options.rename = true
        when "--comic"
          @options.comics = arg
        when "--verbose"
          @options.print = true
        when "--unrar"
          @options.unrar = true
        when "--episodename"
          @options.episode_name = true
        when "--regex"
          @options.regex = arg
        when "--tv"
          @options.tv = arg
        when "--root"
          @options.root = true
        when "--monitor"
          @options.monitor = true
        end
      end
    end

end