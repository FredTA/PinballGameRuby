# Assignment: small pinball game
# ACA17FT, Fred Tovey-Ansell

require 'io/console'

# cursor keys to control the racquet
RIGHT="\e[C"
LEFT="\e[D"

# Cells on the screen, blank and two boundaries, horizontal and vertical
SC_BLANK=' '
SC_H='-'
SC_V='|'
SC_STAR='*'

# The size of the screen
SCREEN_X=15
SCREEN_Y=15

RACQUET_SIZE=4

# the initial position of the ball
$x=SCREEN_X/2+2
$y=SCREEN_Y/2-2

# the old coordinates of the ball
$oldx=$x;$oldy=$y

# the speed of the ball - how much to increase the value of $x and $y per time unit.
$dx=0.1
# negative value means the ball is moving up the screen,
# positive means moving down.
$dy=0.2

$originalSpeed = Math.sqrt(($dx*$dx)+($dy*$dy))
$originaldy=0.2

# used to configure keyboard for input without having to press Enter
def startKbd
	$stdin.echo=false
	$stdin.raw!
end

# used to configure keyboard for input when pinball terminates.
def endKbd
	$stdin.echo=true
	$stdin.cooked!
end

# obtains keystroke from keyboard if available
def readChar
	input = STDIN.read_nonblock(1) rescue nil
	if  input == "\e" then
		input  << STDIN.read_nonblock(1)  rescue  nil
		input  << STDIN.read_nonblock(1)  rescue  nil
	end
	
	return  input
end

def update(racquet,screen,testmode, ballTracker, totalVisits)
    
    if screen[$y.floor][$x.floor] == SC_H #if hitting a horizontal wall 
        if $y.floor == SCREEN_Y-1 #If ball is hitting the floor
            if $x.floor != racquet-2 and $x.floor != racquet-1 and $x.floor != racquet and $x.floor != racquet+1
                return nil #if it's a horizonal wall, not at the top and not on the raquet, return nil 
            elsif (racquet - $x).abs > 1 #If the ball hits the racquet off centre
                $dx = rand(-0.9..0.9)
                $dy = Math.sqrt((($originalSpeed*$originalSpeed) - ($dx*$dx)).abs)
                #Set $dy to such a value that speed will remain constant, unless a value of large magnitude..
                #..was chosen for x in which case there will be some difference in the new speed
                newSpeed = Math.sqrt(($dx*$dx)+($dy*$dy))

                if newSpeed > $originalSpeed * 1.75 or $originalSpeed > newSpeed * 1.75
                    #If the new magnigitude of $dx is too large to maintain a relavily constant speed
                    #choose $dy so that the ball does not speed up too much
                    $dx = $originaldy
                    $dy = $originaldy
                end
            end
        end
       $dy = -$dy #If about to hit a horizontal wall, reverse direction of vertical motion 
    elsif screen[$y.floor][$x.floor] == SC_V
       $dx = -$dx #If about to hit a vertical wall, reverse direction of horizontal motion 
    end
    
    x=$x.floor
    y=$y.floor
    $x+=$dx
    $y+=$dy
    
    if screen[$y.floor][$x.floor] == SC_BLANK
        if $oldx.floor != $x.floor or $oldy.floor != $y.floor
            ballTracker[$y.floor][$x.floor] += 1
            totalVisits += 1
            if ballTracker[$y.floor][$x.floor] >= 3 && ballTracker[$y.floor][$x.floor] > totalVisits * 0.02
                #Cells visited more than 3 times and more than 2% of the total number of visits of all cells 
                screen[$y.floor][$x.floor] = SC_STAR #should be painted with a star
            end
        end
    end
    
    print "no_wall" if testmode
    return x==$x.floor && y == $y.floor	#Will return false if ball hasn't visibly moved
end

def displayDyn(screen,racquet)
    
   for x in 2 ..SCREEN_X-1 do 
       print "\e[#{SCREEN_Y};#{x}H-"
       #Go through the bottom row and replace character with the horizontal wall
   end
    
   for x in 1..RACQUET_SIZE do
       print "\e[#{SCREEN_Y};#{(racquet-2)+x}H="
   end 
   #Writes the racquet to the screen as the "=" character over the wall character

  # clears the old position of the ball, using the value in the screen array
  # and plots the current position.
  if $y >= 0 && $x >= 0 && $y < SCREEN_Y && $x < SCREEN_X
		# erases the old ball position
    print "\e[#{1+$oldy.floor};#{1+$oldx.floor}H#{screen[$oldy.floor][$oldx.floor]}"
		# displays the new position
    print "\e[#{1+$y.floor};#{1+$x.floor}H@"
		# records the current coordinates of the ball so that when displayDyn is 
		# called again, the ball can be erased
    $oldx=$x.floor;$oldy=$y.floor
  end
