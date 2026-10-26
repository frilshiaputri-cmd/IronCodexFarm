-- Airflow-style dashboard replica for IronCodexFarm
-- Visual recreation based on the user-provided screenshot; not the original Airflow source.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local LP=Players.LocalPlayer
local A={}
local C={bg=Color3.fromRGB(15,15,15),side=Color3.fromRGB(20,20,20),card=Color3.fromRGB(25,25,25),selected=Color3.fromRGB(43,43,43),border=Color3.fromRGB(44,44,44),text=Color3.fromRGB(242,242,245),muted=Color3.fromRGB(145,145,150),purple=Color3.fromRGB(143,161,255)}
local function make(class,props,parent) local o=Instance.new(class); for k,v in pairs(props or {}) do pcall(function() o[k]=v end) end; o.Parent=parent; return o end
local function round(o,n) make("UICorner",{CornerRadius=UDim.new(0,n or 12)},o) end
local function outline(o) make("UIStroke",{Color=C.border,Thickness=1,Transparency=.12},o) end
local function text(parent,s,size,color,font)
 return make("TextLabel",{BackgroundTransparency=1,Text=tostring(s or ""),TextSize=size or 14,TextColor3=color or C.text,Font=font or Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true,Size=UDim2.new(1,0,0,size+8)},parent)
end
local function card(parent,h)
 local f=make("Frame",{BackgroundColor3=C.card,BorderSizePixel=0,Size=UDim2.new(1,0,0,h or 0)},parent); round(f,15); outline(f); return f
