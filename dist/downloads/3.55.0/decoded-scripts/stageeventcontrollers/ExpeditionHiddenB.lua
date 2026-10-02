local local_class = newclass('ExpeditionHiddenEventB')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	if stage.PlayHiddenEvent == true then
		message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
		message_system:Subscribe(self, typeof(CS.Oak.ExpeditionEndEvent), 'on_expedition_end')
		message_system:SubscribeOnce(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start')
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed')

		return util.cs_generator(self.load_npc, self, 'expedition_save_npc')
	end
end

function local_class:load_npc(npc_spec_name)
	local created_map = load_util.create_optimized_npcs_async({ save_npc = npc_spec_name })
	local character = created_map['save_npc']

	character.Name = 'hidden_event_save_npc'
	character.Owner = CS.Oak.Player.Local
	character.EntityGroup = CS.Oak.EntityGroups.Neutral0

	-- 캐릭터 캐싱
	self.save_npc = character
	character_manager:RegisterCharacterByName(character)
end

function local_class:on_stage_loaded(e)
	-- NPC 위치 지정
	local zone = CS.Oak.LuaBattleExtensions.GetBattleZoneBounds(party_manager.UserParty.Leader)
	if zone ~= nil then
		self.save_npc.Position = field:GetGroundPositionAt(zone.Bounds.center)
	else
		self.save_npc.Position = vector(0,0,0)
	end

	character_util.set_active_state(self.save_npc, 'enabled')

	-- 마커 추가
	ui_quest_marker:AddQuestMarkerToIFO('exp_hidden_save_npc', -1, true, self.save_npc)
end

function local_class:on_expedition_end(e)
	if self.save_npc and not self.save_npc.CharacterStatsBehaviour.IsDead and
			(self.save_npc.ActiveState & CS.Oak.ActiveState.InField) ~= 0 then
		-- NPC가 살아 있으면, 히든 이벤트 클리어 시킴
		local play_result = e.PlayResult

		-- 일단 Clear 일 때만 성공한 것으로 취급함
		if play_result == CS.Oak.ExpeditionStage.Result.TimeOutClear then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.event_fail_routine, self))
		elseif play_result == CS.Oak.ExpeditionStage.Result.TimeOutFail then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.event_fail_routine, self))
		elseif play_result == CS.Oak.ExpeditionStage.Result.Clear then
			stage:ClearHiddenEvent()
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.event_clear_routine, self))
		elseif play_result == CS.Oak.ExpeditionStage.Result.Defeated then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.event_fail_routine, self))
		end
	end
end

function local_class:event_clear_routine()
	--- 타임오버시에 죽는 것을 방지
	character_util.set_immortal(self.save_npc, true)

	--- 디버프 및 상태이상 제거
	message_system:SendSync(self.save_npc, CS.Oak.CharacterAilmentResetEvent.Instance)
	buff_manager:CureAllDebuffs(self.save_npc, self.save_npc)

	--- 보스 없음
	coroutine.yield(nil)

	--- 팡파레 사운드 종료 대기
	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	local party_leader = CS.Oak.PartyManager.Instance[0].Leader
	local direction = direction_util.get_opposite(direction_util.to_side_dir(party_leader.Direction))
	local pos = party_leader.Position - direction_util.to_vector3(direction) * 1.5
	local dist = vector_util.get_x0z(pos - self.save_npc.Position).magnitude
	local duration = 1
	local speed = math.max(1, dist / duration)
	local waypoints = create_generic_list(unity_class.vector3)
	waypoints:Add(pos)

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	local move_info = CS.Oak.WaypointMoveInfo()

	move_info.speed = speed
	move_info.waypoints = waypoints
	move_info.lastDirection = direction
	move_info.endType = CS.Oak.WaypointMoveEndType.Stop
	move_info.yMode = CS.Oak.CharacterYMode.Free

	CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.save_npc, move_info)

	coroutine.yield(coroutine_class.wait_for_sec(duration))

	character_util.set_direction(self.save_npc, direction)
	character_util.set_anim_and_emotion(self.save_npc,
			{name = 'victory_get', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
			{name = 'smile', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
end

function local_class:event_fail_routine()
	--- 타임오버시에 죽는 것을 방지
	character_util.set_immortal(self.save_npc, true)

	--- 디버프 및 상태이상 제거
	message_system:SendSync(self.save_npc, CS.Oak.CharacterAilmentResetEvent.Instance)
	buff_manager:CureAllDebuffs(self.save_npc, self.save_npc)

	character_util.set_direction(self.save_npc, direction_util.to_side_dir(self.save_npc.Direction))
	character_util.set_anim_and_emotion(self.save_npc,
			{name = 'hurt', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
			{name = 'tired', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
end

function local_class:on_battle_start(e)
	-- NPC를 전투에 참가시킴
	CS.Oak.StageUtil.NpcToAllyInBattle(self.save_npc)
end

function local_class:on_field_object_destroyed(e)
	if lua_helper.reference_equals(e.FieldObject, self.save_npc) then
		-- 마커 제거
		ui_quest_marker:RemoveQuestMarker('exp_hidden_save_npc')
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
