class Episode 	
	attr_accessor :season, :episode_no, :episode_name, :show, :aired
	
	def initialize(*args)  
    case args.size
    when 1
      if args[0] =~ /(.+)\sS(\d\d)E(\d\d).*/ or args[0] =~ /(.+):\s(\d+)x(\d\d).*/
        @show = $1.rstrip() 
        @season = $2 
    		@episode_no = $3 
  		end
    when 3 
      @show = args[0].rstrip() 
      @season = args[1] 
    	@episode_no = args[2] 
    when 4
      @show = args[0].rstrip() 
      @season = args[1] 
    	@episode_no = args[2]
    	@episode_name = args[3]
    else
      error
    end
    aired = true
    @season = "0#{@season.to_i}" if @season.to_i < 10
    @episode_no = "0#{@episode_no.to_i}" if @episode_no.to_i < 10
	end

	def season_string
		"Season #{season}" 
	end
	
	def episode_name
	    name = TVRage::episode_name self
	    return "" if name.class == StringIO
			@episode_name = name
			@episode_name.gsub!(/\//, "\s") 
			@episode_name.gsub!("&#x27 ", "'") 
			@episode_name.gsub!("&#x26 ", "&") 
			@episode_name.gsub!("&\s39 ", "'") 
			@episode_name.gsub!("[\W&&[^\s-\.]]", "") 
			@episode_name
	end

	def x_format 
    "#{@season.to_i}x0#{@episode_no}"
	end

	def to_s 
	  string = search_term
	  string << " - #{@episode_name}" if @episode_name
	  string
	end
	
	def search_term
	  "#{@show} S#{@season}E#{@episode_no}"
  end
  
  def <=>(other)
    receiver_season = self.season.to_i * 1000
    argument_season = other.season.to_i * 1000
    receiver_episode = self.episode_no.to_i
    argument_episode = other.episode_no.to_i
    (receiver_season+receiver_episode) <=> (argument_episode+argument_season)
  end

  def == (other) 
    return true if @show = other.show and @episode_no == other.episode_no and @season == other.season     
  end

end