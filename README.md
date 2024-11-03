
# Lua Fligh&Float Simulator

Pure lua beginning od the implementation of a game-ish simulator. No good reason for it to exist.

First it was developped as dual Lua / Luajit, later moved to only care for Lua5.3+.

It is to managa an ocean covered planet, where boats and submarines and balloons float,  planes fly, 
sailboats sail, and orcas attack yachts.

It implements...

* vector math
* rigid body physics simulator
* aero/hydro-dynamic foil and hull simulator
* ocean and atmospheric physics

A lot of code is ransacked all over the place, but the idea was to make it clean.

## Visualization dependencies:

Note for self: at some point in tought about displaying using three.js from an integrated 
lumen http server. Whatever code it was lives in fvis-three/ and start_lumen.lua

Now all the visualization is OpenGL through MoonGL:

```
$ sudo apt install libglew-dev
$ git clone https://github.com/stetre/moongl
$ cd moongl
$ make 
$ sudo make install
$ cd ..
$ sudo apt install libglfw3
$ git clone https://github.com/stetre/moonglfw
$ cd moonglfw
$ make 
$ sudo make install
```
These may ask for some more MoonGL libs to be installed.

Also there is some code around to write data for guplot, specially for debugging purpoes.

## How to run:

```
$ lua start.lua
```

In  the start_lua file you will find a refence to world/* files, which define scenarios. You 
can start fromt here to see what sort of stuff you can do. Also there are simulation paremeters.

## Who

jvisca@fing.edu.uy - [Grupo MINA](https://www.fing.edu.uy/inco/grupos/mina/), Facultad de Ingeniería - Udelar, 2024

## License

MIT
