import { World } from './world/world.js';

function main() {
  // Get a reference to the container element
  const container = document.querySelector('#scene-container');

  // create a new world
  const world = new World(container);

  // draw the scene
  world.render();
}


function get_appropriate_ws_url()
{
	var u = new String(document.URL);

	/*
	 * We open the websocket encrypted if this page came on an
	 * https:// url itself, otherwise unencrypted
	 */

	if (u.substring(0, 5) == "https") {
		//return "wss://localhost:12345";
		u = u.replace('https://','');
		u = u.substring(0, u.indexOf('/'));
		return "wss://" + u;
	} else {
		//return "ws://localhost:12345";
		u = u.replace('http://','');
		u = u.substring(0, u.indexOf('/'));
		return "ws://" + u;
	}
}




document.getElementById("wslsh_status").textContent = get_appropriate_ws_url();

/* lumen shell protocol */
	
	var socket_lsh;

	if (typeof MozWebSocket != "undefined") {
		socket_lsh = new MozWebSocket(get_appropriate_ws_url(),
				   "lua-fvis-protocol");
	} else {
		socket_lsh = new WebSocket(get_appropriate_ws_url(),
				   "lua-fvis-protocol");
	}


	try {
		socket_lsh.onopen = function() {
			document.getElementById("wslsh_statustd").style.backgroundColor = "#40ff40";
			document.getElementById("wslsh_status").textContent = " shell connection opened ";
		} 

		socket_lsh.onmessage =function got_packet(msg) {
			console.log('Received: ' + msg.data); 
			/*
			var shellout = document.getElementById("shellout");
			shellout.value += msg.data;
			shellout.scrollTop = shellout.scrollHeight;
			document.getElementById( "shellin").focus()
			*/
		} 

		socket_lsh.onclose = function(){
			document.getElementById("wslsh_statustd").style.backgroundColor = "#ff4040";
			document.getElementById("wslsh_status").textContent = " shell connection CLOSED ";
		}
		socket_lsh.onerror = function(error){
			console.log('Error detected: ' + error);
		}
	} catch(exception) {
		alert('<p>Error' + exception);  
	}

function checkSubmit(e)
{
   if(e && e.keyCode == 13)
   {
      shellsend();
      return false;
   }
}

function shellsend() {
	var shellout = document.getElementById("shellout");
	var shellin = document.getElementById( "shellin");
	var command = shellin.value;
	shellout.value += (command+'\r\n');
	socket_lsh.send(command);
	shellin.value = '';
}


main()
