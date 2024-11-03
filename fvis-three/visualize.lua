local M = {}

local lumen = require'lumen'
local log     = lumen.log
local sched   = lumen.sched
local selector  = require 'lumen.tasks.selector'
local http_server = require "lumen.tasks.http-server"

M.ws = nil

M.init = function ( params )

  params = params or {}
  params.service = params.service or 'luasocket'

------------------------------------------------------------
  log.setlevel('ALL', 'HTTP')
  selector.init({service=params.service})

  http_server.serve_static_content_from_ram('/', 'fvis-three/www')

  http_server.serve_static_content_from_table('/big/', {['/file.txt']=string.rep('x',10000000)})

  if params.service=='nixio' then
    http_server.serve_static_content_from_stream('/docs/', 'lumen/docs')
  else
    http_server.serve_static_content_from_ram('/docs/', 'lumen/docs')
  end

  http_server.set_websocket_protocol('lumen-shell-protocol', function(ws)
      local shell = require 'lumen.tasks.shell' 
      local sh = shell.new_shell()

      sched.run(function()
          while true do
            local message,opcode = ws:receive()
            if not message then
              ws:close()
              return
            end
            if opcode == ws.TEXT then
              sh.pipe_in:write('line', message)
            end
          end
        end):attach(sh.task)

      sched.run(function()
          while true do
            local _, prompt, out = sh.pipe_out:read()
            if out then 
              assert(ws:send(tostring(out)..'\r\n'))
            end
            if prompt then
              assert(ws:send(prompt))
            end
          end
        end):attach(sh.task)
    end)


  http_server.set_websocket_protocol('lua-fvis-protocol', function(ws)
      --print ('!!!!!!!!!!!!!!!!!!!1')
      sched.run(function()
          while true do
            local message,opcode = ws:receive()
            if not message then
              M.ws = nil
              ws:close()
              return
            end
            if opcode == ws.TEXT then
              print('from websocket', ws, message)
            end
          end
        end
      )

      sched.run(function()
          sched.sleep(1)
          ws:broadcast('tick')
        end
      )
    end)


  local conf = {
    ip='127.0.0.1', 
    port=8080,
    ws_enable = true,
    max_age = {ico=5, css=60},
    kill_on_close = true,
  }
  assert(http_server.init(conf))

  print ('http server listening on', conf.ip, conf.port)
  for _, h in pairs (http_server.request_handlers) do
    print ('url:', h.pattern)
  end
  print('TIP: access http://'..conf.ip..':'..conf.port..'/shell.html for a websocket-based interactive console')
------------------------------------------------------------
  return M
end

M.close = function ()
  http_server.close()
end

M.display = function ( w )
  --if M.ws then M.ws:broadcast('ping!') end
end

return M