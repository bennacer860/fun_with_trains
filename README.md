

Introduction
------------

![enter image description here](http://i.imgur.com/Ui1zIEI.png)


I have been playing with creating my own [API wrapper](http://routetomastery.com/blog/2015/02/04/create-your-first-api-wrapper-with-tdd/) lately and i didn't find a good use to it.  Fortunately i found inspiration when i saw my colleague building a widget for dashing.  

You can see in the image above that using the this the [ruby_wmata gem](https://rubygems.org/gems/ruby_wmata) i can see when are the next train coming. but i can also tell when if there are some trains boarding. 
It get's more interesting if i go to the [WMATA api documentation](https://developer.wmata.com/docs/services/547636a6f9182302184cda78/operations/547636a6f918230da855363f) and see what kind of information i can retrieve about each train:

```json
{
"Trains":[
		{
		"Car":"6",
		"Destination":"SilvrSpg",
		"DestinationCode":"B08",
		"DestinationName":"Silver Spring",
		"Group":"1",
		"Line":"RD",
		"LocationCode":"A01",
		"LocationName":"Metro Center",
		"Min":"3"
		},
		{
...
```

mmm, i can get how many cars the train has and more importantly it's direction. 
What if i try to track the trains movement on a specific line, would i be able to determine where the trains are in real time? This is the problem i would try to resolve in this post.

Step 1 : Get the stations code
------------------------------

Given the information provided earlier, we need to find out where all the trains are in a specific line. In order to achieve that we need to make the `GetPrediction` on each station, The only problem is that we need a list of station codes to do that. Fortunately, we can use the `jPath` that will return all the stations between  a `FromStationCode` and a `ToStationCode`. So let's try to find all these stations code first.

```ruby 
require 'ruby_wmata'
WMATA.api = 'kfgpmgvfgacx98de9q3xazww'
#pick just 9 stations for the demonstration
path = WMATA.train_path("A01","A15")
path_by_code = @path.map{|station| station["StationCode"]}
```

Step 2 : Find where the trains are
----------------------------------

 

Now that we have a list of train station codes, we can iterate through it then and make the next train API call. We will retrieve the list of all the arriving trains and sometime we will see that some trains are "BRD", it would mean that the location of that train is the stations itself. So whenever we see that let's mark the stations with a 'T' to indicate the presence of a train and '---'  the absence of a trains .
 So i want something that looks like:

```
## the first like would represent the 3 first letters of a station's name
2015-02-28 18:04:13 -0500:Met-Far-Dup-Woo-Cle-Van-Ten-Fri-Bet
2015-02-28 18:04:14 -0500:-T---------------------------------
2015-02-28 18:04:24 -0500:-----T-----------------------------
2015-02-28 18:04:34 -0500:---------T-------------------------
``` 

Let's code it:
```ruby
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
```

Now that we are extracting information about each stations, let's implement the function `train_boarding ` that will tell us if there is a train boarding on that station

```ruby
def train_boarding?(next_trains)
  next_trains.select{|train| train['Min'] == 'BRD'}.empty?
end
```

Step 3 : Update periodically the display to show trains position
----------------------------------------------------------------

Now that we have all the information we need on a specific time. let's try to update the display every 10s. Also we don't want to show the same information multiple time, so we won't refresh the display if the train are in the same positions.  
We can also add some colors to the display to make it more user friendly using the `colorize` gem. (we all know that User friendly in a terminal is not possible!! )

```ruby
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
  sleep 10
end
```

And here is the final result:

[image]

Obviously,  this implementation is not perfect. We can argue a couple of things
 - We don't really see the direction of the trains 
 - What if there are 2 trains going to the opposite directions boarding, we are not showing that information
 - We could replace the last display by the current one but you would not see the movement of the trains 

Conclusion
----------

We came a long way form knowing the next train in a train station to display a whole line with the trains moving in realtime. This method could be implement for any other public transportation with a decent API . The most obvious one would be the next bus.
We can also extend this project to make have a full map with more than one line and see all the train moving in realtime using Javascript and HTML/CSS.Who knows maybe my next project!


