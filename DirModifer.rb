dir = "/Volumes/UNTITLED/Keeping/Peter David"

def sting(num)
  str = ""
  (3 - num.to_s.length).times { str += "0" }
  "#{str}#{num}"
end
# Dir.glob("#{dir}/**/*") do |file|
Dir.glob("#{dir}/**") do |file|
   if file =~ /(.*)\s(By|\-).*/
     puts $1
     File.rename(file,  $1)
   end
end
 