local local_class = newclass('QueenCastle2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 330

	--region npc
	self.get_hero_ai = function()
		return get_character('hero_ai')
	end

	self.get_constant_hero_ai = function()
		return get_character('constant_hero_ai')
	end

	self.get_hero_black = function()
		return get_character('hero_ai_black')
	end
	--endregion

	--region field object
	self.get_desk = function()
		return get_field_object('hero_ai_desk')
	end
	--endregion

	--region dynamic npcs
	self.kid_guardian_loop = true
	self.kid_guardian_count = 9
	--endregion

	--region object pool
	self.get_fx_magic_circle = function()
		return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')
	end

	self.get_fx_reset = function()
		return unity_object_pool.GetOrCreate('FX_reset_object')
	end

	self.get_middle_explosion_blue = function()
		return unity_object_pool.GetOrCreate('FX_middle_explosion_blue')
	end
	self.get_fx_statue_laser = function()
		return unity_object_pool.GetOrCreate('fx_queencastle_heavenhold_statue_laser')
	end

	self.get_dead_effect = function()
		return unity_object_pool.GetOrCreate('FX_dead')
	end

	self.get_fx_lasthit = function()
		return unity_object_pool.GetOrCreate('FX_lasthit')
	end
	--endregion

	--region next check
	self.quest_clear_count = 0
	--endregion

	--region field object
	self.get_power_stone_statue = function()
		return get_field_object('power_stone_statue')
	end

	self.get_wisdom_stone_statue = function()
		return get_field_object('wisdom_stone_statue')
	end

	self.get_courage_stone_statue = function()
		return get_field_object('courage_stone_statue')
	end
	--endregion

	--region typing_text
	self.typing_text_obj = nil
	self.typing_text = nil
	self.typing_text_asset_bundle_name = 'ui/prologue'
	self.typing_text_asset_name = 'typing_text'
	--endregion

	self.exit_stage_name = 'exit_queencastle_1_3'

	--region courage challenge
	self.get_jump_tile = function()
		return get_field_object('courage_jump_tile')
	end

	self.is_jumping = false
	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if self.fx_magic_circles then
		for i = 1, #self.fx_magic_circles do
			if type_util.is_zone_full_enter(e, get_party_leader(), self.fx_magic_circles[i].zone_name) then
				start_coroutine(self.teleport_magic_circle, self, i)
				return true
			end
		end
	end

	if type_util.is_zone_full_enter(e, get_party_leader(), 's7_stage_end_zone') and
			self.exit_magic_circle ~= nil then
		sp_util.start_scene(function()
			-- 스테이지 클리어
			screen_util.fade_out_circular_async(1, 'linear')

			screen_util.fade_out_async(0, unity_class.color.black, 'linear')

			CS.Oak.TeleportPartyStageLogic.Execute(self.exit_stage_name, 'queencastle_1_3', '', true)
		end)
	end

	if type_util.is_zone_full_enter(e, get_party_leader(), 'courage_jump_tile_zone') and
			not self.is_jumping and not lua_helper.type_compare(
					user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) then
		if lua_helper.type_compare(user_party.Leader.CharacterBehaviour.CurrentState, CS.Oak.CharacterForcedDashState) then
			sp_util.start_scene(self.accel_jump, self)
		else
			sp_util.start_scene(self.normal_jump, self)
		end
		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'magic_circle_appear' then
		local disposable = e:GetParamAt(4) == 'disposable' and true or false
		self:add_magic_circle(e:GetParamAt(1), e:GetParamAt(2), e:GetParamAt(3), true, disposable, e:GetParamAt(5))
		return true

	elseif e:GetParamAt(0) == 'head_reset_open_1' then
		self.dummy_head_check[1] = true
		return true
	elseif e:GetParamAt(0) == 'head_reset_open_2' then
		self.dummy_head_check[2] = true
		return true

	elseif e:GetParamAt(0) == 'capsule_move' then
		self:kid_guardian_capsule_move()
		return true
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	if e.IsTurningOn and self.dummy_head_check[1] and
			lua_helper.reference_equals(e.SwitchObject, get_field_object('s6_head_reset_switch_1')) then
		self:reset_dummy_head('dummy_head_3_1', 1)
		return true
	elseif e.IsTurningOn and self.dummy_head_check[2] and
			lua_helper.reference_equals(e.SwitchObject, get_field_object('s6_head_reset_switch_2')) then
		self:reset_dummy_head('dummy_head_6_1', 2)
		return true
	end
	return false
end

function local_class:on_stage_end_event(e)
	self.kid_guardian_loop = false
	if self.dynamic_npcs ~= nil then
		for i = 1, self.kid_guardian_count do
			character_util.stop(self.dynamic_npcs['kid_guardian_' .. i])
		end
	end
	return true
end
--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	self.dummy_head_check = nil
	self.dummy_head_pos = nil

	self.kid_guardian_loop = false
	if self.dynamic_npcs ~= nil then
		load_util.dispose_dynamic_npcs(self.dynamic_npcs)
		self.dynamic_npcs = nil
	end

	if self.fx_magic_circles ~= nil then
		for i = 1, #self.fx_magic_circles do
			if self.fx_magic_circles[i].fx ~= nil then
				self.fx_magic_circles[i].fx:Dispose()
				self.fx_magic_circles[i].fx = nil
			end
		end
		self.fx_magic_circles = nil
	end

	if self.exit_magic_circle ~= nil then
		self.exit_magic_circle:Dispose()
		self.exit_magic_circle = nil
	end

	if self.typing_text_obj ~= nil then
		CS.UnityEngine.Object.Destroy(self.typing_text_obj)
		self.typing_text_obj = nil
		self.typing_text = nil
	end

	if self.princess_appear_effect ~= nil then
		CS.UnityEngine.Object.Destroy(self.princess_appear_effect)
		self.princess_appear_effect = nil
	end

	self:stone_laser_dispose()

	if self.res_holder then
		self.res_holder:Dispose()
		self.res_holder = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 맵 npc 세팅
	self:dummy_head_setting()
	start_coroutine(self.kid_guardian_routine, self)

	-- 마법진 세팅
	quest_util.load_pool_resource('MagicCircle_AppearIdle',
			'FX_reset_object',
			'FX_middle_explosion_blue',
			'fx_queencastle_heavenhold_statue_laser',
			'FX_lasthit',
			'FX_dead')

	self:setting_magic_circle()

	-- 점프 타일 세팅
	self.get_jump_tile().FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour.Instance

	-- 석상 세팅
	self:setting_stone_statue()

	-- 안드로이드 머리 세팅
	self.dummy_head_check = { false, false }
	local head_3_1 = get_character('dummy_head_3_1')
	local head_6_1 = get_character('dummy_head_6_1')
	self.dummy_head_pos = { head_3_1.Position + vector(3, 0, 0), head_6_1.Position + vector(3, 0, 0) }

	head_3_1.Hitbox = CS.Oak.Hitbox(vector(0.8, 1, 0.8))
	head_6_1.Hitbox = CS.Oak.Hitbox(vector(0.8, 1, 0.8))


	if main_quest_progress ~= nil and (main_quest_progress.IsComplete or main_quest_progress.InnerProgress > 5) then
		self.dummy_head_check = { true, true }

		character_util.set_position(head_3_1, head_3_1.Position + vector(3, 0, 0))
		head_3_1.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		head_3_1.Holdable = CS.Oak.Holdable()
		head_3_1.Holdable.BounceSfxHandleName = '01_bounce_head_01'
		character_util.set_position(head_6_1, head_6_1.Position + vector(3, 0, 0))
		head_6_1.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		head_6_1.Holdable = CS.Oak.Holdable()
		head_6_1.Holdable.BounceSfxHandleName = '01_bounce_head_01'
	end

	-- 재진입 시에 3개의 시련을 클리어 했을 경우
	if self.quest_clear_count == 3 then
		self:stone_laser_dispose()
	end

	-- exit용 마법진 처리
	if main_quest_progress ~= nil and (main_quest_progress.IsComplete or main_quest_progress.InnerProgress > 6) then
		self.exit_magic_circle = self.get_fx_magic_circle():Instantiate(
				field_util.get_marker_pos('s7_magic_circle_pos'))
	end

	-- typing text 로드
	self.res_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, self.typing_text_asset_bundle_name, self.typing_text_asset_name, function(prefab)
				self.typing_text_obj = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab).gameObject
				self.typing_text = self.typing_text_obj:GetComponent(typeof(CS.UITypingText))

				self.typing_text.Widget:SetAnchor(stage.UIRoot.gameObject, 1, 90, 1, 110)
				self.typing_text.Widget.topAnchor.relative = 0
				self.typing_text.Widget:UpdateAnchors()
				self.typing_text.Label.fontSize = 32
				self.typing_text.Label.color = unity_class.color.white
			end)

	self.typing_text_obj:SetActive(false)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/v2_3_futurecastle/effects/futurecastle', 'fx_event_princess_appear_blue', function(prefab)
				self.princess_appear_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.princess_appear_effect:SetActive(false)
			end)

	--light 관리
	get_field_object('directional_light_1').ActiveState = active_state('disabled')

	local capsule_puzzle_quest_id = 349
	local puzzle_quest_progress = user_progress:GetStartedQuest(capsule_puzzle_quest_id)
	if puzzle_quest_progress ~= nil and puzzle_quest_progress.IsComplete then
		self:set_kid_guardian_capsule()
	end

	-- Only Spine 포함 전체 NPC 1회 업데이트
	local parent_transform = stage.StageTransform
	local child_count = parent_transform.childCount

	for i = 0, child_count - 1 do
		local cur_child = parent_transform:GetChild(i)
		local spine_controller = cur_child:GetComponent(typeof(CS.Oak.SpineController))

		if spine_controller ~= nil then
			spine_controller:ForceUpdateSpines(0)
		end
	end

	-- 용기의 시련 재시작 체크용
	local courage_quest_id = 335
	local quest_progress = user_progress:GetStartedQuest(courage_quest_id)

	-- 시작 연출 관리
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start_after'), true, true)
	elseif main_quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'), false, false)
	elseif main_quest_progress.InnerProgress == 6 and not quest_progress.IsComplete and
			not get_field_object('bravery_proof_chest').FieldObjectBehaviour.IsOpened and
			quest_util.get_custom_state(quest_progress, 'courage_battle_4') >= 0 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start_after'), false, false)
	elseif main_quest_progress.InnerProgress == 6 and not quest_progress.IsComplete and
			quest_util.get_custom_state(quest_progress, 'courage_puzzle_2') == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start_after'), false, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start_after'), true, true)
	end

	-- 애니메이션 door, 길막 npc 처리
	if main_quest_progress ~= nil and (main_quest_progress.IsComplete or main_quest_progress.InnerProgress > 5) then
		local door = get_field_object('s6_gate_1')
		door.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		local animator = door:GetComponent(typeof(CS.UnityEngine.Animator))
		animator:Play('end')

		for i = 1, 4 do
			character_util.set_active_state(get_character('dummy_wall_' .. i), 'disabled')
		end
	end
