local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()
local serverConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

function PoliceItems()
    plsr.Inventory.Items:RegisterUse(config.Items.detCord, "PDItems", function(source, slot, itemData)
        if plsr.State:Player(source).onDuty == "police" then
            plsr.Callbacks:ClientCallback(source, "Police:DoDetCord", {}, function(s, doorId)
                if s and plsr.Inventory.Items:RemoveSlot(slot.Owner, slot.Name, 1, slot.Slot, 1) then
                    plsr.Doors:SetLock(doorId, false)
                    plsr.Doors:DisableDoor(doorId, serverConfig.DetCordDoorDisableSec)
                end
            end)
        end
    end)
end
