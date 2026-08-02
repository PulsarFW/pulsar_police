local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

AddEventHandler("Government:Client:OnDuty", function()
	plsr.Jobs.Duty:On("government")
end)

AddEventHandler("Government:Client:OffDuty", function()
	plsr.Jobs.Duty:Off("government")
end)

AddEventHandler("Government:Client:BuyID", function()
	plsr.Callbacks:ServerCallback("Government:BuyID")
end)

AddEventHandler("Government:Client:DoLicenseBuy", function(license)
	plsr.Callbacks:ServerCallback("Government:BuyLicense", license)
end)

AddEventHandler("Government:Client:DoWeaponsLicenseBuyPolice", function(license)
	plsr.Callbacks:ServerCallback("Government:Client:DoWeaponsLicenseBuyPolice", {})
end)

AddEventHandler("Government:Client:BuyLicense", function()
	local licenses = plsr.State.character.Licenses
	local items = {}

	if not licenses.Drivers.Active then
		if not licenses.Drivers.Suspended then
			table.insert(items, {
				label = config.Licenses.drivers.label,
				description = string.format("Renew Drivers License ($%s)", config.Licenses.drivers.price),
				event = "Government:Client:DoLicenseBuy",
				data = "drivers",
			})
		else
			table.insert(items, {
				label = config.Licenses.drivers.label,
				description = "Unable To Renew, License Is Suspended.",
			})
		end
	end

	if not licenses.Weapons.Active then
		if not licenses.Weapons.Suspended then
			if plsr.State.flags.onDuty == 'police' then
				table.insert(items, {
					label = "Weapons License (Police)",
					description = string.format("Purchase Weapons License ($%s)", config.PoliceWeaponsLicensePrice),
					event = "Government:Client:DoWeaponsLicenseBuyPolice",
					data = "weapons_police",
				})
			else
				table.insert(items, {
					label = config.Licenses.weapons.label,
					description = string.format("Purchase Weapons License ($%s)", config.Licenses.weapons.price),
					event = "Government:Client:DoLicenseBuy",
					data = "weapons",
				})
			end
		else
			table.insert(items, {
				label = config.Licenses.weapons.label,
				description = "Unable To Purchase, License Is Suspended.",
			})
		end
	end

	if not licenses.Hunting.Active then
		if not licenses.Hunting.Suspended then
			table.insert(items, {
				label = config.Licenses.hunting.label,
				description = string.format("Purchase Hunting License ($%s)", config.Licenses.hunting.price),
				event = "Government:Client:DoLicenseBuy",
				data = "hunting",
			})
		else
			table.insert(items, {
				label = config.Licenses.hunting.label,
				description = "Unable To Purchase, License Is Suspended.",
			})
		end
	end

	if not licenses.Fishing.Active then
		if not licenses.Fishing.Suspended then
			table.insert(items, {
				label = config.Licenses.fishing.label,
				description = string.format("Purchase Fishing License ($%s)", config.Licenses.fishing.price),
				event = "Government:Client:DoLicenseBuy",
				data = "fishing",
			})
		else
			table.insert(items, {
				label = config.Licenses.fishing.label,
				description = "Unable To Purchase, License Is Suspended.",
			})
		end
	end

	plsr.ListMenu:Show({
		main = {
			label = "Licensing Services",
			items = items,
		}
	})
end)