end

--region 안드로이드 더미 머리 세팅
function local_class:dummy_head_setting()
	local dummy_group = 13
	local head_count = 2
	local angle = { -20, 105 }

	for i = 1, dummy_group do
		for j = 1, head_count do
			local dummy_head = get_character('dummy_head_' .. i .. '_' .. j)
			dummy_head.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
			field_ui_manager:RemoveUI(dummy_head, CS.Oak.FieldUiType.CharacterStats)
			character_util.spine_rotate(dummy_head, angle[j], 0)
		end

		local dummy_wall = get_field_object('dummy_wall_' .. i)
		dummy_wall.Hitbox = CS.Oak.Hitbox(vector(2, 1, 1.5))
	end

	for i = 1, 6 do
		local dummy = get_character('dummy_3_' .. i)
		field_ui_manager:RemoveUI(dummy, CS.Oak.FieldUiType.CharacterStats)
	end
end

function local_class:reset_dummy_head(head_name, index)
	local head = get_character(head_name)
	local effect_pool = unity_object_pool.GetOrCreate('FX_reset_object')
	effect_pool:Instantiate(head.Position)
	character_util.set_position(head, self.dummy_head_pos[index])
	effect_pool:Instantiate(head.Position)
end
--endregion

--region 시험관 꼬마 가디언 루틴
function local_class:set_kid_guardian_capsule()
	local kid_guardian = self.dynamic_npcs['kid_guardian_9']
	kid_guardian.Position = kid_guardian.Position + vector(0, 0, 2)
	local capsule = get_field_object('capsule_move')
	capsule.Position = capsule.Position + vector(0, 0, 2)
