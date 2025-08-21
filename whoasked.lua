local noobworkspace = game:GetService("Workspace")
local plrservicets = game:GetService("Players")
local me = plrservicets.LocalPlayer
local RunService = game:GetService("RunService")

local function guiprotectionfunctionts(gui)
    if get_hidden_gui or gethui then
        local hiddenui = get_hidden_gui or gethui
        gui.Parent = hiddenui()
    elseif (syn and syn.protect_gui) then
        syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
    else
        gui.Parent = game:GetService("CoreGui")
    end
end

local function GetCamera() 
    return noobworkspace.CurrentCamera
end 

local function GetDistance(Part) 
    if me.Character and me.Character:FindFirstChild("HumanoidRootPart") and Part~=nil then
        if Part:IsA("Model") and  Part.PrimaryPart~=nil then 
          return math.floor((me.Character.HumanoidRootPart.Position - Part.PrimaryPart.Position).Magnitude)
        else
            return math.floor((me.Character.HumanoidRootPart.Position - Part.Position).Magnitude)
        end 
    end

    return 0
end 

local function IsFriendly(Part)
    local PlayerFound = nil 
    if Part.Parent and Part.Parent:FindFirstChild("HumanoidRootPart") then 
        PlayerFound = plrservicets:GetPlayerFromCharacter(Part.Parent)
    end

    if PlayerFound and PlayerFound.Team ~= nil and me.Team ~= nil then 
        return PlayerFound.Team == me.Team
    end

    return false 
end

local function GetHealth(Part)
    local PlayerFound = nil 

    if Part.Parent and Part.Parent:FindFirstChild("HumanoidRootPart") then 
        PlayerFound = plrservicets:GetPlayerFromCharacter(Part.Parent)
    end

    if PlayerFound then 
      if PlayerFound.Character and PlayerFound.Character:FindFirstChild("HumanoidRootPart") and PlayerFound.Character:FindFirstChild("Humanoid") then 
        local Humanoid = PlayerFound.Character:FindFirstChild("Humanoid")
        return math.floor(Humanoid.Health),math.floor(Humanoid.MaxHealth)
      else 
        return 0,100
      end 
    end     

    return 0,100
end 

getgenv().LazyESP = {
    Components = {},
    Drawings = {},
    Utils = {
        ["GetCamera"] = GetCamera,
        ["GetDistance"] = GetDistance, 
        ["IsFriendly"] = IsFriendly,
        ["GetHealth"] = GetHealth,
        ["ProtectGui"] = guiprotectionfunctionts
    }
}

LazyESP.UpdateDrawingComponent = function(ComponentName, PropertyToUpdate, NewValue)
    LazyESP.Components[ComponentName][PropertyToUpdate] = NewValue
end 

LazyESP.GetDrawingColor = function(Part, DefaultColor, TeamCheck)
    local IsPlayerFriendly = LazyESP.Utils.IsFriendly(Part)

    if TeamCheck == true and IsPlayerFriendly == true then 
        return Color3.fromRGB(135, 206, 235)
    elseif TeamCheck == true and IsPlayerFriendly == false then 
        return Color3.fromRGB(255, 165, 0)
    end

    return DefaultColor  
end

LazyESP.Get2DPosition = function(Camera, PartPosition)
    local MyCamera = GetCamera()

    local Vector, Visible = MyCamera:WorldToViewportPoint(PartPosition)
    return Vector3.new(Vector.X, Vector.Y, Vector.Z), Visible
end

LazyESP.CreateComponent = function(ComponentData)
    LazyESP.Components[ComponentData.ComponentName] = {
        ["Enabled"] = ComponentData.Enabled or false,
        ["TeamCheck"] = ComponentData.ESPMetaData.TeamCheck or false,
        ["ShowTracers"] = ComponentData.ESPMetaData.ShowTracers or false,
        ["TracerColor"] = ComponentData.ESPMetaData.TracerColor or Color3.fromRGB(255, 165, 0),
        ["TracerTextColor"] = ComponentData.ESPMetaData.TracerTextColor or Color3.fromRGB(255, 165, 0),
        ["ShowCharacterBox"] = ComponentData.ESPMetaData.ShowCharacterBox or false,
        ["CharacterBoxColor"] = ComponentData.ESPMetaData.CharacterBoxColor or Color3.fromRGB(255, 165, 0),
        ["ShowHighlight"] = ComponentData.ESPMetaData.ShowHighlight or false,
        ["HighlightColor"] = ComponentData.ESPMetaData.HighlightColor or Color3.fromRGB(255, 165, 0),
        ["RenderDistance"] = ComponentData.ESPMetaData.RenderDistance or 999999
    }
