module Clipboard

	def self.to_clipboard(string)
    IO.popen('pbcopy', 'w').puts string    
  end
  
end