end

function local_class:kid_guardian_capsule_move()
	local kid_guardian = self.dynamic_npcs['kid_guardian_9']
	character_util.move_to(kid_guardian, kid_guardian.Position + vector(0, 0, 2), 2)
end

function local_class:kid_guardian_routine()
	self.dynamic_npcs = load_util.create_dynamic_npcs_async({
		kid_guardian_1 = 'qc_kid_guardian',
		kid_guardian_2 = 'qc_kid_guardian',
		kid_guardian_3 = 'qc_kid_guardian',
		kid_guardian_4 = 'qc_kid_guardian',
		kid_guardian_5 = 'qc_kid_guardian',
		kid_guardian_6 = 'qc_kid_guardian',
		kid_guardian_7 = 'qc_kid_guardian',
		kid_guardian_8 = 'qc_kid_guardian',
		kid_guardian_9 = 'qc_kid_guardian',
	})

	local npcs = {}
	for i = 1, self.kid_guardian_count do
		local npc = self.dynamic_npcs['kid_guardian_' .. i]
		npc.SpineController:AddFadeColor('kid_guardian_' .. i, unity_class.color.black, 1, 0)
		character_util.set_position(npc, field_util.get_marker_pos('capsule_pos_' .. i))
		character_util.set_anim(npc, { name = 'idle', loop = false })
		field_ui_manager:RemoveUI(npc, CS.Oak.FieldUiType.CharacterStats)
		character_util.set_active_shadow(npc, false)
		if i ~= self.kid_guardian_count then
			table.insert(npcs, npc)
		end
	end

	local time_passed = 0
	local time_count = 0
	while self.kid_guardian_loop do
		time_passed = time_passed + unity_class.time.deltaTime
		if time_passed >= 2 then
			time_count = time_count + 1
			time_passed = 0
		end

		if time_count == 1 and time_passed == 0 then
			for _, npc in ipairs(npcs) do
				wp_util.move(npc, npc.Position + vector(0, 0.1, 0), nil, 2)
			end
		elseif time_count == 2 and time_passed == 0 then
			time_count = 0
			for _, npc in ipairs(npcs) do
				wp_util.move(npc, npc.Position - vector(0, 0.1, 0), nil, 2)
			end
		end

		coroutine.yield()
	end
