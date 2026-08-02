-- direct, unbatched notification to the target's own client - CuffThread below needs isCuffed to be
-- true synchronously right after this, not after the next SetPublicFlag flush tick
RegisterNetEvent('Handcuffs:Client:SetCuffed', function(isCuffed, isHardCuffed)
	plsr.State.flags.isCuffed = isCuffed
	plsr.State.flags.isHardCuffed = isHardCuffed
end)

AddEventHandler("Handcuffs:Client:DoCuffBreak", function()
	if _cuffPromise ~= nil then
		_cuffPromise:resolve(true)
		plsr.Notification:Success("You Broke Out Of The Cuffs")
	end
end)

AddEventHandler("Handcuffs:Client:FailCuffBreak", function()
	if _cuffPromise ~= nil then
		ResetTimer()
		_cuffPromise:resolve(false)
		plsr.Notification:Error("Failed Breaking Out Of Cuffs")
	end
end)

AddEventHandler("Handcuffs:Client:HardCuff", function(entity, data)
	TriggerServerEvent("Handcuffs:Server:HardCuff", entity.serverId)
end)

AddEventHandler("Handcuffs:Client:SoftCuff", function(entity, data)
	TriggerServerEvent("Handcuffs:Server:SoftCuff", entity.serverId)
end)

AddEventHandler("Handcuffs:Client:Uncuff", function(entity, data)
	TriggerServerEvent("Handcuffs:Server:Uncuff", entity.serverId)
end)

RegisterNetEvent("Handcuffs:Client:CuffingAnim", function()
	if not IsPedInAnyVehicle(PlayerPedId(), true) then
		local animDict = "mp_arrest_paired"
		local anim = "cop_p2_back_right"

		loadAnimDict(animDict)

		while not HasAnimDictLoaded(animDict) do
			Wait(0)
		end

		Wait(100)
		TaskPlayAnim(PlayerPedId(), animDict, anim, 8.0, -8, -1, 16, 0, 0, 0, 0)
		Wait(3250)
		ClearPedTasksImmediately(PlayerPedId())
	end
end)

RegisterNetEvent("Handcuffs:Client:UncuffingAnim", function()
	if not IsPedInAnyVehicle(PlayerPedId(), true) then
		local animDict = "mp_arresting"
		local anim = "a_uncuff"

		loadAnimDict(animDict)

		plsr.Weapons:UnequipIfEquipped()

		while not HasAnimDictLoaded(animDict) do
			Wait(0)
		end

		if IsEntityPlayingAnim(PlayerPedId(), animDict, anim, 3) then
			ClearPedSecondaryTask(PlayerPedId())
		else
			TaskPlayAnim(PlayerPedId(), animDict, anim, 1.0, 1.0, 3000, 16, -1, 0, 0, 0)
		end
	end
end)

_cuffFlags = 17
local lastFlag = nil
function cuffAnim()
	if
		IsPedInAnyVehicle(PlayerPedId())
		or plsr.State.flags.isHospitalized
		or IsPedBeingStunned(PlayerPedId())
	then
		return
	end

	RequestAnimDict("mp_arresting")
	while not HasAnimDictLoaded("mp_arresting") do
		Wait(1)
	end
	ClearPedTasksImmediately(PlayerPedId())
	TaskPlayAnim(PlayerPedId(), "mp_arresting", "idle", 8.0, 8.0, -1, _cuffFlags, 0.0, 0, 0, 0)
end

AddEventHandler("Handcuffs:Client:DoShittyAnim", function()
	Wait(100)
	cuffAnim()
end)

local _cuffThreading = false
RegisterNetEvent("Handcuffs:Client:CuffThread", function(cId)
	if _cuffThreading then
		return
	end
	_cuffThreading = true

	CreateThread(function()
		-- Wait till this is synced from server
		while not plsr.State.flags.isCuffed do
			Wait(10)
		end

		while plsr.State.flags.isCuffed do
			-- if not plsr.State.flags.isHardCuffed then
			-- 	FreezeEntityPosition(PlayerPedId(), true)
			-- end
			-- if not IsEntityPlayingAnim(PlayerPedId(), "mp_arrest_paired", "crook_p2_back_right", 3) then
			-- 	beingCuffedAnim(tonumber(cId))
			-- end
			Wait(5)

			plsr.Weapons:UnequipIfEquipped()

			if not plsr.State.flags.isHardCuffed and IsPedClimbing(PlayerPedId()) then
				Wait(500)
				SetPedToRagdoll(PlayerPedId(), 3000, 1000, 0, 0, 0, 0)
			end

			-- if CanPedRagdoll(PlayerPedId()) then
			-- 	SetPedCanRagdoll(PlayerPedId(), false)
			-- end

			DisableControlAction(1, 75, true) -- F
			DisableControlAction(1, 25, true) -- Aim
			DisableControlAction(1, 106, true) -- VehicleMouseControlOverride
			DisableControlAction(1, 140, true) --Disables Melee Actions
			DisableControlAction(1, 141, true) --Disables Melee Actions
			DisableControlAction(1, 142, true) --Disables Melee Actions
			DisableControlAction(1, 37, true) --Disables INPUT_SELECT_WEAPON (tab) Actions
			DisablePlayerFiring(PlayerPedId(), true) -- Disable weapon firing

			if
				not plsr.State.flags.isHospitalized
				and (
					(
						not IsEntityPlayingAnim(PlayerPedId(), "mp_arresting", "idle", 3)
						and not plsr.State.flags.isDead
						and not plsr.State.flags.inTrunk
					)
					or (
						IsPedRagdoll(PlayerPedId())
						and not plsr.State.flags.isDead
						and not plsr.State.flags.inTrunk
					)
				) and not IsPedFalling(PlayerPedId())
			then
				cuffAnim()
			end
			if plsr.State.flags.isDead or plsr.State.flags.inTrunk then
				Wait(1000)
			end
		end

		-- if not CanPedRagdoll(PlayerPedId()) then
		-- 	SetPedCanRagdoll(PlayerPedId(), true)
		-- end
		ClearPedTasks(PlayerPedId())
		FreezeEntityPosition(PlayerPedId(), false)
		_cuffThreading = false
	end)
end)
