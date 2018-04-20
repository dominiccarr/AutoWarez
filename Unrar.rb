require_relative "Strings.rb"

module Unrar
  
  def self.handle(dir)
    directory_arr = Dir.new(dir).entries
    archives = directory_arr.select { |file| file.is_rar? }
    archives.each { |x| Unrar::unrar_multiple(x, dir) if x.include? 'part1' }
    archives.each { |x| Unrar::unrar_single(x, dir) if not x.include? 'part' }
  end
  
  def self.unrar_multiple(name, directory) 
  	if Unrar.unrar_single name, directory
  	  all = Dir.new(directory).entries
  	  parts = all.select { |file| file.include? name.slice(0, name.length - 7) and file =~ /.rar$/ }
    	parts.each { |file| File.delete("#{directory}#{file}") }
  	end
  end
  
  def self.unrar_single(name, directory) 
  	puts "Unraring #{name}"
    # directory.gsub!(/\s/, '\ ')
    # name.gsub!(/\s/, '\ ')
    Dir.chdir directory
  	res = `unrar -o+ x #{name}`
  	File.delete("#{directory}/#{name}") if res.include? "All OK"
  	return res.include? "All OK"
  end
    
end

if __FILE__ == $0 
 	Unrar.handle(ARGV[0])
end
