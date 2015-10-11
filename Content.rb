class Content
  attr_accessor :name
  attr_reader :orig_name, :directory
  
  def initialize(name, directory, unwanted="", replacement="")
    @name = name
    @orig_name = name.clone
    @directory = directory
    @name.gsub!(/#{unwanted}/, replacement)
    clean @name
  end
  
  def clean(content)
    content.gsub!(".#{content.ext}", '')
    content.gsub!("AwesomeDL.com_", '')
    content.gsub!(/\_|\[|\]|\(|\)|\#|\+/, " ")
    content.strip!
  	content.gsub!(/\s+/, "\s")
  	content.gsub!("-", " ") if content.is_tv?
  	content.gsub!("&#x27;", "'")
  	content.gsub!("&#x26;", "&")
  	content.gsub!("&\s39;", "'")
  	content.gsub!("[\W&&[^\s-\.]]", "")
  	content.gsub!(/^(.)/) { |m| $1.capitalize }
    content.gsub!(/\s(.)/) { |m| "\s#{$1.capitalize}" }
  end
  
  def ext
    @orig_name.ext
  end
  
  def to_s
    "#{@name}.#{ext}"
  end
end