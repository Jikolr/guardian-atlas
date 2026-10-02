local local_class = newclass('PixyWorld6Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	--region Character
	--꼬마 공주
	self.get_princess = function()
		return get_character('princess')
	end

	--코르네
	self.get_pixy_girl = function()
		return get_character('pixy_girl')
	end

	--배틀 몬스터 (인베이더)
	self.get_battle_invader = function(number, idx)
		return get_character('s21_battle_invader_' .. number .. '_' .. idx)
	end

	--픽시
	self.get_pixy = function(number)
		return get_character('pixy_' .. number)
	end

	--전투용 픽시
	self.get_pixy_battle = function(number)
		return get_character('battle_pixy_' .. number)
	end

	--인베이더
	self.get_invader = function(number)
		return get_character('s21_invader_' .. number)
	end
	--endregion Character

	--region field object
	self.get_rock = function(number)
		return get_field_object('s21_rock_' .. number)
	end

	self.get_pixy_interacting = function(number)
		return get_field_object('s21_pixy_interacting_' .. number)
	end
	--endregion field object

	--region Marker
	--중앙 마커
	self.get_center_pos = function(number)
		return field_util.get_marker_pos('s21_center_pos_' .. number)
	end
	--endregion Marker

	--region Fx
	self.fx = {
		hit = function()
			return unity_object_pool.GetOrCreate('FX_hit')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}

	--endregion Fx

	--region Etc
	self.custom_state_name = 'escape_pixy'
	self.current_escape_pixy_state = nil
	self.current_craft_state = nil

	self.door_name = 's21_door_4'

	self.is_in_battle = false

	self.battle_zone_name = 's21_battle_zone_'

	self.battle_data = {
		{
			invaders = nil,
			zone_name = self.battle_zone_name .. 1,
			group_name = 's21_battle_zone_1',
			gate_name = 's21_battle_gate_1',
			is_battle = false,
			is_clear = false
		},
		{
			invaders = nil,
			zone_name = self.battle_zone_name .. 2,
			group_name = 's21_battle_zone_2',
			gate_name = 's21_battle_gate_2',
			is_battle = false,
			is_clear = false
		}
	}

	self.battle_pixy_party_list = {}

	self.pw_util = nil

	--퀘스트 마커 네임
	self.quest_marker_name = 'main_quest_marker'

	self.wait_pos = vector(999, 0, 999)

	self.attack_duration = nil

	self.attack_routine_list = {}

	-- 메인 퀘스트 id
	self.main_quest_id = 412

	self.stage_controller = nil

	self.quest_progress = nil

	self.background_attacher = nil

	self.renderer = nil

	self.material = nil

	self.background_color_red_color = nil

	self.boomerang_controller = nil

	self.tint_fade_check_list = {
		fade_in = false,
		fade_out = false
	}
	--endregion Etc
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractFinishEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractCancelEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 파티멤버 전투 시에만 등장 로직 / 전투 팔로우 배틀 로직
	custom_stage_option_util.register_option({
		break_in_party_member = {},
		follow_npc_battle_logic = { quest_id = 412 },
	})
	self.fx:load_all()

	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_obj_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractCancelEvent), 'on_interact_cancel_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractFinishEvent), 'on_interact_finish_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')

	self.background_attacher = get_or_create_global_table(
			'Quest/Main/PixyWorld/Common/BackgroundAttacher'
	)

	self.background_attacher:load_async()

	self:pre_setting()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'interacting' then
		--마울 주민 구출 구간 #2
		local pixy_6 = self.get_pixy_interacting(6)
		local pixy_7 = self.get_pixy_interacting(7)
		local pixy_8 = self.get_pixy_interacting(8)
		local pixy_9 = self.get_pixy_interacting(9)

		message_system:SendSync(get_party_leader(), CS.Oak.StateResetEvent.Instance)

		if self.is_in_battle and
				(lua_helper.reference_equals(e.Sender, pixy_6) or
						lua_helper.reference_equals(e.Sender, pixy_7) or
						lua_helper.reference_equals(e.Sender, pixy_8) or
						lua_helper.reference_equals(e.Sender, pixy_9)) then
			local index = tonumber(string.sub(e.Sender.Name, string.len(e.Sender.Name), string.len(e.Sender.Name)))
			local pixy = self.get_pixy_battle(index)

			self.battle_pixy_party_list["pixy_" .. index] = {
				target = pixy,
				pos = pixy.Position,
				dir = pixy.Direction,
				index = index }

			character_util.remove_anim_and_emotion(pixy)
			character_util.convert_to_non_party_player(pixy)

			-- 무적 상태로 변경
			character_util.set_immortal(pixy, true)

			local battle = stage.BattleManager:GetBattleForMyParty()
			pixy:OnEvent(CS.Oak.BattleStartEvent.Create(battle))

			e.Sender.Position = self.wait_pos

			return true
		end

		--배틀 중이 아닐때 2번째 구출 구간
		if not self.is_in_battle and
				(lua_helper.reference_equals(e.Sender, pixy_6) or
						lua_helper.reference_equals(e.Sender, pixy_7) or
						lua_helper.reference_equals(e.Sender, pixy_8) or
						lua_helper.reference_equals(e.Sender, pixy_9)) then
			local index = tonumber(string.sub(e.Sender.Name, string.len(e.Sender.Name), string.len(e.Sender.Name)))

			e.Sender.Position = self.wait_pos

			start_coroutine(self.escape_pixy, self, index)

			return true
		end
	end
