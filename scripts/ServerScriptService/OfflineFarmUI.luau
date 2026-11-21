-- OfflineFarmUI V39 | LocalScript
local Players=game:GetService("Players")
local remote=game:GetService("ReplicatedStorage"):WaitForChild("OfflineFarmV39")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="OfflineFarmUI"; gui.ResetOnSpawn=false; gui.DisplayOrder=50; gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.Size=UDim2.new(.85,0,0,270); panel.Position=UDim2.fromScale(.5,.5); panel.AnchorPoint=Vector2.new(.5,.5); panel.BackgroundColor3=Color3.fromRGB(25,35,51); panel.Visible=false; panel.Parent=gui
local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(440,270); limit.Parent=panel
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,14); corner.Parent=panel
local function label(text,y,h,size,color)
	local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-24,0,h); l.Position=UDim2.new(0,12,0,y); l.BackgroundTransparency=1; l.Text=text; l.TextColor3=color; l.Font=Enum.Font.GothamBold; l.TextSize=size; l.TextWrapped=true; l.Parent=panel; return l
end
label("FARM OFFLINE",12,38,25,Color3.new(1,1,1))
label("Suas espadas produziram dinheiro enquanto você estava fora!",53,48,16,Color3.fromRGB(190,205,225))
local timeLabel=label("",105,26,16,Color3.fromRGB(190,205,225))
local amountLabel=label("",134,48,32,Color3.fromRGB(115,255,110))
local button=Instance.new("TextButton"); button.Size=UDim2.new(1,-32,0,48); button.Position=UDim2.new(0,16,0,194); button.BackgroundColor3=Color3.fromRGB(38,145,76); button.TextColor3=Color3.new(1,1,1); button.Font=Enum.Font.GothamBold; button.TextSize=18; button.Text="RESGATAR"; button.Parent=panel
local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,9); c.Parent=button
local function fmt(n)
	for _,v in ipairs({{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do
		if n>=v[1] then return (string.format("%.2f",n/v[1]):gsub("0+$",""):gsub("%.$",""))..v[2] end
	end
	return tostring(math.floor(n))
end
local busy=false
button.Activated:Connect(function()
	if busy then return end
	busy=true; button.Text="Resgatando..."
	local ok,claimed=pcall(function() return remote:InvokeServer("Claim") end)
	if ok and claimed then panel.Visible=false else button.Text="Tentar novamente" end
	busy=false
end)
task.spawn(function()
	for i=1,120 do
		local ok,amount,seconds=pcall(function() return remote:InvokeServer("State") end)
		if ok and type(amount)=="number" then
			if amount>0 then
				amountLabel.Text="+$"..fmt(amount)
				timeLabel.Text=string.format("Tempo offline: %dh %02dmin",math.floor(seconds/3600),math.floor(seconds/60)%60)
				panel.Visible=true
			end
			return
		end
		task.wait(1)
	end
end)