end
--endregion

--region 마법진 관리
function local_class:setting_magic_circle()
	self.fx_magic_circles = {}

	local power_quest_id = 333
	local quest_progress = user_progress:GetStartedQuest(power_quest_id)

	-- 힘의 시험 마법진 처리
	if quest_progress == nil or not quest_progress.IsComplete then
		self:add_magic_circle('power_magic_circle_pos_1',
				'power_teleport_zone_1', 'power_teleport_pos_1', false)
	else
		self:add_magic_circle('power_magic_circle_pos_1',
				'power_teleport_zone_1', 'power_teleport_pos_1', true)
	end
	self:add_magic_circle('power_magic_circle_pos_2',
			'power_teleport_zone_2', 'power_teleport_pos_2')

	-- 지혜의 시험 마법진 처리
	local wisdom_quest_id = 334
	quest_progress = user_progress:GetStartedQuest(wisdom_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		self:add_magic_circle('wisdom_magic_circle_pos_1',
				'wisdom_teleport_zone_1', 'wisdom_teleport_pos_1', false, true)
		self:add_magic_circle('wisdom_magic_circle_pos_2',
				'wisdom_teleport_zone_2', 'wisdom_teleport_pos_2')
		self:add_magic_circle('wisdom_magic_circle_pos_3',
				'wisdom_teleport_zone_3', 'wisdom_teleport_pos_3')
		self:add_magic_circle('wisdom_magic_circle_pos_4',
				'wisdom_teleport_zone_4', 'wisdom_teleport_pos_4')
	else
		self:add_magic_circle('wisdom_magic_circle_pos_1',
				'wisdom_teleport_zone_1', 'wisdom_teleport_pos_4')

		self:add_magic_circle('wisdom_magic_circle_pos_7',
				'wisdom_teleport_zone_7', 'wisdom_teleport_pos_7')

		self:add_magic_circle('wisdom_magic_circle_pos_8',
				'wisdom_teleport_zone_8', 'wisdom_teleport_pos_8')
	end

	self:add_magic_circle('wisdom_magic_circle_pos_6',
			'wisdom_teleport_zone_6', 'wisdom_teleport_pos_6')

	-- 용기의 시험 마법진 처리
	local courage_quest_id = 335
	quest_progress = user_progress:GetStartedQuest(courage_quest_id)

	if quest_progress == nil or not quest_progress.IsComplete then
		if quest_util.get_custom_state(quest_progress, 'courage_puzzle_2') ~= 1 then
			self:add_magic_circle('courage_magic_circle_pos_1',
					'courage_teleport_zone_1', 'courage_teleport_pos_1', false)
		end

		self:add_magic_circle('courage_magic_circle_pos_2',
				'courage_teleport_zone_2', 'courage_teleport_pos_2', false, true)
	else
		self:add_magic_circle('courage_magic_circle_pos_1',
				'courage_teleport_zone_1', 'courage_teleport_pos_1')

		self:add_magic_circle('courage_magic_circle_pos_3',
				'courage_teleport_zone_3', 'courage_puzzle_4_end_pos')

		self:add_magic_circle('courage_magic_circle_pos_4',
				'courage_teleport_zone_4', 'courage_4_teleport_pos')
	end
end

--- 마법진 추가
--- @param appear_marker string 마법진 생성 위치
--- @param zone_name string 마법진 공간(해당 공간에 들어갈 경우 순간이동)
--- @param target_marker string 도착 위치(마커의 위치와 방향 적용)
--- @param control boolean 도착 후 컨트롤 조작 여부
--- @param disposable boolean 일회용인지
function local_class:add_magic_circle(appear_marker, zone_name, target_marker, control, disposable, stone_statue)
	control = lua_helper.get_or_default(control, true)
	disposable = lua_helper.get_or_default(disposable, false)
	stone_statue = lua_helper.get_or_default(stone_statue, nil)

	local magic_circle = {
		fx = self.get_fx_magic_circle():Instantiate(field_util.get_marker_pos(appear_marker)),
		zone_name = zone_name,
		target_marker = target_marker,
		control = control,
		disposable = disposable,
		stone_statue = stone_statue
	}

	table.insert(self.fx_magic_circles, magic_circle)
end

function local_class:remove_magic_circle(i)
	self.fx_magic_circles[i].fx:Dispose()
	table.remove(self.fx_magic_circles, i)
end

-- 텔레포트 연출
function local_class:teleport_magic_circle(i)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local leader = get_party_leader()
	local marker = field:GetMarker(self.fx_magic_circles[i].target_marker)
	control = lua_helper.get_or_default(control, true)

	local current_state = leader.FieldObjectBehaviour.CurrentActionState

	if lua_helper.type_compare(current_state, CS.Oak.CharacterHoldUpState) then
		local hold_target = current_state.HoldTarget

		if hold_target ~= nil then
			command_util.execute_throw(leader, hold_target, direction_util.to_vector3(leader.Direction),
					leader.Position, 4, false)
		end
	end

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'npc' })
	character_util.set_direction(leader, 'down')
	scene_util.set_anim(leader, self, 'idle')
	character_util.spine_set_alpha_fade(leader, 0, 0.5)

	wait_for_sec(0.2)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(leader, marker.position)

	local knight_bow = self.get_knight()
	if not lua_helper.reference_equals(leader, knight_bow) then
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		local bow = knight_bow.Weapon1.WeaponSpec.SpriteName

		character_util.set_active_state(knight_bow, 'enabled')
		character_util.set_position(knight_bow, leader.Position)
		character_util.convert_to_manual_character(knight_bow, param, true)
		coroutine.yield()

		character_util.set_position(leader, vector(999, 0, 999))
		character_util.spine_set_alpha_fade(knight_bow, 0, 0)
		character_util.spine_set_alpha_fade(leader, 1, 0)
		knight_bow.SpineController:SetAttachment('[base]weapon1', bow)
		knight_bow.SpineController:SetAttachment('[base]weapon2', 'empty')
		scene_util.show_weapon(knight_bow)

		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'switch_knight_bow' }))
	end

	character_util.set_direction(knight_bow, marker.direction)
	camera_util.return_to_leader(0.5)

	character_util.spine_set_alpha_fade(knight_bow, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	character_util.remove_anim(knight_bow)

	if self.fx_magic_circles[i].control and self.fx_magic_circles[i].stone_statue == nil then
		party_util.reset_controllers()
		field_ui_manager:Show()
	end

	self.fx_magic_circles[i].control = true

	if self.fx_magic_circles[i].stone_statue ~= nil then
		start_coroutine(self.stone_statue_event, self, get_field_object(self.fx_magic_circles[i].stone_statue))
	end

	if self.fx_magic_circles[i].disposable then
		self:remove_magic_circle(i)
	end
end
--endregion

function local_class:challenge_door_open()
	get_field_object('courage_c_wall_1').ActiveState = active_state('disabled')
	get_field_object('courage_c_wall_2').ActiveState = active_state('disabled')
	message_system:Publish(CS.Oak.DoorOpenEvent.Create('wisdom_challange_door'))
end

--region 석상 관리
function local_class:setting_stone_statue()
	self.get_fx_statue_lasers = {}

	if get_field_object('power_proof_chest').FieldObjectBehaviour.IsOpened then
		self.get_power_stone_statue().transform:Find('mesh').localRotation = unity_class.quaternion.Euler(0, 0, 0)
		self:add_statue_laser(self.get_power_stone_statue())
		self.quest_clear_count = self.quest_clear_count + 1
	else
		self.get_power_stone_statue().transform:Find('mesh').localRotation = unity_class.quaternion.Euler(0, 180, 0)
	end

	if get_field_object('wisdom_proof_chest').FieldObjectBehaviour.IsOpened then
		self.get_wisdom_stone_statue().transform:Find('mesh').localRotation = unity_class.quaternion.Euler(0, -120, 0)
		self:add_statue_laser(self.get_wisdom_stone_statue())
		self.quest_clear_count = self.quest_clear_count + 1
	end

	if get_field_object('bravery_proof_chest').FieldObjectBehaviour.IsOpened then
		self.get_courage_stone_statue().transform:Find('mesh').localRotation = unity_class.quaternion.Euler(0, 120, 0)
		self:add_statue_laser(self.get_courage_stone_statue())
		self.quest_clear_count = self.quest_clear_count + 1
	end

	if self.quest_clear_count == 3 then
		self:challenge_door_open()
	end
end

function local_class:add_statue_laser(stone_statue)
	local effect = self.get_fx_statue_laser():Instantiate(stone_statue.Position)

	if stone_statue == self.get_power_stone_statue() then
		effect.transform.localPosition = vector(-0.5, 0, 81.3)
		effect.transform.localScale = vector(1, 1, 0.23)
		effect.transform.localRotation = unity_class.quaternion.Euler(vector(0, 180, 0))
	elseif stone_statue == self.get_wisdom_stone_statue() then
		effect.transform.localPosition = vector(-4.8, 0, 74.5)
		effect.transform.localScale = vector(1, 1, 0.33)
		effect.transform.localRotation = unity_class.quaternion.Euler(vector(0, 54.4, 0))
	else
		effect.transform.localPosition = vector(4.2, 0, 74.5)
		effect.transform.localScale = vector(1, 1, 0.35)
		effect.transform.localRotation = unity_class.quaternion.Euler(vector(0, -56.5, 0))
	end

	table.insert(self.get_fx_statue_lasers, effect)
end

function local_class:stone_laser_dispose()
	if self.get_fx_statue_lasers ~= nil then
		for i, effect in ipairs(self.get_fx_statue_lasers) do
			effect:Dispose()
		end
		self.get_fx_statue_lasers = nil
	end
end

function local_class:stone_statue_event(stone_statue)
	wait_for_sec(0.5)

	local angle = 0
	if stone_statue == self.get_power_stone_statue() then
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'power_test_clear' }))
	elseif stone_statue == self.get_wisdom_stone_statue() then
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'wisdom_test_clear' }))
		angle = -120

		self:add_magic_circle('wisdom_magic_circle_pos_1',
				'wisdom_teleport_zone_1', 'wisdom_teleport_pos_4')

		self:add_magic_circle('wisdom_magic_circle_pos_7',
				'wisdom_teleport_zone_7', 'wisdom_teleport_pos_7')

		self:add_magic_circle('wisdom_magic_circle_pos_8',
				'wisdom_teleport_zone_8', 'wisdom_teleport_pos_8')
	elseif stone_statue == self.get_courage_stone_statue() then
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'courage_test_clear' }))
		angle = 120

		self:add_magic_circle('courage_magic_circle_pos_1',
				'courage_teleport_zone_1', 'courage_teleport_pos_1')

		self:add_magic_circle('courage_magic_circle_pos_3',
				'courage_teleport_zone_3', 'courage_puzzle_4_end_pos')

		self:add_magic_circle('courage_magic_circle_pos_4',
				'courage_teleport_zone_4', 'courage_4_teleport_pos')
	end

	camera_util.resize_by_ratio(6.5, 1.5)
	camera_util.move_async(stone_statue.Position, 1.5)

	music_player_util.play_sfx_one_shot('01_bunker_laser_01')
	local time_passed = 0
	local rotate_time = 2
	local mesh = stone_statue.transform:Find('mesh')
	local start_angle = mesh.localRotation.eulerAngles.y

	while time_passed < rotate_time do
		time_passed = time_passed + unity_class.time.deltaTime

		local cur_angle = unity_class.mathf.Lerp(start_angle, angle, time_passed / rotate_time)
		mesh.localRotation = unity_class.quaternion.Euler(0, cur_angle, 0)
		coroutine.yield()
	end

	mesh.localRotation = unity_class.quaternion.Euler(0, angle, 0)

	stone_statue:Shake(0.04, 1)
	wait_for_sec(1)

	camera_util.cancel_shake()
	camera_util.shake(0.3, 0.5)
	self:add_statue_laser(stone_statue)
	self.quest_clear_count = self.quest_clear_count + 1

	-- 모든 상자를 열었다면
	if self.quest_clear_count == 3 then
		local loop_sfx = music_player_util.play_sfx(
				{ sfx_name = '02_light_laser_loop_01', loop = true, volume = 0.5 })
		wait_for_sec(2.5)

		local constant_hero_ai = self.get_constant_hero_ai()
		local hero_ai = self.get_hero_black()
		local desk_pos = self.get_desk().Position + vector(1.5, 0, 0)
		local constant_hero_ai_pos = desk_pos + vector(0, 2, 0)

		camera_util.resize_by_ratio(3, 1.5)
		camera_util.move_async(desk_pos + vector(0, 0, 1), 1.5)

		character_util.spine_set_alpha_fade(constant_hero_ai, 0, 0)

		music_player_util.play_sfx_one_shot('01_portal_11')
		self.princess_appear_effect.transform.localPosition = constant_hero_ai_pos
		self.princess_appear_effect:SetActive(true)

		character_util.set_position(constant_hero_ai, constant_hero_ai_pos)
		character_util.spine_set_alpha_fade(constant_hero_ai, 1, 1)
		wait_for_sec(1)

		--케이든 AI (down, idle, idle) : 미래의 용사가 시련을 전부 통과했음을 확인
		scene_util.show_normal_speech_async(constant_hero_ai, 'qc_main_s7_1')


		--케이든 AI (down, idle, idle) : 헤븐홀드 비상 복구 시스템을 가동합니다.
		music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
		music_player_util.play_stage_music({ state = 'muted' })
		scene_util.show_normal_speech_async(constant_hero_ai, 'qc_main_s7_2')

		--카메라 shake (0.05, 9999)
		camera_util.shake(0.05, 9999)

		local alpha_loop = true
		music_player_util.play_sfx_one_shot('01_bunker_ui_01')
		start_coroutine(function()
			while alpha_loop do
				music_player_util.play_sfx_one_shot('02_evolve_result_01')
				character_util.spine_set_alpha_fade(constant_hero_ai, 0, 0.5)
				wait_for_sec(0.5)
				character_util.spine_set_alpha_fade(constant_hero_ai, 1, 0.5)
				wait_for_sec(0.5)
			end

			self.get_fx_reset():Instantiate(constant_hero_ai.Position)
			music_player_util.play_sfx_one_shot('01_object_warp_01')
			music_player_util.play_sfx_one_shot('02_evolve_result_01')
			character_util.spine_set_alpha_fade(constant_hero_ai, 0, 0.5)
			wait_for_sec(0.5)

			self:stone_laser_dispose()
			loop_sfx:FadeOut()
			character_util.set_active_state(constant_hero_ai, 'disabled')
		end)

		wait_for_sec(1.5)

		-- 아래 자막 : 오퍼레이션 시작.
		music_player_util.play_sfx_one_shot('01_ui_transition_04')
		scene_util.show_normal_speech_async(constant_hero_ai, 'qc_main_s7_4')

		alpha_loop = false
		camera_util.cancel_shake()
		wait_for_sec(1)

		local hero_ai_pos = desk_pos - vector(0, 0, 2.5)
		camera_util.resize_by_ratio(2.5, 0.5)
		camera_util.move_async(desk_pos - vector(0, 0, 2.5), 0.5)

		character_util.set_position(hero_ai, hero_ai_pos)
		scene_util.set_direction(hero_ai, 'up', false)
		scene_util.set_anim(hero_ai, self, { name = 'idle' })
		hero_ai.SpineController:AddColor(hero_ai.Name, unity_color({ 0, 0, 0, 1 }), 1, 0)

		character_util.set_position(hero_ai, hero_ai_pos + vector(0, 10, 0), true)

		local cur_time = unity_class.time.time
		local start_pos = hero_ai.Position
		local fail_time = 1
		local free_fall = CS.CalculatorFreeFall(fail_time, hero_ai.Position.y, 0)
		while unity_class.time.time - cur_time < fail_time do
			free_fall:Proceed(unity_class.time.deltaTime)
			local dist_y = free_fall:GetDistance()

			if start_pos.y + dist_y > 0 then
				character_util.set_position(hero_ai, start_pos + vector(0, dist_y, 0), true)
			else
				character_util.set_position(hero_ai, vector(start_pos.x, 0, start_pos.z))
			end
			coroutine.yield(nil)
		end

		music_player_util.play_sfx_one_shot('02_stomp_fire_02')
		music_player_util.play_sfx_one_shot('02_princess_provoke_01')
		camera_util.shake(0.3, 0.5)
		self.get_fx_lasthit():Instantiate(hero_ai_pos)
		self.get_dead_effect():Instantiate(hero_ai_pos)
		self.get_middle_explosion_blue():Instantiate(hero_ai_pos)

		wait_for_sec(1)

		camera_util.resize_to_default(1)
		wait_for_sec(1)

		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'hero_ai_ready' }))

		wait_for_sec(2)

		self:challenge_door_open()

		camera_util.resize_to_default(1.5)
		camera_util.return_to_leader(1.5)
		--미래의 용사를 더 강하게 만들기 위한 추가 시련이 열렸습니다.
		field_ui_util.show_narration_async({ key = 'qc_main_s7_5' })

		music_player_util.play_stage_music({ state = 'field' })
	else
		wait_for_sec(2.5)

		camera_util.resize_to_default(1)
		camera_util.return_to_leader(1)
	end

	party_util.reset_controllers()
	field_ui_manager:Show()