end

function local_class:on_interact_event(e)
	--마울 주민 구출 구간 #1
	local pixy_5 = self.get_pixy(5)

	if lua_helper.reference_equals(e.Target, pixy_5) then
		start_coroutine(self.escape_pixy, self, 5)

		return true
	end

	--마울 주민 구출 구간 #3
	local pixy_10 = self.get_pixy(10)
	if lua_helper.reference_equals(e.Target, pixy_10) then
		start_coroutine(self.escape_pixy, self, 10)

		return true
	end

	return false
end

function local_class:on_battle_start_event(e)
	self.is_in_battle = true

	return true
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.battle_data[1].group_name then
		self.is_in_battle = false

		self:end_battle()

		return
	end

	if e.BattleGroupName == self.battle_data[2].group_name then
		self.is_in_battle = false

		self:end_battle()

		return
	end

	return
end

function local_class:on_field_obj_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, self.get_invader(1)) then
		self.attack_routine_list[e.FieldObject.Name] = false

		start_coroutine(self.escape_pixy, self, 1)

		return
	end

	if lua_helper.reference_equals(e.FieldObject, self.get_invader(3)) then
		self.attack_routine_list[e.FieldObject.Name] = false

		start_coroutine(self.escape_pixy, self, 3)

		return
	end

	return
end

function local_class:on_interact_cancel_event()
	if not self.is_in_battle then
		start_coroutine(function()
			-- TODO: 배틀 시 부메랑 버튼이 사라진 상태에서 ui가 저장되므로, 타이밍 상 활성화 시켜도 활성화가 되지 않아 1프레임 기다림
			coroutine.yield(nil)

			self.boomerang_controller:boomerang_active_setting(true)
		end)
	end

	return true
end
function local_class:on_interact_finish_event()
	if not self.is_in_battle then
		start_coroutine(function()
			-- TODO: 배틀 시 부메랑 버튼이 사라진 상태에서 ui가 저장되므로, 타이밍 상 활성화 시켜도 활성화가 되지 않아 1프레임 기다림
			coroutine.yield(nil)

			self.boomerang_controller:boomerang_active_setting(true)
		end)
	end

	return true
end

function local_class:on_camera_grid_enter_event(e)
	if not self.quest_progress.IsComplete and self.quest_progress.InnerProgress >= 21 then
		if type_util.is_player_enter_to_cam_grid(e, 'default_town_grid') then
			start_coroutine(self.background_color_fade_out, self, 1)

		elseif type_util.is_player_enter_to_cam_grid(e, 'red_town_grid') then
			start_coroutine(self.background_color_fade_in, self, 1)
		end
	end

	return false
end

--endregion event

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.boomerang_controller = get_stage_event_controller('PixyWorldBoomerangController')

	if self.quest_progress.InnerProgress < 23 then
		music_player_util.set_stage_music_clip_async({ name = 'bgm_suspense_theme', state = 'field' })
	end

	-- 시작 연출
	if self.quest_progress == nil or self.quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif self.quest_progress.InnerProgress == 19 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), false, true)
	elseif self.quest_progress.InnerProgress == 20 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s21_start_pos'), true, true)
	elseif self.quest_progress.InnerProgress == 21 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s22_start_pos'), true, true)
	elseif self.quest_progress.InnerProgress == 22 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s23_start_pos'), true, true)
	elseif self.quest_progress.InnerProgress == 23 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), false, false)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