end
local icons={Home="⌂",Main="⌂",["Auto Farm"]="♧",Redeem="♔",Settings="⚙",house="⌂",["tree-pine"]="♧",gift="♔",settings="⚙"}
function A:CreateWindow(opt)
 opt=opt or {}; local pg=LP:WaitForChild("PlayerGui"); local old=pg:FindFirstChild("AirflowDashboard"); if old then old:Destroy() end
 local sg=make("ScreenGui",{Name="AirflowDashboard",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=50},pg)
 local root=make("Frame",{Name="Window",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=opt.Size or UDim2.fromOffset(1060,560),BackgroundColor3=C.bg,BorderSizePixel=0,ClipsDescendants=true},sg); round(root,18); outline(root)
 make("UISizeConstraint",{MinSize=Vector2.new(320,360),MaxSize=Vector2.new(1240,820)},root)
 local side=make("Frame",{BackgroundColor3=C.side,BorderSizePixel=0,Size=UDim2.new(0,205,1,0)},root)
 local logo=make("ImageLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(15,19),Size=UDim2.fromOffset(35,35),Image=tostring(opt.Icon or ""),ScaleType=Enum.ScaleType.Fit},side)
 local title=text(side,opt.Name or "IronCodexFarm",15,C.text,Enum.Font.GothamSemibold); title.Position=UDim2.fromOffset(62,18); title.Size=UDim2.new(1,-70,0,24)
 local sub=text(side,opt.LoadingSubtitle or "Airflow UI",11,C.muted); sub.Position=UDim2.fromOffset(62,42); sub.Size=UDim2.new(1,-70,0,20); sub.TextTruncate=Enum.TextTruncate.AtEnd
 local nav=make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(10,83),Size=UDim2.new(1,-20,1,-180),ScrollBarThickness=2,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},side)
 make("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},nav)
 make("Frame",{BackgroundColor3=C.border,BorderSizePixel=0,Position=UDim2.new(0,14,1,-102),Size=UDim2.new(1,-28,0,1)},side)
 local profile=make("Frame",{BackgroundColor3=C.card,Position=UDim2.new(0,10,1,-88),Size=UDim2.new(1,-20,0,72)},side); round(profile,13); outline(profile)
 local av=make("ImageLabel",{BackgroundColor3=C.selected,Position=UDim2.fromOffset(10,14),Size=UDim2.fromOffset(42,42),Image=""},profile); round(av,21)
 pcall(function() av.Image=Players:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
 local pn=text(profile,LP.DisplayName,12,C.text,Enum.Font.GothamSemibold); pn.Position=UDim2.fromOffset(60,11); pn.Size=UDim2.new(1,-75,0,22)
 local place=text(profile,game.Name or "Current Experience",10,C.muted); place.Position=UDim2.fromOffset(60,34); place.Size=UDim2.new(1,-75,0,20)
 local content=make("Frame",{BackgroundTransparency=1,Position=UDim2.new(0,205,0,0),Size=UDim2.new(1,-205,1,0)},root)
 local top=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(28,18),Size=UDim2.new(1,-56,0,48)},content)
 local picon=text(top,"⌂",30,C.purple); picon.Size=UDim2.fromOffset(36,42)
 local ptitle=text(top,"Home",26,C.text,Enum.Font.GothamMedium); ptitle.Position=UDim2.fromOffset(42,0); ptitle.Size=UDim2.new(.5,0,0,42)
 local search=make("TextBox",{PlaceholderText="⌕  Search",Text="",ClearTextOnFocus=false,TextSize=14,Font=Enum.Font.Gotham,TextColor3=C.text,PlaceholderColor3=C.muted,BackgroundColor3=C.bg,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-36,0,5),Size=UDim2.fromOffset(190,36)},top); round(search,10); outline(search)
 local expand=make("TextButton",{Text="⛶",TextSize=23,Font=Enum.Font.Gotham,TextColor3=C.muted,BackgroundTransparency=1,Size=UDim2.fromOffset(30,36),Position=UDim2.new(1,-30,0,5)},top)
 expand.MouseButton1Click:Connect(function() root.Size=root.Size.X.Scale>.9 and UDim2.new(.82,0,.91,0) or UDim2.new(.96,0,.96,0) end)
 local pages=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(28,78),Size=UDim2.new(1,-56,1,-96)},content)
 local win={Screen=sg,Root=root,Tabs={},Pages=pages}; setmetatable(win,{__index=A})
 local function selectTab(t) ptitle.Text=t.Name; picon.Text=icons[t.Icon] or icons[t.Name] or "•"; for _,v in ipairs(win.Tabs) do v.Page.Visible=v==t; v.Button.BackgroundColor3=v==t and C.selected or C.side; v.Button.TextColor3=v==t and C.text or C.muted end end
 function win:CreateTab(o)
  o=o or {}; local name=o.Name or "Tab"; local page=make("ScrollingFrame",{Name=name:gsub("%W","").."Page",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Visible=false,ScrollBarThickness=3,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},pages)
  make("UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},page)
  local t={Name=name,Icon=o.Icon or name,Page=page,Groups={}}; setmetatable(t,{__index=A}); t.Window=win
  local b=make("TextButton",{AutoButtonColor=false,Text=(icons[t.Icon] or icons[name] or "•").."    "..name,TextSize=14,Font=Enum.Font.Gotham,TextColor3=C.muted,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=C.side,Size=UDim2.new(1,0,0,43)},nav); round(b,11); make("UIPadding",{PaddingLeft=UDim.new(0,14)},b); b.LayoutOrder=#win.Tabs+1; b.MouseButton1Click:Connect(function() selectTab(t) end); t.Button=b
  function t:CreateGroupbox(go)
   go=go or {}; local g={Name=go.Name or "Group",Side=go.Side or "Left",Tab=t,Controls={},_count=0}; setmetatable(g,{__index=A})
   local f=card(page,0); f.AutomaticSize=Enum.AutomaticSize.Y; f.Size=UDim2.new(1,0,0,0); g.Frame=f
   local h=text(f,g.Name,15,C.text,Enum.Font.GothamSemibold); h.Position=UDim2.fromOffset(17,10); h.Size=UDim2.new(1,-34,0,26)
   local c=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(16,43),Size=UDim2.new(1,-32,0,0),AutomaticSize=Enum.AutomaticSize.Y},f)
   make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},c); make("UIPadding",{PaddingBottom=UDim.new(0,15)},f); g.Container=c; table.insert(t.Groups,g); return g
  end
  table.insert(win.Tabs,t); if #win.Tabs==1 then selectTab(t) end; return t
 end
 function win:Notify(o)
  o=o or {}; local f=make("Frame",{BackgroundColor3=C.selected,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-20,0,20),Size=UDim2.fromOffset(270,76),ZIndex=100},sg); round(f,12); outline(f)
  local a=text(f,o.Title or "Notice",14,C.text,Enum.Font.GothamSemibold); a.Position=UDim2.fromOffset(14,8); a.Size=UDim2.new(1,-28,0,22)
  local b=text(f,o.Content or "",12,C.muted); b.Position=UDim2.fromOffset(14,31); b.Size=UDim2.new(1,-28,0,35)
  task.delay(tonumber(o.Duration) or 4,function() if f.Parent then f:Destroy() end end); return f
 end
 function win:Destroy() sg:Destroy() end
 local open=make("TextButton",{Text="▦",TextSize=31,TextColor3=C.purple,BackgroundColor3=C.bg,AutoButtonColor=false,Size=UDim2.fromOffset(64,64),Position=UDim2.new(0,22,.5,-32),Visible=false},sg); round(open,18); outline(open)
 open.MouseButton1Click:Connect(function() root.Visible=true; open.Visible=false end)
 UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode.Name==(opt.ToggleUIKeybind or "RightShift") then root.Visible=not root.Visible; open.Visible=not root.Visible end end)
 local home=win:CreateTab({Name="Home",Icon="house"})
 local welcome=card(home.Page,168)
 local wl=text(welcome,"WELCOME BACK",11,C.muted,Enum.Font.GothamMedium); wl.Position=UDim2.fromOffset(22,16); wl.Size=UDim2.new(1,-44,0,20)
 local dn=text(welcome,LP.DisplayName,26,C.text,Enum.Font.GothamSemibold); dn.Position=UDim2.fromOffset(22,39); dn.Size=UDim2.new(1,-175,0,38)
 local un=text(welcome,"@"..LP.Name,14,C.muted); un.Position=UDim2.fromOffset(22,78); un.Size=UDim2.new(1,-175,0,24)
 local pills=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(22,115),Size=UDim2.new(1,-44,0,32)},welcome)
 for i,s in ipairs({"✦  Free","◉  Name","♙  Avatar"}) do local b=make("TextButton",{Text=s,TextSize=12,Font=Enum.Font.GothamMedium,TextColor3=i==1 and C.purple or C.muted,BackgroundColor3=C.selected,AutoButtonColor=false,Position=UDim2.fromOffset((i-1)*88,0),Size=UDim2.fromOffset(i==3 and 88 or 82,32)},pills); round(b,9) end
 local wa=make("ImageLabel",{BackgroundTransparency=1,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-15,.5,4),Size=UDim2.fromOffset(130,130),Image="",ScaleType=Enum.ScaleType.Fit},welcome)
 pcall(function() wa.Image=Players:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.AvatarBust,Enum.ThumbnailSize.Size150x150) end)
 local stats=card(home.Page,188)
 local fl=text(stats,"FPS",12,C.muted); fl.Position=UDim2.fromOffset(20,13); fl.Size=UDim2.fromOffset(100,20)
 local fv=text(stats,"— fps",24,C.text,Enum.Font.GothamMedium); fv.Position=UDim2.fromOffset(20,34); fv.Size=UDim2.fromOffset(140,32)
 local pl=text(stats,"Ping",12,C.muted); pl.Position=UDim2.new(.57,0,0,13); pl.Size=UDim2.fromOffset(90,20)
 local pv=text(stats,"— ms",24,C.text,Enum.Font.GothamMedium); pv.Position=UDim2.new(.57,0,0,34); pv.Size=UDim2.fromOffset(140,32)
 local bars=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(20,88),Size=UDim2.new(1,-40,0,28)},stats)
 for i=1,68 do make("Frame",{BackgroundColor3=i<35 and Color3.fromRGB(112,75,78) or Color3.fromRGB(80,113,91),BorderSizePixel=0,AnchorPoint=Vector2.new(0,1),Position=UDim2.new((i-1)/68,0,1,0),Size=UDim2.new(0,3,0,i<35 and math.random(5,25) or 17)},bars) end
 make("Frame",{BackgroundColor3=C.border,BorderSizePixel=0,Position=UDim2.fromOffset(20,123),Size=UDim2.new(1,-40,0,1)},stats)
 local metrics={{"Players",#Players:GetPlayers().."/"..Players.MaxPlayers},{"Execs","—"},{"Session","00m 00s"}}
 local started=os.clock()
 for i,m in ipairs(metrics) do local x=(i-1)*.32+.02; local v=text(stats,m[2],15,C.text,Enum.Font.GothamSemibold); v.Position=UDim2.new(x,0,0,134); v.Size=UDim2.new(.28,0,0,22); local c=text(stats,m[1],12,C.muted); c.Position=UDim2.new(x,0,0,156); c.Size=UDim2.new(.28,0,0,18); if m[1]=="Session" then task.spawn(function() while sg.Parent do task.wait(1); if c.Parent then local e=math.floor(os.clock()-started); v.Text=string.format("%dm %02ds",math.floor(e/60),e%60) end end end) end end
 local gamecard=card(home.Page,88); local gt=text(gamecard,game.Name or "Current Experience",15,C.text,Enum.Font.GothamSemibold); gt.Position=UDim2.fromOffset(92,18); gt.Size=UDim2.new(1,-110,0,24)
 local gs=text(gamecard,"by Roblox  ·  "..#Players:GetPlayers().."/"..Players.MaxPlayers.." players",12,C.muted); gs.Position=UDim2.fromOffset(92,43); gs.Size=UDim2.new(1,-110,0,20)
 local thumb=make("ImageLabel",{BackgroundColor3=C.selected,BorderSizePixel=0,Position=UDim2.fromOffset(18,16),Size=UDim2.fromOffset(56,56),Image=""},gamecard); round(thumb,11)
 selectTab(home)
 task.spawn(function() while sg.Parent do task.wait(1); local ping=0; pcall(function() ping=math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end); pv.Text=tostring(ping).." ms"; end end)
 return win
end
local function add(g,h)
 g._count=(g._count or 0)+1
 local f=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h or 34),LayoutOrder=g._count},g.Container); table.insert(g.Controls,f); return f
