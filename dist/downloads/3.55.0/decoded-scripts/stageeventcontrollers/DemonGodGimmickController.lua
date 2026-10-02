---@class LaboseWorldDemonGodGimmickController
local local_class = newclass('LaboseWorldDemonGodGimmickController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- fx
	self.fx = {
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}

	self.demongod_gimmicks = {
		---@type LaboseWorldDemonGodAndrasGimmick
		demon_slayer = nil,
		---@type LaboseWorldDemonGodPymonGimmick
		demon_powergirl = nil,
		---@type LaboseWorldDemonGodCrosselleGimmick
		demon_operator = nil
	}

	---@type LaboseWorldDemonGodGimmickBase
	self.cur_demongod_gimmick = nil

	self.stage_ended = false
	self.button_on = false

	self.button = nil
	self.cur_button_owner = nil

	self.button_icon_name = 'actbtn_ic_change.png'

	---@type LaboseWorldScreenplayManager
	self.sp_manager = get_or_create_global_table('Quest/Main/LaboseWorld/Common/LaboseWorldScreenplayManager')

	self.touchable_request = {
		deactivate_request_keys = create_lua_hashset(),
		add_deactivate_request = function(this, key)
			return this.deactivate_request_keys:add(key)
		end,
		remove_deactivate_request = function(this, key)
			return this.deactivate_request_keys:remove(key)
		end,
		is_touchable = function(this)
			return #this.deactivate_request_keys == 0
		end
	}

	self.in_battle_deactivate_key = 'in_battle'
	self.in_fog_deactivate_key = 'in_fog'
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent))

	self.cs_controller = nil

	self.button = nil
	self.cur_button_owner = nil

	if self.demongod_gimmicks ~= nil then
		for _, gimmick in pairs(self.demongod_gimmicks) do
			gimmick:dispose()
		end
		self.demongod_gimmicks = nil
	end
	self.cur_demongod_gimmick = nil

	self.sp_manager = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_gamepad_event')

	self.fx:load_all()
	yield_return(unity_object_pool, 'WaitAll')

	self:load_async()
end

--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_touch_event(e)
	if self.button_on and e.TouchEventType == CS.Oak.TouchEventType.CustomFunction1TouchDown and not self:is_touch_blocked_state() then
		music_player_util.play_sfx_one_shot('01_button_05')
		-- ZoneEnter 등의 이벤트보다 우선순위가 낮으므로 try로만 처리
		self.sp_manager:try_start_coroutine(self.swap_manual_character_scene, self)

		return true
	end

	return false
end

function local_class:on_gamepad_event(e)
	if self.button_on and e.GamepadEventType == CS.Oak.GamepadEventType.RightTriggerDown and not self:is_touch_blocked_state() then
		music_player_util.play_sfx_one_shot('01_button_05')
		-- ZoneEnter 등의 이벤트보다 우선순위가 낮으므로 try로만 처리
		self.sp_manager:try_start_coroutine(self.swap_manual_character_scene, self)

		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'party_fog_collide_state' then
		if e:GetParamAt(1) == 'enter' then
			self:request_deactivate_button(self.in_fog_deactivate_key)

			return true

		elseif e:GetParamAt(1) == 'leave' then
			self:request_activate_button(self.in_fog_deactivate_key)

			return true
		end
	end

	return false
end

function local_class:on_stage_end_event(e)
	self.stage_ended = true
	return true
end

function local_class:on_battle_start_event(e)
	self:request_deactivate_button(self.in_battle_deactivate_key)
end

function local_class:on_battle_end_event(e)
	self:request_activate_button(self.in_battle_deactivate_key)
end

function local_class:on_interact_event(e)
	if self.cur_demongod_gimmick ~= nil then
		self.cur_demongod_gimmick:on_interact_event(e)
	end
end

--endregion

-- 업데이트 루틴
function local_class:update_routine()
	while not self.stage_ended do
		self:update(unity_class.time.deltaTime)
		coroutine.yield(nil)
	end
end

-- 업데이트
function local_class:update(dt)
	self:update_button()

	if self.cur_demongod_gimmick ~= nil then
		self.cur_demongod_gimmick:update(dt)
	end
end

-- 로드
function local_class:load_async()
	self.demongod_gimmicks =
	{
		demon_slayer = get_or_create_global_variable('Quest/Main/LaboseWorld/DemonGod/Gimmick/AndrasGimmick')(),
		demon_powergirl = get_or_create_global_variable('Quest/Main/LaboseWorld/DemonGod/Gimmick/PymonGimmick')(),
		demon_operator = get_or_create_global_variable('Quest/Main/LaboseWorld/DemonGod/Gimmick/CrosselleGimmick')()
	}
	for _, gimmick in pairs(self.demongod_gimmicks) do
		gimmick:load_async()
	end

	---@type LaboseWorldDemonGodGimmickBase
	self:change_demongod_gimmick('demon_slayer')
	self:create_button()

	start_coroutine(self.update_routine, self)
end

-- 버튼 생성
function local_class:create_button()
	local leader = get_party_leader()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	field_ui_manager:SetUI(leader, ui_type)

	self.button = field_ui_manager:GetUI(leader)[ui_type]
	self.cur_button_owner = leader
	message_system:Publish(CS.Oak.FieldUICustomButtonEvent.Create(true))
	self:show_button()
end

function local_class:request_activate_button(key)
	self.touchable_request:remove_deactivate_request(key)
end

function local_class:request_deactivate_button(key)
	self.touchable_request:add_deactivate_request(key)
end

