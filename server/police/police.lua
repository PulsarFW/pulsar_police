local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()
local sharedConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

local _breached = {}
local _swabCounter = 1

local _generatedNames = {}

CreateThread(function()
		PoliceItems()
		RegisterCommands()

		GlobalState["PrisonLockdown"] = false
		GlobalState["PrisonCellsLocked"] = false
		GlobalState["PoliceCars"] = config.PoliceCars
		GlobalState["EMSCars"] = config.EMSCars

		for k, v in pairs(config.Armories) do
			plsr.Logger:Trace("Police", string.format("Registering Poly Inventory ^2%s^7 For ^3%s^7", v.id, v.name))
			plsr.Inventory.Poly:Create(v)
		end

		plsr.Inventory.Items:RegisterUse(sharedConfig.Items.spikes, "Police", function(source, slot, itemData)
			if GetVehiclePedIsIn(GetPlayerPed(source)) == 0 then
				plsr.Callbacks:ClientCallback(source, "Police:DeploySpikes", {}, function(data)
					if data ~= nil then
						TriggerClientEvent("Police:Client:AddDeployedSpike", -1, data.positions, data.h, source)
						
						local newValue = slot.CreateDate - math.ceil(itemData.durability / 4)
						if (os.time() - itemData.durability >= newValue) then
							plsr.Inventory.Items:RemoveId(slot.Owner, slot.invType, slot)
						else
							plsr.Inventory:SetItemCreateDate(
								slot.id,
								newValue
							)
						end

						plsr.Execute:Client(source, "Notification", "Success", "You Deployed Spikes (Despawn In 20s)")
					end
				end)
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Police:GSRTest", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)

			if plsr.State:Player(source).onDuty == "police" or plsr.State:Player(source).onDuty == "ems" then
				local target = Player(data)
				if target ~= nil then
					local targetGSR = plsr.State:Player(data).GSR
					if targetGSR ~= nil and (os.time() - targetGSR) <= (60 * 60) then
						plsr.Chat.Send.System:Single(source, "GSR: Positive")
					else
						plsr.Chat.Send.System:Single(source, "GSR: Negative")
					end
				else
					plsr.Execute:Client(source, "Notification", "Error", "Invalid Target")
				end
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Prison:SetLockdown", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			-- add PD Alert
			if char and (plsr.State:Player(source).onDuty == "prison" or plsr.State:Player(source).onDuty == "police") then
				GlobalState["PrisonLockdown"] = not GlobalState["PrisonLockdown"]
				GlobalState["PrisonCellsLocked"] = GlobalState["PrisonLockdown"]
				for i = 1, 27 do
					plsr.Doors:SetLock(string.format("prison_cell_%s", i), GlobalState["PrisonCellsLocked"])
				end
				plsr.Execute:Client(source, "Notification", "Info", string.format("Cell Door State: %s", GlobalState["PrisonCellsLocked"]), GlobalState["PrisonCellsLocked"] and "Locked" or "Unlocked")
				cb(true, GlobalState["PrisonLockdown"])
			else
				cb(false)
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Prison:SetCellState", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if char and (plsr.State:Player(source).onDuty == "prison" or plsr.State:Player(source).onDuty == "police") then
				GlobalState["PrisonCellsLocked"] = not GlobalState["PrisonCellsLocked"]
				for i = 1, 27 do
					plsr.Doors:SetLock(string.format("prison_cell_%s", i), GlobalState["PrisonCellsLocked"])
				end
				plsr.Execute:Client(source, "Notification", "Info", string.format("Cell Door State: %s", GlobalState["PrisonCellsLocked"]), GlobalState["PrisonCellsLocked"] and "Locked" or "Unlocked")
				cb(true, GlobalState["PrisonCellsLocked"])
			else
				cb(false)
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Police:BACTest", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)

			if plsr.State:Player(source).onDuty == "police" or plsr.State:Player(source).onDuty == "ems" then
				local target = Player(data)
				if target ~= nil then
					-- Great Code Kapp
					if plsr.State:Player(data).isDrunk and plsr.State:Player(data).isDrunk > 0 then
						if plsr.State:Player(data).isDrunk >= 70 then
							plsr.Chat.Send.System:Single(source, "BAC: 0.22% - Above Limit")
						elseif plsr.State:Player(data).isDrunk >= 40 then
							plsr.Chat.Send.System:Single(source, "BAC: 0.13% - Above Limit")
						elseif plsr.State:Player(data).isDrunk >= 30 then
							plsr.Chat.Send.System:Single(source, "BAC: 0.1% - Above Limit")
						elseif plsr.State:Player(data).isDrunk >= 25 then
							plsr.Chat.Send.System:Single(source, "BAC: 0.085% - Above Limit")
						elseif plsr.State:Player(data).isDrunk >= 15 then
							plsr.Chat.Send.System:Single(source, "BAC: 0.04% - Below Limit")
						else
							plsr.Chat.Send.System:Single(source, "BAC: 0.025% - Below Limit")
						end
					else
						plsr.Chat.Send.System:Single(source, "BAC: Not Drunk")
					end
				else
					plsr.Execute:Client(source, "Notification", "Error", "Invalid Target")
				end
			end

			cb(true)
		end)

		plsr.Callbacks:RegisterServerCallback("Police:DNASwab", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)

			if char and plsr.State:Player(source).onDuty == "police" or plsr.State:Player(source).onDuty == "ems" then
				local tChar = plsr.Fetch:CharacterSource(data)
				if tChar ~= nil then

					local coords = GetEntityCoords(GetPlayerPed(data))
					_swabCounter += 1

					plsr.Inventory:AddItem(char:GetData('SID'), 'evidence-dna', 1, {
						EvidenceType = 'blood',
						EvidenceId = string.format('%s-%s', os.date('%d%m%y-%H%M%S', os.time()), 950000 + _swabCounter),
						EvidenceCoords = { x = coords.x, y = coords.y, z = coords.z },
						EvidenceDNA = tChar:GetData("SID"),
						EvidenceSwab = true,
						EvidenceDegraded = false,
					}, 1)

					return
				end

				plsr.Execute:Client(source, "Notification", "Error", "Invalid Target")
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Police:Breach", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)

			if (data?.type == nil or data?.property == nil) then
				cb(false)
				return
			end

			if plsr.State:Player(source).onDuty == "police" then
				_breached[data.type] = _breached[data.type] or {}

				if data.type == "property" then
					if (_breached[data.type][data.property] or 0) > os.time() then
						cb(true)
						plsr.Execute:Client(source, "Properties", "Enter", data.property)
					else
						plsr.Callbacks:ClientCallback(source, "Police:Breach", {}, function(s)
							if s then
								_breached[data.type][data.property] = os.time() + (60 * 10)
								plsr.Execute:Client(source, "Properties", "Enter", data.property)
								cb(true)
							else
								cb(false)
							end
						end)
					end
				elseif data.type == "robbery" then
					if (_breached[data.type][data.property] or 0) > os.time() then
						TriggerEvent("Labor:Server:Houseplsr.Robbery:Breach", source, data.property)

						cb(true)
					else
						plsr.Callbacks:ClientCallback(source, "Police:Breach", {}, function(s)
							if s then
								TriggerEvent("Labor:Server:Houseplsr.Robbery:Breach", source, data.property)

								cb(true)
							else
								cb(false)
							end
						end)
					end
				elseif data.type == "apartment" then
					local aptTier = plsr.Fetch:GetOfflineData(data.property, "Apartment")

					if aptTier ~= nil then
						local id = aptTier or 1
						if id == aptTier then
							if (_breached[data.type][data.property] or 0) > os.time() then
								plsr.Execute:Client(source, "Apartment", "Enter", aptTier, data.property)

								return cb(data.property)
							else
								plsr.Callbacks:ClientCallback(source, "Police:Breach", {}, function(s)
									if s then
										_breached[data.type][data.property] = os.time() + (60 * 10)
										plsr.Execute:Client(source, "Apartment", "Enter", aptTier, data.property)

										return cb(data.property)
									else
										cb(false)
									end
								end)
							end
						else
							plsr.Execute:Client(source, "Notification", "Error", "Target Does Not Reside Here")
							return cb(false)
						end
					else
						plsr.Execute:Client(source, "Notification", "Error", "Target Not Online")
						return cb(false)
					end
				end
			else
				cb(false)
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Police:AccessRifleRack", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if char ~= nil then
				local myDuty = plsr.State:Player(source).onDuty
				if myDuty == 'police' then
					local veh = GetVehiclePedIsIn(GetPlayerPed(source))
					if veh ~= 0 then
						if config.PoliceCars[GetEntityModel(veh)] then
							local entState = plsr.State.Entity(veh)
							if plsr.Vehicles.Keys:Has(source, entState.VIN, 'police') then
								plsr.Callbacks:ClientCallback(source, "Inventory:Compartment:Open", {
									invType = 3,
									owner = ("pdrack:%s"):format(entState.VIN),
								}, function()
									plsr.Inventory:OpenSecondary(source, 3, ("pdrack:%s"):format(entState.VIN))
								end)
							else
								plsr.Execute:Client(source, "Notification", "Error", "Can't Access The Locked Compartment")
							end
						else
							plsr.Execute:Client(source, "Notification", "Error", "Vehicle Not Outfitted With A Secured Compartment")
						end
					else
						plsr.Execute:Client(source, "Notification", "Error", "Not In A Vehicle")
					end
				elseif myDuty == 'prison' then
					local veh = GetVehiclePedIsIn(GetPlayerPed(source))
					if veh ~= 0 then
						if config.PoliceCars[GetEntityModel(veh)] then
							local entState = plsr.State.Entity(veh)
							if plsr.Vehicles.Keys:Has(source, entState.VIN, 'prison') then
								plsr.Callbacks:ClientCallback(source, "Inventory:Compartment:Open", {
									invType = 999,
									owner = ("pdrack:%s"):format(entState.VIN),
								}, function()
									plsr.Inventory:OpenSecondary(source, 999, ("pdrack:%s"):format(entState.VIN))
								end)
							else
								plsr.Execute:Client(source, "Notification", "Error", "Can't Access The Locked Compartment")
							end
						else
							plsr.Execute:Client(source, "Notification", "Error", "Vehicle Not Outfitted With A Secured Compartment")
						end
					else
						plsr.Execute:Client(source, "Notification", "Error", "Not In A Vehicle")
					end
				end
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Police:RemoveMask", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if char ~= nil and plsr.State:Player(source).onDuty == "police" then
				local tChar = plsr.Fetch:CharacterSource(data)
				if tChar ~= nil then
					plsr.Ped.Mask:Unequip(data)
				end
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Police:GetRadioChannel", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if char ~= nil and plsr.State:Player(source).onDuty == "police" then
				local targetOnRadio = plsr.State:Player(tonumber(data)).onRadio
				if targetOnRadio then
					plsr.Chat.Send.System:Single(source, string.format("Radio Frequency: %s", targetOnRadio))
				else
					plsr.Chat.Send.System:Single(source, string.format("Not On Radio"))
				end
			end
		end)
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Police", POLICE)
end)

