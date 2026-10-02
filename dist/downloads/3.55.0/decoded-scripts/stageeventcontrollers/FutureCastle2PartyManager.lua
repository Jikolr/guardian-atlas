local local_class = newclass("FutureCastle2PartyManagerController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 공주
	self.princess = nil

	-- 전투 시에 나오는 진짜 파티원들
	self.saved_party = nil

	-- 전투 존 저장
	self.battle_zone_name = nil

	-- 전투 중인지 확인하는 플래그
	self.is_battle = false

	-- 숨겨진 파티원들의 전투 시작 이벤트가 발생하지 않는 플래그
	self.ignore_battle_hidden_party = false

	-- 기타 상수

	-- 캐릭터 이름
	self.princess_name = 'princess'

	-- 필드 이벤트 존 이름
	self.battle_event_zone_name = 'BATTLE'

	-- 타일맵 마커 이름
	self.default_start_marker_name = 'default_start'

	-- 커스텀 이벤트 이름
	self.ignore_battle_custom_event = 'party_manager_ignore_battle'

	-- 오브젝트 풀 프리셋
	self.teleport_effect_preset = 'FX_reset_object'
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate(self.teleport_effect_preset)

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.WaypointOpenedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.WaypointClosedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.princess = get_character(self.princess_name)

	self.saved_party = create_generic_list(CS.Oak.Character)
	for i = 1, user_party.Count - 1 do
		self.saved_party:Add(user_party[i])
	end
end

function local_class:need_on_launch()
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.BattleStartEvent) then
		self:on_battle_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.BattleEndEvent) then
		self:on_battle_end_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.WaypointOpenedEvent) then
		self:on_waypoint_opened_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.WaypointClosedEvent) then
		self:on_waypoint_closed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	-- 모든 파티원들을 알파 페이드 아웃하고 비활성화
	for i = 0, self.saved_party.Count - 1 do
		character_util.set_active_state(self.saved_party[i], 'disabled')
		character_util.spine_set_alpha_fade(self.saved_party[i], 0, 0)
	end

	local start_marker = field:GetMarker(self.default_start_marker_name)

	character_util.set_immortal(self.princess, true)
	character_util.set_position(self.princess, start_marker.position +
			CS.Oak.DirectionExtensions.ToVector3(CS.Oak.DirectionExtensions.GetOpposite(start_marker.direction)) * 0.7)
	character_util.set_direction(self.princess, start_marker.direction)
end

function local_class:on_stage_start_event(e)
	-- 공주, 플레이어를 제외한 파티원 달리기 이펙트 해제
	for i = 0, self.saved_party.Count - 1 do
		stage.SmokeManager:UnsetCharacterSmoke(self.saved_party[i])
	end

	-- 공주 파티에 포함, 상태는 NPC 유지
	-- 공주는 파티에 아직 안 들어간 상태이므로 index는 (- 파티원 수 + 1)
	character_util.convert_to_following_npc(self.princess, user_party, false,
			CS.Oak.NpcFollowingStateInBattle.Keep, -(user_party.Count - 1))
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if string.find(zone_name, self.battle_event_zone_name) then
		self.battle_zone_name = zone_name
	end
end

function local_class:on_battle_start_event(e)
	if not self.is_battle then
		self.is_battle = true

		self:battle_start(e)
	end
end

function local_class:on_battle_end_event(e)
	if e.IsKill and self.is_battle then
		self.is_battle = false

		self:battle_end()
	end
end

function local_class:on_waypoint_opened_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.waypoint_open, self, e))
end

function local_class:on_waypoint_closed_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.waypoint_close, self))
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == self.ignore_battle_custom_event then
		if not e:GetParamAt(1) or e:GetParamAt(1) == 'true' then
			self.ignore_battle_hidden_party = true

			for i = 0, self.saved_party.Count - 1 do
				self.saved_party[i].FieldObjectController.DontFight = true
			end
		elseif e:GetParamAt(1) == 'false' then
			self.ignore_battle_hidden_party = false

			for i = 0, self.saved_party.Count - 1 do
				self.saved_party[i].FieldObjectController.DontFight = false
			end
		end
	end
end

function local_class:on_field_object_revived_event(e)
	if not self.is_battle and lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		self:reset_princess()
		return true
	end

	return false
end