--region section21
--region custom
function local_class:pre_setting()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.current_escape_pixy_state = self.quest_progress:GetCustomState(self.custom_state_name)

	self.renderer = self.background_attacher.background_objects['default']:GetComponentInChildren(typeof(CS.UnityEngine.MeshRenderer))

	self.material = self.renderer.material

	local background_color = nil

	self.background_color = {
		default_color = unity_class.color(1, 0, 0, 0),
		red = unity_class.color(1, 0, 0, 20 / 255)
	}

	if self.quest_progress.IsComplete or self.quest_progress.InnerProgress > 21 then
		background_color = self.background_color.default
	else
		--23섹션 이전
		--항상 적용
		--정해진 위치에 fire_floor_2x2 배치 필요.
		--필드 80% 붉게 틴트
		background_color = self.background_color.red
	end

	self.material.color = background_color

	--current state가 -1일 경우 제대로 작동하지 않으므로 초기화 작업
	if self.current_escape_pixy_state == -1 then
		self.current_escape_pixy_state = 0
	end

	character_util.set_immortal(self.get_pixy_girl(), true)
	character_util.set_immortal(self.get_princess(), true)

	--요정 세팅
	if self.quest_progress.InnerProgress < 22 then
		self:npc_setting()
	end

	message_system:Publish(CS.Oak.ChangeTilemapVisualEvent.Create('controller_town'))
end