end 

LazyESP.DestroyDrawing = function(DrawingType,DrawingToUpdate)
    if DrawingType == "Drawing" then 
        DrawingToUpdate.Visible = false
        DrawingToUpdate:Destroy()
    elseif DrawingType == "Highlight" then 
        DrawingToUpdate.Enabled = false
        DrawingToUpdate:Destroy()
    end
end 

LazyESP.RenderDrawing = function(DrawingType, ComponentMetaData, DrawingToUpdate, DrawingData)
    local MyCamera = GetCamera()
    local Part = DrawingData.Part 

    if Part ~= nil  and Part.Parent~=nil then        
        if DrawingType == "TracerLine" then
            local DrawingColor = LazyESP.GetDrawingColor(Part, ComponentMetaData.TracerColor, ComponentMetaData.TeamCheck)
            local To, Visible = LazyESP.Get2DPosition(MyCamera, Part.Position)
            local TracerLine = DrawingToUpdate[1]

            TracerLine.To = Vector2.new(To.X, To.Y)
            TracerLine.Color = DrawingColor

              TracerLine.Visible = Visible        
        elseif DrawingType == "TracerText" then
         if Part~=nil and Part.Parent~=nil then  
            local Distance = LazyESP.Utils.GetDistance(Part)
            local DrawingColor = LazyESP.GetDrawingColor(Part, ComponentMetaData.TracerTextColor, ComponentMetaData.TeamCheck)
            local To, Visible = LazyESP.Get2DPosition(MyCamera, Part.Position + Vector3.new(0,0,0)) 
            local TracerText = DrawingToUpdate[1]

            TracerText.Position = Vector2.new(To.X, To.Y+25)
            TracerText.Color = DrawingColor
            TracerText.Text = "Name: " .. DrawingData.Text .. " | Distance: " .. tostring(Distance)
            TracerText.Visible = Visible
        end 

        elseif DrawingType == "CharacterBox" then
            if Part~=nil and Part.Parent~=nil and Part.Parent:FindFirstChild("HumanoidRootPart") and Part.Parent:FindFirstChild("Head")  then
                local DrawingColor = LazyESP.GetDrawingColor(Part.Parent.HumanoidRootPart, ComponentMetaData.CharacterBoxColor, ComponentMetaData.TeamCheck)
                local Health,MaxHealth = LazyESP.Utils.GetHealth(Part.Parent.HumanoidRootPart)
                local RootTo, RootVisible = LazyESP.Get2DPosition(MyCamera, Part.Parent.HumanoidRootPart.Position)
                local HeadTo, HeadVisible = LazyESP.Get2DPosition(MyCamera, Part.Parent.Head.Position + Vector3.new(0, 0.5, 0))  
                local FeetPosition =  nil 

                if Part.Parent and Part.Parent:FindFirstChild("LowerTorso") then 
                  FeetPosition  = Part.Parent.LowerTorso.Position
                elseif Part.Parent and Part.Parent:FindFirstChild("HumanoidRootPart") then 
                    FeetPosition = Part.Parent.HumanoidRootPart.Position
                end 

                if FeetPosition~=nil then 
                local FeetTo, FeetVisible = LazyESP.Get2DPosition(MyCamera, FeetPosition - Vector3.new(0, 3, 0))  

                local BoxHeight = math.abs(HeadTo.Y - FeetTo.Y)  
                local BoxWidth = 2350 / RootTo.Z  

                local CharacterBox = DrawingToUpdate[1]
                local HealthBar = DrawingToUpdate[2]

                CharacterBox.Position = Vector2.new(RootTo.X - BoxWidth / 2, HeadTo.Y)
                CharacterBox.Size = Vector2.new(BoxWidth, BoxHeight)
                CharacterBox.Color = DrawingColor
                CharacterBox.Visible = RootVisible 

                local healthBarHeight = math.abs(HeadTo.Y - FeetTo.Y)
                local healthOffset = Health / MaxHealth * healthBarHeight
                local healthBarX = RootTo.X - BoxWidth / 2 - (BoxWidth * 0.1) 
                
                HealthBar.From = Vector2.new(healthBarX, HeadTo.Y + BoxHeight + 2)
                HealthBar.To = Vector2.new(healthBarX, HeadTo.Y + BoxHeight + 2 - healthOffset)
                
                if Health>50 then 
                  HealthBar.Color = Color3.fromRGB(22, 199, 81)
                else 
                    HealthBar.Color = Color3.fromRGB(186, 22, 22)
                end 

        
                HealthBar.Visible = RootVisible
            end 
            end 

        elseif DrawingType == "Highlight" then 
            if Part~=nil and Part.Parent~=nil then  
                local DrawingColor = LazyESP.GetDrawingColor(Part, ComponentMetaData.HighlightColor, ComponentMetaData.TeamCheck)

                local Highlight = DrawingToUpdate[1]
                
                if Highlight.Adornee == nil then 
                    Highlight.Adornee  = Part.Parent
                end

                Highlight.FillColor = DrawingColor
                Highlight.OutlineColor = DrawingColor
                Highlight.Enabled = true 
            end 
        end
    end
