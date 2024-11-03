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
set ylabel 'd'
plot "pendulum.data" using 1:6 w l t 'd', \

set terminal qt 1
set xlabel 'x'
set ylabel 'z'
plot 'pendulum.data' using 4:5 with l

pause mouse keypress

unset output