function local_class:npc_setting()
	local center_1_pos = self.get_center_pos(1)
	local center_2_pos = self.get_center_pos(2)
	local center_3_pos = self.get_center_pos(3)

	--
	local npc_data = {
		--픽시 1번
		--pw_pixy_male_a, left, scared, idle, shake 지속.
		{
			target = self.get_pixy(1),
			pos = center_1_pos + vector(4, 0, 0),
			dir = 'right',
			emo = 'scared',
			anim = 'prostrate',
			shake = true,
			index = 1
		},
		--픽시 2번
		--pw_pixy_female_a, left, scared, idle, shake 지속.
		{
			target = self.get_pixy(2),
			pos = center_1_pos + vector(5, 0, 0),
			dir = 'right',
			emo = 'scared',
			anim = 'prostrate',
			shake = true,
			index = 2
		},
		--픽시 3번
		--pw_pixy_male_b, left, scared, prostrate
		{
			target = self.get_pixy(3),
			pos = center_3_pos + vector(5.5, 0, 0),
			dir = 'left',
			emo = 'scared',
			anim = 'prostrate',
			shake = true,
			index = 3,
			--is_crash = true,
			--is_listener = true,
		},
		--픽시 4번
		--pw_pixy_traitor, up, scared, success
		{
			target = self.get_pixy(4),
			pos = center_3_pos + vector(0, 0, -6),
			dir = 'up',
			emo = 'scared',
			anim = 'success',
			index = 4,
		},
		--픽시 5번
		--pw_pixy_guard, right, damaged, prostrate
		{
			target = self.get_pixy(5),
			pos = center_1_pos + vector(-4, 0, -0.5),
			dir = 'right',
			emo = 'damaged',
			anim = 'prostrate',
			is_crash = true,
			is_listener = true,
			index = 5,
		},
		--픽시 6번
		--pw_pixy_female_b, right, damaged, prostrate
		{
			target = self.get_pixy_battle(6),
			pos = center_2_pos + vector(-10, 0, 0),
			dir = 'right',
			emo = 'damaged',
			anim = 'prostrate',
			is_crash = true,
			interacting = self.get_pixy_interacting(6),
			index = 6,
		},
		--픽시 7번
		--pw_pixy_male_b, left, damaged, hurt
		{
			target = self.get_pixy_battle(7),
			pos = center_2_pos + vector(-7.5, 0, -7.5),
			dir = 'left',
			emo = 'damaged',
			anim = 'hurt',
			is_crash = true,
			interacting = self.get_pixy_interacting(7),
			index = 7,
		},
		--픽시 8번
		--pw_pixy_female_a, right, damaged, hurt
		{
			target = self.get_pixy_battle(8),
			pos = center_2_pos + vector(5, 0, 0),
			dir = 'right',
			emo = 'damaged',
			anim = 'hurt',
			is_crash = true,
			interacting = self.get_pixy_interacting(8),
			index = 8,
		},
		--픽시 9번
		--pw_pixy_guard, left, damaged, prostrate
		{
			target = self.get_pixy_battle(9),
			pos = center_2_pos + vector(10.5, 0, 5.5),
			dir = 'left',
			emo = 'damaged',
			anim = 'prostrate',
			is_crash = true,
			interacting = self.get_pixy_interacting(9),
			index = 9,
		},
		--픽시 10번
		--pw_pixy_male_a, right, scared, idle, shake 지속하는 상태.
		{
			target = self.get_pixy(10),
			pos = center_3_pos + vector(-6, 0, 1),
			dir = 'right',
			emo = 'scared',
			anim = 'prostrate',
			is_crash = true,
			is_listener = true,
			shake = true,
			index = 10,
		},
		--촌장
		--pw_pixy_female_b, up, scared, success
		{
			target = self.get_pixy(11),
			pos = center_3_pos + vector(-1, 0, -6),
			dir = 'up',
			emo = 'scared',
			anim = 'success',
			index = 11,
		},
		--인베이더1
		{
			target = self.get_invader(1),
			pos = center_1_pos + vector(3, 0, 0),
			dir = 'right',
			emo = 'attack',
			anim = 'attack',
			is_crash = true,
			attack_fo = self.get_pixy(1),
			is_monster = true,
			index = 1,
		},
		----인베이더2
		--{
		--	target = self.get_invader(2),
		--	pos = center_1_pos + vector(3, 0, -0.5),
		--	dir = 'right',
		--	emo = 'attack',
		--	anim = 'attack',
		--	is_crash = true,
		--	attack_fo = self.get_pixy(2),
		--	is_monster = true,
		--	index = 2,
		--},
		--인베이더3
		{
			target = self.get_invader(3),
			pos = center_3_pos + vector(5.5, 0, 1),
			dir = 'down',
			emo = 'attack',
			anim = 'attack',
			is_crash = true,
			attack_fo = self.get_pixy(3),
			is_monster = true,
			index = 3,
		}
	}

	for _, target_data in pairs(npc_data) do
		local target = target_data.target
		local target_pos = target_data.pos
		local target_dir = target_data.dir
		local target_emo = target_data.emo
		local target_anim = target_data.anim
		local target_tint = target_data.tint
		local target_shake = target_data.shake
		local target_is_anim_loop = target_data.is_anim_loop
		local target_is_crash = target_data.is_crash
		local target_is_listener = target_data.is_listener
		local target_interacting = target_data.interacting
		local target_attack_fo = target_data.attack_fo
		local target_is_monster = target_data.is_monster
		local target_index = target_data.index
		local target_hit_box = target_data.hit_box

		if self:is_escape_pixy(target_index) then
			goto continue
		end

		field_object_util.set_active_state(target, active_state_type.enabled)

		character_util.set_position(target, target_pos)

		character_util.remove_anim_and_emotion(target)

		scene_util.set_direction(target, target_dir, false)

		if target_emo then
			scene_util.set_emotion(target, self, target_emo)
		end

		if target_anim then
			scene_util.set_anim(target, self, { name = target_anim, loop = target_is_anim_loop })
		end

		if target_hit_box then
			target.Hitbox = target_hit_box
		end

		if target_shake then
			scene_util.shake(target, 0.03, 9999)
		end

		if target_tint then
			character_util.add_color(target, 'dark_tint', unity_class.color.black, 0.7, 0)
		end

		if target_is_crash then
			field_object_util.set_active_state(target, active_state_type.enabled)
			target.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		else
			target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		end

		if target_is_listener then
			target.Interactable = CS.Oak.NPCInteractable.Create()
			character_util.add_listener(target, self)
		end

		if target_interacting then
			target_interacting.Position = target_pos
			--field_object_util.set_active_state(target_interacting, active_state_type.visible)
		end

		if target_is_monster then
			character_util.convert_to_monster(target)
			target.DamagedBehaviour = CS.Oak.MonsterAssassinateDamagedBehaviour.Create()
			target.FieldObjectController.DontFight = true
			target.DamagedBehaviour.ShowDamageNumber = false
			target.DamagedBehaviour.ApplyOtherDamage = false
			target.DamagedBehaviour.ApplyAilment = false
			target.DamagedBehaviour.ApplyBombDamage = false
			field_ui_manager:RemoveUI(target, CS.Oak.FieldUiType.TopHpBar)
			message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(target, true))

			character_util.set_death_type(target, 'airspin')
			scene_util.show_weapon(target)
		end

		if target_attack_fo then
			start_coroutine(function()
				local invader = target
				local pixy = target_attack_fo
				local attack_duration = spine_util.get_animation_duration(invader, 'attack')

				self.attack_routine_list[invader.Name] = true

				while self.attack_routine_list[invader.Name] and (self.quest_progress.InnerProgress < 22) do
					scene_util.set_anim(invader, self, { name = 'attack', sfx_name = '02_hit_big_01', count = 1 })

					wait_for_sec(attack_duration * 0.5)

					if self.attack_routine_list[invader.Name] then
						character_util.spine_damage_red_pulse(pixy)
						character_util.spine_damage_squish_default(pixy)

						music_player_util.play_sfx({
							sfx_name = '02_normal_slash_02', loop = false, parent = pixy, player_priority = 'npc'
						})
						self.fx.hit():Instantiate(pixy.Bounds.center)

						wait_for_sec(attack_duration * 0.5)

						wait_for_sec(0.5)
					end
				end
			end)
		end

		:: continue ::
	end