RegisterNetEvent("Police:Server:Cuff", function()
	local src = source
	local char = plsr.Fetch:CharacterSource(src)
	local onDuty = plsr.State:Player(src).onDuty
	if char ~= nil and (onDuty == "police" or onDuty == "prison")then
		plsr.Handcuffs:HardCuff(src)
	end
end)

RegisterNetEvent("Police:Server:Uncuff", function()
	local src = source
	local char = plsr.Fetch:CharacterSource(src)
	local onDuty = plsr.State:Player(src).onDuty
	if char ~= nil and (onDuty == "police" or onDuty == "prison")then
		plsr.Handcuffs:Uncuff(src)
	end
end)

RegisterNetEvent("Police:Server:RunPlate", function(plate, VIN, model)
	local src = source
	local char = plsr.Fetch:CharacterSource(src)
	if char ~= nil then
		local myDuty = plsr.State:Player(src).onDuty
		if myDuty and myDuty == "police" then
			plsr.Police:RunPlate(src, plate, {
				VIN = VIN,
				model = model
			})
		end
	end
end)

RegisterNetEvent("Police:Server:Panic", function(isAlpha)
	local src = source
	local char = plsr.Fetch:CharacterSource(src)
	if plsr.State:Player(src).onDuty == "police" then
		local coords = GetEntityCoords(GetPlayerPed(src))
		plsr.Callbacks:ClientCallback(src, "EmergencyAlerts:GetStreetName", coords, function(location)
			if isAlpha then
				plsr.EmergencyAlerts:Create("13-A", "Officer Down", {"police_alerts", "ems_alerts"}, location, {
					icon = "circle-exclamation",
					details = string.format(
						"%s - %s %s | %s",
						char:GetData("Callsign"),
						char:GetData("First"),
						char:GetData("Last"),
						plsr.State:Player(src).onRadio and string.format("Radio Freq: %s", plsr.State:Player(src).onRadio) or "Not On Radio"
					)
				}, true, {
					icon = 303,
					size = 1.2,
					color = 26,
					duration = (60 * 10),
				}, 1)
			else
				plsr.EmergencyAlerts:Create("13-B", "Officer Down", {"police_alerts", "ems_alerts"}, location, {
					icon = "circle-exclamation",
					details = string.format(
						"%s - %s %s",
						char:GetData("Callsign"),
						char:GetData("First"),
						char:GetData("Last"),
						plsr.State:Player(src).onRadio and string.format("Radio Freq: %s", plsr.State:Player(src).onRadio) or "Not On Radio"
					)
				}, false, {
					icon = 303,
					size = 0.9,
					color = 26,
					duration = (60 * 10),
				}, 1)
			end
		end)
	elseif plsr.State:Player(src).onDuty == "prison" then
		local coords = GetEntityCoords(GetPlayerPed(src))
		plsr.Callbacks:ClientCallback(src, "EmergencyAlerts:GetStreetName", coords, function(location)
			if isAlpha then
				plsr.EmergencyAlerts:Create("13-A", "Corrections Officer Down", {"police_alerts", "doc_alerts", "ems_alerts"}, location, {
					icon = "circle-exclamation",
					details = string.format(
						"%s - %s %s | %s",
						char:GetData("Callsign"),
						char:GetData("First"),
						char:GetData("Last"),
						plsr.State:Player(src).onRadio and string.format("Radio Freq: %s", plsr.State:Player(src).onRadio) or "Not On Radio"
					)
				}, true, {
					icon = 303,
					size = 1.2,
					color = 26,
					duration = (60 * 10),
				}, 1)
			else
				plsr.EmergencyAlerts:Create("13-B", "Corrections Officer Down", {"police_alerts", "doc_alerts", "ems_alerts"}, location, {
					icon = "circle-exclamation",
					details = string.format(
						"%s - %s %s | %s",
						char:GetData("Callsign"),
						char:GetData("First"),
						char:GetData("Last"),
						plsr.State:Player(src).onRadio and string.format("Radio Freq: %s", plsr.State:Player(src).onRadio) or "Not On Radio"
					)
				}, false, {
					icon = 303,
					size = 0.9,
					color = 26,
					duration = (60 * 10),
				}, 1)
			end
		end)
	end
end)

