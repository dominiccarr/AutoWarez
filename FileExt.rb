module FileExt
   def self.hidden?(arg)
      return true if arg =~ /^\..*/
      false
   end
end

File.send(:include, FileExt)