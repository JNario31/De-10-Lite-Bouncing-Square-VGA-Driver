# De-10-Lite-Bouncing-Square-VGA-Driver

Utilizes PLL clock divider to convert 50MHz to 25MHz for VGA display
Resolution of 640x480p 

H and V sync generator created using a horizontal and vertical counter
de variable to check if in active pixel range

frame (buffer) counter used to allows speed of action
frame reg used to animate (update) square at start of of sync

qx and qy are variables that describe the position of the square (updated to change its position)
square will be drawn within these coordinates

qdx and qy are variables that describe direction, when 0 move right/down respectively