end
function A:CreateLabel(s)
 local f=add(self,30); local l=text(f,s,13,C.muted); l.Size=UDim2.fromScale(1,1)
 return {Instance=l,SetText=function(_,v) l.Text=tostring(v or "") end,Destroy=function() f:Destroy() end}
end
function A:CreateParagraph(o)
 o=o or {}; local f=add(self,66); local t=text(f,o.Title or "Information",13,C.text,Enum.Font.GothamSemibold); t.Size=UDim2.new(1,0,0,23)
 local b=text(f,o.Content or "",12,C.muted); b.Position=UDim2.fromOffset(0,24); b.Size=UDim2.new(1,0,0,38); b.TextYAlignment=Enum.TextYAlignment.Top
 return {Instance=f,SetText=function(_,v) b.Text=tostring(v or "") end}
end
function A:CreateToggle(o)
 o=o or {}; local f=add(self,42); local l=text(f,o.Name or "Toggle",13,C.text); l.Size=UDim2.new(1,-70,1,0)
 local track=make("TextButton",{Text="",AutoButtonColor=false,BackgroundColor3=o.Default and C.purple or C.selected,AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,0,.5,0),Size=UDim2.fromOffset(43,24)},f); round(track,13)
 local knob=make("Frame",{BackgroundColor3=Color3.fromRGB(245,245,245),Size=UDim2.fromOffset(18,18),Position=o.Default and UDim2.new(1,-21,0,3) or UDim2.fromOffset(3,3)},track); round(knob,9)
 local value=o.Default==true
 local function set(v,fire) value=v==true; Tween:Create(track,TweenInfo.new(.12),{BackgroundColor3=value and C.purple or C.selected}):Play(); Tween:Create(knob,TweenInfo.new(.12),{Position=value and UDim2.new(1,-21,0,3) or UDim2.fromOffset(3,3)}):Play(); if fire and type(o.Callback)=="function" then task.spawn(o.Callback,value) end end
 track.MouseButton1Click:Connect(function() set(not value,true) end)
 return {Instance=track,GetState=function() return value end,SetState=function(_,v) set(v,true) end,Flag=o.Flag}
