local local_class = newclass('QueenCastle5Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사 가져오기
	function self.get_knight()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end


	self.get_fx_magic_circle = function()
		return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 330

	-- 마빈 섹터 퀘스트 id
	self.sector_quest_id = 332

	--미로용
	-- 그리드 이름
	self.get_grid_name = function(idx)
		return 'me9_maze_grid_' .. idx
	end

	-- 실패 이벤트 체크용
	self.exit_playing_flag = false

	-- 존에서 체크하고, 엔터에서 설정한다.
	self.active_zone_list = {false,false,false,false,false,false}

	-- 방향맞췄을 경우 체크용
	self.success_flag = false

	-- 첫 번째 방인지 체크
	self.first_maze_check_flag = true

	self.dark_zone_event_args = {
		field_tint_color = unity_color({0.7, 0.7, 0.7, 1}),
		field_tint_key = 'jerico_tint',
		tint_duration = 0.3
	}

	-- 첫 번째 매직 포털 사용한 전적이 있는지?
	self.is_portal_appeared = false

	self.magic_circle_brazier_puzzle_on_off_state = {
		false, false, false, false
	}

	self.puzzle_brazier_name = 'puzzle_brazier_'

	self.comic_books = {}

	self.magic_circle_appeared_custom_key = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BrazierOnOffEvent), 'on_brazier_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.LinkDoorOpenedEvent), 'on_link_door_opened_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.mural = get_or_create_global_table('Quest/Main/QueenCastle/Common/MuralTheatreController')

	self.mural:load_async()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	local sector_quest_progress = user_progress:GetStartedQuest(self.sector_quest_id)
	start_coroutine(self.pre_setting, self, sector_quest_progress)
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_link_door_opened_event(e)
	local type_name = e.LinkDoorTypeName

	if type_name == 'pink' then
		quest_marker_util.remove('qc_ds_link_door')
	end
end

function local_class:on_camera_grid_enter_event(e)
	local grid_list = {
		self.get_grid_name(2),
		self.get_grid_name(3),
		self.get_grid_name(4),
		self.get_grid_name(5),
		self.get_grid_name(6),
		self.get_grid_name(7),
		self.get_grid_name(8),
		self.get_grid_name(9),
		self.get_grid_name(1)
	}

	for idx=1, #grid_list do
		if not self.first_maze_check_flag then
			if type_util.is_player_enter_to_cam_grid(e, grid_list[idx])
					and not self.success_flag
					and not self.exit_playing_flag then
				sp_util.start_scene(self.maze_exit_event,self)
				return
			end
			if type_util.is_player_enter_to_cam_grid(e, grid_list[idx]) then
				start_coroutine(self.flag_reset, self, idx)
				return
			end
		else
			if idx == 7 then
				return
			end
			if type_util.is_player_enter_to_cam_grid(e, grid_list[idx]) then
				start_coroutine(self.flag_reset, self, idx)
				self.first_maze_check_flag = false
				return
			end
		end
	end
end

function local_class:on_link_door_event(e)
end

function local_class:on_zone_enter_event(e)
	--region 미로
	local maze_zone_name_list = {
		{'me9_maze_zone_1_1','me9_maze_zone_1_2'},
		{'me9_maze_zone_2_1','me9_maze_zone_2_1'},
		{'me9_maze_zone_3_1','me9_maze_zone_3_2'},
		{'me9_maze_zone_4_1','me9_maze_zone_4_2'},
		{'me9_maze_zone_5_1','me9_maze_zone_5_1'}
	}

	if type_util.is_zone_full_enter(e, user_party.Leader, 'me9_dark_zone') then
		field_util.tint(self.dark_zone_event_args.field_tint_key, self.dark_zone_event_args.field_tint_color,
			self.dark_zone_event_args.tint_duration)
	end

	for idx = 1, #maze_zone_name_list do
		if type_util.is_zone_full_enter(e, user_party.Leader, maze_zone_name_list[idx][1])
				and self.active_zone_list[idx] then
			start_coroutine(self.grid_maze,self,maze_zone_name_list[idx][1],maze_zone_name_list[idx][2])
		end
	end
	if type_util.is_zone_full_enter(e, user_party.Leader, 'me9_maze_exit_zone')
			and not self.exit_playing_flag then
		start_coroutine(self.maze_exit_event,self)
	end
	--endregion

	if self.fx_magic_circles and #self.fx_magic_circles > 0 then
		if self.is_portal_appeared == false then
			return
		end

		for i = 1, #self.fx_magic_circles do
			local magic_circle = self.fx_magic_circles[i]

			if type_util.is_zone_full_enter(e, get_party_leader(), magic_circle.zone_name) then
				start_coroutine(self.teleport_magic_circle, self, magic_circle.target_marker)
				magic_circle.control = true
				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, 'me9_dark_zone') then
		field_util.remove_tint(self.dark_zone_event_args.field_tint_key, self.dark_zone_event_args.tint_duration)
	end
