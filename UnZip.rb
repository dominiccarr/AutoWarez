module UnZip
  
  def self.handle(archives, dir)
    archives.each { |archive| Unrar::unrar_single(archive, dir) }
  end

  def self.unzip_single(name, directory) 
  	puts "Unzipping #{name}"
  	directory.gsub!(/\s/, '\ ')
  	name.gsub!(/\s/, '\ ')
  	res = `unzip #{directory}/#{name} -d #{directory}#{name.gsub("."+name.ext, "")}`
  	File.delete("#{directory}/#{name}")
  	return true
  end
  
end