end

function local_class:end_battle()
	local wait_all_list = {}

	for _, value in pairs(self.battle_pixy_party_list) do
		character_util.convert_to_npc(value.target)

		table.insert(wait_all_list, util.cs_generator(function()
			local target = value.target
			local target_pos = value.pos
			local target_dir = value.dir
			local target_index = value.index

			target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

			wp_util.move_async(target, target_pos, nil, 1)
			target.Direction = target_dir

			self:escape_pixy(target_index, true)
		end))
	end

	self.battle_pixy_party_list = {}
	start_coroutine(function()
		wait_all(wait_all_list)
	end)
end

function local_class:escape_pixy(index_number, is_battle)
	self:save_current_escape_pixy(index_number)

	if index_number == 1 then
		-- 두 명의 연출 이므로 예외처리
		self:save_current_escape_pixy(2)

		--1번 픽시, 2번 픽시
		self:escape_pixy_1()
	elseif index_number == 3 then
		-- 3번 픽시
		self:escape_pixy_3()
	elseif index_number == 5 then
		-- 5번 픽시
		self:escape_pixy_5()
	elseif index_number == 6 then
		-- 6번 픽시
		self:escape_pixy_6(is_battle)
	elseif index_number == 7 then
		-- 7번 픽시
		self:escape_pixy_7(is_battle)
	elseif index_number == 8 then
		-- 8번 픽시
		self:escape_pixy_8(is_battle)
	elseif index_number == 9 then
		-- 9번 픽시
		self:escape_pixy_9(is_battle)
	elseif index_number == 10 then
		-- 10번 픽시
		self:escape_pixy_10()
	end
end

function local_class:escape_pixy_common(npc_data)
	local escape_list = {}
	for _, pixy in pairs(npc_data) do
		table.insert(escape_list, util.cs_generator(function()
			character_util.remove_anim_and_emotion(pixy.target)
			scene_util.set_emotion(pixy.target, self, 'attack')

			wp_util.move_async(pixy.target, pixy.pos.first, 6)
			character_util.spine_set_alpha_fade_v2(pixy.target, 0, 0.5)
			wp_util.move_async(pixy.target, pixy.pos.second, 6)

			pixy.target.Position = self.wait_pos
		end))
	end

	--이후 속도 6으로 정해진 동선 따라 카메라 그리드 너머로 이동한다.
	--이동할 때 표정 attack으로.
	--그리드 너머로 넘어가는 순간 1초간 알파페이드 아웃되며 사라지도록 처리.
	wait_all(escape_list)
end