RegisterNetEvent('Police:Server:Tackle', function(target)
	local src = source
	if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) < 5.0 then
		TriggerClientEvent('Police:Client:GetTackled', target)
	end
end)

RegisterNetEvent("Prison:Server:Lockdown:AlertPolice", function(state)
	local src = source
	if state then
		plsr.Robbery:TriggerPDAlert(src, GetEntityCoords(GetPlayerPed(src)), "10-98", "Bolingbroke Penitentiary Lockdown", {
			icon = 526,
			size = 0.9,
			color = 1,
			duration = (60 * 5),
		})
	end
	TriggerClientEvent("Prison:Client:JailAlarm", -1, state)
end)

POLICE = {
	IsInBreach = function(self, source, type, id, extraCheck)
		if plsr.State:Player(source).onDuty == "police" and (not extraCheck or plsr.Jobs.Permissions:HasPermissionInJob(source, 'police', 'PD_RAID')) then
			if _breached[type] and _breached[type][id] and ((_breached[type][id] or 0) > os.time()) then
				if extraCheck then
					local char = plsr.Fetch:CharacterSource(source)
					if char then
						plsr.Logger:Warn(
							"Police",
							string.format(
								"Police Raid - Character %s %s (%s) - Accessing Property %s (%s)",
								char:GetData("First"),
								char:GetData("Last"),
								char:GetData("SID"),
								id,
								type
							),
							{
								console = true,
								discord = {
									embed = true,
									type = 'info',
								}
							}
						)
					end
				end

				return true
			end
		end
	
		return false
	end,
	RunPlate = function(self, source, plate, wasEntity)
		plsr.Database:Query(
			"SELECT `data`, `flags` FROM `vehicles` WHERE `registered_plate` = ? OR `fake_plate` = ?",
			{ plate, plate },
			function(success, rows)
			local results = {}
			if success then
				for k, row in ipairs(rows) do
					local ok, v = pcall(json.decode, row.data)
					if ok and type(v) == "table" then
						if row.flags then
							local fok, flags = pcall(json.decode, row.flags)
							v.Flags = (fok and flags) or nil
						end
						table.insert(results, v)
					end
				end
			end
			if not success or #results == 0 then
				local stolen = plsr.Radar:CheckPlate(plate)
				if stolen then
					if not _generatedNames[plate] then
						_generatedNames[plate] = string.format(
							"%s %s",
							plsr.Generator.Name:First(),
							plsr.Generator.Name:Last()
						)
					end

					if wasEntity then
						plsr.Chat.Send.Services:Dispatch(
							source,
							string.format(
								"<b>Owner</b>: %s<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown<br /><br />%s",
								_generatedNames[plate],
								wasEntity.VIN,
								wasEntity.model,
								plate,
								stolen
							)
						)
					else
						plsr.Chat.Send.Services:Dispatch(
							source,
							string.format(
								"<b>Owner</b>: %s<br /><b>VIN</b>: Unknown<br /><b>Make & Model</b>: Unknown<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown<br /><br />%s",
								_generatedNames[plate],
								plate,
								stolen
							)
						)
					end
				elseif wasEntity then
					if not _generatedNames[plate] then
						_generatedNames[plate] = string.format(
							"%s %s",
							plsr.Generator.Name:First(),
							plsr.Generator.Name:Last()
						)
					end

					plsr.Chat.Send.Services:Dispatch(
						source,
						string.format(
							"<b>Owner</b>: %s<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown",
							_generatedNames[plate],
							wasEntity.VIN,
							wasEntity.model,
							plate
						)
					)
				else
					plsr.Chat.Send.Services:Dispatch(source, "No Plate Match")
				end
				return
			end

			if #results > 1 then
				plsr.Chat.Send.Services:Dispatch(source, "Multiple Matches, Please Use MDT")
			else
				local vehicle = results[1]
				if vehicle.FakePlate and vehicle.FakePlateData then
					local stolen = plsr.Radar:CheckPlate(plate)
					if stolen then
						plsr.Chat.Send.Services:Dispatch(
							source,
							string.format(
								"<b>Owner</b>: %s (%s)<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown<br /><br />%s",
								vehicle.FakePlateData.OwnerName,
								vehicle.FakePlateData.SID,
								vehicle.FakePlateData.VIN,
								vehicle.FakePlateData.Vehicle or string.format('%s %s', vehicle.Make, vehicle.Model),
								vehicle.FakePlate,
								stolen
							)
						)
					else
						plsr.Chat.Send.Services:Dispatch(
							source,
							string.format(
								"<b>Owner</b>: %s (%s)<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown",
								vehicle.FakePlateData.OwnerName,
								vehicle.FakePlateData.SID,
								vehicle.FakePlateData.VIN,
								vehicle.FakePlateData.Vehicle or string.format('%s %s', vehicle.Make, vehicle.Model),
								vehicle.FakePlate
							)
						)
					end
				else
					local ownerName = "Unknown"
					if vehicle.Owner.Type == 0 then
						local owner = plsr.MDT.People:View(vehicle.Owner.Id)

						ownerName = string.format("%s %s", owner.First, owner.Last)
					elseif vehicle.Owner.Type == 1 then
						local jobData = plsr.Jobs:DoesExist(vehicle.Owner.Id, vehicle.Owner.Workplace)
						if jobData then
							if jobData.Workplace then
								ownerName = string.format('%s (%s)', jobData.Name, jobData.Workplace.Name)
							else
								ownerName = jobData.Name
							end
						end
					end
	
					local stolen = false
					if vehicle.Flags then
						for k, v in ipairs(vehicle.Flags) do
							if v.Type == "stolen" then
								stolen = v.Description
								break
							end
						end
					end
	
					if stolen then
						plsr.Chat.Send.Services:Dispatch(
							source,
							string.format(
								"<b>Owner</b>: %s (%s)<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s %s<br /><b>Plate</b>: %s<br /><b>Class</b>: %s<br /><br /><b>Vehicle Reported Stolen</b>: %s",
								ownerName,
								vehicle.Owner.Id,
								vehicle.VIN,
								vehicle.Make,
								vehicle.Model,
								vehicle.RegisteredPlate,
								vehicle.Class,
								stolen
							)
						)
					else
						plsr.Chat.Send.Services:Dispatch(
							source,
							string.format(
								"Owner: %s (%s)\nVIN: %s\nMake & Model: %s %s\nPlate: %s\nClass: %s",
								ownerName,
								vehicle.Owner.Id,
								vehicle.VIN,
								vehicle.Make,
								vehicle.Model,
								vehicle.RegisteredPlate,
								vehicle.Class
							)
						)
					end
				end
			end
		end)
	end,
	IsPdCar = function(self, model)
		return config.PoliceCars[model]
	end,
	IsEMSCar = function(self, model)
		return config.EMSCars[model]
	end,
}

RegisterNetEvent("Police:Server:RemoveSpikes", function()
	TriggerClientEvent("Police:Client:RemoveSpikes", -1, source)
end)

RegisterNetEvent("Police:Server:Slimjim", function()
	local src = source

	if plsr.State:Player(src).onDuty == "police" then
		plsr.Callbacks:ClientCallback(src, "Vehicles:Slimjim", true, function()
	
		end)
	end
end)