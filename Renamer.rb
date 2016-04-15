class Renamer
  
  attr_accessor :warez, :orig, :args, :dir

  def handle(warez)
    @warez = warez
    directory = Dir.new(warez.options.dir).entries
    directory.select! { |file| not File.hidden? file }
  
    directory.each do |title| 
      next unless matches? title
      title.transform!(warez.options.unwanted, warez.options.replacement)
      rename title 
    end
  end
  
  def rename(name)
    @orig = name.original_name
    @args = @warez.options
    @dir = @warez.options.dir
  end

end