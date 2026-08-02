local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()
local serverConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

CreateThread(function()
	plsr.Callbacks:RegisterServerCallback("Government:BuyID", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if plsr.Wallet:Modify(source, -config.GovIdPrice) then
			plsr.Inventory:AddItem(char:GetData("SID"), serverConfig.Items.governmentId, 1, {}, 1)
		else
			plsr.Execute:Client(source, "Notification", "Error", "Not Enough Cash")
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Government:BuyLicense", function(source, data, cb)
		if config.Licenses[data] ~= nil then
			local char = plsr.Fetch:CharacterSource(source)
			local licenses = char:GetData("Licenses")
			if plsr.Wallet:Modify(source, -config.Licenses[data].price) then
				if licenses[config.Licenses[data].key] ~= nil and not licenses[config.Licenses[data].key].Active then
					licenses[config.Licenses[data].key].Active = true
					char:SetData("Licenses", licenses)

					plsr.Middleware:TriggerEvent("Characters:ForceStore", source)
				else
					plsr.Execute:Client(source, "Notification", "Error", "Unable To Purchase License")
				end
			else
				plsr.Execute:Client(source, "Notification", "Error", "Not Enough Cash")
			end
		else
			plsr.Logger:Error(
				"Government",
				string.format("%s Tried To Buy Invalid License Type %s", char:GetData("SID"), data),
				{
					console = true,
					discord = true,
				}
			)
			plsr.Execute:Client(source, "Notification", "Error", "Unable To Purchase License")
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Government:Client:DoWeaponsLicenseBuyPolice", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if plsr.Jobs.Permissions:HasJob(source, "police") and char then
			local licenses = char:GetData("Licenses")
			if plsr.Wallet:Modify(source, -config.PoliceWeaponsLicensePrice) then
				licenses["Weapons"].Active = true
				char:SetData("Licenses", licenses)
				plsr.Middleware:TriggerEvent("Characters:ForceStore", source)
			else
				plsr.Execute:Client(source, "Notification", "Error", "Not Enough Cash")
			end
		else
			plsr.Execute:Client(source, "Notification", "Error", "You are Not PD")
		end
	end)

	plsr.Inventory.Poly:Create(serverConfig.DojStorage)
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Government", _GOVT)
end)

_GOVT = {}

RegisterNetEvent("Government:Server:Gavel", function()
	TriggerClientEvent("Government:Client:Gavel", -1)
end)