--픽시 1,2번 탈출 연출
function local_class:escape_pixy_1()
	local center_1_pos = self.get_center_pos(1)

	local npc_data = {
		pixy_1 = {
			target = self.get_pixy(1),
			pos = {
				first = {
					center_1_pos + vector(0, 0, 0),
					center_1_pos + vector(0, 0, -5)
				},
				second = {
					center_1_pos + vector(0, 0, -9)
				}
			}
		},
		pixy_2 = {
			target = self.get_pixy(2),
			pos = {
				first = {
					center_1_pos + vector(0, 0, 0),
					center_1_pos + vector(0, 0, -5)
				},
				second = {
					center_1_pos + vector(0, 0, -9)
				}
			}
		}
	}
	character_util.stop_shake(npc_data.pixy_1.target)
	character_util.stop_shake(npc_data.pixy_2.target)

	wait_for_sec(0.5)

	--픽시 1, 2번은 이더리얼로 처리.
	--1회 shake 후, 픽시 1, 2번이 마리오점프하며 일어난다.
	wait_all({
		util.cs_generator(scene_util.shake_and_wakeup, npc_data.pixy_1.target, 'right', 1, nil, true),
		util.cs_generator(scene_util.shake_and_wakeup, npc_data.pixy_2.target, 'right', 1, nil, true)
	})

	--픽시 2번도 left, smile, cast.
	scene_util.set_emotion(npc_data.pixy_2.target, self, 'smile')
	scene_util.set_anim(npc_data.pixy_2.target, self, 'cast')

	scene_util.set_direction(npc_data.pixy_1.target, 'left', false)
	scene_util.set_direction(npc_data.pixy_2.target, 'left', false)

	--픽시 1번(left, smile, cast, 스킵 불가능) : 살려주셔서 감사합니다, 용사님!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(npc_data.pixy_1.target, self,
			nil,
			'cast',
			'smile',
			{ key = 'pw_main_s21_1', skip = false })

	self:escape_pixy_common(npc_data)
end

function local_class:escape_pixy_3()
	local center_3_pos = self.get_center_pos(3)

	local npc_data = {
		pixy_3 = {
			target = self.get_pixy(3),
			pos = {
				first = {
					center_3_pos + vector(6, 0, 3),
					center_3_pos + vector(5, 0, 3),
					center_3_pos + vector(5, 0, 4),
					center_3_pos + vector(1, 0, 4),
					center_3_pos + vector(1, 0, 7),
				},
				second = {
					center_3_pos + vector(1, 0, 11)
				}
			}
		}
	}
	--픽시 3번은 이더리얼로 처리.
	--1회 shake 후, 픽시 3번이 마리오점프하며 일어난다.
	scene_util.shake_and_wakeup(npc_data.pixy_3.target, 'right', 1, nil, true)

	--character_util.remove_relate_event(npc_data.pixy_3.target, self)
	character_util.stop_shake(npc_data.pixy_3.target)

	wait_for_sec(0.5)

	npc_data.pixy_3.target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	--이후 속도 6으로 정해진 동선 따라 카메라 그리드 너머로 이동한다.
	--그리드 너머로 넘어가는 순간 1초간 알파페이드 아웃되며 사라지도록 처리.
	--픽시 3번은(left, smile, cast, 스킵 불가능) : 살려주셔서 감사합니다, 용사님!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(npc_data.pixy_3.target, self,
			nil,
			'cast',
			'smile',
			{ key = 'pw_main_s21_7', skip = false })

	self:escape_pixy_common(npc_data)
end

--픽시 5번 탈출 연출
function local_class:escape_pixy_5()
	local center_1_pos = self.get_center_pos(1)

	local npc_data = {
		pixy_5 = {
			target = self.get_pixy(5),
			pos = {
				first = {
					center_1_pos + vector(-4, 0, 1.5),
					center_1_pos + vector(-2, 0, 1.5),
					center_1_pos + vector(-2, 0, -5),
				},
				second = {
					center_1_pos + vector(-2, 0, -9)
				}
			}
		},
	}

	character_util.remove_relate_event(npc_data.pixy_5.target, self)

	npc_data.pixy_5.target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	--npc가 2회 shake 한 후, 마리오 점프하며 일어난다.
	scene_util.shake_and_wakeup(npc_data.pixy_5.target, 'right', 2, nil, true)

	if get_party_leader().Position.x > npc_data.pixy_5.target.Position.x then
		scene_util.set_direction(npc_data.pixy_5.target, 'right', false)
	else
		scene_util.set_direction(npc_data.pixy_5.target, 'left', false)
	end

	--이후, 대사 픽시 5번(파티리더 바라본 채로(left/right로만.), smile, cast, 스킵 불가능) : 도와주셔서 감사합니다, 용사님!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(npc_data.pixy_5.target, self,
			nil,
			'cast',
			'smile',
			{ key = 'pw_main_s21_2', skip = false })

	self:escape_pixy_common(npc_data)
end

