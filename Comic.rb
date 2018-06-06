class Comic
  attr_accessor :title, :publisher, :info

	def initialize(title, publisher, issue_num, raw="") 
		@title = title
		@publisher = publisher
		@issue_num = issue_num
        @raw = raw
	end
	
	def reprint?
	  @info =~ /(.*)2ND PTG(.*)/ or @info =~ /(.*)3RD PTG(.*)/ or  @info =~ /(.*)4TH PTG(.*)/ or @info =~ /(.*)POSTER(.*)/
  end
	
	def display
	  "#{@title} #{issue_num}"
  end

	def to_s 
	  string = display
	  string << " --- #{info}" if info and info.strip != ""
    string
	end
	
	def issue_num
	  @issue_num.to_s.gsub(/(\d+)(\.\d+)?/) {
	    hole = $1.to_i
	    frac = $2
	    zeroes = 3-(hole.to_s.length)
	    ret = ""
	    ret = "#{"0" * zeroes}" if zeroes>0
	    ret << "#{hole}#{frac}"
	    return ret
	  }
  end

	def == (other) 
		if @issue_num < other.issue_num
			-1
		elsif @issue_num > other.issue_num
			1
		end
		0
	end
	
	def publisher?(publisher)
	  @publisher.downcase == publisher.downcase
  end
	
	def - (other)
	  @issue_num - other.issue_num
	end
	
end