-- 버튼 show
function local_class:show_button()
	local leader = get_party_leader()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	self.button_on = true
	field_ui_manager:ChangeUIOwner(ui_type, self.cur_button_owner, leader)

	self.button:SetIcon(self.button_icon_name)
	field_ui_manager:ShowTargetUI(ui_type, leader)

	self.cur_button_owner = leader
end

-- 버튼 hide
function local_class:hide_button()
	self.button_on = false
	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.CustomButton1, get_party_leader())
end

-- 버튼 update
function local_class:update_button()
	if self.button_on then
		if not self.touchable_request:is_touchable() or self:is_touch_blocked_state() then
			self:hide_button()
		end
	else
		if self.touchable_request:is_touchable() and not self:is_touch_blocked_state() then
			self:show_button()
		end
	end
end

function local_class:is_touch_blocked_state()
	local leader = get_party_leader()

	local is_party_in_action = false

	for i = 1, user_party.Count do
		local member = user_party[i - 1]

		if lua_helper.type_compare(member.CharacterBehaviour.CurrentState, CS.Oak.CharacterJumpState) or
				lua_helper.type_compare(member.CharacterBehaviour.CurrentState, CS.Oak.CharacterHookShotState) then
			is_party_in_action = true

			break
		end
	end

	return lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) or
			lua_helper.type_compare(leader.CharacterBehaviour.CurrentState, CS.Oak.CharacterAssassinateState) or
			lua_helper.type_compare(leader.CharacterBehaviour.CurrentState, CS.Oak.CharacterForcedDashState) or
			is_party_in_action
end

function local_class:swap_manual_character_scene()
	local entered_leader = get_party_leader()

	character_util.cancel_all_battle_actions(entered_leader, true)

	character_util.stop(entered_leader)

	coroutine.yield()

	if lua_helper.type_compare(entered_leader.CharacterBehaviour.CurrentState, CS.Oak.CharacterJumpState) or
			lua_helper.type_compare(entered_leader.CharacterBehaviour.CurrentState, CS.Oak.CharacterForcedDashState) then

		party_util.reset_controllers()

		return
	end

	sp_util.enter_scene({ hide_weapon = false })

	wait_for_sec(0.1)

	self:swap_manual_character_routine()

	sp_util.exit_scene(nil, entered_leader)
end

-- 캐릭터 스왑 처리
function local_class:swap_manual_character_routine()
	local cur_leader = get_party_leader()
	local next_leader = user_party[1]
	local next_party_member_1 = user_party[2]

	stage_camera:SetTarget(nil)

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	param.MoveCamera = false

	character_util.convert_to_manual_character(next_leader, param, true)
	character_util.set_immortal(next_leader, false)

	self:change_demongod_gimmick(next_leader.Name)

	character_util.convert_to_party_member_v2(next_party_member_1, user_party, true)
	character_util.convert_to_party_member_v2(cur_leader, user_party, true)

	party_util.stop_and_disable_control()

	local move_key = 'swap'
	local duration = 0.5
	local has_mover = false

	for i = 0, user_party.Count - 1 do
		local member = user_party[i]
		local target_pos = user_party[(i - 1 + user_party.Count) % user_party.Count].Position
		local move_diff = target_pos - member.Position
		local move_dir = vector_util.to_direction(move_diff)

		if not vector_util.is_almost_zero(move_diff) then
			wp_util.move(member, target_pos, nil, duration, {
				locked_dir = move_dir
			})

			has_mover = true
		end
	end

	if has_mover then
		while true do
			local all_stopped = true

			for i = 0, user_party.Count - 1 do
				local member = user_party[i]

				if member.FieldObjectBehaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped then
					all_stopped = false
					break
				end
			end

			if all_stopped then
				break
			end

			coroutine.yield()
		end
	else
		wait_for_sec(duration)
	end

	-- FIXME : 안개 기믹에서 이모션 바꾼게 안지워지는 케이스가 있어서 일단 꺼주긴 하지만...
	-- 안개쪽에서 리더 체크를 좀 더 명확하게 해주는 게 낫지 않을까 싶음
	party_util.remove_emotion()

	stage_camera:SetTarget(next_leader)
end

-- 기믹 변경
function local_class:change_demongod_gimmick(name)
	if self.cur_demongod_gimmick ~= nil then
		self.cur_demongod_gimmick:exit()
	end

	self.cur_demongod_gimmick = self.demongod_gimmicks[name]
	self.cur_demongod_gimmick:enter()
end

-- 안드라스 전용 크리쳐 interactable 추가
function local_class:add_creature_interactable(fo)
	self.demongod_gimmicks.demon_slayer:add_interactable(fo)
end

function local_class:convert_creature_to_holdable_routine(fo)
	self.demongod_gimmicks.demon_slayer:convert_to_holdable_routine(fo)
end

function local_class:convert_creature_to_holdable_immediately(fo)
	self.demongod_gimmicks.demon_slayer:convert_to_holdable_immediately(fo)
end

function local_class:add_interact_ignore_truck(fo)
	self.demongod_gimmicks.demon_powergirl:add_interact_ignore_object(fo)
end

function local_class:remove_interact_ignore_truck(fo)
	self.demongod_gimmicks.demon_powergirl:remove_interact_ignore_object(fo)
end

-- 파이몬 물건 움직이는 함수
function local_class:move_truck_routine(fo)
	self.demongod_gimmicks.demon_powergirl:move_object_routine(fo)
end

function local_class:get_truck_crash_npc_event_key()
	return self.demongod_gimmicks.demon_powergirl.npc_crash_event_key
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
