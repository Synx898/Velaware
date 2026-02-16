-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.

-- Initialize controller locks FIRST
if not getgenv().controller then
	getgenv().controller = {}
end

if not getgenv().controller.lock then
	getgenv().controller.lock = {
		knife = false,
		general = false
	}
end

local player = game:GetService("Players").LocalPlayer

function init()
	local playerModel = workspace:FindFirstChild(player.Name)
	if playerModel then
		local gun = playerModel:FindFirstChild("GunController")
		if gun then
			pcall(function()
				gun:Destroy()
			end)
		end
		local knife = playerModel:FindFirstChild("KnifeController")
		if knife then
			pcall(function()
				knife:Destroy()
			end)
		end
	end
end

-- Run immediately
init()

-- Also run on respawn
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	init()
end)

return true
