local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

function HandcuffItems()
	for _, entry in ipairs(config.CuffItems) do
		plsr.Inventory.Items:RegisterUse(entry.item, "Handcuffs", function(source, item)
			plsr.Callbacks:ClientCallback(source, "Handcuffs:VehCheck", {}, function(inVeh)
				if not inVeh then
					plsr.Handcuffs:ToggleCuffs(source)
				end
			end)
		end)
	end
end
