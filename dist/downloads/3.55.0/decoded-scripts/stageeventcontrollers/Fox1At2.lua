local local_class = newclass('Fox1At2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 이벤트 존 이름
	self.rat_hole_zone_name = 'rat_hole_zone'
	self.rat_passage_zone_name = 'rat_passage_zone'
	self.rat_interact_zone_name = 'rat_interact_zone'

	-- 캐릭터를 가져오는 함수
	self.get_nari = function() return get_character('nari') end
	self.get_mouse_knight = function() return get_character('mouse_knight') end
	self.get_mouse_nari = function() return get_character('mouse_nari') end
	self.get_cat_guard = function(num) return get_character('cat_' .. num) end
	self.get_civil_in_guard = function(num) return get_character('civil_in_guard_' .. num) end
	self.get_rat_hole_cat = function() return get_character('cat') end

	-- 오브젝트를 가져오는 함수
	self.get_rat_passage = function(num) return get_field_object('rat_passage_' .. num) end
	self.get_rat_hole_out = function(num) return get_field_object('rat_hole_out_' .. num) end

	-- 마커를 가져오는 함수
	self.get_cat_guard_reset_marker = function(num) return field:GetMarker('cat_guard_reset_' .. num).position end
	self.get_rat_hole_inside_marker = function(num) return field:GetMarker('rat_hole_inside_' .. num) end

	-- 이펙트 풀을 가져오는 함수
	self.get_dead_effect = function() return unity_object_pool.GetOrCreate('FX_dead') end
	self.get_fx_reset = function() return unity_object_pool.GetOrCreate('FX_reset_object') end

	-- 변신 여부 판정 함수
	self.is_change_rat_party = false

	-- 변신 버튼 활성화 여부
	self.is_transformation_button_enabled = true

	-- 변신 버튼 UI를 붙일 대상
	self.transformation_button_target = nil

	-- 메인 퀘스트(fox_main) id
	self.main_quest_id = 60009

	-- 고양이 가드의 수
	self.cat_guard_count = 2
	-- 쥐 통로의 수
	self.rat_passage_count = 7

	-- 쥐 구멍의 수
	self.rat_hole_count = 5

	-- 현재 disabled_controls 의 리스트
	self.current_disabled_controls = nil

	self.is_transforming = false

	self.human_detect_name = 'fox_guard'
	self.is_detecting = false

	self.bomb_list = {}
	self.bomb_origin_pos_list = {}

	-- 배틀이 진행중인지
	self.battle_playing = false

	-- 퀘스트 마커 이슈 처리용
	self.marker_active_check = false
	-- 퀘스트 마커와 트래커 이름
	self.quest_marker_name = 'fox_main'

	self.button_img = 'ic_mouse_change.png'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_gamepad_event')

	self.get_dead_effect()
	self.get_fx_reset()

	return
end

function local_class:need_on_launch()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress ~= nil and (quest_progress.InnerProgress <= 5 or quest_progress.InnerProgress >= 8) then
		return true
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent))

	self.transformation_button_target = nil
	self.current_control_disabled = nil
	self.bomb_list = nil
	self.bomb_origin_pos_list = nil
	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		return self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.TouchEvent) then
		return self:on_touch_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		return self:on_custom_stage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		return self:on_switch_on_off_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.BattleStartEvent) then
		return self:on_battle_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.BattleEndEvent) then
		return self:on_battle_end_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectRevivedEvent) then
		return self:on_field_object_revived_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.BattleGroupEliminatedEvent) then
		return self:on_battle_group_eliminated_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)

	local target_zone = field:GetZone('bomb_storage')
	local obj_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(target_zone.Bounds, unity_class.vector3.zero)
	for i = 0, obj_list.Count - 1 do
		local obj = obj_list[i]

		if obj.Name == '[GIMMICK]gunpowderpot' then
			table.insert(self.bomb_list, obj)
			table.insert(self.bomb_origin_pos_list, obj.Position)
		end
	end

	obj_list:Dispose()

	return false
end

function local_class:opening_routine(position)
	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)

	wait_for_sec(0.5)

	screen_util.fade_in_circular(1, 'linear')

	coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(position,
			CS.Oak.Direction.Up, game_string:GetString(stage.Name)))
end

function local_class:on_stage_start_event(e)
	self.transformation_button_target = user_party.Leader

	field_ui_manager:SetUI(self.transformation_button_target, CS.Oak.FieldUiType.CustomButton1)
	local custom_ui = field_ui_manager:GetUI(self.transformation_button_target)[CS.Oak.FieldUiType.CustomButton1]
	custom_ui:SetIcon(self.button_img)

	self:set_transformation_button_enable(true)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress.InnerProgress >= 9 or quest_progress.IsComplete then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.opening_routine, self, vector(18.5, 0, 121)))
	end

	return false