end

function local_class:on_brazier_on_off_event(e)
	local brazier_name = e.BrazierObject.Name
	if string.match(brazier_name, self.puzzle_brazier_name) == nil then
		return
	end

	if self.is_portal_appeared  then
		return
	end

	local brazier_index = tonumber(string.sub(brazier_name, #brazier_name, #brazier_name))
	if brazier_index == nil or brazier_index > #self.magic_circle_brazier_puzzle_on_off_state then
		return true
	end

	if self:is_all_brazier_turned_on() then
		self:appear_hidden_portal()
	end
end

function local_class:is_all_brazier_turned_on()
	for i = 1, 4 do
		local brazier = get_field_object(self.puzzle_brazier_name .. i)
		if not brazier.CombustibleBehaviour.IsBurning then
			return false
		end
	end

	return true
end

--endregion
--region 미로
function local_class:grid_maze(start_zone,end_zone)
	if not self.success_flag then
		start_coroutine(function(_)
			self.success_flag = true
			wait_for_unscaled_sec(0.5)
			self.success_flag = false
		end,self)
	end

	local target_pos = (field:GetZone(end_zone).Bounds.center) - (field:GetZone(start_zone).Bounds.center)

	if target_pos == vector(0,0,0) then
		return
	end
	self:party_add_position(target_pos)
end

function local_class:appear_hidden_portal()
	self.is_portal_appeared = true

	local num_brazier = 4

	quest_marker_util.remove('portal_guide_marker')
	for i = 1, num_brazier do
		local braizer = get_field_object(self.puzzle_brazier_name .. i)
		local combustible_behaviour = braizer.CombustibleBehaviour
		combustible_behaviour.IsAffectedBurn = false
		combustible_behaviour:UpdateBurnLifeTime(0)

		command_util.execute_extinguish(nil, braizer)
		command_util.execute_burn(braizer, braizer, true)
	end

	music_player_util.play_sfx({
		sfx_name = '02_magic_shield_01',
		play_pos = field_util.get_marker_pos('portal_pos_1'),
		type_priority = 'event',
		player_priority = 'object'
	})
	self:add_magic_circle('portal_pos_1', 'magic_portal_zone_1', 'portal_pos_exit_2', true)

	stage_progress_util.set_custom_data(self.magic_circle_appeared_custom_key, true)

	quest_marker_util.add_quest_marker_to_ifo('qc_ds_link_door', 332,
			true, get_field_object('link_door_switch_1'))
end

function local_class:party_add_position(add_pos)
	for i = 0, user_party.Count - 1 do
		local target = user_party[i]
		if i >= 2 then
			character_util.convert_to_non_party_player(target)
			target.Position = target.Position + add_pos
			character_util.convert_to_following_npc(target, user_party, false)
		else
			target.Position = target.Position + add_pos
		end
	end

	stage_camera:ResetPositionWithOutGridMove()
end
function local_class:flag_reset(grid_idx)
	--self.success_flag = false
	self.active_zone_list = {false,false,false,false,false,false}

	if grid_idx == 1 then
		self.active_zone_list[1] = true
	elseif grid_idx == 2 then
		self.active_zone_list[4] = true
	elseif grid_idx == 3 then
		self.active_zone_list[3] = true
	elseif grid_idx == 4 then
		self.active_zone_list[2] = true
	elseif grid_idx == 5 then
		self.active_zone_list[5] = true
	elseif grid_idx == 6 then
		self.active_zone_list[6] = true
	end
end
function local_class:maze_exit_event()
	self.exit_playing_flag = true
	local exit_pos = field_util.get_marker_pos('me9_maze_exit_pos')
	music_player_util.play_sfx_one_shot('01_fade_out_01')
	screen_util.fade_out_async(0.3, unity_class.color.white, 'linear')
	--local pos = exit_pos - user_party.Leader.Position
	--self:party_add_position(pos)
	party_util.align_party(exit_pos,'left',0,'linear')
	CS.Oak.MessageSystem.Instance:Publish(CS.Oak.ClearPartyMemberFollowOpsEvent.Instance)
	stage_camera:ResetPositionWithOutGridMove()
	wait_for_sec(0.3)
	self.first_maze_check_flag = true
	screen_util.fade_in_async(0.3, unity_class.color.white, 'linear')
	self.exit_playing_flag = false
end
--endregion
--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BrazierOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.LinkDoorOpenedEvent))

	if self.fx_magic_circles ~= nil then
		for i = 1, #self.fx_magic_circles do
			if self.fx_magic_circles[i].fx ~= nil then
				self.fx_magic_circles[i].fx:Dispose()
				self.fx_magic_circles[i].fx = nil
			end
		end
		self.fx_magic_circles = nil
	end


	self:dispose_all_android_parts()
	self:dispose_all_comic_books()

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting(sector_quest_progress)
	if sector_quest_progress == nil then
		logger_util.error("Failed to get progress from quest: " .. self.sector_quest_id)
	end

	self.is_portal_appeared =
		(quest_util.get_custom_state(sector_quest_progress, 'hidden_portal_appeared') == 1) or
				stage_progress_util.get_custom_data(self.magic_circle_appeared_custom_key, false)

	-- 마법진 세팅
	quest_util.load_pool_resource('MagicCircle_AppearIdle')

	self:set_magic_circles()
	self:place_brokne_android_parts()
	self:set_cherico_event_items()

	do
		local qc_util = get_or_create_global_table('Quest/Main/QueenCastle/Common/Util')
		qc_util:set_sector_directional_light(2)
	end

	-- 시작 연출 관리
	if sector_quest_progress == nil or sector_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'), true, true)
	elseif sector_quest_progress.InnerProgress <= 1 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'), true, true)
	else
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:set_magic_circles()
	self.fx_magic_circles = {}

	self:add_magic_circle('portal_pos_2', 'magic_portal_zone_2', 'portal_pos_exit_1', true)

	if self.is_portal_appeared then
		self:add_magic_circle('portal_pos_1', 'magic_portal_zone_1', 'portal_pos_exit_2', true)
	end
