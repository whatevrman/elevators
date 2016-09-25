module GenPeopleFiles
  module ModMethods
    # generate an input file for elevator simulation
    #   filename: written to this file
    #   nbr_floors: floors range from 1 through nbr_floors
    #   rate: average number of arrivals (events) per time unit
    #   max_time: time units 1, 2, ..., max_time
    # file format:
    # <nbr_floors>
    # <id>1 <arrival_time>1 <origin_floor>1 <destination_floor>1
    # ...
    # <id>n <arrival_time>n <origin_floor>n <destination_floor>n
    def gen_input_file(filename, nbr_floors, rate, max_time)
      File.open(filename, 'w') do |f|
        time = 1
        indx = 99
        f.puts(nbr_floors)
        loop do
          time += sleep_for(rate)
          break if time >= max_time+1
          indx += 1
          org = rand_in_range(1, nbr_floors+1)
          dest = rand_in_range(1, nbr_floors)
          dest += 1 if dest >= org
          res = [indx, time.to_i, org, dest]
          res = res.map(&:to_s).join(' ')
          f.puts(res)
        end
      end
    end

    # generate a series of elevator simulation files
    def gen_input_files(fileprefix, nbr_files, nbr_floors, rate, max_time)
      nbr_files.times do |n|
        filename = fileprefix + ("%.3d" % n) + '.in'
        gen_input_file(filename, nbr_floors, rate, max_time)
      end
    end
    # Poisson process rate: Average number of events per time unit
    def sleep_for(rate)
      -Math.log(1.0 - Random.rand) / rate
    end
    def rand_in_range(a, b)
      rand(b-a) + a
    end
  end

  extend ModMethods
end
class  Person
  # Store information of each passenger

  def initialize(id,time,orig,dest)
    @id=id
    @time=time.to_i
    @origin=orig.to_i
    @destination=dest.to_i
  end
  def id
    @id
  end
  def info
    @id
  end
  def time
    @time
  end
  def to_s
    # Used during testing to see who's boarding, and where
    @id.to_s+' at '+@time.to_s+' boarded at '+@origin.to_s+', going to '+@destination.to_s
  end
  def origin
    @origin
  end
  def destination
    @destination
  end

  def call(elev)
    # lets the elevator know the person is ready to
    # be picked up
    elev.call(self)
  end
  def wait(elev)
    #stores wait time for the person, once they depart
    elev.time-@time
  end
end

class Elevator
  def initialize(floor)
    @time=floor
    @pass=[]
    @wait=[]
    @calls=[]
    @floor=0
  end
  def set_start(num)
    @floor=num
  end
  def move_up
    @floor+=1
    @time+=1
  end
  def move_down
    @floor-=1
    @time+=1
  end
  def time
    @time
  end
  def floor
    @floor
  end
  def calls(per)
    # works in conjunction with person call method to
    # determine when a person is ready to board
    if @time==per.time
      @calls.push(per)
    end
  end
  def board(person)
    # adds person to the elevator
    puts '        '+person.id+' got on at '+person.origin.to_s+' going to '+person.destination.to_s
    @pass.push(person)
  end
  def who
    # specifies who is on the elevator, used for testing
    @pass.each do |x|
      x.info
    end
  end
  def depart(person)
    puts '        '+person.id+' left at '+person.destination.to_s
    if @time!=1
      @pass.delete(person)
      @wait.push(person.wait(self))
    end
  end
  def remove(strategy,x)
    # removes person from the @people Array
    # in the strategy after departing,
    # so that all people are accounted for,
    # and to end the loop
    strategy.people.delete(x)
  end
  def check(strategy,x)
    # evaluates which people need to be boarding
    # or departing
    if x.origin==@floor&&@calls.include?(x)&&!@pass.include?(x)
      self.board(x)
    elsif @floor==x.destination&&@pass.include?(x)
      self.depart(x)
      self.remove(strategy,x)
    end
  end
  def average_wait
    @wait.reduce(:+).to_f / @wait.size
  end
end
module Strategy
  # defines methods usable for nearly any strategy
  # mixed into Strategy1 and a future strategy,
  # to be developed by me
  def initialize
    @floors
    @info=[]
    @people=[]
    @wait=[]
  end
  def input(file)
    File.foreach(file) do |line|
      @info.push(line.split)
    end
    @floors=@info[0.to_i]
    @info.shift
    @info.each do |x|
      @people.push(Person.new(x[0],x[1],x[2],x[3]))
    end
  end
  def people
    @people
  end
end

class Strategy1
  include Strategy
  def strategy(elev)
    puts 'Time '+elev.time.to_s+':'' Floor '+elev.floor.to_s
    @people.each do |x|
      elev.calls(x)
      elev.check(self,x)
    end
  end
  def move_up(elev)
    until elev.floor==@floors[0].to_i do
      strategy(elev)
      elev.move_up
    end
  end
  def move_down(elev)
    until elev.floor==1 do
      strategy(elev)
      elev.move_down
    end
  end
  def remove(x)
    people.delete(x)
  end
  def average_wait
    @wait.reduce(:+).to_f / @wait.size
  end
  def run(x)
    x.times do
      self.single
    end
    puts @wait
    puts 'Overall average for '+x.to_s+' runs is '+self.average_wait.to_s
  end
  def single
    @info=[]
    @people=Array.new
    # commented the file generation out, to use the same
    # txt file that caused the infinite loop
    self.input('test.txt')
    elev=Elevator.new(1)
    elev.set_start(1)
    # @people contains all persons created by the txt file.
    # Each person is removed as they depart the elevator
    until @people.empty? do
      self.move_up(elev)
      self.move_down(elev)
    end
    @wait.push(elev.average_wait)
    puts 'end of run'
  end
end
GenPeopleFiles.gen_input_file('test.txt', 10, 1, 10)
s=Strategy1.new

startTime = Time.now
s.run(100)
endTime= Time.now
totalTime = (endTime - startTime) * 1000
puts(totalTime.to_s + ' ms')
