local local_class = newclass('DemonShirePassage1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_boss_rat = function() return get_character('battle_8_boss') end

	self.get_note_interactable = function(index) return get_field_object('rat_note_interactable_' .. index) end
	self.get_rat_item_wall = function(index) return get_field_object('rat_item_wall_' .. index) end

	self.get_note_pos = function(index) return field:GetMarker('rat_note_pos_' .. index).position end
	self.get_rat_item_pos = function(index) return field:GetMarker('rat_item_pos_' .. index).position end

	self.note_item_ids = {
		20657,
		20661,
		20662
	}

	self.rat_item_ids = {
		20658,
		20660,
		20660,
		20659,
	}

	self.drop_items = {}

	-- 쥐갈공명 보스 타이틀 이벤트를 보았는지
	self.meet_boss_rat = false

	self.boss_rat_battle_zone_name = 'battle8'
	self.boss_rat_battle_group_name = 'battle8'

	self.battle_gate_name = 'battle_8_gate_'
	self.battle_gate_count = 2

	self.battle_door_name = 'cheese_door_'
	self.battle_door_count = 2
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	screen_util.preload_boss_title()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	for i = 1, #self.drop_items do
		self.drop_items[i]:ConsumeComplete()
	end
	self.drop_items = nil

	self.cs_controller = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_stage_loaded_event(_)
	-- 상자를 열지 않은 경우
	if not star_piece_util.has_star_piece('star_piece_1') then
		message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	else
		self:set_boss_holdable(true)

		for i = 1, self.battle_door_count do
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.battle_door_name .. i, true))
		end
	end

	self:set_rat_events()

	return true
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), self.boss_rat_battle_zone_name)
			and not self.meet_boss_rat then
		self.meet_boss_rat = true
		sp_util.play_normal_screenplay(self.active_boss_rat_routine, self)

		return true
	end

	return false
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.boss_rat_battle_group_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_after_boss_rat_battle, self))
		return true
	end

	return false
end

function local_class:set_rat_events()
	-- 쪽지 세팅
	for i = 1, #self.note_item_ids do
		local target_pos = self.get_note_pos(i)
		self:set_drop_item(self.note_item_ids[i], target_pos)
		self.get_note_interactable(i).Position = target_pos
	end

	-- 보스 방 앞 아이템 세팅
	for i = 1, #self.rat_item_ids do
		local target_pos = self.get_rat_item_pos(i)
		local wall = self.get_rat_item_wall(i)
		self:set_drop_item(self.rat_item_ids[i], target_pos)
		wall.Position = target_pos
		wall.Hitbox = CS.Oak.Hitbox(vector(0.7, 1, 0.7))
	end
end

function local_class:set_drop_item(item_id, pos)
	local drop_item = drop_item_util.create_item({
		itemid = item_id, pos = pos, notforinven = true, lootstate = 'dontfindlooter',
	})

	table.insert(self.drop_items, drop_item)
end

--- 보스 타이틀 연출
function local_class:active_boss_rat_routine()
	local boss = self.get_boss_rat()

	user_party:PositionParty(vector(boss.Position.x, 0, get_party_leader().Position.z + 2),
			CS.Oak.Direction.Up, 1, 'arc')

	camera_util.move_async(boss.Position, 0.7)

	screen_util.show_boss_title('ds_passage_boss_title',
			'ds_passage_boss_subtitle', 2, false)

	wait_for_sec(2)

	music_player_util.play_stage_music({name = 'bgm_battle_boss', state = 'combat', mix = 0})

	camera_util.return_to_leader(0.5)

	for i = 1, self.battle_gate_count do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.battle_gate_name .. i))
	end

	for i = 1, self.battle_door_count do
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.battle_door_name .. i, false))
	end

	character_util.convert_to_monster(boss, self.boss_rat_battle_group_name, self.boss_rat_battle_zone_name)
	boss.DamagedBehaviour.DeathType = CS.Oak.DeathType.Prostrate

	command_util.execute_monster_notice(boss, get_party_leader(), 'battle')

	message_system:Publish(CS.Oak.ShowBossHPEvent.Create(boss))
end

function local_class:set_after_boss_rat_battle()
	music_player_util.set_stage_music_clip_async({name = 'ondemand/v2_15_demonworld/audio:bgm_battle_normal_02', state = 'combat'})
	for i = 1, self.battle_gate_count do
		message_system:PublishSync(CS.Oak.BattleGateOpenEvent.Create(self.battle_gate_name .. i))
	end

	for i = 1, self.battle_door_count do
		message_system:PublishSync(CS.Oak.DoorOpenEvent.Create(self.battle_door_name .. i, false))
	end

	self:set_boss_holdable(false)
end

function local_class:set_boss_holdable(on_stage_loaded)
	local boss = self.get_boss_rat()

	character_util.convert_to_npc(boss)
	boss.Holdable = CS.Oak.Holdable()
	character_util.set_emotion(boss, { name = 'damaged' })

	if on_stage_loaded then
		character_util.set_direction(boss, 'left')
		character_util.set_anim(boss, { name = 'prostrate' })
	else
		-- 원랜 한프레임 기다리는 것을 생각했으나, 이렇게 해야 대기 없이 높은 우선순위로 충돌 방식 세팅 가능함
		boss.OverrideCrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