end

function local_class:on_touch_event(e)
	if e.TouchEventType == CS.Oak.TouchEventType.CustomFunction1TouchDown
			and self.is_transformation_button_enabled
			and not lua_helper.type_compare(user_party.Leader.FieldObjectBehaviour.CurrentState,
			CS.Oak.CharacterKnockBackState)
			and not lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState)
			and not self.is_transforming
	then
		self.is_transforming = true
		sp_util.play_normal_screenplay(self.touch_transformation_button, self)
		return true
	end

	return false
end

function local_class:on_gamepad_event(e)
	if e.GamepadEventType == CS.Oak.GamepadEventType.RightTriggerDown
			and self.is_transformation_button_enabled
			and not lua_helper.type_compare(user_party.Leader.FieldObjectBehaviour.CurrentState,
			CS.Oak.CharacterKnockBackState)
			and not lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState)
			and not self.is_transforming
	then
		self.is_transforming = true
		sp_util.play_normal_screenplay(self.touch_transformation_button, self)
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.rat_hole_zone_name then
				-- 쥐 구멍에 들어왔을 땐, 캐릭터가 원래 크기로 돌아오게
				self.is_transformation_button_enabled = false
				self:set_transformation_button_enable(false)

				local mouse_knight = self.get_mouse_knight()
				local mouse_nari = self.get_mouse_nari()

				mouse_knight:RemoveGiantFactor('transform')
				mouse_nari:RemoveGiantFactor('transform')
				return true
			elseif e.Zone.Name == self.rat_passage_zone_name then
				-- 통로 안에 들어갔을 땐, 사람으로 돌아오면 안되므로 변신 버튼을 비활성화 시킨다.
				self.is_transformation_button_enabled = false
				if not self.is_transforming then
					self:set_transformation_button_enable(false)
				end
				return true
			end
		end
	end

	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		-- 쥐구멍 근처 이벤트 존에 들어왔을 때, 쥐 일 때는 사용 가능하게 Interact를 켜주고 사람 일 때는 사용 불가능 하게 꺼준다.
		if e.Zone.Name == 'only_rat_interact_zone' then
			local mouse_knight = self.get_mouse_knight()

			if lua_helper.reference_equals(e.FieldObject, mouse_knight) then
				self.current_disabled_controls = { 'attack', 'super', 'assassination', 'party_support_battle_action', 'throw', 'hold' }
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_controls, self, user_party.Leader, self.current_disabled_controls))
				return true
			else
				self.current_disabled_controls = { 'interact' }
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_controls, self, user_party.Leader, self.current_disabled_controls))
				return true
			end
		elseif e.Zone.Name == self.rat_interact_zone_name then
			local mouse_knight = self.get_mouse_knight()

			if lua_helper.reference_equals(e.FieldObject, mouse_knight) then
				self.current_disabled_controls = { 'attack', 'super', 'assassination', 'party_support_battle_action', 'throw', 'hold' }
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_controls, self, user_party.Leader, self.current_disabled_controls))
				return true
			end
		end
	end

	if self.marker_active_check and type_util.is_zone_full_enter(e, user_party.Leader, 'village_entry') then
		ui_quest_marker:RemoveQuestMarker(self.quest_marker_name)
		ui_quest_marker:AddQuestMarkerToIFO(self.quest_marker_name, self.main_quest_id, true, get_character('to_present'))
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.rat_hole_zone_name then
				-- 쥐 구멍에 나왔을 땐, 캐릭터가 0.5배 크기가 되게
				self.is_transformation_button_enabled = true
				self:set_transformation_button_enable(true)

				local mouse_knight = self.get_mouse_knight()
				local mouse_nari = self.get_mouse_nari()

				mouse_knight:SetGiantFactor('transform', 0.5)
				mouse_nari:SetGiantFactor('transform', 0.5)
				return true
			elseif e.Zone.Name == self.rat_passage_zone_name and not self.battle_playing then
				-- 통로 밖으로 나오면, 다시 변신 버튼이 활성화 된다.
				self.is_transformation_button_enabled = true
				if not self.is_transforming then
					self:set_transformation_button_enable(true)
				end
				return true
			end
		end
	end

	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		-- 쥐구멍 근처 이벤트 존에 나갔을 때, 쥐 일 때는 Interact를 꺼주고 사람 일 때는 켜준다.
		if e.Zone.Name == 'only_rat_interact_zone' then
			local mouse_knight = self.get_mouse_knight()

			if lua_helper.reference_equals(e.FieldObject, mouse_knight) then
				self.current_disabled_controls = { 'attack', 'super', 'assassination', 'party_support_battle_action', 'throw', 'hold', 'interact' }
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_controls, self, user_party.Leader, self.current_disabled_controls))
				return true
			else
				self.current_disabled_controls = nil
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_controls, self, user_party.Leader))
				return true
			end

		elseif e.Zone.Name == self.rat_interact_zone_name then
			local mouse_knight = self.get_mouse_knight()

			if lua_helper.reference_equals(e.FieldObject, mouse_knight) then
				self.current_disabled_controls = { 'attack', 'super', 'assassination', 'party_support_battle_action', 'throw', 'hold', 'interact' }
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_controls, self, user_party.Leader, self.current_disabled_controls))
				return true
			end
		end
	end

	if self.marker_active_check and type_util.is_zone_full_leave(e, user_party.Leader, 'village_entry') then
		-- 해당 위치에 적절한 zone이 없어 임의 위치값으로 검사
		local leader_pos = user_party.Leader.Position
		if leader_pos.x > -7 and leader_pos.z > 99 then
			ui_quest_marker:RemoveQuestMarker(self.quest_marker_name)
			ui_quest_marker:AddQuestMarkerToPoint(self.quest_marker_name, self.main_quest_id, true, vector(18.5,0,168))
		end
	end

	return false
