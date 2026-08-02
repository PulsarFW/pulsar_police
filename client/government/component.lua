local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

CreateThread(function()
	local govServices = {
		{
			icon = "id-card",
			text = string.format("Purchase ID ($%s)", config.GovIdPrice),
			event = "Government:Client:BuyID",
		},
		{
			icon = "file-certificate",
			text = "License Services",
			event = "Government:Client:BuyLicense",
		},
		{
			icon = "gavel",
			text = "Public Records",
			event = "Government:Client:AccessPublicRecords",
		},
		{
			icon = "clipboard-list",
			text = "Go On Duty",
			event = "Government:Client:OnDuty",
			jobPerms = {
				{
					job = "government",
					reqOffDuty = true,
				},
			},
		},
		{
			icon = "clipboard",
			text = "Go Off Duty",
			event = "Government:Client:OffDuty",
			jobPerms = {
				{
					job = "government",
					reqDuty = true,
				},
			},
		},
		{
			icon = "shop-lock",
			text = "DOJ Shop",
			event = "Government:Client:DOJShop",
			jobPerms = {
				{
					job = "government",
					workplace = "doj",
					reqDuty = true,
				},
			},
		},
	}

	plsr.PedInteraction:Add(
		"govt-services",
		`a_f_m_eastsa_02`,
		config.GovtServicesNpc.coords,
		config.GovtServicesNpc.heading,
		config.GovtServicesNpc.dist,
		govServices,
		"bell-concierge"
	)

	for k, v in ipairs(config.ClockInPoints.government) do
		plsr.Targeting.Zones:AddBox("gov-info-" .. k, "gavel", v.coords, v.length, v.width, v.options, {
			{
				icon = "clipboard-list",
				text = "Go On Duty",
				event = "Government:Client:OnDuty",
				jobPerms = {
					{
						job = "government",
						reqOffDuty = true,
					},
				},
			},
			{
				icon = "clipboard",
				text = "Go Off Duty",
				event = "Government:Client:OffDuty",
				jobPerms = {
					{
						job = "government",
						reqDuty = true,
					},
				},
			},
			{
				icon = "gavel",
				text = "Public Records",
				event = "Government:Client:AccessPublicRecords",
			},
		}, 3.0, true)
	end

	local courtZone = config.Courthouse.zone
	plsr.Polyzone.Create:Box("courtroom", courtZone.coords, courtZone.length, courtZone.width, courtZone.options, {})

	local gavelZone = config.Courthouse.gavel
	plsr.Targeting.Zones:AddBox("court-gavel", "gavel", gavelZone.coords, gavelZone.length, gavelZone.width, gavelZone.options, {
		{
			icon = "gavel",
			text = "Use Gavel",
			event = "Government:Client:UseGavel",
			-- jobPerms = {
			--     {
			--         job = 'government',
			--         reqDuty = true,
			--     }
			-- },
		},
	}, 3.0, true)
end)

RegisterNetEvent("Characters:Client:Spawn", function()
	local courthouseBlip = config.Courthouse.blip
	plsr.Blips:Add("courthouse", "Courthouse", courthouseBlip.coords, courthouseBlip.sprite, courthouseBlip.colour, courthouseBlip.scale)
end)

AddEventHandler("Government:Client:UseGavel", function()
	TriggerServerEvent("Government:Server:Gavel")
end)

RegisterNetEvent("Government:Client:Gavel", function()
	if not plsr.State.flags.loggedIn then
		return
	end
	local coords = GetEntityCoords(PlayerPedId())
	if plsr.Polyzone:IsCoordsInZone(coords, "courtroom") then
		plsr.Sounds.Play:One("gavel.ogg", 0.6)
	end
end)

AddEventHandler("Government:Client:DOJShop", function()
	plsr.Inventory.Shop:Open("doj-shop")
end)
