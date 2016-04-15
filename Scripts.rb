require_relative 'Comics.rb'
require_relative 'TVMaze.rb'
require 'getoptlong'

def main
  opts = GetoptLong.new([ "--dir", "-d", GetoptLong::REQUIRED_ARGUMENT ], 
  [ "--comics", "-c", GetoptLong::NO_ARGUMENT ], 
  [ "--tv", "-t", GetoptLong::NO_ARGUMENT ],
  [ "--win", "-w", GetoptLong::NO_ARGUMENT ])
  
  opts.each do |opt, arg|
    case opt
    when "--dir"
      Comics::dowload_check_printer(arg)
    when "--tv"
      TVMaze::schedule
    when "--comics"
      Comics::print
    when "--win"
      puts Comics::win_o_clock
    end
  end
end

main