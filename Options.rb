class Options 
  
  attr_accessor :print, :rename, :unrar, :create, :move, :recursive, 
  :delete, :root, :list, :unwanted, :replacement, :episode_name, :regex, :dir,
  :tv, :comics, :monitor
  
  def initialize()
    @print = true
    @rename = true
    @unrar = false
    @create = false
    @move = false
    @recursive = false
    @delete = false
    @root = false
    @list = false
    @unwanted = ""
    @replacement = ""
    @episode_name = false
    @monitor = false
    @dir = ""
    @tv = ""
    @comics = ""
  end
  
end