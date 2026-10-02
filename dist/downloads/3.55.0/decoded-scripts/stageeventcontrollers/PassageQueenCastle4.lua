local local_class = newclass('PassageQueenCastle4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- door control 퀘스트 id
	self.door_control_quest_id = 353

	-- NPC
	-- door control 퀘스트 관련
	self.get_door_cat = function()
		return get_character('door_control_cat')
	end

	self.get_butterfly = function()
		return get_character('door_control_butterfly')
	end

	-- field object
	self.get_door_control_key = function(num)
		return get_field_object('key_' .. num)
	end

	self.get_door_control_chair = function()
		return get_field_object('door_control_chair')
	end

	self.get_other_world_door_interact_object = function()
		return get_field_object('out_a')
	end

	self.get_our_world_door_interact_object = function()
		return get_field_object('in_a')
	end

	-- shear
	self.get_shear_controller = function()
		return get_field_object('shear_controller')
	end

	-- Marker
	-- 고양이 나비 돌아다닐 위치
	self.get_ending_door_cat_move_pos = function(num)
		return field:GetMarker('other_world_cat_pos_' .. num).position
	end

	self.other_world_interact_object_name = 'out_a'
	self.our_world_interact_object_name = 'in_a'

	self.shear_controller = nil

	self.ambient_sound = nil

	self.door_control_key_max_count = 3
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')

	local door_control_quest_progress = user_progress:GetStartedQuest(self.door_control_quest_id)
	if door_control_quest_progress ~= nil then
		if door_control_quest_progress.IsComplete then
			character_util.add_listener(self.get_door_cat(), self)
		end
	end
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	start_coroutine(self.pre_setting, self)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, typeof(CS.Oak.InteractEvent)) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_exit_interact_teleport_start_event(e)
	local interact_handle_name = e.ExitHandleName

	if self.other_world_interact_object_name == interact_handle_name then
		start_coroutine(self.control_shear, self, 'disabled')
	elseif self.our_world_interact_object_name == interact_handle_name then
		start_coroutine(self.control_shear, self, 'enabled')
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'door_cat_add_listener' then
		local cat = self.get_door_cat()
		character_util.add_listener(cat, self)
		return true
	end

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_door_cat()) then
		local door_control_quest_progress = user_progress:GetStartedQuest(self.door_control_quest_id)
		if door_control_quest_progress ~= nil then
			if door_control_quest_progress.IsComplete then
				start_coroutine(self.door_cat_oneline_ment, self)
			end
		end
	end

	return false
end

function local_class:on_field_object_revived_event(e)
	local battle_zone = field_util.get_zone('battle3')
	local leader = get_party_leader()

	-- 훅샷을 이용하다가 죽고 부활 했을 때 바닥이 아니면 존 중앙으로 이동
	if lua_helper.reference_equals(e.FieldObject, leader) and
			battle_zone:Contains(leader.Position) and not field:IsThereFloorAt(leader.Position) then

		local revive_pos = field:GetGroundPositionAt(battle_zone.Bounds.center)
		party_util.position_party(revive_pos, 'down', 'arc')
		camera_util.move(leader.Position, 0, { end_target = leader })

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

function local_class:pre_setting()
	-- 서브 퀘스트 관리
	-- survivor
	local door_control_quest_progress = user_progress:GetStartedQuest(self.door_control_quest_id)
	if door_control_quest_progress ~= nil then
		if door_control_quest_progress.IsComplete then
			start_coroutine(self.door_control_complete_setting, self)
		end
	end

	stage_launch_util.play_launch_stage('up', field:GetMarker('default_start').position, true, true)
end

-- door control 퀘스트 클리어 후 관련 npc 셋팅
function local_class:door_control_complete_setting()
	local cat = self.get_door_cat()
	local butterfly = self.get_butterfly()
	local cat_loop_pos_1 = self.get_ending_door_cat_move_pos(1)

	self:door_control_complete_object_setting()

	cat.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
	butterfly.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance

	stage.FieldUIManager:RemoveUI(cat, CS.Oak.FieldUiType.CharacterStats)
	stage.FieldUIManager:RemoveUI(butterfly, CS.Oak.FieldUiType.CharacterStats)

	character_util.set_active_state(cat, 'enabled')
	character_util.set_active_state(butterfly, 'enabled')

	character_util.set_position(cat, cat_loop_pos_1 + vector(-1, 0, 0))
	--scene_util.set_emotion(cat, self, { name = 'smile' })
	scene_util.set_direction_by_args(cat, { dir = 'left', sfx = false })

	character_util.set_position(butterfly, cat_loop_pos_1 + vector(-3, 0, 0))
	scene_util.set_direction_by_args(butterfly, { dir = 'left', sfx = false })

	character_util.remove_anim_and_emotion(cat)
	character_util.remove_anim_and_emotion(butterfly)

	character_util.add_listener(cat, self)

	local move_pos_list = {}
	local start_index = 1
	local last_index = 4
	for i = last_index, start_index, -1 do
		table.insert(move_pos_list, self.get_ending_door_cat_move_pos(i))
	end
	wp_util.move(cat, move_pos_list, 4.5, nil, { end_type = 'loop' })
	wp_util.move(butterfly, move_pos_list, 4.5, nil, { end_type = 'loop' })
end

function local_class:door_control_complete_object_setting()
	local chair = self.get_door_control_chair()
	chair.Pushable = CS.Oak.UnitPushable()

	-- 포탈 입구 인터랙션 가능하게 관련 오브젝트 활성화
	local exit = self.get_other_world_door_interact_object()
	exit.ActiveState = active_state('enabled')
	local exit_renderer_tf = exit.Transform:Find('exit_tile 1')
	exit_renderer_tf.gameObject:SetActive(false)

	exit = self.get_our_world_door_interact_object()
	exit_renderer_tf = exit.Transform:Find('exit_tile 1')
	exit_renderer_tf.gameObject:SetActive(false)

	for i = 1, self.door_control_key_max_count do
		local key = self.get_door_control_key(i)
		if key ~= nil then
			key.ActiveState = active_state('disabled')
		end
	end
end

function local_class:control_shear(state)
	local shear = self.get_shear_controller()
	if shear ~= nil then
		wait_for_sec(0.5)
		if state == 'disabled' then
			-- 미니게임에서 shear 적용되지 않도록 처리
			if not self.shear_controller then
				self.shear_controller = self.get_shear_controller():GetComponent(typeof(CS.Oak.ShearController))
				self.origin_shear = self.shear_controller.Shear
			end
			music_player_util.play_stage_music({ state = 'muted' })
			self.ambient_sound = music_player_util.play_sfx(
					{ sfx_name = "01_amb_village_02", loop = true, type_priority = 'loop' })

			self.shear_controller.Shear = 0
		elseif state == 'enabled' then
			self.shear_controller.Shear = self.origin_shear

			music_player_util.fade_out_sfx(self.ambient_sound, 1)
			music_player_util.play_stage_music({ state = 'field', mix = 1 })
		end
	end
end

function local_class:door_cat_oneline_ment()
	local cat = self.get_door_cat()
	music_player_util.play_sfx_one_shot('01_guild_cat_01')
	speech_bubble_util.show_speech_bubble(cat, { key = 'qc_door_control_7_1', skip = false })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
