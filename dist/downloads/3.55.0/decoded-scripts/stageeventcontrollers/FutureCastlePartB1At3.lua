local local_class = newclass("FutureCastlePartB1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 캐릭터 가져오기
	self.get_princess = function() return get_character('princess') end
	self.get_lorain_head = function() return get_field_object('lorain_head') end

	-- 로레인 머리 상태
	self.lorain_head_state = { princess_owned = 1, hold_up = 2, stage_end = 3 }

	-- 현재 로레인 머리 상태
	self.current_lorain_head_state = self.lorain_head_state.princess_owned

	-- 로레인 머리 이벤트중인지?
	self.is_lorain_head_event = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	if self.is_lorain_head_event then
		message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	end

	self.current_lorain_head_state = self.lorain_head_state.stage_end
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'lorain_head_hold_up' then
		self.current_lorain_head_state = self.lorain_head_state.hold_up
		return true
	elseif e:GetParamAt(0) == 'lorain_head_event_start' then
		self.is_lorain_head_event = true
		message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_fo_event')
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.lorain_head_update_frame, self))
		return true
	end

	return false
end

function local_class:on_move_fo_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party_leader) and self.current_lorain_head_state == self.lorain_head_state.hold_up then
		local lorain_head = self.get_lorain_head()
		lorain_head.Position = vector(user_party_leader.Position.x, user_party_leader.Position.y + 1, user_party_leader.Position.z)
	end

	return false
end

-- 로레인 머리 Update Frame
function local_class:lorain_head_update_frame()
	local princess = self.get_princess()
	local princess_weapon_name = self.get_princess().Weapon2.WeaponSpec.SpriteName

	-- 공주가 로레인 머리 들고있을 때의 방향별 방패 스프라이트 이름
	local shield_sprite_names = {}
	shield_sprite_names[CS.Oak.Direction.Down] = 'loraine_head_front'
	shield_sprite_names[CS.Oak.Direction.Up] = 'loraine_head_back'
	shield_sprite_names[CS.Oak.Direction.Right] = 'loraine_head_side'
	shield_sprite_names[CS.Oak.Direction.Left] = 'loraine_head_side'

	-- 공주의 로레인 방패 방향 보정
	while self.current_lorain_head_state == self.lorain_head_state.princess_owned do
		princess.SpineController:SetAttachment('[base]weapon2', shield_sprite_names[princess.Direction])
		coroutine.yield(nil)
	end

	-- 공주가 들고있는 상태가 끝났으니 원래 방패로 변경
	princess.SpineController:SetAttachment('[base]weapon2', princess_weapon_name)

	local lorain_head = self.get_lorain_head()
	local spine_controller = lorain_head.UnityGameObject:GetComponent(typeof(CS.Oak.SpineController))

	-- 로레인 머리 스파인 방향 보정
	while self.current_lorain_head_state == self.lorain_head_state.hold_up do
		spine_controller.Direction = user_party_leader.Direction
		coroutine.yield(nil)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}