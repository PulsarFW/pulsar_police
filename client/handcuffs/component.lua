_cuffPromise = nil

local MAX_CUFF_ATTEMPTS = 2

CreateThread(function()
	plsr.State.flags.isCuffed = false
	plsr.State.flags.isHardCuffed = false

	plsr.Callbacks:RegisterClientCallback("Handcuffs:VehCheck", function(data, cb)
		cb(IsPedInAnyVehicle(PlayerPedId()))
	end)

	plsr.Callbacks:RegisterClientCallback("Handcuffs:DoCuff", function(data, cb)
		if not IsPedInAnyVehicle(PlayerPedId(), true) then
			if _cuffPromise == nil then
				if not plsr.State.flags.isCuffed then
					beingCuffedAnim(data.cuffer)
				end

				if data.isHardCuffed then
					_cuffFlags = 17
				else
					_cuffFlags = 49
				end

				if not data.forced and not plsr.State.flags.isCuffed and not plsr.State.flags.isDead then
					CuffAttempt()
					_cuffPromise = promise.new()
					plsr.Minigame.Play:RoundSkillbar(
						1.35 * math.ceil(((_attempts / 2) or 1)),
						(4 - (_attempts / 2) > 1 and 4 - (_attempts / 2) or 1),
						{
							onSuccess = "Handcuffs:Client:DoCuffBreak",
							onFail = "Handcuffs:Client:FailCuffBreak",
						},
						{
							animation = false,
						}
					)
					cb(Citizen.Await(_cuffPromise))
				else
					ResetTimer()
					cb(false)
					cuffAnim()
				end
			else
				cb(-1)
			end

			_cuffPromise = nil
		else
			cb(-1)
		end
	end)
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Handcuffs", _HANDCUFFS)
end)

_HANDCUFFS = {}
