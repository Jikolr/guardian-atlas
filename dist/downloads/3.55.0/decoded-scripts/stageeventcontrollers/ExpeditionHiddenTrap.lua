local local_class = newclass('ExpeditionHiddenEventTrap')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	self.is_loaded = false
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_stage_loaded_event(e)
	self.is_loaded = true

	-- 스테이지 로드 시점에서 이벤트 세팅
	self.item = get_field_object('floating_item_1')
	self.do_event = not self.item.FieldObjectBehaviour.IsGetted
	self.event_triggered = false

	self.npcs = character_manager:GetAllNpcs()

	if not self.do_event then
		-- NPC 들 다 안보이게 처리
		for i = 0, self.npcs.Count - 1 do
			self.npcs[i].ActiveState = active_state('disabled')
		end

		-- 배틀 게이트 동작 안하게 처리
		local gates = field:GetFieldObjectsWithBehaviour(typeof(CS.Oak.BattleGateBehaviour))

		for i = 0, gates.Count - 1 do
			gates[i].FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour.Instance
		end

		gates:Dispose()
	end

	return true
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if not self.is_loaded then
		return
	end

	if not self.do_event then
		return
	end

	if self.event_triggered then
		return
	end

	if self.event_triggered == false and
			self.item.FieldObjectBehaviour.IsGetted and
			CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(user_party.Leader.FieldObjectController.CurrentState,
					typeof(CS.Oak.CharacterControllerManualTouchState)) then

		self.event_triggered = true
		self:start_battle_event()
	end
end

function local_class:start_battle_event()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.monster_direction, self))
end


function local_class:monster_direction()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	-- 몬스터들 분노 연출
	local sb = speech_bubble_util.generate_speech_bubble(user_party.Leader, {
		key = 'expedition_talk_hidden_spider_shout',
		skip = false,
		bubble_type = 'shout',
		life_time = 2.1,
		viewport_pos = vector(0.5, 0.75),
		scale = 1.8
	})

	speech_bubble.instance:ShowSpeechBubble(sb)

	music_player_util.play_sfx({
		sfx_name = '01_creature_15',
		play_pos = user_party.Leader.Position,
		type_priority = 'event'
	})

	--party_util.set_direction('down')
	party_util.set_emotion({ name = 'scared' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	music_player_util.play_sfx({
		sfx_name = '03_runaway_01',
		play_pos = user_party.Leader.Position,
		type_priority = 'event'
	})

	for i = 0, self.npcs.Count - 1 do
		-- 개별 애니메이션
		local name = self.npcs[i].Name
		if name == 'exp2_head_crab_spider_darkness' or name == 'exp2_archer_light' or name == 'exp2_runaway_shooter_light' then
			character_util.set_animation_n_times(self.npcs[i], {name = 'jump', count = 2})
		else
			character_util.set_anim(self.npcs[i], { name = 'attack' })
		end
	end

	wait_for_sec(2.8)

	-- 애니메이션 제거
	party_util.remove_emotion()
	party_util.remove_animation()

	for i = 0, self.npcs.Count - 1 do
		character_util.remove_anim(self.npcs[i])
	end

	field_ui_manager:Show()
	party_util.reset_controllers()

	-- 전투 개시
	for i = 0, self.npcs.Count - 1 do
		character_util.convert_to_monster(self.npcs[i], 'battle1', 'battle1')
		command_util.execute_monster_notice(self.npcs[i], user_party.Leader, 'battle')
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.item = nil
	self.npcs = nil
	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
