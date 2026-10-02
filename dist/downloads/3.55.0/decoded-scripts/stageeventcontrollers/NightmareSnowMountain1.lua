local local_class = newclass("NightmareSnowMountain1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 이벤트 존 이름
	self.victim_push_zone_name = 'victim_push_zone'

	-- 루피나 희생자 NPC 수
	self.victim_num = 4

	-- 루피나 희생자 NPC Pushable 동기화 루틴 flag
	self.is_victim_push_routine_update = false

	-- 캐릭터를 가져오는 함수
	self.get_victim = function(num) return get_character('lupina_victim_' .. num) end

	-- 오브젝트를 가져오는 함수
	self.get_victim_pushable = function(num) return get_field_object('lupina_victim_pushable_' .. num) end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.victim_push_zone_name then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.victim_push_routine, self))
				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.victim_push_zone_name then
				self.is_victim_push_routine_update = false
				return true
			end
		end

		for i = 1, self.victim_num do
			local pushable = self.get_victim_pushable(i)

			if lua_helper.reference_equals(e.FieldObject, pushable) then
				if e.Zone.Name == self.victim_push_zone_name then
					local cmd = CS.Oak.PushEndCommand.Create(user_party.Leader, pushable, user_party.Leader.Position, pushable.Position)
					command_util.execute_cmd(cmd)

					music_player:PlaySfxOneShot('01_guild_warp_01')
					for j = 1, self.victim_num do
						local reset_target = self.get_victim_pushable(j)
						message_system:Send(reset_target, CS.Oak.GimmickResetEvent.Instance)
					end
					return true
				end
			end
		end
	end

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_field_object('witch_bookcase')) then
		sp_util.play_normal_screenplay(function()
			field_ui_util.show_narration_async({ key = 'lupina_bookcase'})
		end )
	end

	for i = 1, 8 do
		if lua_helper.reference_equals(e.Target, get_field_object('chest_' .. i)) then
			sp_util.play_normal_screenplay(function()
				field_ui_util.show_narration_async({ key = 'lupina_chest_' .. i})
			end )
		end
	end
end

function local_class:on_stage_loaded_event(e)
	-- 루피나 방의 얼어붙은 NPC들 설정
	for i = 1, self.victim_num do
		local victim = self.get_victim(i)

		field_ui_manager:RemoveUI(victim, CS.Oak.FieldUiType.CharacterStats)
		character_util.set_active_state(victim, 'visible')
	end

	-- 설인들에게 맞고 있는 예티를 지속적으로 shake
	local yeti = get_character('yeti_1')
	character_util.shake(yeti, 0.04, 9999)

	local witch_bed = get_field_object('witch_bed')
	witch_bed.Transform.localScale = vector(1, 1, 1.3)
	witch_bed.Hitbox = CS.Oak.Hitbox(vector(0.75, 0, 0.25), vector(2.6, 1, 2))

	for i = 1, 4 do
		local ice_snowman = get_character('ice_snowman_' .. i)
		ice_snowman.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		field_ui_manager:RemoveUI(ice_snowman, CS.Oak.FieldUiType.CharacterStats)
	end

	return true
end

-- NPC들을 Pushable 오브젝트와 위치를 동기화 시키는 작업
function local_class:victim_push_routine()
	self.is_victim_push_routine_update = true

	while self.is_victim_push_routine_update do
		for i = 1, self.victim_num do
			local victim = self.get_victim(i)
			local pushable = self.get_victim_pushable(i)

			victim.Position = vector_util.get_x0z(pushable.Position)
		end

		coroutine.yield(nil)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
