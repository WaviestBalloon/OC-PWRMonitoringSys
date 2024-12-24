local component = require("component")
local fs = require("filesystem")
local computer = component.computer
local gpu = component.gpu
local standardConfigFilename = "monitoralias.config"

local screens = {}
local primaryScreen = gpu.getScreen()
print("Found primary screen @ ".. primaryScreen)
for address, componentType in component.list("screen") do
	print("Found monitor @ ".. address .." (".. componentType ..")")
	table.insert(screens, address)
end

if fs.exists(standardConfigFilename) then
	error(standardConfigFilename .." already exists! Remove the existing configuration file to continue setup")
end

print("Starting setup...\nGet ready to check your connected displays, you'll see a [SETUP] tag on each display that it detects\n")
local config = io.open(standardConfigFilename, "a")

for i, address in pairs(screens) do
	gpu.bind(address, true)
	os.sleep(0.5)

	print("[SETUP] This screen is at index ".. i .."\nAddress: ".. address)

	os.sleep(0.5)
	gpu.bind(primaryScreen, true)
	os.sleep(0.5)

	print("What alias would you like to call this display? ")
	local alias = io.read()
	if alias == "" then
		error("Empty alias found")
	end

	print("Labelling ".. address .." as \"".. alias .."\"...")
	config:write(alias .."=".. address .."\n")
	os.sleep(0.5)
end

gpu.bind(primaryScreen, true)
os.sleep(0.5)

config:close()
print("Completed successfully!")
