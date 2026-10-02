local local_class = newclass('WaterWorldAngelFruitsStageController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 476
	self.quest_progress = nil

	self.is_bgm_started = false
	self.crowd_buzz_bgm = nil
	self.crowd_buzz_sfx_on = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self:bgm_stop()

	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if self.crowd_buzz_sfx_on and type_util.is_zone_full_enter(e, user_party.Leader, 'sub_field') then
		self:bgm_start()
	end
end

function local_class:on_zone_leave_event(e)
	if self.crowd_buzz_sfx_on and type_util.is_zone_full_leave(e, user_party.Leader, 'sub_field') then
		self:bgm_stop()
	end
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if self.quest_progress ~= nil and self.quest_progress.IsComplete == false
			and self.quest_progress.InnerProgress < 4 then
		self.crowd_buzz_sfx_on = true
	end

	stage_start_util.start_function(self.quest_progress)
end

function local_class:bgm_start()
	if self.is_bgm_started then
		return
	end

	self.is_bgm_started = true

	local bgm_name = '01_crowd_buzz_02'

	self.crowd_buzz_bgm = music_player_util.play_sfx({
				sfx_name = bgm_name,
				loop = true,
				type_priority = 'loop',
				player_priority = 'npc',
				fade_in_time = 6,
				volume = 0.5
	})
end

function local_class:bgm_stop()
	if self.crowd_buzz_bgm == nil then
		return
	end

	self.is_bgm_started = false

	music_player_util.fade_out_sfx(self.crowd_buzz_bgm, 1)

	self.crowd_buzz_bgm = nil
end

return local_class
