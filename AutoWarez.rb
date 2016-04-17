require_relative 'Renamer.rb'
require_relative 'Warez.rb'

module Strings
    
  def conform!
    gsub!(/\./, " ")
    gsub!(/\s(.)/) { |m| "\s#{$1.capitalize}" }
    long_lormat!
    # hack to deal with The 100
    if self =~ /(The 100 )[Ss](\d\d)[eE](\d\d).*/
      name = "#{$1}S#{$2}E#{$3}"
      gsub!(self, name)
      return
    end
    regex!
  end
  
  def long_lormat!
  	gsub!('Season ', 'S0')
  	gsub!(' Episode ', 'E')
  	gsub!('EP', 'E');
  	[ 'season', 'episode', 'SERIES', 'EPISODE' ].each { |e| gsub!(e, '') }
  	(1960..Time.new.year).each { |val| gsub!(val.to_s, '') }
  end
  
  def regex!
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
  
end

class TVRenamer < Renamer
  
  def initialize
    super
    String.send(:include, Strings)
  end
  
  def matches?(title)
    title.is_tv?
  end
  
  def rename(name) 
    super name
    
    # handle non-tv videos
    if name.is_video? and not (name =~ /(.*)\sS(\d{2})E(\d{2})/) and args.move
      orig = name.original_name
      @warez.rename(name, "#{dir}/#{orig}", "#{args.tv}/#{name}") 
    end
    
    return unless (name =~ /(.*)\sS(\d{2})E(\d{2})/) and args.rename
    
    directory = $1
    season = $2.to_i
    if args.episode_name 
      episode = Episode.new($1, $2, $3)
      episode.episode_name
      name = "#{episode}"
    end 
    orig = name.original_name
    
    if args.create and not args.move
      FileUtils.mkdir_p("#{dir}/#{directory}/Season #{season}");
     @warez.rename(name, "#{dir}/#{orig}", "#{dir}/#{directory}/Season #{season}/#{name}") 
    elsif args.create and args.move
      FileUtils.mkdir_p("#{args.tv}/#{directory}/Season #{season}")
      @warez.rename(name, "#{dir}/#{orig}", "#{args.tv}/#{directory}/Season #{season}/#{name}")
    elsif not args.create and args.move
      @warez.rename(name, "#{dir}/#{orig}", "#{args.tv}/#{name}")    
    elsif not args.create and not args.move
      @warez.rename(name, "#{dir}/#{orig}", "#{dir}/#{name}")
    end
  end
  
end

warez = Warez.new
if __FILE__ == $0 
  warez.run(TVRenamer.new)
end