end

function local_class:on_custom_stage_event(e)
	-- TODO : Sender와 Target 정보 확인해서 걸리는걸로 바꿔야 함.(고양이와 주민 디텍터 항상 켜져있도록 하기 위함)
	if e.Params[0] == 'cat_guard' then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.detected_cat, self, e.Params[1]))
		return true
	elseif e.Params[0] == self.human_detect_name and not self.is_detecting then
		self.is_detecting = true
		sp_util.play_normal_screenplay(self.detected_human, self, e.Sender)
		return true
	elseif e.Params[0] == 'rat_hole_cat' then
		--coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.detected_rat_hole_cat, self))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.detected_cat, self, e.Params[1]))
		return true
	elseif e.Params[0] == 'change_rat_party' then
		self.is_change_rat_party = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.change_rat_party, self))
		return true
	elseif e.Params[0] == 'change_human_party' then
		self.is_change_rat_party = false
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.change_human_party, self))
		return true
	elseif e.Params[0] == 'transformation_button_enabled' then
		self.is_transformation_button_enabled = true
		self:set_transformation_button_enable(true)
		return true
	elseif e.Params[0] == 'transformation_button_disabled' then
		self.is_transformation_button_enabled = false
		self:set_transformation_button_enable(false)
		return true
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	if lua_helper.reference_equals(e.SwitchObject, get_field_object('bomb_reset_switch')) then
		if e.IsTurningOn then
			local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

			music_player_util.play_sfx({ sfx_name = '02_cast_fail_01' })

			local tint_color = unity_color({0.125, 0.149, 0.353, 1})
			for k, v in pairs(self.bomb_list) do
				local heal_info = CS.Oak.HealInfo()
				heal_info.sender = user_party.Leader
				heal_info.target = v
				heal_info.heal = v.FieldObjectStatsBehaviour.MaxHP
				heal_info.isRevive = true
				command_util.execute_heal(heal_info)

				self.get_fx_reset():Instantiate(self.bomb_origin_pos_list[k])

				if quest_progress.InnerProgress == 8 then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
						v.Position = vector(999, 999, 999)
						coroutine.yield()
						local renderer = v.transform:GetComponentInChildren(typeof(CS.UnityEngine.Renderer))
						renderer.material.color = tint_color
						v.Position = self.bomb_origin_pos_list[k]
					end))
				else
					v.Position = self.bomb_origin_pos_list[k]
				end

			end
			return true
		end
	end

	return false
end

function local_class:on_battle_start_event(e)
	local mouse_knight = self.get_mouse_knight()

	-- 전투 시에는 변신 버튼을 비활성화 시킨다.
	self.is_transformation_button_enabled = false
	self:set_transformation_button_enable(false)
	self.battle_playing = true
	-- 고양이와의 전투는 쥐 상태로 이루어지므로 고양이 전투를 제외한 모든 전투에서는 쥐 상태를 풀어준다.
	local is_cat_battle = e.StartedBattle.AllCharacters:Contains(get_character('present_cat'))
	if not is_cat_battle then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mouse_knight_battle_aggro_toss, self))
		return true
	end

	return false
end

