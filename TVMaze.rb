require 'rubygems'
require 'ics'
require 'open-uri'
require_relative 'Episode.rb'

module TVMaze
  
  TEMP = "/Users/user/Downloads"
  TOKEN = "JMFOWpvrNabTUvkesHTR8hdADMob6Srm"
  URI = "http://api.tvmaze.com/ical/followed?token=#{TOKEN}"
  PATH = "#{TEMP}/tv.ics"
  
  def self.get_calendar
    
    if not File.exists?(PATH)
      File.open(PATH, "wb") do |saved_file|
          open(URI, "rb") do |read_file|
          saved_file.write(read_file.read)
        end
      end
    end

    return ICS::Event.file(File.open(PATH))
  end
  
  def self.get_by_air_date(date=(Date.today-1))
    events = self.get_calendar

    events.select! do |event|
      date_aired = Date.parse(event.dtstart)
      date_aired == date
    end
        
    events.map! { |episode| Episode.new(episode.summary) }
    events.select! { |episode| episode.show != nil }

    return events
  end
  
  def self.delete!
    File.delete(PATH)
  end
  
  def self.schedule
    puts "#{Date::DAYNAMES[Date.today.wday]}"
    TVMaze::get_by_air_date.each { |ep| puts "\t #{ep}"}
    puts "#{Date::DAYNAMES[(Date.today+1).wday]}"
    TVMaze::get_by_air_date(Date.today).each { |ep| puts "\t #{ep}"}
    puts "#{Date::DAYNAMES[(Date.today+2).wday]}"
    TVMaze::get_by_air_date(Date.today+2).each { |ep| puts "---- #{ep}"}
    self.delete!
  end
  
end

if __FILE__ == $0
  TVMaze.schedule
end