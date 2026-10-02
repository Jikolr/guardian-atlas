local local_class = newclass('NightmareQueenCastle5Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.script = nil

	self.main_quest_id = 460

	self.character = metatable_helper.inherit({
		spec = {
			summer_android = 'summer_android',
		}
	}, function(this, key)
		return get_character(this.spec[key])
	end)

	self.fx = metatable_helper.create_fx_accessor({
		water_splash = function()
			return unity_object_pool.GetOrCreate('fx_fish_water_splash2_loop')
		end
	})

	self.water_state = {
		empty = 'empty_water',
		fill = 'fill_water',
	}

	self.current_water_state = self.water_state.empty

	-- AA72 이벤트 봤는지
	self.is_shown_summer_android = {
		[self.water_state.empty] = false,
		[self.water_state.fill] = false
	}
end

function local_class:dispose()
	self.script:dispose()

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.script = nil

	self.cs_controller = nil
end

function local_class:load_resource()
	local script_path = 'Quest/Nightmare/QueenCastle/Common/WeaponNpcBattleLogic'

	self.script = CS.Oak.StageLuaScript.Create(script_path)

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	self.fx:load_async()
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event()
	self:wreck_setting()

	self:water_switch_setting()

	self:summer_android_setting()

	for i = 1, 2 do
		local assistance = get_character('s3_assistance_' .. i)
		character_util.add_color(assistance, assistance.Name, unity_class.color.black, 0.7, 0)
		field_ui_util.remove_ui(assistance, CS.Oak.FieldUiType.CharacterStats)
	end

	return true
end

function local_class:on_zone_enter_event(e)
	if not self.is_shown_summer_android[self.current_water_state] and
		type_util.is_zone_full_enter(e, get_party_leader(), 'show_summer_android') then

		self.is_shown_summer_android[self.current_water_state] = true

		start_coroutine(self.show_summer_android, self)

		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == self.water_state.empty or e:GetParamAt(0) == self.water_state.fill then
		self.current_water_state = e:GetParamAt(0)
		self:summer_android_setting()
		return true
	end

	return false
end

function local_class:on_interact_event(e)
	if not self.is_interacted_switch and type_util.is_interacted_target(e, self.broken_switch) then
		self.is_interacted_switch = true

		sp_util.start_scene(function()
			--시프티 (진행 방향, idle, idle): 조사가 끝날 때까지 건드리지 않는 게 좋겠습니다.
			music_player_util.play_sfx_one_shot('03_dialogue_worker_03')
			scene_util.play_normal_speech_action(get_character('twins_android_b'), self, nil,
				nil, nil, 'nm_qc_broken_switch_1')

			self.is_interacted_switch = false
		end)

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

	self.script:load()

	stage_start_util.start_function(quest_progress)
end

--- 잔해 세팅
function local_class:wreck_setting()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress ~= nil then
		if quest_progress.InnerProgress < 2 then
			local wreck_pos = field_util.get_marker_pos('s2_wreck_pos')
			get_field_object('s2_wreck_1').Position = wreck_pos
			get_field_object('s2_wreck_2').Position = wreck_pos + vector(0, 0, 2)
		end

		if quest_progress.IsComplete then
			for i = 1, 2 do
				local wreck = get_field_object('s3_wreck_' .. i)
				field_object_util.set_active_state(wreck, active_state_type.disabled)
			end
		end
	end
end

--- 고장난 물 스위치 기믹 처리
function local_class:water_switch_setting()
	self.broken_switch = {}

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress ~= nil then
		if quest_progress.InnerProgress < 2 then
			local broken_switch = get_field_object('s1_broken_switch')
			local normal_switch = get_field_object('s1_normal_switch')

			broken_switch.Position = normal_switch.Position
			normal_switch.Position = vector(999, 0, 999)

			table.insert(self.broken_switch, broken_switch)
		end

		if not quest_progress.IsComplete then
			for i = 1, 3 do
				local broken_switch = get_field_object('s3_broken_switch_' .. i)
				local normal_switch = get_field_object('s3_normal_switch_' .. i)

				broken_switch.Position = normal_switch.Position
				normal_switch.Position = vector(999, 0, 999)

				table.insert(self.broken_switch, broken_switch)
			end
		end
	end
end

--- AA72 세팅
function local_class:summer_android_setting()
	local summer_android = self.character.summer_android

	if self.current_water_state == self.water_state.empty then
		character_util.stop_shake(summer_android)
		scene_util.set_emotion(summer_android, self, 'tired')
		summer_android.Position = vector_util.get_x0z(summer_android.Position, 0)

		if self.fx_water_splash then
			self.fx_water_splash:Dispose()
			self.fx_water_splash = nil
		end

	else
		--AA72 shake 0.03세기로 지속 출력
		character_util.shake(summer_android, 0.03, 999999)
		scene_util.set_emotion(summer_android, self, 'attack')
		summer_android.Position = vector_util.get_x0z(summer_android.Position, 1)
		self.fx_water_splash = self.fx.water_splash():Instantiate(summer_android.Position + vector(0, 0.03, 0))
	end
end

-- AA72 이벤트
function local_class:show_summer_android()
	local summer_android = self.character.summer_android

	local play_sfx = function(sfx_name)
		music_player_util.play_sfx({
			sfx_name = sfx_name,
			parent = summer_android,
			type_priority = 'event',
			player_priority = 'npc'
		})
	end

	if self.current_water_state == self.water_state.empty then
		--AA72 (down, tired, idle): 물이 없어서 수영을 연습할 수 없습니다.
		play_sfx('03_dialogue_worker_03')
		scene_util.play_normal_speech_action(summer_android, self, 'down',
			nil, nil, { key = 'nm_qc_summer_android_1' })

		--AA72 (down, tired, idle): 이대로 가다간…
		scene_util.play_normal_speech_action(summer_android, self, 'down',
			nil, nil, { key = 'nm_qc_summer_android_2' })

		--AA72 (down, tired, idle) (shake): 폐기처분을 당할지도 모릅니다.
		character_util.shake(summer_android, 0.03, 0.5)
		play_sfx('03_dialogue_sadness_01')
		scene_util.play_normal_speech_action(summer_android, self, 'down',
			nil, nil, { key = 'nm_qc_summer_android_3' })

		--AA72 (down, tired, idle): 물이 나올 때까지 기다려봐야겠습니다.
		scene_util.play_normal_speech_action(summer_android, self, 'down',
			nil, nil, { key = 'nm_qc_summer_android_4' })
	else

		--AA72 (down, attack, idle): 어푸! 어푸! 어푸!
		play_sfx('01_water_splash_01')
		scene_util.play_normal_speech_action(summer_android, self, 'down',
			nil, nil, { key = 'nm_qc_summer_android_5' })

		--AA72 (down, attack, idle): 물이 나와서, 어푸! 다행입니다, 어푸!
		play_sfx('03_dialogue_positive_01')
		scene_util.play_normal_speech_action(summer_android, self, 'down',
			nil, nil, { key = 'nm_qc_summer_android_6' })

		--AA72 (down, attack, idle): 폐기처분을, 어푸! 당하지 않게, 어푸, 열심히 해야겠습니다, 어푸!
		play_sfx('03_dialogue_worker_01')
		scene_util.play_normal_speech_action(summer_android, self, 'down',
			nil, nil, { key = 'nm_qc_summer_android_7' })

		--AA72 (down, attack, idle): 목표 시간… 어푸! 1,000시간…. 어푸!
		play_sfx('01_water_splash_01')
		scene_util.play_normal_speech_action(summer_android, self, 'down',
			nil, nil, { key = 'nm_qc_summer_android_8' })
	end
end

return local_class