end
function A:CreateButton(o)
 o=o or {}; local f=add(self,38); local b=make("TextButton",{Text=o.Name or "Button",TextSize=13,Font=Enum.Font.GothamMedium,TextColor3=C.text,BackgroundColor3=C.selected,AutoButtonColor=false,Size=UDim2.fromScale(1,1)},f); round(b,9)
 b.MouseButton1Click:Connect(function() if type(o.Callback)=="function" then task.spawn(o.Callback) end end); return {Instance=b}
end
function A:CreateInput(o)
 o=o or {}; local f=add(self,38); local b=make("TextBox",{Text=o.Default or "",PlaceholderText=o.Placeholder or o.Name or "Enter text",TextSize=13,Font=Enum.Font.Gotham,TextColor3=C.text,PlaceholderColor3=C.muted,BackgroundColor3=C.bg,BorderSizePixel=0,ClearTextOnFocus=false,Size=UDim2.fromScale(1,1)},f); round(b,9); outline(b)
 b.FocusLost:Connect(function(enter) if type(o.Callback)=="function" then task.spawn(o.Callback,b.Text,enter) end end); return {Instance=b,GetValue=function() return b.Text end,SetValue=function(_,v) b.Text=tostring(v) end}
end
function A:CreateDropdown(o)
 o=o or {}; local values=o.Options or o.Values or {}; local i=1; local val=o.Default or values[1] or "Select"; for n,v in ipairs(values) do if v==val then i=n end end
 local f=add(self,38); local b=make("TextButton",{Text=(o.Name or "Dropdown")..": "..tostring(val),TextSize=13,Font=Enum.Font.Gotham,TextColor3=C.text,BackgroundColor3=C.selected,AutoButtonColor=false,Size=UDim2.fromScale(1,1)},f); round(b,9)
 b.MouseButton1Click:Connect(function() if #values>0 then i=i%#values+1; val=values[i]; b.Text=(o.Name or "Dropdown")..": "..tostring(val); if type(o.Callback)=="function" then task.spawn(o.Callback,val) end end end); return {Instance=b,GetValue=function() return val end}
end
function A:CreateSlider(o)
 o=o or {}; local mn=tonumber(o.Min) or 0; local mx=tonumber(o.Max) or 100; local val=math.clamp(tonumber(o.Default) or mn,mn,mx); local f=add(self,58)
 local t=text(f,(o.Name or "Slider")..": "..val,13,C.text); t.Size=UDim2.new(1,0,0,23)
 local bar=make("TextButton",{Text="",AutoButtonColor=false,BackgroundColor3=C.selected,Position=UDim2.fromOffset(0,31),Size=UDim2.new(1,0,0,8)},f); round(bar,4)
 local fill=make("Frame",{BackgroundColor3=C.purple,BorderSizePixel=0,Size=UDim2.new((val-mn)/math.max(mx-mn,1),0,1,0)},bar); round(fill,4)
 bar.MouseButton1Click:Connect(function() local pct=math.clamp((UIS:GetMouseLocation().X-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1); val=math.floor(mn+(mx-mn)*pct+.5); fill.Size=UDim2.new((val-mn)/math.max(mx-mn,1),0,1,0); t.Text=(o.Name or "Slider")..": "..val; if type(o.Callback)=="function" then task.spawn(o.Callback,val) end end)
 return {GetValue=function() return val end}
end
function A:CreateKeybind(o)
 o=o or {}; local f=add(self,38); local key=o.Default; local b=make("TextButton",{Text=(o.Name or "Keybind").." ["..tostring(key or "None").."]",TextSize=13,Font=Enum.Font.Gotham,TextColor3=C.text,BackgroundColor3=C.selected,AutoButtonColor=false,Size=UDim2.fromScale(1,1)},f); round(b,9)
 local waiting=false; b.MouseButton1Click:Connect(function() waiting=true; b.Text=(o.Name or "Keybind").." [Press key]" end)
 local con; con=UIS.InputBegan:Connect(function(input,processed) if waiting and input.UserInputType==Enum.UserInputType.Keyboard then key=input.KeyCode.Name; waiting=false; b.Text=(o.Name or "Keybind").." ["..key.."]"; if type(o.Callback)=="function" then task.spawn(o.Callback,key) end elseif not processed and key and input.KeyCode.Name==key and type(o.Callback)=="function" then task.spawn(o.Callback,key) end end)
 return {GetValue=function() return key end,Destroy=function() con:Disconnect(); f:Destroy() end}
end
return setmetatable(A,A)
