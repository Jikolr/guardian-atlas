local local_class = newclass('WaterWorld5Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 465
	self.quest_progress = nil

	self.object = {
		energy_extractor = function(idx)
			return get_field_object('energy_extractor_' .. idx)
		end,

		security = function()
			return get_field_object('s16_security')
		end,
	}

	-- 에너지 추출 장치 오브젝트
	self.energy_extractor_count = 36

	self.patrol = {
		data = {
			ww_patrol_detect_1 = {
				npc_prefix = 'patrol_1_',
				group_name = 'patrol_1_battle_zone',
				event_zone = 'patrol_1_battle_zone',
				count = 5
			},
			ww_patrol_detect_2 = {
				npc_prefix = 'patrol_2_',
				group_name = 'patrol_2_battle_zone',
				event_zone = 'patrol_2_battle_zone',
				count = 5
			},
			ww_patrol_detect_3 = {
				npc_prefix = 'patrol_3_',
				group_name = 'patrol_3_battle_zone',
				event_zone = 'patrol_3_battle_zone',
				count = 5
			},
		},


		---@param this self
		---@param e CustomStageEvent
		is_detect = function(this, e)
			local custom_key = e:GetParamAt(0)

			for key, info in pairs(this.data) do
				if key == custom_key then
					start_coroutine(function()
						this:battle_start(info)
					end)

					return true
				end
			end

			return false
		end,

		---@param e CustomStageEvent
		battle_start = function(this, info)
			local count = info.count
			local prefix = info.npc_prefix

			for i = 1, count do
				local npc = get_character(prefix .. i)

				if npc ~= nil then
					character_util.convert_to_monster(npc, info.group_name, info.event_zone)
					command_util.publish_monster_notice(npc, get_party_leader(), 'battle')
				end
			end

			--카메라 shake(0.3, 0.2)
			camera_util.shake(0.3, 0.2)

			--(남)경비(shout 말풍선, 말풍선 크기 1.2, 위치 vector(0.5, 0.75)): 침입자다!
			scene_util.play_shout_speech_action(user_party.Leader, self, nil,
					nil, nil,
					{ key = 'ww_stage_5_1_1', skip = false, viewport_pos = vector(0.5, 0.75), scale = 1.2 })
		end,
	}

	self.amb_sfx = {
		handler = nil,

		---@param this self
		play = function(this, volume, fade_in_time)
			if this.handler ~= nil then
				return
			end

			this.handler = music_player_util.play_sfx({
				sfx_name = '01_amb_exploration_01',
				loop = true,
				type_priority = 'loop',
				volume = volume,
				fade_in_time = fade_in_time
			})
		end,

		change_volume = function(this, volume, duration)
			if this.handler == nil then
				return
			end

			music_player_util.change_sfx_volume(this.handler, volume, duration)
		end,

		---@param this self
		---@param fade_out_time number
		fade_out = function(this, fade_out_time)
			if this.handler == nil then
				return
			end

			music_player_util.fade_out_sfx(this.handler, fade_out_time)
			this.handler = nil
		end,

		---@param this self
		stop = function(this)
			if this.handler == nil then
				return
			end

			music_player_util.stop_sfx(this.handler)
			this.handler = nil
		end
	}
	self.interact_exit_name = nil
end

function local_class:dispose()
	self.cs_controller = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TeleportPartyFadeOutFinishEvent))

	self.amb_sfx:stop()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.TeleportPartyFadeOutFinishEvent), 'on_teleport_party_fadeout_finish_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_custom_stage_event(e)
	if self.patrol:is_detect(e) then
		return true
	end

	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:pre_setting(quest_progress)

	stage_start_util.start_function(quest_progress)
end

function local_class:on_exit_interact_teleport_start_event(e)
	self.interact_exit_name = e.ExitHandleName

	if e.ExitHandleName == 'exit_inside_to_outside' then
		self.amb_sfx:stop()

		return true
	end

	return false
end

function local_class:on_teleport_party_fadeout_finish_event(_)
	if self.interact_exit_name == nil then
		return false
	end

	if self.interact_exit_name == 'exit_outside_to_inside' then
		self.amb_sfx:play()
		self.interact_exit_name = nil

		return true
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	for idx = 1, self.energy_extractor_count do
		local energy_extractor = self.object.energy_extractor(idx)

		if energy_extractor == nil then
			return false
		end

		if lua_helper.reference_equals(e.FieldObject, energy_extractor) then
			camera_util.shake(0.1, 0.3)
			return true
		end
	end

	return false
end

function local_class:pre_setting(quest_progress)
	if quest_progress ~= nil then
		-- 메인 섹션18 이후 오브젝트 애니 변경
		if quest_progress.InnerProgress > 16 then
			local security = self.object.security()

			animator_util.play(security, 'break_idle')
		end
	end
end

return local_class
