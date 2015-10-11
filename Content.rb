class Content
  attr_accessor :name
  attr_reader :orig_name, :directory
  
  def initialize(name, directory, unwanted="", replacement="")
    @name = name
    @orig_name = name.clone
    @directory = directory
    @name.gsub!(/#{unwanted}/, replacement)
  end
    
  def ext
    @orig_name.ext
  end
  
  def to_s
    "#{@name}.#{ext}"
  end
end