local local_class = newclass('QueenShipPassage3Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.get_boss_lamb = function() return get_character('devil_lamb') end
	self.boss_lamb_battle_zone_name = 'battle8'
	self.boss_lamb_battle_group_name = 'battle8'
	self.meet_boss_lamb = false

	-- 마법진 사용 중 체크
	self.warp_magiccircle = false

	-- effect
	-- 마법진
	self.get_fx_magic_circle = function()
		return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')
	end

	-- markers
	self.get_magic_circle_passage_pos = function(num)
		return field:GetMarker('magic_circle_passage_'..num..'_out_pos').position
	end

	-- zone names
	self.magic_circle_passage_zone_1_name = 'magic_circle_passage_zone_1'
	self.magic_circle_passage_zone_2_name = 'magic_circle_passage_zone_2'

	self.magiccircle_out_markers = {
		magic_circle_passage_zone_1 = 'magic_circle_passage_1_out_pos',
		magic_circle_passage_zone_2 = 'magic_circle_passage_2_out_pos'
	}

	self.battle_gate_name = 'battle_8_gate_'
	self.battle_gate_count = 2

	self.battle_door_name = 'sheep_door_'
	self.battle_door_count = 2
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	screen_util.preload_boss_title()
	self.get_fx_magic_circle()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	local lamb = self.get_boss_lamb()
	if not star_piece_util.has_star_piece('star_piece_1') then
		message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	else
		-- 스타피스를 먹었다면 클리어 했다는 것이기 때문에 그에 대한 처리를 해준다.
		self.meet_boss_lamb = true
		character_util.set_active_state(lamb, 'disabled')

		for i = 1, self.battle_door_count do
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.battle_door_name .. i, true))
		end
	end

	character_util.add_color(lamb, 'lamb', unity_color({1, 0, 0, 1}), 0.7, 0)

	local effect_pos = self.get_magic_circle_passage_pos(1) + vector(0, 0, -4.5)
	self.magic_circle_passage_effect_1 = self.get_fx_magic_circle():Instantiate(effect_pos)

	effect_pos = self.get_magic_circle_passage_pos(2) + vector(0, 0, 3)
	self.magic_circle_passage_effect_2 = self.get_fx_magic_circle():Instantiate(effect_pos)

	return true
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.boss_lamb_battle_group_name then
		self:set_after_boss_lamb_battle()
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), self.boss_lamb_battle_zone_name)
			and not self.meet_boss_lamb then
		self.meet_boss_lamb = true
		sp_util.play_normal_screenplay(self.active_boss_lamb_routine, self)

		return true
	end

	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if not self.warp_magiccircle then
			if e.Zone.Name == self.magic_circle_passage_zone_1_name or
					e.Zone.Name == self.magic_circle_passage_zone_2_name then
				self.warp_magiccircle = true
				sp_util.play_normal_screenplay(self.enter_magiccircle_event, self, e.Zone.Name)
			end
		end
	end

	return false
end
--endregion

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

--- 양 보스 타이틀 연출
function local_class:active_boss_lamb_routine()
	music_player_util.play_stage_music({ state = 'muted' })
	local boss = self.get_boss_lamb()

	user_party:PositionParty(vector(boss.Position.x, 0, get_party_leader().Position.z + 2),
			CS.Oak.Direction.Up, 1, 'arc')

	camera_util.move_async(boss.Position, 0.7)

	screen_util.show_boss_title('qs_passage_3_boss_title',
			'qs_passage_3_boss_subtitle', 2, false)

	wait_for_sec(2)

	music_player_util.play_stage_music({state = 'combat'})

	camera_util.return_to_leader(0.5)

	for i = 1, self.battle_gate_count do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.battle_gate_name .. i))
	end

	for i = 1, self.battle_door_count do
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.battle_door_name .. i, false))
	end

	character_util.convert_to_monster(boss, self.boss_lamb_battle_group_name, self.boss_lamb_battle_zone_name)
	boss.DamagedBehaviour.DeathType = CS.Oak.DeathType.Prostrate

	command_util.execute_monster_notice(boss, get_party_leader(), 'battle')

	message_system:Publish(CS.Oak.ShowBossHPEvent.Create(boss))
end

function local_class:set_after_boss_lamb_battle()
	for i = 1, self.battle_gate_count do
		message_system:PublishSync(CS.Oak.BattleGateOpenEvent.Create(self.battle_gate_name .. i))
	end

	for i = 1, self.battle_door_count do
		message_system:PublishSync(CS.Oak.DoorOpenEvent.Create(self.battle_door_name .. i, false))
	end

	music_player_util.play_stage_music({ state = 'field' })
end

--region Magic Circle
-- 마법진 진입 이벤트
function local_class:enter_magiccircle_event(zone_name)
	local center = field:GetZone(zone_name).Bounds.center

	local out_marker_name = self.magiccircle_out_markers[zone_name]
	local out_marker = field:GetMarker(out_marker_name)

	self.warp_magiccircle = true

	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 0, 0.5)
	end

	wait_for_sec(0.2)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	local party_dir = ''
	if zone_name == self.magic_circle_passage_zone_1_name then
		party_dir = 'up'
	elseif zone_name == self.magic_circle_passage_zone_2_name then
		party_dir = 'down'
	end

	party_util.position_party(out_marker.position, party_dir, 'linear')

	user_party.Leader:OnEvent(CS.Oak.StateResetEvent.Instance)

	wait_for_sec(0.5)

	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 1, 0.5)
	end

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
