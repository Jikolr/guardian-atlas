local local_class = newclass('DreamVillage2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 441

	-- virtual field object
	self.virtual_wall = {
		fo = nil,
		create_wall = function(this, pos, hitbox)
			this.fo = field_object_util.create_virtual_field_object(pos, { hit_box = hitbox })
		end,
		dispose = function(this)
			if this.fo ~= nil then
				this.fo:Dispose()
			end

			this.fo = nil
		end
	}

	-- 석상
	self.square_statue = function()
		return get_character('square_statue')
	end

	self.is_in_infinite_grid = false

	self.blizzard_sfx = nil

	self.time_conversion = nil
	self.time_conversion_event_key = 'dv_stage_2'

	self.marker = {
		infinite_start_pos = function()
			return field_util.get_marker_pos('s7_infinite_start_pos')
		end,
		infinite_end_pos = function()
			return field_util.get_marker_pos('s7_infinite_end_pos')
		end,
	}

	self.sp_controller = nil
end

function local_class:dispose()
	if self.sp_controller then
		self.sp_controller:dispose()
		self.sp_controller = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TimeConversionChangedEvent))

	self.virtual_wall:dispose()

	self.cs_controller = nil
end

function local_class:load_resource()
	self:setting_statue()

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseEndEvent), 'on_pause_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.TimeConversionChangedEvent), 'on_time_conversion_changed_event')
end

function local_class:setting_statue()
	local square_statue = self.square_statue()

	square_statue.SpineController.ShadowTransform.localScale = unity_class.vector3.one * 2
	field_ui_manager:RemoveUI(square_statue, CS.Oak.FieldUiType.CharacterStats)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_field_object('powder_item_1')) then
		self.sp_controller:try_start_scene(self.interact_powder, self)
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress.InnerProgress >= 7 and
			type_util.is_zone_full_enter(e, get_party_leader(), 's7_infinite_end_zone') then
		self:teleport_to_infinite_reset_pos()
		return true
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress.InnerProgress >= 6 and
			type_util.is_player_enter_to_cam_grid(e, 's7_infinite_grid') then
		self:remove_run_smoke()
		self.is_in_infinite_grid = true
		self:hide_minimap_ui()

		if quest_progress.InnerProgress == 6 then
			self:play_blizzard_sfx()
		end

		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress.InnerProgress >= 6 and
			type_util.is_player_leave_to_cam_grid(e, 's7_infinite_grid') then
		self:reset_run_smoke()
		self.is_in_infinite_grid = false
		self:show_minimap_ui()

		if quest_progress.InnerProgress == 6 then
			self:stop_blizzard_sfx()
		end

		return true
	end

	return false
end

function local_class:on_pause_end_event(_)
	self:hide_minimap_ui()

	return true
end

function local_class:on_time_conversion_changed_event(_)
	self:hide_minimap_ui()

	return true
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:time_conversion_setting()

	if quest_progress == nil or quest_progress.InnerProgress < 8 then
		-- is_system_active가 false 상태에선 conversion_active_setting가 return 하고 실행되지 않음 - 순서 변경함.
		self.time_conversion:conversion_active_setting(false)
		self.time_conversion.is_system_active = false
	end

	if quest_progress ~= nil and quest_progress.InnerProgress >= 9 then
		local hole = get_field_object('s9_hole')
		local animator = hole:GetComponent(typeof(CS.UnityEngine.Animator))
		animator:Play('open', -1, 10)
	end

	if quest_progress.InnerProgress >= 10 then
		self:block_infinite_field()
	end

	local created, dv_sp_manager = global_table_util.try_create_dream_village_screenplay_manager()
	self.sp_controller = dv_sp_manager:get_sp_controller(self.cs_controller)

	stage_start_util.start_function(quest_progress)
end

function local_class:remove_run_smoke()
	for i = 0, user_party.Count - 1 do
		local party_member = user_party[i]
		stage.SmokeManager:UnsetCharacterSmoke(party_member)
	end
end

function local_class:reset_run_smoke()
	for i = 0, user_party.Count - 1 do
		local party_member = user_party[i]
		stage.SmokeManager:SetCharacterSmoke(party_member)
	end
end

function local_class:teleport_to_infinite_reset_pos()
	local end_pos = self.marker.infinite_end_pos()
	local start_pos = self.marker.infinite_start_pos()

	for i = 0, user_party.Count - 1 do
		local party_member = user_party[i]
		local party_member_cur_pos = party_member.Position
		local pos_diff = party_member_cur_pos - end_pos
		local party_member_new_pos = start_pos + pos_diff
		party_member.Position = party_member_new_pos
	end
end

function local_class:block_infinite_field()
	--11섹션 이상부터는 exit 생기므로, 투명벽으로 막아서 무한 달리기 공간 진입 못하게 해야함.
	--or 7섹션에서 연출용으로 막는 경우에도 호출됨.
	local pivot_pos = field_util.get_marker_pos('default_start') + vector(0, 0, -2.5)
	self.virtual_wall:create_wall(pivot_pos, CS.Oak.Hitbox(vector(4, 1, 1)))
end

function local_class:interact_powder()
	local twins_younger = get_character('twins_younger')

	if twins_younger.Direction == CS.Oak.Direction.Up then
		scene_util.set_direction(twins_younger, 'right', false)
	end

	-- 도화(파티원으로 따라다닐 예정)(tired, idle) : 여… 영혼술 재료로 흔하게 쓰이는 가루예요.
	scene_util.play_normal_speech_action(twins_younger, self, nil, nil,
			{ name = 'tired', keep = true }, 'dv_stage2_item_narration_4_1')

	-- 도화(tired, idle) : 자… 자세한 성분은 잘 몰라요. 항상 어머니가 만들어 주셔서….
	scene_util.play_normal_speech_action(twins_younger, self, nil, nil,
			'tired', 'dv_stage2_item_narration_4_2')
end

function local_class:hide_minimap_ui()
	if self.is_in_infinite_grid then
		-- 미니맵 제거
		stage.FieldUIMiniMap:Hide()
	end
end

function local_class:show_minimap_ui()
	if not self.is_in_infinite_grid then
		-- 미니맵 제거
		stage.FieldUIMiniMap:Show()
	end
end

function local_class:play_blizzard_sfx()
	if self.blizzard_sfx == nil then
		self.blizzard_sfx = music_player_util.play_sfx({
			sfx_name = '01_blizzard_04', loop = true, fade_in_time = 4, volume = 0.5 })
	end
end

function local_class:stop_blizzard_sfx()
	if self.blizzard_sfx ~= nil then
		music_player_util.fade_out_sfx(self.blizzard_sfx, 1)
		self.blizzard_sfx = nil
	end
end

function local_class:time_conversion_setting()
	do
		-- 밤/낮 세팅
		self.time_conversion = get_stage_event_controller('TimeConversionManager')

		-- 콜백 등록
		self.time_conversion:register_callback(self.time_conversion_event_key, {
			-- 낮
			daylight = function()
				self:reset_square_statue()
			end,
			-- 밤
			night = function()
				self:set_alpha_square_statue()
			end
		}, true)
	end
end

function local_class:reset_square_statue()
	local square_statue = self.square_statue()

	character_util.remove_color(square_statue, square_statue.Name, 2)
end

function local_class:set_alpha_square_statue()
	local square_statue = self.square_statue()

	character_util.add_color(square_statue, square_statue.Name, unity_color({ 0.5, 0.4, 0.4 }), 1, 1)
end

return local_class
