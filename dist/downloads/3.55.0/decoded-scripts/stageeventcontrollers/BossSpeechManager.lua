local local_class = newclass("BossSpeechManagerController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 리소스 홀더
	self.resholder = nil
	-- 보스 대사UI 루아테이블
	self.boss_speech = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.UI.BossSpeechEvent), 'on_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.resholder = CS.Foundations.ResourceHolder()

	coroutine.yield(self.resholder:LoadPrefabAsync(CS.Oak.UI.BossSpeech.AssetName,
			function(p)
				local speech_go = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
				self.boss_speech = speech_go:GetComponent(typeof(CS.Oak.UI.BossSpeech)).GetControllerLuaTable
				speech_go:SetActive(false)
			end))
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	if e == nil then
		return false
	end

	self.boss_speech:set_speech(e.SpeechKey, e.SpeechText, e.LabelColor, e.FontSize, e.TypeSpeed, e.WaitTime, e.LabelBgColor, e.PlayDialogue)

	return true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.UI.BossSpeechEvent))

	if self.resholder ~= nil then
		self.resholder:Dispose()
		self.resholder = nil
	end

	self.boss_speech = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
