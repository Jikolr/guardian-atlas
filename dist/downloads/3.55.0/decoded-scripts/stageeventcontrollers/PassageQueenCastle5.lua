local local_class = newclass('PassageQueenCastle5Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 마법진 이펙트
	self.get_fx_magic_circle = function()
		return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')
	end

	-- 마법진 존 이름
	self.magic_circle_zone_names = {
		'portal_1_1',
		'portal_1_2',
		'portal_2_1',
		'portal_2_2'
	}

	self.custom_stage_state = {
		kill_boss = 1
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')

	self.get_fx_magic_circle()
	screen_util.preload_boss_title()

	return util.cs_generator(self.on_load_resource, self)
end
--endregion

function local_class:on_load_resource()
end

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

--- StageLoadedEvent
function local_class:on_stage_loaded_event(_)
	self:create_magic_circle()

	-- 보스 잡았으면 비활성화
	if stage_progress_util.get_custom_data(self.custom_stage_state.kill_boss, false) then
		local boss = get_character('battle_8_boss')
		boss.ActiveState = active_state('disabled')
		self.end_boss_battle = true
	end

	return true
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if not self.end_boss_battle and type_util.is_zone_full_enter(e, get_party_leader(), 'battle8') then
		self.end_boss_battle = true

		sp_util.start_scene(function()
			local boss = get_character('battle_8_boss')
			party_util.align_party(boss.Position + vector(0, 0, -1.5), 'down', 1, 'linear')

			screen_util.show_boss_title('passage_qc_5_2', 'passage_qc_5_3', 2)
			wait_for_sec(2)

			character_util.convert_to_monster(boss, 'battle8', 'battle8')
		end)

		return true
	end

	if self.magic_circle_data[e.Zone.Name] and self.magic_circle_data[e.Zone.Name].in_leader then
		return false
	end

	if type_util.is_zone_full_enter(e, get_party_leader(), 'portal_1_1') and user_party.Count ~= 3 then
		self.magic_circle_data[e.Zone.Name].in_leader = true
		sp_util.start_scene(function()
			-- 어디선가 목소리가 들린다… 세 명이 오리라…
			field_ui_util.show_narration_async({ key = 'passage_qc_5_1', mintotalduration = 1 })
		end)

		return true
	end

	for i = 1, #self.magic_circle_zone_names do
		if type_util.is_zone_full_enter(e, get_party_leader(), self.magic_circle_zone_names[i]) then
			self.magic_circle_data[e.Zone.Name].in_leader = true
			sp_util.start_scene(self.teleport, self, self.magic_circle_data[e.Zone.Name])
			return true
		end
	end

	return false
end

--- ZoneLeaveEvent
function local_class:on_zone_leave_event(e)
	if self.magic_circle_data[e.Zone.Name] and not self.magic_circle_data[e.Zone.Name].in_leader then
		return false
	end

	for i = 1, #self.magic_circle_zone_names do
		if type_util.is_zone_full_leave(e, get_party_leader(), self.magic_circle_zone_names[i]) then
			self.magic_circle_data[e.Zone.Name].in_leader = false
			return true
		end
	end

	return false
end

--- BattleGroupEliminatedEvent
function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == 'battle8' then
		stage_progress_util.set_custom_data(self.custom_stage_state.kill_boss, true)
		return true
	end

	return false
end

--- CameraGridEnterEvent
function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, 'puzzle_grid') then
		camera_util.resize_by_ratio(5,1)
		return true
	end

	return false
end

--- CameraGridLeaveEvent
function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 'puzzle_grid') then
		camera_util.resize_to_default(1)
		return true
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

--- 마법진 생성
function local_class:create_magic_circle()
	self.magic_circle_data = {}

	for i = 1, #self.magic_circle_zone_names do
		local zone_name = self.magic_circle_zone_names[i]
		local zone = field_util.get_zone(zone_name)
		local magic_circle_effect = self.get_fx_magic_circle():Instantiate(zone.Bounds.center)

		local marker_name = zone_name .. '_exit'
		self.magic_circle_data[zone_name] = {
			effect = magic_circle_effect,
			exit_pos = field_util.get_marker_pos(marker_name),
			exit_dir = field_util.get_marker_dir(marker_name),
			in_leader = false
		}
	end
end

--- 마법진 텔레포트
function local_class:teleport(data)
	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'npc' })

	party_util.spine_set_alpha_fade(0, 0.5)
	wait_for_sec(0.2)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	party_util.spine_set_alpha_fade(1, 0)
	party_util.position_party(data.exit_pos, data.exit_dir, 'linear')
	camera_util.return_to_leader(0)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