-- 배틀 시작 시 호출되는 이벤트, 파티원들 등장해서 전투 참여
function local_class:battle_start(e)
	-- 공주 점프
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.princess_battle, self))

	if self.ignore_battle_hidden_party then
		return
	end

	-- 파티원 활성화
	for i = 0, self.saved_party.Count - 1 do
		unity_object_pool.GetOrCreate(self.teleport_effect_preset):Instantiate(self.saved_party[i].Position)

		--배틀 시작되면 Immortal 설정 해제
		character_util.set_immortal(self.saved_party[i], false)

		character_util.set_active_state(self.saved_party[i], 'enabled')
		self.saved_party[i]:SetAlphaFade(1, 0.3)
	end
end

-- 공주 점프해서 이동 후 전투 참여
function local_class:princess_battle()
	character_util.set_direction(self.princess, user_party_leader.Direction)
	character_util.jump(self.princess, 1, 0.3)
	character_util.move_to(self.princess,
			user_party_leader.Position + CS.Oak.DirectionExtensions.ToVector3(user_party_leader.Direction) * 0.5,
			0.3,nil, true, false)

	wait_for_sec(0.3)

	-- 공주도 전투 참여
	CS.Oak.StageUtil.NpcToAllyInBattle(self.princess)
end

-- 배틀 종료 시 호출되는 이벤트, 파티원들 사라짐
function local_class:battle_end()
	-- 공주 NPC로 복구
	self:reset_princess()

	if self.ignore_battle_hidden_party then
		return
	end

	-- 파티원 비활성화
	for i = 0, self.saved_party.Count - 1 do

		-- HeroDeadState인 경우, 강제로 관에 넣음
		if lua_helper.type_compare(self.saved_party[i].FieldObjectBehaviour.CurrentState, CS.Oak.HeroDeadState) then
			self.saved_party[i]:SetCoffin(true)
		end

		-- 파티원이 배틀 끝난 뒤에도 죽지 않도록 Immortal 설정
		character_util.set_immortal(self.saved_party[i], true)

		self.saved_party[i]:SetAlphaFade(0, 0)

		unity_object_pool.GetOrCreate(self.teleport_effect_preset):Instantiate(self.saved_party[i].Position)

		character_util.set_active_state(self.saved_party[i], 'disabled')
	end
end

-- 웨이포인트 열릴 때 파티원들 알파 페이드 인
function local_class:waypoint_open(e)
	local waypoint_pos = e.WaypointPosition

	-- 공주 State 리셋
	self.princess:OnEvent(CS.Oak.StateResetEvent.Instance)

	for i = 0, self.saved_party.Count - 1 do
		character_util.set_active_state(self.saved_party[i], 'enabled')
	end

	coroutine.yield(nil)

	local princess_waypoint_list = create_generic_list(unity_class.vector3)
	princess_waypoint_list:Add(waypoint_pos + vector(-1.7, 0, 0))

	character_util.move_waypoint(self.princess, princess_waypoint_list,
			2, false, 'stop', 'floor', 'right')

	-- 파티원 활성화
	for i = 0, self.saved_party.Count - 1 do
		unity_object_pool.GetOrCreate(self.teleport_effect_preset):Instantiate(self.saved_party[i].Position)

		self.saved_party[i]:SetAlphaFade(1, 0.3)
	end

	character_util.set_anim(self.princess, { name = 'seat' })
	character_util.set_emotion(self.princess, { name = 'blush' })
end

-- 웨이포인트 닫힐 때 파티원들 알파 페이드 아웃
function local_class:waypoint_close()
	-- 공주 NPC로 복구
	self:reset_princess()

	character_util.remove_anim(self.princess)
	character_util.remove_emotion(self.princess)

	-- 파티원 비활성화
	for i = 0, self.saved_party.Count - 1 do
		unity_object_pool.GetOrCreate(self.teleport_effect_preset):Instantiate(self.saved_party[i].Position)

		self.saved_party[i]:SetAlphaFade(0, 0.3)

		character_util.set_active_state(self.saved_party[i], 'disabled')
	end
end

-- 공주 복구
function local_class:reset_princess()
	character_util.convert_to_following_npc(self.princess, user_party, false,
			CS.Oak.NpcFollowingStateInBattle.Keep, -self.saved_party.Count)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.WaypointOpenedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.WaypointClosedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))

	self.princess = nil

	self.saved_party = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
