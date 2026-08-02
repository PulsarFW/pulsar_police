local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

function EMSItems()
	-- Inventory.Items:RegisterUse("tourniquet", "MedicalItems", function(source, item)
	-- 	local char = Fetch:CharacterSource(source)
	-- 	if char:GetData("Damage").Bleed > 0 then
	-- 		if Inventory.Items:RemoveSlot(item.Owner, item.Name, 1, item.Slot, 1) then
	-- 			Player(source).state.tourniquet = (
	-- 					GetGameTimer() + ((1000 * 60 * 5) / char:GetData("Damage").Bleed or 1)
	-- 				)
	-- 		end
	-- 	else
	-- 		Execute:Client(source, "Notification", "Error", "You're Not Bleeding")
	-- 	end
	-- end)

	plsr.Inventory.Items:RegisterUse(config.Items.medical.morphine, "MedicalItems", function(source, item)
		if plsr.Inventory.Items:RemoveSlot(item.Owner, item.Name, 1, item.Slot, 1) then
			plsr.Damage.Effects:Painkiller(source, 1)
		end
	end)

	plsr.Inventory.Items:RegisterUse(config.Items.medical.oxy, "MedicalItems", function(source, item)
		local plr = plsr.State:Player(source)
		local char = plsr.Fetch:CharacterSource(source)
		if plsr.Inventory.Items:RemoveSlot(item.Owner, item.Name, 1, item.Slot, 1) then
			plsr.Damage.Effects:Painkiller(source, 2)

			if plr.healTicks ~= nil then
				local f = plr.healTicks
				for i = 1, 5 do
					table.insert(f, "5")
				end
				plr.healTicks = f
			else
				plr.healTicks = { "5", "5", "5", "5", "5" }
			end
			Wait(100)
			TriggerClientEvent("Damage:Client:Ticks:Heal", source)
		end
	end)

	plsr.Inventory.Items:RegisterUse(config.Items.medical.bandage, "MedicalItems", function(source, item)
		local plr = plsr.State:Player(source)
		local char = plsr.Fetch:CharacterSource(source)
		local ped = GetPlayerPed(source)
		local curr = GetEntityHealth(ped)
		local max = GetEntityMaxHealth(ped)
		if plsr.Inventory.Items:RemoveSlot(item.Owner, item.Name, 1, item.Slot, 1) then
			local heal = 10
			if curr < (max * 0.75) then
				local p = promise.new()
				plsr.Callbacks:ClientCallback(source, "EMS:Heal", heal, function(s)
					p:resolve(s)
				end)
				Citizen.Await(p)
			end

			if plr.healTicks ~= nil then
				local f = plr.healTicks
				for i = 1, 2 do
					table.insert(f, "5")
				end
				plr.healTicks = f
			else
				plr.healTicks = { "5", "5" }
			end
			Wait(100)
			TriggerClientEvent("Damage:Client:Ticks:Heal", source)
		end
	end)

	plsr.Inventory.Items:RegisterUse(config.Items.medical.firstaid, "MedicalItems", function(source, item)
		local plr = plsr.State:Player(source)
		local char = plsr.Fetch:CharacterSource(source)
		local ped = GetPlayerPed(source)
		local curr = GetEntityHealth(ped)
		local max = GetEntityMaxHealth(ped)
		if plsr.Inventory.Items:RemoveSlot(item.Owner, item.Name, 1, item.Slot, 1) then
			local p = promise.new()
			local heal = 15
			if curr + heal > max then
				heal = max - curr
			end
			plsr.Callbacks:ClientCallback(source, "EMS:Heal", heal, function(s)
				p:resolve(s)
			end)
			Citizen.Await(p)

			if plr.healTicks ~= nil then
				local f = plr.healTicks
				for i = 1, 2 do
					table.insert(f, "10")
				end

				table.insert(f, "5")

				plr.healTicks = f
			else
				plr.healTicks = { "10", "10", "5" }
			end
			Wait(100)
			TriggerClientEvent("Damage:Client:Ticks:Heal", source)
		end
	end)

	plsr.Inventory.Items:RegisterUse(config.Items.medical.ifak, "MedicalItems", function(source, item)
		local plr = plsr.State:Player(source)
		local char = plsr.Fetch:CharacterSource(source)
		local ped = GetPlayerPed(source)
		local curr = GetEntityHealth(ped)
		local max = GetEntityMaxHealth(ped)
		if plsr.Inventory.Items:RemoveSlot(item.Owner, item.Name, 1, item.Slot, 1) then
			local p = promise.new()
			local heal = 30
			if curr + heal > max then
				heal = max - curr
			end
			plsr.Callbacks:ClientCallback(source, "EMS:Heal", heal, function(s)
				p:resolve(s)
			end)
			Citizen.Await(p)

			if plr.healTicks ~= nil then
				local f = plr.healTicks
				for i = 1, 2 do
					table.insert(f, "15")
				end
				table.insert(f, "10")
				for i = 1, 2 do
					table.insert(f, "5")
				end

				plr.healTicks = f
			else
				plr.healTicks = { "15", "15", "10", "5", "5" }
			end
			Wait(100)
			TriggerClientEvent("Damage:Client:Ticks:Heal", source)
		end
	end)

	-- Inventory.Items:RegisterUse("gauze", "MedicalItems", function(source, item)
	-- 	local char = Fetch:CharacterSource(source)
	-- 	if Inventory.Items:RemoveSlot(item.Owner, item.Name, 1, item.Slot, 1) then
	-- 		local dmg = char:GetData("Damage")
	-- 		if dmg.Bleed > 1 then
	-- 			dmg.Bleed = dmg.Bleed - 1
	-- 			char:SetData("Damage", dmg)
	-- 		else
	-- 			Execute:Client(source, "Notification", "Error", "You continue bleeding through the gauze")
	-- 		end
	-- 	end
	-- end)

	plsr.Inventory.Items:RegisterUse(config.Items.medical.medicalkit, "MedicalItems", function(source, item)
		local char = plsr.Fetch:CharacterSource(source)
		if plsr.Jobs.Permissions:HasJob(source, "ems", false, false, 2) then
			local myCoords = GetEntityCoords(GetPlayerPed(source))
			for k, v in pairs(plsr.Fetch:AllCharacters()) do
				if v ~= nil then
					if v:GetData("Source") ~= source and plsr.State:Player(v:GetData("Source")).isHospitalized then
						local tPos = GetEntityCoords(GetPlayerPed(v:GetData("Source")))
						local dist = #(vector3(myCoords.x, myCoords.y, myCoords.z) - vector3(tPos.x, tPos.y, tPos.z))
						if dist <= 2.5 then
							TriggerClientEvent("EMS:Client:TreatWounds", source, v:GetData("Source"))
							return
						end
					end
				end
			end
			plsr.Execute:Client(source, "Notification", "Error", "Not Near Any Hospitalized Patients")
		else
			plsr.Execute:Client(source, "Notification", "Error", "You're not trained to use this")
		end
	end)
end
