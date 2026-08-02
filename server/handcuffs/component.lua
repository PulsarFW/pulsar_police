local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

AddEventHandler("Characters:Server:PlayerLoggedOut", function(source, cData)
	TriggerClientEvent('Handcuffs:Client:SetCuffed', source, false, false)
	plsr.State:SetPublicFlag(source, 'isCuffed', false)
	plsr.State:SetPublicFlag(source, 'isHardCuffed', false)
end)

CreateThread(function()
	HandcuffItems()
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Handcuffs", _HANDCUFFS)
end)

function DoCuff(source, target, isHardCuffed, isForced)
	TriggerClientEvent("Handcuffs:Client:CuffingAnim", source)
	plsr.Callbacks:ClientCallback(target, "Handcuffs:DoCuff", {
		cuffer = source,
		isHardCuffed = isHardCuffed,
		forced = isForced,
	}, function(result)
		if result == -1 then
			plsr.Execute:Client(source, "Notification", "Error", "Unable To Cuff Player")
		else
			local ped = GetPlayerPed(target)
			if result then
				ClearPedTasksImmediately(GetPlayerPed(target))
				ClearPedTasksImmediately(GetPlayerPed(source))

				plsr.Execute:Client(source, "Notification", "Error", "Suspect Broke Out Of The Cuffs")
				plsr.Sounds.Play:Distance(target, 10, "handcuff_break.ogg", 0.35)
				--plsr.Sounds.Play:One(target, "handcuff_break.ogg", 0.35)
				TriggerClientEvent('Handcuffs:Client:SetCuffed', target, false, false)
				plsr.State:SetPublicFlag(target, 'isCuffed', false)
				plsr.State:SetPublicFlag(target, 'isHardCuffed', false)
				SetPedConfigFlag(ped, 120, false)
				SetPedConfigFlag(ped, 121, false)
			else
				plsr.Execute:Client(source, "Notification", "Success", "You Cuffed A Player")
				plsr.Sounds.Play:Distance(target, 10, "handcuff_on.ogg", 0.55)
				CreateThread(function()
					Wait(1050)
					plsr.Sounds.Play:Distance(target, 10, "handcuff_on.ogg", 0.55)
				end)
				SetPedConfigFlag(ped, 120, true)
				SetPedConfigFlag(ped, 121, isHardCuffed)
				TriggerClientEvent('Handcuffs:Client:SetCuffed', target, true, isHardCuffed)
				plsr.State:SetPublicFlag(target, 'isCuffed', true)
				plsr.State:SetPublicFlag(target, 'isHardCuffed', isHardCuffed)
				--FreezeEntityPosition(ped, false)
				TriggerClientEvent("Handcuffs:Client:CuffThread", target)
			end
		end
	end)
end

RegisterNetEvent("Handcuffs:Server:HardCuff", function(target)
	local src = source

	if not target then
		return
	end

	local mPos = GetEntityCoords(GetPlayerPed(src))
	local tPos = GetEntityCoords(GetPlayerPed(target))

	if #(vector3(mPos.x, mPos.y, mPos.z) - vector3(tPos.x, tPos.y, tPos.z)) <= 1.5 then
		if plsr.Inventory.Items:HasAnyItems(src, config.CuffItems) then
			if
				not plsr.State:Player(target).isCuffed
				or (plsr.State:Player(target).isCuffed and not plsr.State:Player(target).isHardCuffed)
			then
				plsr.Handcuffs:HardCuffTarget(src, target, false)
			else
				plsr.Execute:Client(source, "Notification", "Error", "Target Already Hard Cuffed")
			end
		end
	else
		plsr.Execute:Client(source, "Notification", "Error", "Target Too Far")
	end
end)

RegisterNetEvent("Handcuffs:Server:SoftCuff", function(target)
	local src = source

	if not target then
		return
	end

	local mPos = GetEntityCoords(GetPlayerPed(src))
	local tPos = GetEntityCoords(GetPlayerPed(target))

	if #(vector3(mPos.x, mPos.y, mPos.z) - vector3(tPos.x, tPos.y, tPos.z)) <= 1.5 then
		if plsr.Inventory.Items:HasAnyItems(src, config.CuffItems) then
			if not plsr.State:Player(target).isCuffed or (plsr.State:Player(target).isCuffed and plsr.State:Player(target).isHardCuffed) then
				plsr.Handcuffs:SoftCuffTarget(src, target, false)
			end
		else
			--missing items
		end
	else
		--target too far
	end
end)

RegisterNetEvent("Handcuffs:Server:Uncuff", function(target)
	local src = source

	if not target then
		return
	end

	local mPos = GetEntityCoords(GetPlayerPed(src))
	local tPos = GetEntityCoords(GetPlayerPed(target))

	if #(vector3(mPos.x, mPos.y, mPos.z) - vector3(tPos.x, tPos.y, tPos.z)) <= 1.5 then
		if plsr.Inventory.Items:HasAnyItems(src, config.CuffItems) then
			if plsr.State:Player(target).isCuffed then
				plsr.Handcuffs:UncuffTarget(src, target)
			end
		end
	else
		--target too far
	end
end)

