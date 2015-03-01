require 'ruby_wmata'
require 'colorize'

WMATA.api = 'kfgpmgvfgacx98de9q3xazww'
#pick just 9 stations for the demonstration
@path = WMATA.train_path("A01","A10")
@path_by_code = @path.map{|station| station["StationCode"]}

def train_boarding?(next_trains)
  next_trains.select{|train| train['Min'] == 'BRD'}.empty?
end

def find_trains_in_path(path)
      path_with_trains = []
      path.each_with_index{|station,index|
        begin
            next_trains = WMATA.next_trains(station)
            train_boarding?(next_trains) ? path_with_trains[index] = "-T-" : path_with_trains[index] = "---"
        rescue
            path_with_trains[index] = "---"
        end
      }
      return path_with_trains
end

puts "#{Time.now}:".blue + "#{@path.map{|station| station["StationName"][0,3]}.join('-')}".red
last_display = []
while (true) do
  display = find_trains_in_path(@path_by_code).join("-")
  unless display == last_display
    print "#{Time.now}:".blue
    print "#{display}" 
    puts ""
  end
  last_display = display
  sleep 5
end
