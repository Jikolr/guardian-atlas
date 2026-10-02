local local_class = newclass('QueenShip1At7Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사 가져오기
	function self.get_knight()
		return user_util.get_knight_character('knight_female', 'knight_male')
	end

	-- 페이, 메이 가져오기
	function self.get_pei_mei()
		return user_util.get_china_hero_character('pei', 'mei')
	end

	-- 공주 가져오기
	function self.get_princess()
	 	return get_character('princess')
	end

	-- 크로셀 가져오기
	function self.get_croselle()
		return get_character('crosselle')
	end

	-- 파이몬 가져오기
	function self.get_pymon()
		return get_character('pymon')
	end

	-- 안드라스 가져오기
	function self.get_andras()
		return get_character('andras')
	end

	-- 마계 전경이 보여지는 카메라 그리드 구간
	self.background_attaching_grid_list = { 'bridge_1', 'bridge_2' }

	-- 메인 퀘스트 id
	self.main_quest_id = 311

	-- 1페이즈 보스를 클리어 했는지 여부를 저장할 커스텀 스테이트 키
	self.had_conversation_with_bolt = 'has_conversation_with_bolt'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, self.background_attaching_grid_list) then
		self:attach_bg_to_cam()
	end
end

function local_class:on_camera_grid_leave_event(e)
	if table_util.contain_value(self.background_attaching_grid_list, e.CameraGrid.name) then
		self:detach_bg_from_cam()
	end
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 1
	if user_util.has_knight_male() then
		character_spec_id = 2
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end

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
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	if self.bridge_sequnce ~= nil then
		CS.UnityEngine.GameObject.Destroy(self.bridge_sequnce.gameObject)
	end

	self.cs_controller = nil
	self.scene = nil

end

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.res_holder = CS.Foundations.ResourceHolder()

	-- 7 스테이지 다리에서 쓰이는 배경 오브젝트 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
	self.res_holder, 'ondemand/v2_49_queenship/tilesets', 'bridge_sequence', function(prefab)
		self.bridge_sequnce = CS.UnityEngine.GameObject
								.Instantiate(prefab, vector(0, 0, 0), unity_class.quaternion.identity)
	end)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local function change_leader_character(party_member)
		-- 기사를 리더로
		local leader = self.get_knight()
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local function start_stage_event(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
				leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		timeline_util.set_character_key('china_hero', self.get_pei_mei().Name)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	-- 다리 부근 세팅
	self:set_jump_tiles_on_bridge(main_quest_progress)
	self:set_bridge_appearance(main_quest_progress)

	-- 라이팅 처리
	self:set_default_lighting()

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil then
		change_leader_character()
		start_stage_event('left', field:GetMarker('default_start').position, true, true)
		return
	end
	
	-- 퀘스트 클리어 시
	if main_quest_progress.IsComplete then
		change_leader_character({ self.get_princess(), self.get_pei_mei() })
		start_stage_event('left', field:GetMarker('default_start').position, true, true)
		-- 28 섹션
	elseif main_quest_progress.InnerProgress == 27 then
		change_leader_character({ self.get_princess(), self.get_pei_mei() })
		start_stage_event('left', field:GetMarker('default_start').position, false, false)
		
		-- 29섹션
	elseif main_quest_progress.InnerProgress == 28 then
		change_leader_character({ self.get_princess(), self.get_pei_mei() })
		start_stage_event('left', field:GetMarker('default_start').position, true, true)
		
		-- 30 섹션
	elseif main_quest_progress.InnerProgress == 29 then
		local had_conversation_with_bolt = quest_util.get_custom_state(main_quest_progress, self.had_conversation_with_bolt)

		change_leader_character({ self.get_princess(), self.get_pei_mei() })

		if had_conversation_with_bolt == 1 then
			start_stage_event('up', field:GetMarker('s30_start').position, false, false)
		else
			start_stage_event('up', field:GetMarker('s30_start').position, true, true)
		end

	-- 31 섹션
	elseif main_quest_progress.InnerProgress == 30 then
		change_leader_character({ self.get_princess(), self.get_pei_mei() })
		start_stage_event('left', field:GetMarker('default_start').position, false, false)
	end
end

function local_class:attach_bg_to_cam()
	local bg = get_field_object('air_background')

	if bg == nil then
		return
	end

	self.original_bg_parent = bg.Transform.parent
	bg.Transform:SetParent(stage_camera.transform.parent)
	bg.Transform.localPosition = vector(-12.5, -15, 30)

	bg.Transform.localScale = vector(2.75, 1, 2.75)
end

function local_class:detach_bg_from_cam()
	local bg = get_field_object('air_background')

	if bg == nil or self.original_bg_parent == nil then
		return
	end

	bg.Transform:SetParent(self.original_bg_parent)
	bg.Transform.position = vector(999, 0, 999)
end

function local_class:set_jump_tiles_on_bridge(main_quest_progress)
	if main_quest_progress == nil then
		return
	end

	local top_jump_tile = get_field_object('post_jump_tile_top')
	local bottom_jump_tile = get_field_object('post_jump_tile_bottom')

	if top_jump_tile == nil or bottom_jump_tile == nil then
		return
	end

	if main_quest_progress.IsComplete then
		top_jump_tile.Position = field_util.get_marker_pos('post_jump_tile_top_pos')
		bottom_jump_tile.Position = field_util.get_marker_pos('post_jump_tile_bottom_pos')
	else
		top_jump_tile.ActiveState = active_state('disabled')
		bottom_jump_tile.ActiveState = active_state('disabled')
	end
end

function local_class:set_bridge_appearance(main_quest_progress)
	if main_quest_progress == nil then
		return
	end

	local bridge_part_top = get_field_object('destroyable_bridge_top')
	local bridge_part_bottom = get_field_object('destoryable_bridge_bottom')
	local bridge_part_middle = get_field_object('destroyable_bridge_middle')

	if bridge_part_top == nil or bridge_part_bottom == nil or bridge_part_middle == nil then
		return
	end

	if main_quest_progress.IsComplete then
		bridge_part_top.Position = field_util.get_marker_pos('post_destroyable_bridge_top_pos')
		bridge_part_bottom.Position = field_util.get_marker_pos('post_destroyable_bridge_bottom_pos')

		bridge_part_top.ActiveState = active_state('enabled')
		bridge_part_middle.ActiveState = active_state('disabled')
		bridge_part_bottom.ActiveState = active_state('enabled')

		local effect_tile = get_field_object('bridge_destruction_effect')

		if effect_tile == nil then
			return
		end

		effect_tile.Hitbox = CS.Oak.Hitbox(vector(0.125, 0, 4), vector(4, 1, 1))
	else
		bridge_part_top.ActiveState = active_state('disabled')
		bridge_part_bottom.ActiveState = active_state('disabled')
	end
end

function local_class:set_default_lighting()
	local demonworld_lighting = get_field_object('demonworld_lighting')
	demonworld_lighting.ActiveState = active_state('disabled')
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
