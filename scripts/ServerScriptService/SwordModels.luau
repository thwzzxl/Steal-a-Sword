-- SwordModels V35 | Roube uma Espada | ModuleScript
local M = {}
local metal, plastic, neon = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Neon
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local dark, silver, gold = rgb(39,43,56), rgb(190,200,215), rgb(235,174,49)
local names = {Comum='Espada de Ferro', Incomum='Esmeralda', Rara='Frostbite', ['Épica']='Voidblade', ['Lendária']='Solaris'}
function M.Create(rarity)
	local model = Instance.new('Model')
	model.Name = rarity.Id or names[rarity.Name] or ('Espada '..rarity.Name)
	model:SetAttribute('Rarity',rarity.Name)
	model:SetAttribute('SwordId',rarity.Id)
	model:SetAttribute('Price',rarity.Price)
	model:SetAttribute('Income',rarity.Income)
	local function p(name,x,y,z,w,h,d,c,mat,angle,shape)
		local a=Instance.new(shape or 'Part')
		a.Name=name; a.Size=Vector3.new(w,h,d)
		a.CFrame=CFrame.new(x,y,z)*CFrame.Angles(0,0,math.rad(angle or 0))
		a.Color=c; a.Material=mat or metal; a.Anchored=true
		a.CanCollide=false; a.CanTouch=false; a.Massless=true; a.CastShadow=false
		a.TopSurface=Enum.SurfaceType.Smooth; a.BottomSurface=Enum.SurfaceType.Smooth
		a.Parent=model; return a
	end
	local handle=p('Handle',0,0,0,.48,2.1,.48,dark,plastic)
	local function guard(w,c) p('Guard',0,1.15,0,w,.35,.65,c) end
	local function blade(w,h,c,mat) p('Blade',0,1.32+h/2,0,w,h,.24,c,mat) end
	local function gem(y,c,s) p('Gem',0,y,.36,s,s,.25,c,neon,45) end
	local function tip(y,w,c) p('Tip',0,y,0,w,.75,.24,c,metal,0,'WedgePart') end
	p('Pommel',0,-1.12,0,.7,.35,.7,rarity.Color)
	-- IDs especiais primeiro, independentemente da raridade.
	if rarity.Id=='Bronze Blade' then
		local bronze=rgb(184,117,65)
		guard(2.0,bronze); blade(.95,3.5,bronze); tip(5.15,.95,bronze)
		p('Spine',0,3.05,.15,.22,3.2,.09,rgb(225,170,105),metal)
		p('GripBand',0,-.45,0,.56,.18,.56,bronze)
	elseif rarity.Id=='Knight Sword' then
		guard(2.9,silver); blade(1.15,4.15,silver); tip(5.85,1.15,silver)
		for _,side in ipairs({-1,1}) do p('Quillon',side*1.3,1.4,0,.45,.8,.55,gold,metal,-side*30) end
		p('Fuller',0,3.4,.15,.22,3.6,.07,dark,metal)
	elseif rarity.Id=='Crimson Blade' then
		local red=rgb(205,65,75)
		guard(2.5,dark); blade(1.05,4,red); tip(5.7,1.05,red)
		for _,side in ipairs({-1,1}) do p('RedWing',side*.95,1.7,0,.45,1.3,.4,red,metal,-side*35) end
		gem(1.3,rgb(255,110,100),.55)
	elseif rarity.Id=='Jade Katana' then
		local jade=rgb(65,185,135)
		p('Tsuba',0,1.15,0,1.5,.22,.95,gold,metal)
		p('KatanaBlade',.12,3.5,0,.65,4.4,.22,jade,metal,-4)
		p('KatanaTip',.29,5.85,0,.65,.65,.22,jade,metal,-4,'WedgePart')
		p('Edge',.37,3.5,.02,.12,4.35,.24,silver,metal,-4)
		for i=1,5 do p('Wrap',0,-.9+i*.34,.26,.36,.17,.08,jade,plastic,35) end
	elseif rarity.Id=='Thunder Blade' then
		local yellow=rgb(245,210,65)
		guard(2.7,dark); blade(1.15,4.15,silver); tip(5.85,1.15,silver)
		for i=1,5 do p('Bolt',0,1.7+i*.72,.16,.23,.85,.12,yellow,neon,(-1)^i*28) end
		for _,side in ipairs({-1,1}) do p('LightningGuard',side*1.05,1.65,0,.4,1.2,.45,yellow,metal,-side*35) end
	elseif rarity.Id=='Aquamarine' then
		local aqua=rgb(65,205,225)
		guard(2.6,silver); blade(1.35,4.25,aqua); tip(5.95,1.35,aqua)
		for _,side in ipairs({-1,1}) do
			p('Facet',side*.62,3.5,.04,.32,3.8,.32,rgb(145,240,245),metal,side*3)
			p('CrystalGuard',side*1.05,1.7,0,.5,1.25,.5,aqua,metal,-side*35,'WedgePart')
		end
		gem(1.3,rgb(200,255,255),.75)
	elseif rarity.Id=='Wooden Blade' then
		local wood=rgb(155,103,57)
		guard(2.1,rgb(105,66,35)); blade(.85,3.8,wood,Enum.Material.Wood); tip(5.45,.85,wood)
		for i=1,3 do p('Grain',0,2+i*.8,.14,.12,.55,.05,rgb(110,72,40),plastic,12) end
	elseif rarity.Id=='Venom Fang' then
		local green=rgb(75,190,65)
		guard(2.5,dark); blade(.95,4.1,green); tip(5.8,.95,green)
		for _,side in ipairs({-1,1}) do p('Fang',side*.65,2.1,0,.45,1.4,.35,green,metal,-side*30,'WedgePart') end
		p('VenomCore',0,3.4,.15,.2,3.5,.1,rgb(160,255,70),neon); gem(1.3,green,.6)
	elseif rarity.Id=='Glacier' then
		local ice=rgb(90,190,255)
		guard(2.7,silver); blade(1.3,4.4,ice); tip(6.1,1.3,ice)
		for _,side in ipairs({-1,1}) do
			p('Crystal',side*.7,3.1,0,.45,2.3,.4,ice,metal,side*18,'WedgePart')
			p('IceWing',side*1.05,1.5,0,.55,1.2,.5,silver,metal,-side*35)
		end
		p('GlacierCore',0,3.5,.16,.3,3.8,.1,rgb(220,250,255),neon)
	elseif rarity.Id=='Shadow Reaper' then
		local purple=rgb(145,55,220)
		guard(2.8,dark); blade(1.35,4.3,dark); tip(6,1.35,dark)
		for _,side in ipairs({-1,1}) do
			p('ReaperHook',side*1.1,2.1,0,.5,2.1,.4,purple,metal,-side*32,'WedgePart')
			p('ShadowEdge',side*.62,3.5,0,.15,4,.3,purple,neon)
		end
		gem(1.3,purple,.8)
	elseif rarity.Id=='Sunbreaker' then
		local fire=rgb(255,145,35)
		guard(3.2,gold); blade(1.45,4.4,gold); tip(6.1,1.45,gold)
		for _,side in ipairs({-1,1}) do
			p('SunRay',side*1.25,1.75,0,.5,1.7,.5,fire,metal,-side*42)
			p('SunEdge',side*.67,3.5,0,.16,4.1,.3,fire,neon)
		end
		gem(1.35,rgb(255,240,120),.85)
	elseif rarity.Id=='Oblivion' then
		local violet=rgb(155,85,255)
		guard(3.3,dark); blade(1.55,4.5,rgb(25,20,45)); tip(6.2,1.55,dark)
		for _,side in ipairs({-1,1}) do
			p('Orbit',side*1.15,3.2,0,.35,2.6,.35,violet,metal,side*25)
			p('Star',side*1.1,4.6,0,.35,.35,.35,rgb(220,180,255),neon,45)
		end
		p('VoidCore',0,3.6,.17,.38,4.1,.12,violet,neon); gem(1.3,violet,.95)
		local light=Instance.new('PointLight'); light.Color=violet; light.Range=9; light.Brightness=1.2; light.Parent=handle
	elseif rarity.Id=='Infernal' then
		local lava=rgb(255,95,25)
		guard(3.1,dark); blade(1.3,4.4,dark); tip(6.1,1.3,dark)
		for _,side in ipairs({-1,1}) do
			p('FlameEdge',side*.6,3.5,0,.22,4.1,.3,lava,neon)
			p('Horn',side*1.2,1.8,0,.5,1.8,.5,lava,metal,-side*35,'WedgePart')
		end
		for i=1,4 do p('LavaCrack',0,1.8+i*.85,.17,.16,.8,.08,lava,neon,(-1)^i*28) end
		gem(1.2,lava,.8)
	elseif rarity.Id=='Eclipse' then
		local violet=rgb(180,65,255)
		guard(3.2,dark); blade(1.45,4.3,dark); tip(6,1.45,dark)
		for _,side in ipairs({-1,1}) do
			p('Crescent',side*1.15,2.1,0,.4,2.4,.4,violet,metal,-side*30)
			p('Star',side*1.05,4.3,0,.35,.35,.35,violet,neon,45)
		end
		p('CosmicCore',0,3.5,.18,.35,3.9,.1,violet,neon)
		gem(1.3,rgb(255,120,230),.85)
	elseif rarity.Id=='Aether' then
		local cyan=rgb(110,235,255)
		guard(3.4,silver); blade(1.25,4.5,rgb(190,225,245)); tip(6.2,1.25,cyan)
		p('SpiritCore',0,3.6,.18,.3,4.2,.12,cyan,neon)
		for _,side in ipairs({-1,1}) do
			p('Wing',side*1.3,1.85,0,.55,1.9,.4,silver,metal,-side*42,'WedgePart')
			p('FloatingCrystal',side*1.15,3.6,0,.45,1.2,.45,cyan,neon,side*18)
		end
		gem(1.3,cyan,.95)
	elseif rarity.Name=='Comum' then
		guard(2.3,dark); blade(.72,4.1,silver); tip(5.8,.72,silver)
	elseif rarity.Name=='Incomum' then
		local green=rgb(40,170,100)
		guard(2.6,gold); blade(1.05,3.9,green); tip(5.6,1.05,green)
		p('Ridge',0,3.3,.15,.24,3.7,.12,rgb(145,255,188),plastic)
		gem(1.15,rgb(95,255,150),.48)
	elseif rarity.Name=='Rara' then
		local ice=rgb(113,207,255)
		guard(2.8,silver); blade(.85,4.2,ice); tip(5.9,.85,ice)
		for _,side in ipairs({-1,1}) do
			p('IceShard',side*.64,2.35,0,.48,1.65,.32,ice,metal,-side*24,'WedgePart')
			p('GuardWing',side*1.15,1.48,0,.48,1.05,.5,silver,metal,-side*38)
		end
		p('FrostCore',0,3.45,.16,.18,3.6,.1,rgb(205,245,255),neon)
	elseif rarity.Name=='Épica' then
		local purple=rgb(155,78,235)
		blade(1.15,4.05,dark); tip(5.75,1.15,dark); guard(2.1,dark)
		for _,side in ipairs({-1,1}) do
			p('VoidWing',side*1.05,1.55,0,.52,1.5,.55,purple,metal,-side*42)
			p('Edge',side*.53,3.35,0,.12,3.8,.27,purple,neon)
		end
		gem(1.4,purple,.62)
	elseif rarity.Name=='Lendária' then
		guard(3,gold); blade(1.2,4.25,gold); tip(5.95,1.2,gold)
		p('SolarCore',0,3.45,.16,.3,3.8,.12,rgb(255,235,160),neon)
		for _,side in ipairs({-1,1}) do p('SolarWing',side*1.25,1.65,0,.55,1.55,.55,gold,metal,-side*48) end
		gem(1.35,rgb(255,220,95),.7)
	else
		guard(2.3,dark); blade(.75,4.2,rarity.Color); tip(5.9,.75,rarity.Color)
	end
	model.PrimaryPart=handle
	for _,a in ipairs(model:GetChildren()) do
		if a:IsA('BasePart') and a~=handle then
			local weld=Instance.new('WeldConstraint')
			weld.Name='SwordWeld'; weld.Part0=handle; weld.Part1=a; weld.Parent=a
		end
	end
	return model
end
return M
