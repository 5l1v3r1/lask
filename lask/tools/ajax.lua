#!/usr/bin/lua

-- 
-- Copyright (C) spyder
--

local usage = [[
usage:
	ajax type url field1 value1 field2 value2 ...
e.g.
	ajax POST https://mysite.com/bugreport appname myapp version 1.0 '$FILE$_log' '/tmp/myapp.log'
]]

require 'std'
local urlparse = require 'urlparse'
local tasklet = require 'tasklet'
local http = require 'httpx'
local cjson = require 'cjson'

local stderr = io.stderr


local argc = #arg
if argc > 0 then
	local type = arg[1]:lower()
	if type == 'help' then
		print(usage)
		os.exit(0)
	end

	if type ~= 'get' and type ~= 'post' then
		stderr:write('You should specify either get or post.\n')
		os.exit(1)
	end 

	local url = arg[2]
	local urlinfo = url and urlparse.split(url)
	if not urlinfo then
		stderr:write('Not a valid url.\n')
		os.exit(1)
	end

	settings = {
		type = type,	
		url = url,  
	}
	for i = 3, argc, 2 do 
		local field, value = arg[i], arg[i + 1]
		if not value then
			break
		end
		if not settings.data then
			settings.data = {}
		end
		settings.data[key] = value	
	end
else
	local ok
	ok, settings = pcall(cjson.decode, io.stdin:read('*a'))
	if not ok then
		stderr:write(settings, '\n')
		os.exit(1)
	end
end

settings.error = function (resp, err)
	if not resp then
		stderr:write(errno.strerror(err), '\n')
	else
		stderr:write(resp.status, ' ', resp.reason or '', '\n')
		local content = resp.content
		if #content > 0 then
			os.writeb(2, content)
			stderr:write('\n')
		end
	end
	os.exit(1)
end

settings.success = function (data)
	os.writeb(1, data)
	print('')
	os.exit(0)
end

http.ajax(settings)
tasklet.loop()