_HANDCUFFS = {
	SelfToggle = function(self, source)
		if source ~= nil then
			if not plsr.State:Player(source).isCuffed then
				DoCuff(source, source, false, false)
				plsr.Execute:Client(source, "Notification", "Error", "Nobody Around To Cuff")
			else
				plsr.Handcuffs:UncuffTarget(source, source)
			end
		else
			plsr.Execute:Client(source, "Notification", "Error", "Nobody To Cuff")
		end
	end,
	ToggleCuffs = function(self, source)
		plsr.Callbacks:ClientCallback(source, "HUD:GetTargetInfront", {}, function(target)
			if target ~= nil then
				if not plsr.State:Player(target).isCuffed then
					local myPos = GetEntityCoords(GetPlayerPed(source))
					local pos = GetEntityCoords(GetPlayerPed(target))
					if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
						DoCuff(source, target, false, false)
						return
					end
					plsr.Execute:Client(source, "Notification", "Error", "Nobody Around To Cuff")
				else
					plsr.Handcuffs:UncuffTarget(source, target)
				end
			else
				plsr.Execute:Client(source, "Notification", "Error", "Nobody To Cuff")
			end
		end)
	end,
	SoftCuff = function(self, source)
		plsr.Callbacks:ClientCallback(source, "HUD:GetTargetInfront", {}, function(target)
			if target ~= nil then
				if not plsr.State:Player(target).isCuffed then
					local myPos = GetEntityCoords(GetPlayerPed(source))
					local pos = GetEntityCoords(GetPlayerPed(target))
					if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
						DoCuff(source, target, false, false)
						return
					end
					plsr.Execute:Client(source, "Notification", "Error", "Nobody Around To Cuff")
				else
					plsr.Execute:Client(source, "Notification", "Error", "Player Already Cuffed")
				end
			else
				plsr.Execute:Client(source, "Notification", "Error", "Nobody To Cuff")
			end
		end)
	end,
	SoftCuffTarget = function(self, source, target, forced)
		local myPos = GetEntityCoords(GetPlayerPed(source))
		local pos = GetEntityCoords(GetPlayerPed(target))
		if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
			DoCuff(source, target, false, forced)
			return
		end
		plsr.Execute:Client(source, "Notification", "Error", "Nobody Around To Cuff")
	end,
	HardCuff = function(self, source)
		plsr.Callbacks:ClientCallback(source, "HUD:GetTargetInfront", {}, function(target)
			if target ~= nil then
				if not plsr.State:Player(target).isCuffed then
					local myPos = GetEntityCoords(GetPlayerPed(source))
					local pos = GetEntityCoords(GetPlayerPed(target))
					if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
						DoCuff(source, target, true, false)
						return
					end
					plsr.Execute:Client(source, "Notification", "Error", "Nobody Around To Cuff")
				else
					plsr.Execute:Client(source, "Notification", "Error", "Player Already Cuffed")
				end
			else
				plsr.Execute:Client(source, "Notification", "Error", "Nobody To Cuff")
			end
		end)
	end,
	HardCuffTarget = function(self, source, target, forced)
		local myPos = GetEntityCoords(GetPlayerPed(source))
		local pos = GetEntityCoords(GetPlayerPed(target))
		if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
			DoCuff(source, target, true, forced)
			return
		end
		plsr.Execute:Client(source, "Notification", "Error", "Nobody Around To Cuff")
	end,
	Uncuff = function(self, source)
		plsr.Callbacks:ClientCallback(source, "HUD:GetTargetInfront", {}, function(target)
			if target ~= nil then
				if plsr.State:Player(target).isCuffed then
					plsr.Handcuffs:UncuffTarget(source, target)
				else
					plsr.Execute:Client(source, "Notification", "Error", "Player Is Not Cuffed")
				end
			else
				plsr.Execute:Client(source, "Notification", "Error", "Nobody To Cuff")
			end
		end)
	end,
	UncuffTarget = function(self, source, target)
		plsr.Callbacks:ClientCallback(target, "Handcuffs:VehCheck", {}, function(inVeh)
			if not inVeh then
				if source ~= -1 then
					TriggerClientEvent("Handcuffs:Client:UncuffingAnim", source)
					Wait(2200)
				end
				plsr.Sounds.Play:Distance(target, 10, "handcuff_remove.ogg", 0.15)
				local ped = GetPlayerPed(target)
				FreezeEntityPosition(ped, false)
				TriggerClientEvent('Handcuffs:Client:SetCuffed', target, false, false)
				plsr.State:SetPublicFlag(target, 'isCuffed', false)
				plsr.State:SetPublicFlag(target, 'isHardCuffed', false)
				SetPedConfigFlag(ped, 120, false)
				SetPedConfigFlag(ped, 121, false)
			else
				if source ~= -1 then
					plsr.Execute:Client(source, "Notification", "Error", "Unable To Uncuff Player")
				end
			end
		end)
	end,
}