function local_class:escape_pixy_6(is_battle)
	local center_2_pos = self.get_center_pos(2)

	local npc_data = {
		pixy_6 = {
			target = self.get_pixy_battle(6),
			pos = {
				first = {
					center_2_pos + vector(-10, 0, -7.5),
					center_2_pos + vector(-1.5, 0, -7.5),
					center_2_pos + vector(-1.5, 0, -10.5),
				},
				second = {
					center_2_pos + vector(-1.5, 0, -14.5)
				}
			}
		},
	}
	character_util.remove_relate_event(npc_data.pixy_6.target, self)

	npc_data.pixy_6.target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	if not is_battle then
		npc_data.pixy_6.target.SpineController:ForceUpdateSpines(1)
		--npc가 2회 shake 한 후, 마리오 점프하며 일어난다.
		scene_util.shake_and_wakeup(npc_data.pixy_6.target, 'right', 2, nil, true)

		npc_data.pixy_6.target.SpineController:ForceUpdateSpines(1)
	end

	if get_party_leader().Position.x > npc_data.pixy_6.target.Position.x then
		scene_util.set_direction(npc_data.pixy_6.target, 'right', false)
	else
		scene_util.set_direction(npc_data.pixy_6.target, 'left', false)
	end

	--이후, 대사 픽시 6번(파티리더 바라본 채로(left/right로만.), smile, cast, 스킵 불가능) : 도와주셔서 감사합니다, 용사님!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(npc_data.pixy_6.target, self,
			nil,
			'cast',
			'smile',
			{ key = 'pw_main_s21_3', skip = false })

	self:escape_pixy_common(npc_data)
end

function local_class:escape_pixy_7(is_battle)
	local center_2_pos = self.get_center_pos(2)
	local npc_data = {
		pixy_7 = {
			target = self.get_pixy_battle(7),
			pos = {
				first = {
					center_2_pos + vector(-1.5, 0, -7.5),
					center_2_pos + vector(-1.5, 0, -10.5),
				},
				second = {
					center_2_pos + vector(-1.5, 0, -14.5),
				}
			}
		},
	}
	character_util.remove_relate_event(npc_data.pixy_7.target, self)

	npc_data.pixy_7.target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	if not is_battle then
		npc_data.pixy_7.target.SpineController:ForceUpdateSpines(1)

		--npc가 2회 shake 한 후, 마리오 점프하며 일어난다.
		scene_util.shake_and_wakeup(npc_data.pixy_7.target, 'right', 2, nil, true)

		npc_data.pixy_7.target.SpineController:ForceUpdateSpines(1)
	end

	if get_party_leader().Position.x > npc_data.pixy_7.target.Position.x then
		scene_util.set_direction(npc_data.pixy_7.target, 'right', false)
	else
		scene_util.set_direction(npc_data.pixy_7.target, 'left', false)
	end

	--이후, 대사 픽시 7번(파티리더 바라본 채로(left/right로만.), smile, cast, 스킵 불가능) : 도와주셔서 감사합니다, 용사님!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(npc_data.pixy_7.target, self,
			nil,
			'cast',
			'smile',
			{ key = 'pw_main_s21_4', skip = false })

	self:escape_pixy_common(npc_data)
end

function local_class:escape_pixy_8(is_battle)
	local center_2_pos = self.get_center_pos(2)

	local npc_data = {
		pixy_8 = {
			target = self.get_pixy_battle(8),
			pos = {
				first = {
					center_2_pos + vector(10.5, 0, 0),
					center_2_pos + vector(10.5, 0, -7.5),
					center_2_pos + vector(1.5, 0, -7.5),
					center_2_pos + vector(1.5, 0, -10.5),
				},
				second = {
					center_2_pos + vector(1.5, 0, -14.5)
				}
			}
		},
	}

	character_util.remove_relate_event(npc_data.pixy_8.target, self)

	npc_data.pixy_8.target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	if not is_battle then
		npc_data.pixy_8.target.SpineController:ForceUpdateSpines(1)

		--npc가 2회 shake 한 후, 마리오 점프하며 일어난다.
		scene_util.shake_and_wakeup(npc_data.pixy_8.target, 'right', 2, nil, true)

		npc_data.pixy_8.target.SpineController:ForceUpdateSpines(1)
	end

	if get_party_leader().Position.x > npc_data.pixy_8.target.Position.x then
		scene_util.set_direction(npc_data.pixy_8.target, 'right', false)
	else
		scene_util.set_direction(npc_data.pixy_8.target, 'left', false)
	end

	--이후, 대사 픽시 8번(파티리더 바라본 채로(left/right로만.), smile, cast, 스킵 불가능) : 도와주셔서 감사합니다, 용사님!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(npc_data.pixy_8.target, self,
			nil,
			'cast',
			'smile',
			{ key = 'pw_main_s21_5', skip = false })

	self:escape_pixy_common(npc_data)
