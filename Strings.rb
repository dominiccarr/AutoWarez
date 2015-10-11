module StringExtensions
  def is_comic?
    is?([ "cbr", "cbz"])
  end

  def is_tv?
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
end

module BBCode
  def bold 
    "[b]#{self}[/b]"
	end
	
	def italic
		"[i]#{self}[i]"
	end

	def print_size(b) 
		"[size=#{b}]#{self}[/size]"
	end

	def color(b)
		"[color=#{b}]#{self}[/color]"
	end

	def image 
		"[img]#{self}[/img]"
	end

	def code
	  "[code]#{self}[/code]"
	end
end

String.send(:include, BBCode)
String.send(:include, StringExtensions)
