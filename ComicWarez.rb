require_relative 'Renamer.rb'
require_relative 'Warez.rb'

module Strings
    
  def conform!
  gsub!('#', '0')
    gsub!(/(.*?\d{2,}(\.\d){0,1}).*/) { $1 }
    gsub!(/\s(\d{2,3})/) do |match|
      length = 3 - match.to_i.to_s.length
      " #{"0" * length}#{match.to_i}"
    end
    filter!
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

class ComicRenamer < Renamer
    
  def initialize
    super
    String.send(:include, Strings)
  end
  
  def matches?(title)
    title.is_comic?
  end
  
  def rename(name) 
    super name
    
    if not args.create and args.move 
      @warez.rename(name, "#{dir}/#{orig}", "#{args.comics}/#{name}")
    elsif not args.create and not args.move
      @warez.rename(name, "#{dir}/#{orig}", "#{dir}/#{name}")
    end
  end
  
end

if __FILE__ == $0 
  warez = Warez.new
  warez.run(ComicRenamer.new)
end