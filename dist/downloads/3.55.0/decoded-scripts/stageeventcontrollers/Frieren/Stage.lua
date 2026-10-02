local local_class = newclass('ShortStoryFrierenController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 7001901


	self.restaurant_sfx = nil
end

function local_class:dispose()
	self:stop_restaurant_sfx()

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), 'dessert_shop_all_field') then
		music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')
		return true
	end

	if type_util.is_zone_full_enter(e, get_party_leader(), 'izakaya_field') then
		self:start_restaurant_sfx()
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_party_leader(), 'izakaya_field') then
		self:stop_restaurant_sfx()
		return true
	end

	return false
end

function local_class:start_restaurant_sfx()
	if self.restaurant_sfx == nil then
		self.restaurant_sfx = music_player_util.play_sfx({
			sfx_name = '01_amb_restaurant_01',
			loop = true,
			volume = 0.4,
			fade_in_time = 3
		})
	end
end

function local_class:stop_restaurant_sfx()
	if self.restaurant_sfx ~= nil then
		self.restaurant_sfx:Stop()
		self.restaurant_sfx = nil
	end
end



-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:flower_visible()

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('clear_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s2_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 2 then
		local magic_tool_shop_progress = user_progress:GetStartedQuest(7001908)
		local dessert_shop_progress = user_progress:GetStartedQuest(7001905)

		if magic_tool_shop_progress ~= nil and dessert_shop_progress ~= nil then
			if magic_tool_shop_progress.IsComplete and dessert_shop_progress.IsComplete then
				stage_launch_util.play_launch_stage_ignore_disabled_member('down',
				field_util.get_marker_pos('s3_start_pos'), false, true)
				return
			end
		end

		stage_launch_util.play_launch_stage_ignore_disabled_member('down',
				field_util.get_marker_pos('s3_start_pos'), true, true)

	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s4_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), false, false)
	elseif quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s6_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s7_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 7 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), false, false)
	elseif quest_progress.InnerProgress == 8 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s9_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s10_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 10 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s11_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 11 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s12_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 12 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), false, false)
	elseif quest_progress.InnerProgress == 13 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), false, false)
	elseif quest_progress.InnerProgress == 14 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), false, false)
	elseif quest_progress.InnerProgress == 15 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s16_start_pos'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:flower_visible()
	--서브 스테이지 엘프 쪽 꽃 visible 처리
	local zone = field_util.get_zone('sub_elf_flower_zone')

	local obj_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(zone.Bounds, unity_class.vector3.zero)

	for _, target in pairs(obj_list) do
		if target.Name == 'obj_forest_flower2' then
			field_object_util.set_active_state(target, active_state_type.visible)
		end
	end

	obj_list:Dispose()
end

return local_class