end


LazyESP.DrawESP = function(DrawingMetaData)
    for i, v in pairs(LazyESP.Drawings) do 
        if v.DrawingIndex == DrawingMetaData.ESPMetaData.DrawingIndex then 
            LazyESP.DestroyDrawing("Drawing",v.Drawings.TracerLine)
            LazyESP.DestroyDrawing("Drawing",v.Drawings.TracerText)
            LazyESP.DestroyDrawing("Drawing",v.Drawings.CharacterBox)
            LazyESP.DestroyDrawing("Drawing",v.Drawings.HealthBarLine)
            LazyESP.DestroyDrawing("Highlight",v.Drawings.Highlight)
            LazyESP.Drawings[i] = nil 
        end
    end 
    
    local MyCamera = GetCamera()

    if not MyCamera then 
        return 
    end 

    local TracerLine = Drawing.new("Line")
    TracerLine.Thickness = 1
    TracerLine.Transparency = 1
    TracerLine.ZIndex = 1
    TracerLine.From = Vector2.new(MyCamera.ViewportSize.X / 2, MyCamera.ViewportSize.Y / 1)
    TracerLine.Visible = false 

    local TracerText = Drawing.new("Text")
    TracerText.Center = true
    TracerText.Outline = true
    TracerText.Font = 2
    TracerText.Size = 15
    TracerText.Visible = false


    local CharacterBox = Drawing.new("Square")
    CharacterBox.Thickness = 1
    CharacterBox.Filled = false
    CharacterBox.Transparency = 1
    CharacterBox.Visible = false 

    local HealthBarLine = Drawing.new("Line")
    HealthBarLine.Thickness = 3
    HealthBarLine.Transparency = 1
    HealthBarLine.ZIndex = 1
    HealthBarLine.From = Vector2.new(0,0)
    HealthBarLine.Visible = false 

    local CharacterHighlight = Instance.new("Highlight")
    CharacterHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
    CharacterHighlight.FillColor = Color3.fromRGB(255, 165, 0) 
    CharacterHighlight.FillTransparency = 0.3 
    CharacterHighlight.OutlineColor = Color3.fromRGB(255, 165, 0) 
    CharacterHighlight.OutlineTransparency = 0 
    CharacterHighlight.Enabled = false 
    CharacterHighlight.Name = "Part"
    LazyESP.Utils.ProtectGui(CharacterHighlight)
    
    LazyESP.Drawings[DrawingMetaData.DrawingIndex] = {
        ["ComponentName"] = DrawingMetaData.ComponentName,
        ["DrawingIndex"] = DrawingMetaData.DrawingIndex,
        ["Drawings"] = {
            ["TracerLine"] = TracerLine,
            ["TracerText"] = TracerText,
            ["CharacterBox"] = CharacterBox,
            ["HealthBarLine"] = HealthBarLine,
            ["Highlight"] = CharacterHighlight
        },
        ["ESPMetaData"] = DrawingMetaData.ESPMetaData
    }
end

