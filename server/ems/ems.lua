local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()
local sharedConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

CreateThread(function()
	EMSCallbacks()
	EMSItems()
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("EMS", _EMS)
end)

RegisterNetEvent("EMS:Server:CheckICUPatients", function()
	local src = source
	local count = 0
	for k, v in ipairs(plsr.Fetch:AllCharacters()) do
		if v ~= nil then
			if v:GetData("ICU") ~= nil and not v:GetData("ICU").Released then
				count = count + 1
			end
		end
	end

	if count > 0 then
		if count == 1 then
			plsr.Execute:Client(src, "Notification", "Info", "There Is 1 Patient In ICU")
		else
			plsr.Execute:Client(src, "Notification", "Info", string.format("There Are %s Patients In ICU", count))
		end
	else
		plsr.Execute:Client(src, "Notification", "Info", "There Are No Patients In ICU")
	end
end)

RegisterNetEvent("EMS:Server:RequestHelp", function()
	local src = source
	TriggerEvent("EmergencyAlerts:Server:ServerDoPredefined", src, "injuredPerson")
end)

function EMSCallbacks()
	plsr.Callbacks:RegisterServerCallback("EMS:Stabilize", function(source, data, cb)
		local myChar = plsr.Fetch:CharacterSource(source)
		local char = plsr.Fetch:CharacterSource(tonumber(data))
		if char ~= nil then
			if plsr.Inventory.Items:Has(myChar:GetData("SID"), 1, sharedConfig.Items.medical.traumakit, 1) then
				if plsr.Jobs.Permissions:HasJob(source, "ems") then
					plsr.Logger:Info(
						"EMS",
						string.format(
							"%s %s (%s) Stabilized %s %s (%s)",
							myChar:GetData("First"),
							myChar:GetData("Last"),
							myChar:GetData("SID"),
							char:GetData("First"),
							char:GetData("Last"),
							char:GetData("SID")
						),
						{
							console = true,
							file = true,
							database = true,
						}
					)
					plsr.Callbacks:ClientCallback(data, "Damage:FieldStabalize")
					cb({ error = false })
				else
					cb({ error = true, code = 3 })
				end
			else
				cb({ error = true, code = 2 })
			end
		else
			cb({ error = true, code = 1 })
		end
	end)

	plsr.Callbacks:RegisterServerCallback("EMS:FieldTreatWounds", function(source, data, cb)
		local myChar = plsr.Fetch:CharacterSource(source)
		if plsr.Jobs.Permissions:HasJob(source, "ems") then
			if plsr.Inventory.Items:Has(myChar:GetData("SID"), 1, sharedConfig.Items.medical.traumakit, 1) then
				plsr.Execute:Client(data, "Notification", "Success", "Your Wounds Were Treated")
				cb({ error = false })
			else
				cb({ error = true, code = 2 })
			end
		else
			cb({ error = true, code = 1 })
		end
	end)

	-- Callbacks:RegisterServerCallback("EMS:ApplyGauze", function(source, data, cb)
	-- 	local myChar = Fetch:CharacterSource(source)
	-- 	if Jobs.Permissions:HasJob(source, "ems") then
	-- 		if Inventory.Items:Remove(myChar:GetData("SID"), 1, "gauze", 1) then
	-- 			local target = Fetch:Source(data)
	-- 			if target ~= nil then
	-- 				local tChar = target:GetData("Character")
	-- 				if tChar ~= nil then
	-- 					local dmg = tChar:GetData("Damage")
	-- 					if dmg.Bleed > 1 then
	-- 						dmg.Bleed = dmg.Bleed - 1
	-- 						tChar:SetData("Damage", dmg)
	-- 					else
	-- 						Execute:Client(data, "Notification", "Error", "You continue bleeding through the gauze")
	-- 					end
	-- 					cb({ error = false })
	-- 				else
	-- 					cb({ error = true, code = 4 })
	-- 				end
	-- 			else
	-- 				cb({ error = true, code = 3 })
	-- 			end
	-- 		else
	-- 			cb({ error = true, code = 2 })
	-- 		end
	-- 	else
	-- 		cb({ error = true, code = 1 })
	-- 	end
	-- end)

	plsr.Callbacks:RegisterServerCallback("EMS:ApplyBandage", function(source, data, cb)
		local myChar = plsr.Fetch:CharacterSource(source)
		if plsr.Jobs.Permissions:HasJob(source, "ems") then
			if plsr.Inventory.Items:Remove(myChar:GetData("SID"), 1, sharedConfig.Items.medical.bandage, 1) then
				local ped = GetPlayerPed(data)
				local currHp = GetEntityHealth(ped)
				if currHp < (GetEntityMaxHealth(ped) * 0.75) then
					local p = promise.new()

					plsr.Callbacks:ClientCallback(data, "EMS:ApplyBandage", {}, function(s)
						p:resolve(s)
					end)

					Citizen.Await(p)
					plsr.Execute:Client(data, "Notification", "Success", "A Bandage Was Applied To You")
					cb({ error = false })
				else
					cb({ error = true, code = 3 })
				end
			else
				cb({ error = true, code = 2 })
			end
		else
			cb({ error = true, code = 1 })
		end
	end)

	plsr.Callbacks:RegisterServerCallback("EMS:ApplyMorphine", function(source, data, cb)
		local myChar = plsr.Fetch:CharacterSource(source)
		if plsr.Jobs.Permissions:HasJob(source, "ems") then
			if plsr.Inventory.Items:Remove(myChar:GetData("SID"), 1, sharedConfig.Items.medical.morphine, 1) then
				plsr.Damage.Effects:Painkiller(tonumber(data), 3)
				plsr.Execute:Client(data, "Notification", "Success", "You Received A Morphine Shot")
				cb({ error = false })
			else
				cb({ error = true, code = 2 })
			end
		else
			cb({ error = true, code = 1 })
		end
	end)

	plsr.Callbacks:RegisterServerCallback("EMS:TreatWounds", function(source, data, cb)
		local myChar = plsr.Fetch:CharacterSource(source)
		if plsr.Jobs.Permissions:HasJob(source, "ems") then
			plsr.Callbacks:ClientCallback(data, "Damage:Heal", true)
			--TriggerClientEvent("Hospital:Client:GetOut", data)
			plsr.Execute:Client(source, "Notification", "Success", "Patient Has Been Treated")
			plsr.Execute:Client(data, "Notification", "Success", "You've Been Treated")
			cb({ error = false })
		else
			cb({ error = true, code = 1 })
		end
	end)

	plsr.Callbacks:RegisterServerCallback("EMS:CheckDamage", function(source, data, cb)
		local myChar = plsr.Fetch:CharacterSource(source)
		if plsr.Jobs.Permissions:HasJob(source, "ems") or plsr.Jobs.Permissions:HasJob(source, "police") then
			local tChar = plsr.Fetch:CharacterSource(data)
			if tChar ~= nil then
				cb(tChar:GetData("Damage"))
			else
				cb(nil)
			end
		else
			cb(nil)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("EMS:DrugTest", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char ~= nil then
			if plsr.State:Player(source).onDuty == "ems" then
				local tarChar = plsr.Fetch:CharacterSource(data)
				if tarChar ~= nil then
					local tarStates = tarChar:GetData("DrugStates") or {}
					local output = {}
					for k, v in pairs(tarStates) do
						if v.expires > os.time() then
							local item = plsr.Inventory.Items:GetData(v.item)
							if item and item.drugState ~= nil then
								local pct = ((v.expires - os.time()) / item.drugState.duration) * 100
								if pct <= 25 and pct >= 5 then
									table.insert(
										output,
										string.format("Low Presence of %s", config.Drugs[item.drugState.type])
									)
								elseif pct <= 50 then
									table.insert(
										output,
										string.format("Moderate Presence of %s", config.Drugs[item.drugState.type])
									)
								elseif pct <= 75 then
									table.insert(
										output,
										string.format("High Presence of %s", config.Drugs[item.drugState.type])
									)
								elseif pct > 5 then
									table.insert(
										output,
										string.format("Very High Presence of %s", config.Drugs[item.drugState.type])
									)
								end
							end
						end
					end

					if #output > 0 then
						local str = string.format(
							"Drug Test Results For %s %s:<br/><ul>",
							tarChar:GetData("First"),
							tarChar:GetData("Last")
						)
						for k, v in ipairs(output) do
							str = str .. string.format("<li>%s</li>", v)
						end
						str = str .. "</ul>"
						plsr.Chat.Send.Services:TestResult(source, str)
					else
						plsr.Chat.Send.Services:TestResult(
							source,
							"Drug Test Results:<br/><ul><li>All Results Are Negative</li></ul>"
						)
					end
				end
			end
		end

		cb(true)
	end)
end

RegisterNetEvent("EMS:Server:Panic", function(isAlpha)
	local src = source
	local char = plsr.Fetch:CharacterSource(src)
		if plsr.State:Player(src).onDuty == "ems" then
		local coords = GetEntityCoords(GetPlayerPed(src))
		plsr.Callbacks:ClientCallback(src, "EmergencyAlerts:GetStreetName", coords, function(location)
			if isAlpha then
				plsr.EmergencyAlerts:Create(
					"13-A",
					"Medic Down",
					{"police_alerts", "ems_alerts"},
					location,
					{
						icon = "circle-exclamation",
						details = string.format(
							"%s - %s %s",
							char:GetData("Callsign"),
							char:GetData("First"),
							char:GetData("Last"),
							plsr.State:Player(src).onRadio and string.format("Radio Freq: %s", plsr.State:Player(src).onRadio) or "Not On Radio"
						)
					},
					true,
					{
						icon = 303,
						size = 1.2,
						color = 48,
						duration = (60 * 10),
					},
					2
				)
			else
				plsr.EmergencyAlerts:Create(
					"13-B",
					"Medic Down",
					{"police_alerts", "ems_alerts"},
					location,
					{
						icon = "circle-exclamation",
						details = string.format(
							"%s - %s %s",
							char:GetData("Callsign"),
							char:GetData("First"),
							char:GetData("Last"),
							plsr.State:Player(src).onRadio and string.format("Radio Freq: %s", plsr.State:Player(src).onRadio) or "Not On Radio"
						)
					},
					false,
					{
						icon = 303,
						size = 0.9,
						color = 48,
						duration = (60 * 10),
					},
					2
				)
			end
		end)
	end
end)

_EMS = {}
