-- V47.4 | StarterPlayerScripts > RankingUI (LocalScript)
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
local board=workspace:WaitForChild("SwordGameMap"):WaitForChild("GlobalRanking"):WaitForChild("RankingBoard")
local gui=Instance.new("SurfaceGui")
gui.Name="RankingUI"; gui.Adornee=board; gui.Face=Enum.NormalId.Front; gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize; gui.CanvasSize=Vector2.new(800,575); gui.LightInfluence=0; gui.MaxDistance=85; gui.Active=true; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local function label(parent,value,x,y,w,h,color)
	local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Position=UDim2.fromScale(x,y); t.Size=UDim2.fromScale(w,h); t.Text=value; t.TextColor3=color; t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.Parent=parent; return t
end
local white=Color3.fromRGB(230,238,250)
local colors={Cash=Color3.fromRGB(88,220,145),Rebirth=Color3.fromRGB(255,204,91),Income=Color3.fromRGB(181,155,255)}
label(gui,"GLOBAL RANKING",.04,.015,.92,.09,white)
local selected="Cash"
local buttons,rows={},{}
local status=label(gui,"Carregando...",.04,.95,.92,.04,white)
local function render()
	local ok,data=pcall(function() return HttpService:JSONDecode(board:GetAttribute(selected.."Data") or "[]") end)
	if not ok then data={} end
	for i,r in ipairs(rows) do
		local e=data[i]; r.Name.Text=e and e.Name or "—"; r.Score.Text=e and e.Score or "—"; r.Score.TextColor3=colors[selected]; r.Avatar.Image=e and ("rbxthumb://type=AvatarHeadShot&id="..e.Id.."&w=150&h=150") or ""
	end
	for k,b in pairs(buttons) do b.BackgroundColor3=k==selected and colors[k] or Color3.fromRGB(43,60,82); b.TextColor3=k==selected and Color3.fromRGB(18,28,43) or white end
	status.Text=board:GetAttribute(selected.."Status") or "Carregando..."
end
for i,k in ipairs({"Cash","Rebirth","Income"}) do
	local b=Instance.new("TextButton"); b.Position=UDim2.fromScale(.035+(i-1)*.315,.12); b.Size=UDim2.fromScale(.30,.09); b.Text=k=="Income" and "Money/s" or k; b.TextScaled=true; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.Parent=gui; buttons[k]=b
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=b
	b.Activated:Connect(function() selected=k; render() end)
	board:GetAttributeChangedSignal(k.."Data"):Connect(render); board:GetAttributeChangedSignal(k.."Status"):Connect(render)
end
for i=1,10 do
	local r=Instance.new("Frame"); r.Position=UDim2.fromScale(.035,.23+(i-1)*.071); r.Size=UDim2.fromScale(.93,.065); r.BackgroundColor3=Color3.fromRGB(35,49,68); r.BorderSizePixel=0; r.Parent=gui
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=r
	label(r,tostring(i),.01,.1,.08,.8,({Color3.fromRGB(255,205,83),Color3.fromRGB(210,220,235),Color3.fromRGB(204,145,95)})[i] or white)
	local avatar=Instance.new("ImageLabel"); avatar.BackgroundTransparency=1; avatar.Position=UDim2.fromScale(.10,.05); avatar.Size=UDim2.fromScale(.05,.90); avatar.Parent=r
	local name=label(r,"—",.18,.1,.49,.8,white); name.TextXAlignment=Enum.TextXAlignment.Left
	local score=label(r,"—",.69,.1,.29,.8,white); score.TextXAlignment=Enum.TextXAlignment.Right
	rows[i]={Name=name,Score=score,Avatar=avatar}
end
render()
