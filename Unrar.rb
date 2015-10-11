module Unrar
  
  def self.handle(archives, args)
    archives.each { |x| Unrar::unrar_multiple(x,args.dir) if args.unrar and x.include? 'part1' }
    archives.each { |x| Unrar::unrar_single(x, args.dir) if args.unrar and not x.include? 'part' }
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
  	res = `unrar x #{directory.gsub(/\s/, '\ ')}/#{name.gsub(/\s/, '\ ')} #{directory.gsub(/\s/, '\ ')}`
  	File.delete("#{directory}/#{name}") if res.include? "All OK"
  	return res.include? "All OK"
  end
  
end