reset
clear

#set title "Buffer distribution, Separation scenario"
#set xrange [0:50000]
#set yrange [0:1]
#set xlabel 'Time (sec)'
#set ylabel 'Buffer distribution'
#set key right bottom
#set term post size 5in, 2in eps enhanced color  

set mouse


set key top left

#set term post size 7in, 5in eps enhanced color  
#set term x11
#set out "sea.svg"

#set ytics (500, 1000, 2000, 3000, 4000, 5000)

set terminal qt 0
set xlabel 't'
set ylabel 'vel'
plot "balloon.data" using 1:4 w l t 'velx', \
     "balloon.data" using 1:5 w l t 'velz', \

set terminal qt 1
set xlabel 't'
set ylabel 'z'
plot "balloon.data" using 1:3 w l t '', \

set terminal qt 2
set xlabel 'x'
set ylabel 'z'
plot "balloon.data" using 2:3 w l t '', \

set terminal qt 3
set xlabel 't'
set ylabel 'upx'
plot "balloon.data" using 1:6 w l, \

#pause mouse keypress

unset output
