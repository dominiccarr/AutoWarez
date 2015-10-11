require_relative 'AutoWarez.rb'

def self.create_collection(dir)
    collections = "#{dir}/collections/"
    FileUtils.mkdir_p(collections)
    Dir.chdir(dir) 
    
    directory = Dir.new(dir).entries.select { |i| (i.is_cbr? or i.is_cbz?) and !File.hidden? i }
    thing =  Dir.new(dir).name
    directory.each { |i| FileUtils.copy("#{dir}/#{i}", collections) }
        
    directory = Dir.new("#{collections}").entries.select { |i| !File.hidden? i }
    files = Dir.new("#{collections}").entries
    counter = 1
    directory.each do |file| 
       name = file.split('.')[-2]
       if file.is_cbr?
         File.rename("#{collections}#{file}", "#{collections}#{name}.rar") 
         Unrar::unrar_single("#{name}.rar", "#{collections}")
       elsif file.is_cbz?
         File.rename("#{collections}/#{file}", "#{collections}/#{name}.zip") 
         unzip = "#{collections}/#{name}.zip".gsub(/\s/, '\ ')
         `unzip #{unzip} -d #{collections.gsub(/\s/, '\ ')}`
         File.delete("#{collections}/#{name}.zip")
       end
       if file.is_cbr? or file.is_cbz?
         AutoWarez::to_root(collections, collections)
         newfiles = Dir.new(collections).entries.select { |i| not files.include? i }
         newfiles.each do |l|
           File.rename("#{collections}#{l}", "#{collections}#{counter} #{l}")
         end  
         counter += 1
      end
      files = Dir.new(collections).entries
     end     
end

def self.finalize(name, dir)
  Dir.chdir(dir) 
  archive = "#{name}.zip"
  ret = `zip -r #{archive.gsub(/\s/, '\ ')} #{"#{dir}/collections/".gsub(/\s/, '\ ')} `
  File.rename("#{dir}/#{archive}", "#{dir}/#{name}.cbz")
  # FileUtils.rm_rf("#{dir}/collections")
end

def self.create_collections(path)
  entries = Dir.new(path).entries.select{ |l| !File.hidden? l}
  entries.each do |i| 
     AutoWarez::renamer "#{path}#{i}"
     self::create_collection("#{path}#{i}") 
  end
end

  def self.create_cbzs(path)
    entries = Dir.new(path).entries.select{ |l| !File.hidden? l}
    Dir.chdir(path) 
    entries.each do |name| 
      archive = "#{name}.zip"
      ret = `zip -r #{archive.gsub(/\s/, '\ ')} #{name.gsub(/\s/, '\ ')}`
      puts ret
      File.rename("#{path}/#{archive}", "#{path}/#{name}.cbz")
    end
  end
  
  create_cbzs("/Users/dominiccarr/Desktop/Imported Comics")