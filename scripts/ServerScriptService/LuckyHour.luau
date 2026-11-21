-- LuckyHour V1 | Script em ServerScriptService
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local INTERVAL = 30 * 60 -- tempo entre inicios
local DURATION = 5 * 60
local FIRST_WAIT = 10 -- para testar, use 10
local state = Instance.new("Folder")
state.Name = "LuckyHourState"
state:SetAttribute("Active", false)
state:SetAttribute("Multiplier", 1)
local nextStart = Workspace:GetServerTimeNow() + FIRST_WAIT
state:SetAttribute("EndsAt", nextStart)
state.Parent = RS
while true do
	local now = Workspace:GetServerTimeNow()
	if now >= nextStart then
		local finish = nextStart + DURATION
		state:SetAttribute("EndsAt", finish)
		state:SetAttribute("Multiplier", 2)
		state:SetAttribute("Active", true)
		print("[LuckyHour] Evento iniciado: peso 2x!")
		while Workspace:GetServerTimeNow() < finish do task.wait(0.5) end
		nextStart += INTERVAL
		state:SetAttribute("EndsAt", nextStart)
		state:SetAttribute("Multiplier", 1)
		state:SetAttribute("Active", false)
		print("[LuckyHour] Evento encerrado.")
	end
	task.wait(0.5)
end