function local_class:on_battle_end_event(e)
	-- 전투가 끝나면 변신 버튼을 다시 활성화 시켜준다.
	--
	--self.is_transformation_button_enabled = true
	--self:set_transformation_button_enable(true)

	return false
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == 'civil_battle_1' or e.BattleGroupName == 'civil_battle_2' then return true end

	self.is_transformation_button_enabled = true
	self:set_transformation_button_enable(true)
	self.battle_playing = false
	return false
end

function local_class:on_field_object_revived_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		local mouse_knight = self.get_mouse_knight()

		if lua_helper.reference_equals(e.FieldObject, mouse_knight) then
		else
		end

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_controls, self, user_party.Leader, self.current_disabled_controls))
	end

	return false
end

function local_class:on_interact_event(e)
	if user_progress:GetStartedQuest(self.main_quest_id).InnerProgress == 5 then return false end

	for i = 1, self.rat_hole_count do
		-- 변신 중에 쥐구멍 인터렉트 시에 무시하도록 수정
		if lua_helper.reference_equals(e.Target, self.get_rat_hole_out(i)) and not self.is_transforming then

			if self.is_change_rat_party then
				CS.Oak.TeleportPartyStageLogic.Execute(self.get_rat_hole_inside_marker(i))
			elseif not self.is_transforming then
				sp_util.play_normal_screenplay(self.interact_to_hole_out, self, i)
			end
			return true
		end
	end

	return false
end

-- 마커 이슈 처리용
function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id then
		if e.CurrentProgress == 9 then
			self.marker_active_check = true
			return true
		end
	end
	return false
end

-- 변신을 해제하고, 배틀 어그로 넘겨주기
function local_class:mouse_knight_battle_aggro_toss()
	local current_battle = stage.BattleManager:GetBattleFor(user_party.Leader)

	-- 무언가로 변신 중이면, 풀릴 때 까지 기다린다.
	while self.is_transforming do
		coroutine.yield()
	end

	-- 쥐인 경우, 사람으로 되돌린다.
	if self.is_change_rat_party then
		self.is_change_rat_party = false
		self.is_transforming = true
		yield_return_func(self.change_human_party, self)
		self.is_transforming = false
	end

	-- 바뀐 리더에게 전투중 어그로를 넘김
	for i = 0, current_battle.Enemies.Count - 1 do
		local monster = current_battle.Enemies[i].Character

		if monster ~= nil and monster.ActiveState == active_state('enabled') then
			command_util.execute_monster_notice(monster, user_party.Leader, 'battle')
		end
	end
end

function local_class:interact_to_hole_out(index)
	if self.is_transforming then return end

	self.is_transforming = true
	self:set_transformation_button_enable(false)

	yield_return_func(self.change_rat_party, self)
	self.is_change_rat_party = not self.is_change_rat_party

	CS.Oak.TeleportPartyStageLogic.Execute(self.get_rat_hole_inside_marker(index))

	wait_for_sec(1)

	self:set_transformation_button_enable(true)
	self.is_transforming = false
end

-- 변신 버튼을 활성화 시킨다.
-- 단, 조건에 부합하지 않으면 (메인 섹션 진행도) 모든 요청을 무시한다.
function local_class:set_transformation_button_enable(flag)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	local target = self.transformation_button_target

	if quest_progress ~= nil and quest_progress.InnerProgress > 5 then
		if flag and self.is_transformation_button_enabled then
			field_ui_manager:SetUI(target, CS.Oak.FieldUiType.CustomButton1)
			return
		end
	end

	field_ui_manager:RemoveUI(target, CS.Oak.FieldUiType.CustomButton1)
end

-- 변신 버튼을 눌렀을 때
function local_class:touch_transformation_button()
	-- 쥐 변신버튼 사이드 이펙트 처리용
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'transformation_touch_start' }))

	self:set_transformation_button_enable(false)
	if not self.is_change_rat_party then
		yield_return_func(self.change_rat_party, self)
	else
		yield_return_func(self.change_human_party, self)
	end

	self.is_change_rat_party = not self.is_change_rat_party

	self:set_transformation_button_enable(true)
	self.is_transforming = false

	-- 쥐 변신버튼 사이드 이펙트 처리용
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'transformation_touch_end' }))
end

