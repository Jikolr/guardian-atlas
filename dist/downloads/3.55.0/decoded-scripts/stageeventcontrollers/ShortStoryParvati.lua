local local_class = newclass('ShortStoryParvati')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 7001101

	self.get_parvati = function() return get_character('parvati') end
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end
--endregion

--region event
function local_class:on_event(e)
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

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 파르바티로 메뉴얼 캐릭터 변경
	self:convert_manual_character_to_parvati()

	-- 경찰서 문 설정
	local police_dept_door = get_field_object('police_dept_door')
	police_dept_door.Hitbox = CS.Oak.Hitbox(vector(2.5, 1, 1))

	-- 아파트 출구 히트박스 조정
	get_field_object('exit_apartment_outer').Hitbox = CS.Oak.Hitbox(vector(1.5, 1, 2))

	if main_quest_progress == nil or main_quest_progress.InnerProgress == 0 then
		self:set_start_setting(field:GetMarker('parvati_room_center').position, 'right', false, false)
	elseif main_quest_progress.Grade >= 0 then
		self:set_start_setting(field:GetMarker('parvati_room_center').position, 'down', false, true)
	elseif main_quest_progress.InnerProgress >= 1 and main_quest_progress.InnerProgress < 3 then
		self:set_start_setting(field:GetMarker('parvati_room_center').position, 'right', false, true)
	elseif main_quest_progress.InnerProgress >= 3 and main_quest_progress.InnerProgress < 5 then
		self:set_start_setting(field:GetMarker('street_center_start_pos').position, 'right', true, true)
	elseif main_quest_progress.InnerProgress == 5 then
	elseif (main_quest_progress.InnerProgress >= 7 and main_quest_progress.InnerProgress <= 8) or
			(main_quest_progress.InnerProgress >= 11 and main_quest_progress.InnerProgress <= 12) or
			main_quest_progress.InnerProgress == 15 then
		self:set_start_setting(field:GetMarker('street_center_start_pos').position, 'right', true, true)
	elseif main_quest_progress.InnerProgress == 9 or main_quest_progress.InnerProgress == 13 then
		self:set_start_setting(field:GetMarker('parvati_room_bed_start').position, 'right')
	else
		self:set_start_setting(field:GetMarker('default_start').position, 'right', false, true)
	end

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:convert_manual_character_to_parvati()
	local parvati = self.get_parvati()
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = true
	param.MoveCamera = false
	character_util.convert_to_manual_character(parvati, param)
	field_ui_manager:SetUI(parvati, CS.Oak.FieldUiType.TopHpBar)
end

function local_class:set_start_setting(start_pos, start_dir, should_play_stage_music, directional_stage_entry)
	local parvati = self.get_parvati()

	camera_util.move_async(start_pos, 0)
	character_util.set_position(parvati, start_pos)
	character_util.set_direction(parvati, start_dir)
	camera_util.return_to_leader(0)

	if should_play_stage_music then
		music_player_util.play_stage_music({ state = 'field' })
	end

	if directional_stage_entry then
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		stage_launch_util.directional_stage_entry(parvati.Position, parvati.Direction
		, game_string:GetString(stage.Name), true, should_play_stage_music)

		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
