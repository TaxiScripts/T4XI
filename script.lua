-- ======================
-- VISUALS TAB (OUTLINE, odświeżanie co 0.5s)
-- ======================
local Visuals = Window:NewTab("Visuals")
local ESPSection = Visuals:NewSection("ESP Settings")

local espEnabled = false
local espTeamCheck = true
local espColor = Color3.fromRGB(255,255,255)

local outlines = {}

ESPSection:NewToggle("ESP Enabled", "Draw outline around players", function(state)
    espEnabled = state
    if not state then
        for _, ol in pairs(outlines) do ol:Remove() end
        outlines = {}
    end
end)

ESPSection:NewToggle("Team Check", "Ignore teammates", function(state) espTeamCheck = state end)
ESPSection:NewColorPicker("Outline Color", "Color of outline", espColor, function(c) espColor = c end)

-- LOOP ODŚWIEŻANIA CO 0.5s
spawn(function()
    while true do
        if espEnabled then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                        if onScreen and (not espTeamCheck or plr.Team ~= player.Team) then
                            local ol = outlines[plr] or Drawing.new("Quad")
                            outlines[plr] = ol
                            ol.Color = espColor
                            ol.Thickness = 1
                            ol.Visible = true

                            local size = Vector2.new(30,60)
                            local pos = Vector2.new(screenPos.X, screenPos.Y)
                            ol.PointA = pos + Vector2.new(-size.X/2, -size.Y/2)
                            ol.PointB = pos + Vector2.new(size.X/2, -size.Y/2)
                            ol.PointC = pos + Vector2.new(size.X/2, size.Y/2)
                            ol.PointD = pos + Vector2.new(-size.X/2, size.Y/2)
                        elseif outlines[plr] then
                            outlines[plr].Visible = false
                        end
                    end
                end
            end
        end
        wait(0.5) -- odświeżanie co 0.5s
    end
end)
