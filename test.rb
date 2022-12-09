require "down"
require "fileutils"
require_relative "AutoWarez.rb"

class Link < SimpleDelegator
  
  def initialize(string)
    super
  end
  
  def add_link(l)
    @link = l.clone
  end
  
  def link
    @link
  end
end

module StringExtensions
  
  attr_accessor :original_name

  def is_tv?
  	is_video?
  end
  
  def is_video?
  	is?([ "mov", "avi", "rmvb", "wmv", "mkv", "mp4", "mpeg", "divx", "rm", "flv", "mpg", "m4v", "3gp" ])
  end
  
  def is?(arr)
  	arr.each { |s| return true if ext.downcase =~ /#{s}$/ } 
  	false
  end
  
  def ext
    split(".")[-1].downcase
  end
  
  def standard_def
    @original_name.include?("480p")
  end
  
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
  
  def transform!
    @original_name = self.clone
    extension = ext.downcase
	gsub!('TwoDDL_', '')
    clean!
    gsub!(/\w+/) { |w| w.capitalize }
    conform!
    self << ".#{extension}"
  end
  
end

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

map = {}
String.send(:include, StringExtensions)
String.send(:include, Strings)
  
tempfile = Down.download("https://www.ettv.to/dumps/ettv_daily.txt.gz")
FileUtils.mv(tempfile.path, "/Users/user/Downloads/#{tempfile.original_filename}")
`gzip -d /Users/user/Downloads/ettv_daily.txt`

file = File.open("/Users/user/Downloads/ettv_daily.txt")
file_data = file.readlines

file_data.each do |line|
  arr = line.split("|")
  orig = arr[1]
  name = orig.clone.transform!
  
  if name =~ /(.*)\s[Ss](\d{2})[Ee](\d{2})/ and (arr[2] == "TV")

    arr2 = map[$1]
    if arr2 == nil
      arr2 = []
      map[$1] = arr2
    end
    l = Link.new(name)
    l.add_link(arr[-1])
    arr2 << l
    
    # puts name
    # puts $1
    # puts name.original_name
  end
  
end

def selector(name, map)
  if map[name]== nil
    return Link.new("")
  end
  arr = map[name].select { |i| i.standard_def }
  if (!arr.empty?)
    return arr[0]
  else
    return map[name][rand * map[name].length]
  end
end

def dl(name, map)
  url = selector(name, map).link
  return if url == nil
  puts "#{url}" if not url == nil
  tempfile = Down.download(url)
  FileUtils.mv(tempfile.path, "/Users/user/Downloads/#{tempfile.original_filename}")
  `open /Users/user/Downloads/#{tempfile.original_filename}`
end

file = File.open("shows.txt")
shows = file.readlines.map(&:chomp)

shows.each { |show| dl(show, map) }