end

function local_class:escape_pixy_9(is_battle)
	local center_2_pos = self.get_center_pos(2)

	local npc_data = {
		pixy_9 = {
			target = self.get_pixy_battle(9),
			pos = {
				first = {
					center_2_pos + vector(10.5, 0, -7.5),
					center_2_pos + vector(1.5, 0, -7.5),
					center_2_pos + vector(1.5, 0, -10.5),
				},
				second = {
					center_2_pos + vector(1.5, 0, -14.5),
				}
			}
		},
	}

	character_util.remove_relate_event(npc_data.pixy_9.target, self)

	npc_data.pixy_9.target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	if not is_battle then
		npc_data.pixy_9.target.SpineController:ForceUpdateSpines(1)

		--npc가 2회 shake 한 후, 마리오 점프하며 일어난다.
		scene_util.shake_and_wakeup(npc_data.pixy_9.target, 'right', 2, nil, true)

		npc_data.pixy_9.target.SpineController:ForceUpdateSpines(1)
	end

	if get_party_leader().Position.x > npc_data.pixy_9.target.Position.x then
		scene_util.set_direction(npc_data.pixy_9.target, 'right', false)
	else
		scene_util.set_direction(npc_data.pixy_9.target, 'left', false)
	end

	--이후, 대사 픽시 9번(파티리더 바라본 채로(left/right로만.), smile, cast, 스킵 불가능) : 도와주셔서 감사합니다, 용사님!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(npc_data.pixy_9.target, self,
			nil,
			'cast',
			'smile',
			{ key = 'pw_main_s21_6', skip = false })

	self:escape_pixy_common(npc_data)
end

function local_class:escape_pixy_10()
	local center_3_pos = self.get_center_pos(3)

	local npc_data = {
		pixy_10 = {
			target = self.get_pixy(10),
			pos = {
				first = {
					center_3_pos + vector(-6, 0, 5),
					center_3_pos + vector(-1, 0, 5),
					center_3_pos + vector(-1, 0, 7),
				},
				second = {
					center_3_pos + vector(-1, 0, 11),
				}
			}
		},
	}

	character_util.stop_shake(npc_data.pixy_10.target)
	character_util.remove_relate_event(npc_data.pixy_10.target, self)

	npc_data.pixy_10.target.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	--npc가 2회 shake 한 후, 마리오 점프하며 일어난다.
	scene_util.shake_and_wakeup(npc_data.pixy_10.target, 'right', 2, nil, true)

	local look_dir = vector_util.to_direction(get_party_leader().Position - npc_data.pixy_10.target.Position)
	character_util.set_direction(npc_data.pixy_10.target, CS.Oak.DirectionExtensions.GetSideDirection(look_dir))

	--이후, 대사 픽시 10번(파티리더 바라본 채로(left/right로만.), smile, cast, 스킵 불가능) : 도와주셔서 감사합니다, 용사님!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(npc_data.pixy_10.target, self,
			nil,
			'cast',
			'smile',
			{ key = 'pw_main_s21_20', skip = false })

	self:escape_pixy_common(npc_data)
end

function local_class:save_current_escape_pixy(number)
	--current state가 -1일 경우 제대로 작동하지 않으므로 초기화 작업
	if self.current_escape_pixy_state == -1 then
		self.current_escape_pixy_state = 0
	end

	self.current_escape_pixy_state = self.current_escape_pixy_state | (1 << number)

	quest_util.set_custom_state(self.quest_progress, self.custom_state_name, self.current_escape_pixy_state)
end

function local_class:is_escape_pixy(number)
	local bit = 1 << number
	return (self.current_escape_pixy_state & bit) == bit
end

--배경 페이드 아웃

function local_class:background_color_fade_in(duration)
	local start_value = self.material.color.a

	coroutine_util.while_each_frame(duration, function(progress)
		local cur_value = unity_class.mathf.Lerp(start_value, self.background_color.red.a, progress)

		self.material.color = unity_class.color(self.background_color.red.r, 0, 0, cur_value)
	end)
end

function local_class:background_color_fade_out(duration)
	local start_value = self.material.color.a

	coroutine_util.while_each_frame(duration, function(progress)
		local cur_value = unity_class.mathf.Lerp(start_value, 0, progress)

		self.material.color = unity_class.color(self.background_color.red.r, 0, 0, cur_value)
	end)
end

--endregion section21

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
