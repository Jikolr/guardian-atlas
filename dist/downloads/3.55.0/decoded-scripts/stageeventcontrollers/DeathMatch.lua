local local_class = newclass('DeathMatch')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

--	message_system:Subscribe(self, typeof(CS.Oak.StageControlStartEvent), 'on_stage_control_start_event')
--	message_system:Subscribe(self, typeof(CS.Oak.CoopTrollingDetectedEvent), 'on_coop_trolling_detected')
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	return
end

function local_class:need_on_launch()
	return false
end

--[[
function local_class:on_stage_control_start_event(e)
	self.afk_detector = CS.Oak.CoopAfkDetector()
	self.afk_detector:Init()
end

function local_class:on_coop_trolling_detected(e)
	local ci = CS.Oak.CoopClient.Instance

	if ci.IsAlone then
		return true
	end

	local key = string.format('dm_tt_%s', CS.Oak.AuthManager.Instance.UuidHash)
	CS.UnityEngine.PlayerPrefs.SetString(key, CS.GameTime.ServerTime:ToString())
	CS.UnityEngine.PlayerPrefs.Save()

	CS.Oak.NetworkManager.ApiConnection:SendEscapeSaveTroll()

	--CS.Oak.CoopUtil.ShowDisconnectNotice(game_string:Format('escape_banned_inactivity', 20))
	CS.Oak.CoopUtil.ShowDisconnectNotice(game_string:Format(e.MessageKeyString, e.TrollingTimeSec))

	if self.afk_detector ~= nil then
		self.afk_detector:Dispose()
	end
end
--]]

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	--[[
	message_system:Unsubscribe(self, typeof(CS.Oak.StageControlStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopTrollingDetectedEvent))

	if self.afk_detector ~= nil then
		self.afk_detector:Dispose()
		self.afk_detector = nil
	end
	--]]

	self.strongholdObject = nil
	self.cs_controller = nil

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