-- 파티를 쥐로 변신 시킴.
function local_class:change_rat_party()
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'change_start' }))

	-- 무언가 들고있던 도중이었다면 내려놓게함.
	local current_state = user_party.Leader.FieldObjectBehaviour.CurrentActionState

	if lua_helper.type_compare(current_state, CS.Oak.CharacterHoldUpState) then
		local target = current_state.HoldTarget
		command_util.execute_throw(user_party.Leader, target, CS.Oak.DirectionExtensions.ToVector3(user_party.Leader.Direction), user_party.Leader.Position, 4, false)
	end

	-- 나리가 있을 떄의 처리
	local nari = self.get_nari()
	local follow_friend = user_party:Contains(nari)

	-- 현재 배틀액션을 모두 취소해준다.
	user_party.Leader.CharacterBehaviour:CancelAllBattleActions(true)
	if follow_friend then
		nari.CharacterBehaviour:CancelAllBattleActions(true)
	end
	stage.ProjectileManager:ClearProjectiles()

	-- 파티를 사람에서 쥐로 바꿈
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	local mouse_knight = self.get_mouse_knight()
	local mouse_knight_max_hp = mouse_knight.CharacterStatsBehaviour.MaxHP
	local party_leader_hp_ratio = user_party.Leader.CharacterStatsBehaviour.HpRatio
	local mouse_knight_hp = mouse_knight_max_hp * party_leader_hp_ratio

	param.MoveCamera = false
	self.current_disabled_controls = { 'attack', 'super', 'assassination', 'party_support_battle_action', 'throw', 'hold', 'interact' }

	character_util.remove_anim_and_emotion(user_party.Leader)
	mouse_knight.SpineController:Scale(unity_class.vector3.one, 0)
	mouse_knight.Position = user_party.Leader.Position
	mouse_knight.Direction = user_party.Leader.Direction
	character_util.set_active_state(mouse_knight, 'enabled')
	character_util.set_active_state(user_party.Leader, 'disabled')
	mouse_knight.CharacterStatsBehaviour:ChangeHpToFixedValue(math.floor(mouse_knight_hp))
	camera_util.move_async(mouse_knight.Position, 0.01, { end_target = mouse_knight })
	character_util.convert_to_manual_character(mouse_knight, param)

	if follow_friend then
		local mouse_nari = self.get_mouse_nari()

		local mouse_nari_max_hp = mouse_nari.CharacterStatsBehaviour.MaxHP
		local nari_hp_ratio = nari.CharacterStatsBehaviour.HpRatio
		local mouse_nari_hp = mouse_nari_max_hp * nari_hp_ratio

		character_util.remove_anim_and_emotion(nari)
		mouse_nari.SpineController:Scale(unity_class.vector3.one, 0)
		mouse_nari.Position = nari.Position
		mouse_nari.Direction = nari.Direction
		character_util.set_active_state(mouse_nari, 'enabled')
		character_util.set_active_state(nari, 'disabled')
		mouse_nari.CharacterStatsBehaviour:ChangeHpToFixedValue(math.floor(mouse_nari_hp))
		character_util.convert_to_party_member(mouse_nari, user_party, true)
	end

	-- 쥐 변신 애니메이션. 쥐로 변했다가, 점점 작아짐.
	-- 변신하는 동안에는 컨트롤을 뺏어줌.
	party_util.stop_and_disable_control()

	-- 웨이포인트 가드 처리
	yield_return_func(self.cat_guard_enable, self)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if quest_progress.InnerProgress == 8 and not quest_progress.IsComplete then
		self:human_guard_disable()
	end

	music_player:PlaySfxOneShot('02_explosion_01')
	music_player:PlaySfxOneShot('01_mouse_01')
	for i = 0, user_party.Count - 1 do
		local party = user_party[i]
		self.get_dead_effect():Instantiate(party.Position, unity_class.quaternion.identity, party.transform)
	end

	local duration = 0.03
	local anim_count = 1
	local anim_scale_list = {
		1, 0.8, 0.9, 0.7, 0.8, 0.6, 0.7, 0.5
	}

	for i = 1, #anim_scale_list - 1 do
		local next_scale = anim_scale_list[i] * unity_class.vector3.one
		local prev_scale = anim_scale_list[i + 1] * unity_class.vector3.one

		yield_return_func(self.mario_scale, self, next_scale, prev_scale, duration, anim_count)
	end

	for i = 0, user_party.Count - 1 do
		local party = user_party[i]
		party.SpineController:Scale(unity_class.vector3.one, 0)
		party:SetGiantFactor('transform', 0.5)
	end

	user_party_leader.Position = vector(999, 0, 999)
	if follow_friend then
		nari.Position = vector(999, 0, 999)
	end

	party_util.reset_controllers()

	yield_return_func(self.disabled_controls, self, user_party.Leader, self.current_disabled_controls)

	-- 쥐 통로 처리함
	yield_return_func(self.rat_passage_enable, self)

	-- 다른 이벤트 쪽에서 알 수 있게 캐릭터 변경이 완료됐다고 알려준다.
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'change_end' }))
end

