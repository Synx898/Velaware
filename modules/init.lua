-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.
local player = game:GetService("Players").LocalPlayer

function init()
	local playerModel = workspace:FindFirstChild(player.Name) -- Changed from WaitForChild
	if playerModel then
		local gun = playerModel:FindFirstChild("GunController") -- Changed from WaitForChild
		if gun then
			pcall(function()
				gun:Destroy()
			end)
		end
		local knife = playerModel:FindFirstChild("KnifeController") -- Changed from WaitForChild
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
	task.wait(0.5) -- Small delay for character to load
	init()
end)

return true