end

--- 마법진 추가
--- @param appear_marker string 마법진 생성 위치
--- @param zone_name string 마법진 공간(해당 공간에 들어갈 경우 순간이동)
--- @param target_marker string 도착 위치(마커의 위치와 방향 적용)
function local_class:add_magic_circle(appear_marker, zone_name, target_marker, control)
	local magic_circle = {
		fx = self.get_fx_magic_circle():Instantiate(field_util.get_marker_pos(appear_marker)),
		zone_name = zone_name,
		target_marker = target_marker,
		control = control
	}

	table.insert(self.fx_magic_circles, magic_circle)
end


-- 텔레포트 연출
function local_class:teleport_magic_circle(target_marker, control)
	local leader = get_party_leader()

	character_util.set_active_state(leader, 'visible')

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	control = lua_helper.get_or_default(control, true)

	local marker = field:GetMarker(target_marker)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(leader, 'down')
	character_util.spine_set_alpha_fade(leader, 0, 0.5)

	wait_for_sec(0.2)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')
	party_util.align_party(marker.position, 'up', 0, 'arc')
	camera_util.return_to_leader(0)

	party_util.stop_and_disable_control()

	character_util.spine_set_alpha_fade(leader, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	if control then
		party_util.reset_controllers()
		field_ui_manager:Show()
	end

	character_util.set_active_state(leader, 'enabled')
end

function local_class:place_brokne_android_parts()
	local android_parts_sprite_id_list = { 20947, 20948, 20949, 20947, 20948, 20949 }
	local spawn_pos_name = 'android_parts_'

	self.android_parts = {}

	local lootstate = 'dontfindlooter'
	for i = 1, #android_parts_sprite_id_list do
		local spwan_pos = field_util.get_marker_pos(spawn_pos_name .. i)
		local parts = drop_item_util.create_item({
			itemid = android_parts_sprite_id_list[i],
			pos = spwan_pos,
			notforinven = true,
			lootstate = lootstate
		})

		table.insert(self.android_parts, parts)
	end
end

function local_class:set_cherico_event_items()
	local comic_book_box_name = 'me9_comic_book_box_'
	local num_comic_books = 3
	local base_comic_book_id = 20944

	local lootstate = 'dontfindlooter'
	for i = 1, num_comic_books do
		local spwan_pos = get_field_object(comic_book_box_name .. i).Position + vector(0, 1, -0.25)
		local comic_book = drop_item_util.create_item({
			itemid = base_comic_book_id + (i - 1),
			pos = spwan_pos,
			notforinven = true,
			sprscale = 1.2,
			lootstate = lootstate
		})

		local shadow_local_pos = comic_book.ShadowTransform.localPosition
		comic_book.ShadowTransform.localPosition = shadow_local_pos + vector(0, 0.9, 0)

		table.insert(self.comic_books, comic_book)
	end
end

function local_class:dispose_all_comic_books()
	if self.comic_books == nil then
		return
	end

	for i = 1, #self.comic_books do
		drop_item_util.dispose_item(self.comic_books[i])
	end

	self.comic_books = nil
end


function local_class:dispose_all_android_parts()
	if self.android_parts == nil then
		return
	end

	for i = 1, #self.android_parts do
		self.android_parts[i]:ConsumeComplete()
		self.android_parts[i] = nil
	end

	self.android_parts = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