-- 파티를 다시 사람으로 변신을 해제함.
function local_class:change_human_party()
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'change_start' }))

	-- 나리가 있을 떄의 처리
	local mouse_nari = self.get_mouse_nari()
	local follow_friend = user_party:Contains(mouse_nari)

	-- 파티를 쥐에서 원래 파티로 되돌림.
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	local selected_party = CS.Oak.User.Me.Party
	local info = selected_party[0]
	local member_name = CS.Oak.PartyUtil.GeneratePartyName(selected_party, info)
	local origin_member = get_character(member_name)
	local current_member = user_party[0]

	local origin_member_max_hp = origin_member.CharacterStatsBehaviour.MaxHP
	local current_member_hp_ratio = current_member.CharacterStatsBehaviour.HpRatio
	local origin_member_hp = origin_member_max_hp * current_member_hp_ratio

	param.MoveCamera = false
	self.current_disabled_controls = nil

	character_util.remove_anim_and_emotion(current_member)
	origin_member.SpineController:Scale(unity_class.vector3.one * 0.5, 0)
	origin_member.Position = current_member.Position
	origin_member.Direction = current_member.Direction
	character_util.set_active_state(origin_member, 'enabled')
	character_util.set_active_state(current_member, 'disabled')
	origin_member.CharacterStatsBehaviour:ChangeHpToFixedValue(math.floor(origin_member_hp))
	current_member:RemoveGiantFactor('transform')
	camera_util.move_async(origin_member.Position, 0.01, { end_target = origin_member })
	character_util.convert_to_manual_character(origin_member, param)
	--current_member.Position = vector(999, 0, 999)

	if follow_friend then
		local nari = self.get_nari()
		local nari_max_hp = nari.CharacterStatsBehaviour.MaxHP
		local mouse_nari_hp_ratio = mouse_nari.CharacterStatsBehaviour.HpRatio
		local nari_hp = nari_max_hp * mouse_nari_hp_ratio

		character_util.remove_anim_and_emotion(mouse_nari)
		nari.SpineController:Scale(unity_class.vector3.one * 0.5, 0)
		nari.Position = mouse_nari.Position
		nari.Direction = mouse_nari.Direction
		character_util.set_active_state(nari, 'enabled')
		character_util.set_active_state(mouse_nari, 'disabled')
		nari.CharacterStatsBehaviour:ChangeHpToFixedValue(math.floor(nari_hp))
		mouse_nari:RemoveGiantFactor('transform')
		character_util.convert_to_party_member(nari, user_party, true)
		--mouse_nari.Position = vector(999, 0, 999)
	end

	-- 쥐 변신 애니메이션. 쥐가 점점 커졌다가, 사람으로 돌아옴.
	-- 변신하는 동안에는 컨트롤을 뺏어줌.
	party_util.stop_and_disable_control()

	-- 웨이포인트 가드 처리
	yield_return_func(self.cat_guard_disable, self)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if quest_progress.InnerProgress == 8 and not quest_progress.IsComplete then
		self:human_guard_enable()
	end

	music_player:PlaySfxOneShot('02_explosion_01')
	for i = 0, user_party.Count - 1 do
		local party = user_party[i]
		self.get_dead_effect():Instantiate(party.Position, unity_class.quaternion.identity, party.transform)
	end

	local duration = 0.03
	local anim_count = 1
	local anim_scale_list = {
		0.5, 0.7, 0.6, 0.8, 0.7, 0.9, 0.8, 1
	}

	for i = 1, #anim_scale_list - 1 do
		local next_scale = anim_scale_list[i] * unity_class.vector3.one
		local prev_scale = anim_scale_list[i + 1] * unity_class.vector3.one

		yield_return_func(self.mario_scale, self, next_scale, prev_scale, duration, anim_count)
	end

	current_member.Position = vector(999, 0, 999)
	if follow_friend then
		mouse_nari.Position = vector(999, 0, 999)
	end

	party_util.reset_controllers()

	-- 쥐 통로 처리
	yield_return_func(self.rat_passage_disable, self)

	-- 다른 이벤트 쪽에서 알 수 있게 캐릭터 변경이 완료됐다고 알려준다.
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'change_end' }))
end

-- 마리오 버섯 먹고 커지는/작아지는 듯한 연출
function local_class:mario_scale(next_scale, prev_scale, duration, anim_count)
	for i = 1, anim_count do
		for j = 0, user_party.Count - 1 do
			local party = user_party[j]
			party.SpineController:Scale(next_scale, duration)
		end
		wait_for_sec(duration)

		for j = 0, user_party.Count - 1 do
			local party = user_party[j]
			party.SpineController:Scale(prev_scale, duration)
		end
		wait_for_sec(duration)
	end
