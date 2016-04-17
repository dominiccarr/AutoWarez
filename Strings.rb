module StringExtensions
  
  attr_accessor :original_name
  
  def is_comic?
    is?([ "cbr", "cbz"])
  end

  def is_tv?
  	is_video?
  end
  
  def is_video?
  	is?([ "mov", "avi", "rmvb", "wmv", "mkv", "mp4", "mpeg", "divx", "rm", "flv", "mpg", "m4v", "3gp" ])
  end
  
  def is_cbr?
    is?(["cbr"])
  end

  def is_cbz?
    is?(["cbz"])
  end
  
  def is_spam?
    is?([ "nfo", "url" ])
  end
  
  def is_rar?
    is?(["rar"])
  end
  
  def is?(arr)
  	arr.each { |s| return true if self.downcase =~ /#{s}$/ } 
  	false
  end
  
  def ext
    name = split(".")[-1].downcase
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
  
  def transform!(unwanted, replacement)
    @original_name = self.clone
    extension = ext.downcase
    clean!
    gsub!(/#{unwanted}/, replacement)
    gsub!(/\w+/) { |w| w.capitalize }
    conform!
    self << ".#{extension}"
  end
  
end

module FileExtensions
   def File.hidden?(arg)
      return arg =~ /^\..*/
   end
end

module DirExtensions
  def name
    return path.split("/")[-1]
  end
end

File.send(:include, FileExtensions)
Dir.send(:include, DirExtensions)
String.send(:include, StringExtensions)