end
--endregion

--region 용기의 시련 챌린지
function local_class:normal_jump()
	self.is_jumping = true

	local leader = get_party_leader()
	local jump_tile = self.get_jump_tile()

	jump_tile:GetComponent(typeof(CS.UnityEngine.Animator)):Play('on')
	music_player_util.play_sfx_one_shot('03_jumptile_01')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		wait_for_sec(0.2)
		jump_tile:GetComponent(typeof(CS.UnityEngine.Animator)):Play('off')
		self.is_jumping = false
	end))

	local blizzard_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true })

	scene_util.set_emotion(leader, self, 'attack')
	scene_util.set_anim(leader, self, 'get')

	character_util.jump(leader, 4, 1)
	character_util.move_to_async(leader, leader.Position + vector(12, 0, 0), 1)

	blizzard_sfx:FadeOut(0)
	music_player_util.play_sfx_one_shot('03_runaway_01')
	scene_util.set_emotion(leader, self, 'surprise')
	scene_util.set_anim(leader, self, 'embarrassed')
	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.75, 'linear')

	character_util.remove_anim_and_emotion(leader)
	character_util.set_position(leader, field_util.get_marker_pos('courage_puzzle_1_pos'))
	wait_for_sec(0.3)

	screen_util.fade_in_circular_async(0.75, 'linear')
end

function local_class:accel_jump()
	self.is_jumping = true

	local leader = get_party_leader()

	scene_util.set_emotion(leader, self, 'attack')
	scene_util.set_anim(leader, self, 'get')
	local blizzard_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true })

	local jump_tile = self.get_jump_tile()
	local jump_tile_animator = jump_tile:GetComponent(typeof(CS.UnityEngine.Animator))
	jump_tile_animator.speed = 1.5
	jump_tile_animator:Play('on')
	music_player_util.play_sfx_one_shot('03_jumptile_01')
	start_coroutine(function()
		wait_for_sec(0.2)
		jump_tile_animator:Play('off')
	end)

	character_util.jump(leader, 6, 2)
	character_util.move_to_async(leader, field_util.get_marker_pos('courage_accel_jump_pos'), 2)

	blizzard_sfx:FadeOut(0)
	music_player_util.play_sfx_one_shot('01_land_01')

	character_util.remove_anim_and_emotion(leader)

	local reset_switch = get_field_object('courage_challenge_switch')
	message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(reset_switch))

	self.is_jumping = false
end
--endregion
return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