end

def displayBoundaries(screen)
  print "\e[2J\e[#{0};#{0}H" #must be print not puts
    # this clears the screen and sets the cursor to the top-left corner
    
    for x in 0...SCREEN_Y do 
		for y in 0...SCREEN_X do  
		    print screen[x][y] 
		end
        puts ""
	end
    #Goes through the array and outputs each element to the screen as a char
end

# you need to write the code to update the position of the racquet when a user presses cursor left
def racquetLeft(racquet)
    if racquet - 2 != 1 #If the leftermost part of the racket isn't in the left wall
       return racquet - 1 #return the current position but 1 to the left 
    else
        return racquet
    end
end

# you need to write the code to update the position of the racquet when a user presses cursor right
def racquetRight(racquet)
	if racquet + 2 != SCREEN_X-1 #If the rightermost part of the racket isn't in the right wall
       return racquet + 1 #return the current position but 1 to the right
    else 
        return racquet
    end
end
  
# Reports that the game is over
def displayEndgame
 	puts "\e[#{SCREEN_Y+1};#{1}HGame over.\e[#{SCREEN_Y+2};#{1}H"
end

# This is a routine to run the game
def mainloop(screen, ballTracker)
	# draws the screen
	displayBoundaries(screen)
	# configures keyboard
	startKbd

	# initial racquet position in the middle
	racquet=SCREEN_X/2.floor
	# displayes the ball and racquet
    displayDyn(screen,racquet)
    
    totalVisits = 0;
    
	loop do
        # updates the position of the ball
        u=update(racquet,screen,false, ballTracker, totalVisits)
        if u == nil
          # missed the racquet, game over
          displayEndgame
          break
        elsif !u
          # display needs to be updated
          displayDyn(screen,racquet)
        end
        ch = readChar
        if ch == 'q' || ch == "\003" 
          # character 'q' or Ctrl-C means 'quit the game'
          displayEndgame
          break
        elsif ch != nil
          if ch == LEFT 
            racquet = racquetLeft(racquet)
          elsif ch == RIGHT
            racquet = racquetRight(racquet)
          end
        end
    # 100ms per cycle
    sleep(0.1)	
    end
    ensure
		# ensures that when application stops, the keyboard is in a usable state
		endKbd
end

#OPTIONAL "TEST" CODE NOT USED
def tryupdate(x,y,screen)
	$x=x;$y=y
	print "#{x},#{y} : "
	update(SCREEN_X/2,screen,true)
  puts
end
    
#OPTIONAL "TEST" CODE NOT USED
def trytest(screen)
	$dx=0;$dy=0
	tryupdate(0.5,SCREEN_Y/2,screen)
  tryupdate(SCREEN_Y-1.5,SCREEN_Y/2,screen)
end

# This is the main part of the code
begin
	#creating the boundaries
	screen = Array.new(SCREEN_Y) { Array.new(SCREEN_X, SC_BLANK)}
    
    #A 2D array to keep track of where the ball has been
    ballTracker = Array.new(SCREEN_Y) { Array.new(SCREEN_X, 0)}

	(0...SCREEN_Y).each do |row|
		(0...SCREEN_X).each do |column| 
		  if row == 0 || row == SCREEN_Y-1
		    screen[row][column] = SC_H
		  end
			if column == 0 || column == SCREEN_X-1
				screen[row][column] = SC_V
			end
		end
	end

	# This code adds t-shape wall in the middle of the screen
	(4...SCREEN_X/2).each do |column| 
		screen[SCREEN_Y/2][column] = SC_H
	end

	(5...SCREEN_Y-5).each do |row| 
		screen[row][SCREEN_X/2] = SC_V
	end

	# this runs the main loop for the game
	mainloop(screen, ballTracker)

	# if you comment out the above main loop and instead uncomment trytest, 
	#it will run your test routines.
	#trytest(screen)

end