end

-- 공격, 스킬, 들기, 던지기 등 액션을 disabled 한다.
function local_class:disabled_controls(target, controls)
	local disabled_controls_flag = CS.Oak.DisabledControls.None

	if type_util.is_table(controls) then
		for k, v in pairs(controls) do
			local disabled_type = v

			if v == 'none' then
				disabled_type = CS.Oak.DisabledControls.None
			elseif v == 'move' then
				disabled_type = CS.Oak.DisabledControls.Move
			elseif v == 'dash' then
				disabled_type = CS.Oak.DisabledControls.Dash
			elseif v == 'attack' then
				disabled_type = CS.Oak.DisabledControls.Attack
			elseif v == 'super' then
				disabled_type = CS.Oak.DisabledControls.Super
			elseif v == 'assassination' then
				disabled_type = CS.Oak.DisabledControls.Assassination
			elseif v == 'party_support_battle_action' then
				disabled_type = CS.Oak.DisabledControls.PartySupportBattleAction
			elseif v == 'throw' then
				disabled_type = CS.Oak.DisabledControls.Throw
			elseif v == 'hold' then
				disabled_type = CS.Oak.DisabledControls.Hold
			elseif v == 'interact' then
				disabled_type = CS.Oak.DisabledControls.Interact
			elseif v == 'all' then
				disabled_type = CS.Oak.DisabledControls.All
			end

			disabled_controls_flag = disabled_controls_flag | disabled_type
		end
	end

	local manual_touch_state = target.FieldObjectController.CurrentState

	-- 쥐인 상태에서 Exit에 인터랙트해서 이동할 때, CharacterControllerScreenplayState로 전환돼서 CharacterControllerManualTouchState가 될때까지 기다린다.
	-- 더 좋은 방법이 떠오르지 않아서, 일단 coroutine으로 기다리게 함.
	while manual_touch_state == nil or not lua_helper.type_compare(manual_touch_state, CS.Oak.CharacterControllerManualTouchState) do
		manual_touch_state = target.FieldObjectController.CurrentState
		coroutine.yield(nil)
	end

	manual_touch_state:RequestDisableControl(target, disabled_controls_flag)
end

-- 가드의 부채꼴모양 탐지범위가 서서히 페이드 되어서 나타나게 해줌.
function local_class:way_point_guard_range_fade_in(fo, directions, direction_delay, event_name, sight_distance, sight_angle)
	local duration = 0.5
	local attack_range = CS.AttackRange.CreateArc(vector(999, 0, 999), sight_distance, sight_angle)
	local direction = direction_util.to_vector3(fo.Direction)

	attack_range_util.setup_by_direction(attack_range, fo.Position, direction, 0)
	attack_range_util.show(attack_range, duration)

	wait_for_sec(duration)

	attack_range:Hide()
	CS.UnityEngine.Object.Destroy(attack_range)
	fo.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(cat, directions, direction_delay, event_name, sight_distance, sight_angle)
end

-- 가드의 부채꼴모양 탐지범위가 서서히 페이드 되어서 사라지게 해줌.
function local_class:way_point_guard_range_fade_out(fo)
	local duration = 0.5
	local sight_distance = fo.FieldObjectController.SightDistance
	local sight_angle = fo.FieldObjectController.SightAngle
	local attack_range = CS.AttackRange.CreateArc(vector(999, 0, 999), sight_distance, sight_angle)
	local direction = direction_util.to_vector3(fo.Direction)

	fo.FieldObjectController = CS.Oak.NPCCharacterController()

	attack_range_util.setup_by_direction(attack_range, fo.Position, direction, 0)
	attack_range_util.show(attack_range, duration)

	wait_for_sec(duration)

	attack_range:Hide()
	CS.UnityEngine.Object.Destroy(attack_range)
end

-- 고양이 가드 활성화
function local_class:cat_guard_enable()
	for i = 1, self.cat_guard_count do
		local cat = self.get_cat_guard(i)

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.way_point_guard_range_fade_in, self, cat, nil, 0, 'cat_guard', 4, 60))
	end
end

-- 고양이 가드 비활성화
function local_class:cat_guard_disable()
	for i = 1, self.cat_guard_count do
		local cat = self.get_cat_guard(i)

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.way_point_guard_range_fade_out, self, cat))
	end
end

