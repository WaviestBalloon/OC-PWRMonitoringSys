local grafana = {}
local fs = require("filesystem")
local internet = require("internet")

local json = require("json")

local authenticationData = {}
local initalised = false

function getEpochTimestamp() -- tysm: https://oc.cil.li/topic/675-real-life-time-at-least-server-time-in-oc/?do=findComment&comment=2634
	local file = io.open("/tmp/.time", "w")
	file:write()
	file:close()
	
	return fs.lastModified("/tmp/.time")
end

function grafana.generateGrafanaTimestamp() -- Lua does not have BigInts, usually I can use tostring(math.floor(getEpochTimestamp() * 1000000))
	local epoch = tostring(math.floor(getEpochTimestamp() / 1000))
	local i = 0
	repeat
		epoch = epoch .."0"
		i = i + 1
	until i < 27 - string.len(epoch) ~= true

	return epoch -- One issue: There is a time inaccuracy with this when updating below a second (which you shouldn't really be doing anyway), got to look into it more - It most likely stems from `getEpochTimestamp`
end

function grafana.initalise(initTable)
	assert(initTable.user, "No user")
	assert(initTable.password, "No password")
	assert(initTable.logUrl, "No logUrl")
	print("Grafana init as \"".. initTable.user .."\"...")
	
	authenticationData.user = initTable.user
	authenticationData.password = initTable.password
	authenticationData.logUrl = initTable.logUrl -- where Loki is
	
	initalised = true
end

function grafana.sendLog(app, table, level)
	if initalised == false then
		print("sendLog was called but Grafana hasn't been initalised yet!")
		return
	end
	if level == nil then
		level = "info"
	end

	local POSTData = {
		["streams"] = {
			{
				["stream"] = {
					["level"] = level,
					["app"] = app
				},
				["values"] = {
					{
						grafana.generateGrafanaTimestamp(),
						json.encode(table)
					}
				}
			}
		}
	}
	
	local JSONEncoded = json.encode(POSTData)

	local handle = internet.request(authenticationData.logUrl .."/loki/api/v1/push", JSONEncoded, { ["Content-Type"] = "application/json" }, "POST")
	local metatable = getmetatable(handle)
	os.sleep(0) -- Confusing GC jank: https://github.com/MightyPirates/OpenComputers/issues/2255 needs better solution!
	os.sleep(0)

	local code, message, _ = metatable.__index.response()
	if code ~= 204 then
		print("Response was not 204 No Content!")
		print("HTTP Code = ".. tostring(code))
		print("Message = ".. tostring(message))
	end
end

function grafana.sendLogSafe(table)
	pcall(function()
		grafana.sendLog(table)
	end)
end

return grafana
