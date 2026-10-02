local local_class = newclass('CaveBgmManager')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.prev_bgm_name = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	self.prev_bgm_name = stage.Spec.FieldMusicName
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return end
	if e.FieldObject ~= user_party.Leader then return end
	local zone_name = e.Zone.Name

	if zone_name == 'cave_zone' then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_bgm, self, 'bgm_cave_main'))
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave == false then return end
	if e.FieldObject ~= user_party.Leader then return end
	local zone_name = e.Zone.Name

	if zone_name == 'cave_zone' then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_bgm, self, self.prev_bgm_name))
	end

	return false
end

-- 일단 이벤트 상태로 bgm을 자연스럽게 바꾸고 전투 후에 필드 상태로 바뀔것을 대비하여 필드 상태 bgm도 동일한것으로 변경
function local_class:set_bgm(bgm_name)
	music_player_util.play_stage_music({ name = bgm_name, state = 'event', mix = 1 })
	music_player_util.set_stage_music_clip_async({ name = bgm_name, state = 'field' })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