-- 고양이 가드에게 발각 되었을 때
function local_class:detected_cat(cat_guard_name)
	local cat_guard = get_character(cat_guard_name)
	local cat_guard_reset_marker = field:GetMarker(cat_guard_name .. '_reset')

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	party_util.jump(0.5, 0.3)
	character_util.set_emotion(cat_guard, { name = 'attack' })
	character_util.set_anim(cat_guard, { name = 'angry' })

	party_util.look_at(cat_guard)
	party_util.set_emotion({ name = 'damaged' })
	party_util.set_anim({ name = 'embarrassed' })

	music_player:PlaySfxOneShot('01_cat_hiss_01')
	music_player:PlaySfxOneShot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(cat_guard,
			{ key = 'fox_main_detect_cat', skip = true, bubble_type = 'shout' })

	music_player:PlaySfxOneShot('01_drown_01')
	screen_util.fade_out_circular_async(0.75, 'linear')

	character_util.remove_emotion(cat_guard)
	character_util.remove_anim(cat_guard)
	party_util.remove_emotion()
	party_util.remove_animation()
	party_util.position_party(cat_guard_reset_marker.position, cat_guard_reset_marker.direction, 'linear')
	wait_for_sec(0.3)
	screen_util.fade_in_circular_async(0.75, 'linear')

	party_util.reset_controllers()
	field_ui_manager:Show()

	yield_return_func(self.disabled_controls, self, user_party.Leader, self.current_disabled_controls)
end

function local_class:human_guard_enable()
	for i = 3, 14 do
		if self.get_civil_in_guard(i).ActiveState == active_state('enabled') then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.way_point_guard_range_fade_in, self,
					self.get_civil_in_guard(i), nil, 0, self.human_detect_name, 4, 60))

		end
	end
end

function local_class:human_guard_disable()
	for i = 3, 14 do
		if self.get_civil_in_guard(i).ActiveState == active_state('enabled') then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.way_point_guard_range_fade_out, self,
					self.get_civil_in_guard(i)))
		end
	end
end

function local_class:detected_human(detector)

	character_util.set_anim(detector, {name = 'release'})
	character_util.set_emotion(detector, {name = 'attack'})

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	music_player:PlaySfxOneShot('03_runaway_01')
	party_util.look_at(detector)
	party_util.set_emotion({ name = 'scared' })
	party_util.set_anim({ name = 'embarrassed' })
	speech_bubble_util.show_speech_bubble_async(detector, {key = 'fox_main_detect_human', skip = true})
	wait_for_sec(1)

	music_player:PlaySfxOneShot('01_drown_01')
	screen_util.fade_out_circular_async(0.75, 'linear')

	character_util.remove_anim_and_emotion(detector)
	party_util.remove_emotion()
	party_util.remove_animation()

	if table_util.contain_value({
		self.get_civil_in_guard(3),
		self.get_civil_in_guard(4),
		self.get_civil_in_guard(5),
		self.get_civil_in_guard(6),
		self.get_civil_in_guard(7),
		self.get_civil_in_guard(8),
		self.get_civil_in_guard(9),
		self.get_civil_in_guard(10),
		self.get_civil_in_guard(13),
		self.get_civil_in_guard(14),
	}, detector) then
		party_util.position_party(vector(3, 0, 54), 'left', 'linear')

	elseif table_util.contain_value({
		self.get_civil_in_guard(11),
		self.get_civil_in_guard(12),
	}, detector) then
		party_util.position_party(vector(-50, 0, 38), 'right', 'linear')
	end
	wait_for_sec(0.3)
	screen_util.fade_in_circular_async(0.75, 'linear')

	message_system:Publish(CS.Oak.DoorOpenEvent.Create('jail_door', true))
	self.is_detecting = false
end

-- 쥐 구멍에 있는 고양이에게 발각 되었을 때, 플레이어를 강제로 하단으로 이동시킴.
function local_class:detected_rat_hole_cat()
	party_util.stop_and_disable_control()

	party_util.set_emotion({ name = 'scared' })
	party_util.set_anim({ name = 'embarrassed' })

	character_util.move_waypoint_async(user_party.Leader, user_party.Leader.Position + vector(0, 0, -7), 7, true, nil, nil, nil)

	party_util.remove_emotion()
	party_util.remove_animation()

	party_util.reset_controllers()
end

-- FIXME: 쥐 통로로 쓰일 오브젝트가 아직 나오지 않아서, 임시로 다른 기믹을 써서 쥐가 아닐때는 못 지나가게 처리함.
-- 쥐 통로 활성화
function local_class:rat_passage_enable()
	for i = 1, self.rat_passage_count do
		local passage = self.get_rat_passage(i)

		passage.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end
end

-- 쥐 통로 비활성화
function local_class:rat_passage_disable()
	for i = 1, self.rat_passage_count do
		local passage = self.get_rat_passage(i)

		passage.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