LazyESP.UpdateESPDrawings = function()      
    for i, v in pairs(LazyESP.Drawings) do
        if not v.DrawingIndex or not v.DrawingIndex:IsDescendantOf(noobworkspace) then
            LazyESP.DestroyDrawing("Drawing",v.Drawings.TracerLine)
            LazyESP.DestroyDrawing("Drawing",v.Drawings.TracerText)
            LazyESP.DestroyDrawing("Drawing",v.Drawings.CharacterBox)
            LazyESP.DestroyDrawing("Drawing",v.Drawings.HealthBarLine)
            LazyESP.DestroyDrawing("Highlight",v.Drawings.Highlight)
            LazyESP.Drawings[i] = nil 
        else
            local ComponentDataFound = LazyESP.Components[v.ComponentName]
            local RenderDistance = ComponentDataFound.RenderDistance

            if ComponentDataFound and ComponentDataFound.Enabled == true then
                if ComponentDataFound.ShowTracers and v.ESPMetaData.Tracer and v.ESPMetaData.Tracer.Part and v.ESPMetaData.Tracer.Part.Parent~=nil then
                    local Distance = LazyESP.Utils.GetDistance(v.ESPMetaData.Tracer.Part)
                    if Distance<=RenderDistance then 
                       LazyESP.RenderDrawing("TracerLine", ComponentDataFound,{v.Drawings.TracerLine}, v.ESPMetaData.Tracer)
                    else
                        v.Drawings.TracerLine.Visible = false 
                    end
                else
                    v.Drawings.TracerLine.Visible = false 
                end
                
                if v.ESPMetaData.TracerText and v.ESPMetaData.TracerText.Part and  v.ESPMetaData.TracerText.Part.Parent~=nil then
                    local Distance = LazyESP.Utils.GetDistance(v.ESPMetaData.TracerText.Part)
                    if Distance<=RenderDistance then 
                      LazyESP.RenderDrawing("TracerText", ComponentDataFound,{v.Drawings.TracerText}, v.ESPMetaData.TracerText)
                    else
                        v.Drawings.TracerText.Visible = false 
                    end
                else
                    v.Drawings.TracerText.Visible = false 
                end

                if ComponentDataFound.ShowCharacterBox == true and v.ESPMetaData.CharacterBox and v.ESPMetaData.CharacterBox.Part and v.ESPMetaData.CharacterBox.Part.Parent~=nil and v.ESPMetaData.CharacterBox.Part.Parent:FindFirstChild("HumanoidRootPart")  then
                    local Distance = LazyESP.Utils.GetDistance(v.ESPMetaData.CharacterBox.Part)
                    local Health,MaxHealth = LazyESP.Utils.GetHealth(v.ESPMetaData.CharacterBox.Part.Parent.HumanoidRootPart)
                    if Distance<=RenderDistance and Health>0 then 
                    LazyESP.RenderDrawing("CharacterBox", ComponentDataFound,{v.Drawings.CharacterBox,v.Drawings.HealthBarLine}, v.ESPMetaData.CharacterBox)
                    else
                        v.Drawings.CharacterBox.Visible = false 
                        v.Drawings.HealthBarLine.Visible = false 
                    end 
                else
                    v.Drawings.CharacterBox.Visible = false 
                    v.Drawings.HealthBarLine.Visible = false 
                end

                if ComponentDataFound.ShowHighlight == true and v.ESPMetaData.Highlight and v.ESPMetaData.Highlight.Part and v.ESPMetaData.Highlight.Part.Parent~=nil then
                    local Distance = LazyESP.Utils.GetDistance(v.ESPMetaData.Highlight.Part)
                    if Distance<=RenderDistance then 
                    LazyESP.RenderDrawing("Highlight", ComponentDataFound,{v.Drawings.Highlight}, v.ESPMetaData.Highlight)
                    else 
                        v.Drawings.Highlight.Enabled = false
                    end
                else
                    v.Drawings.Highlight.Enabled = false
                end 


            else
                LazyESP.DestroyDrawing("Drawing",v.Drawings.TracerLine)
                LazyESP.DestroyDrawing("Drawing",v.Drawings.TracerText)
                LazyESP.DestroyDrawing("Drawing",v.Drawings.CharacterBox)
                LazyESP.DestroyDrawing("Drawing",v.Drawings.HealthBarLine)
                LazyESP.DestroyDrawing("Highlight",v.Drawings.Highlight)
                LazyESP.Drawings[i] = nil 
            end 
        end
    end
end


task.spawn(function()
    RunService.RenderStepped:Connect(function()
        LazyESP.UpdateESPDrawings()
    end)
end)





--LazyESP.UpdateDrawingComponent("Players", "ShowHighLight", false)
