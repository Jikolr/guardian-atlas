local local_class = newclass("NightmareFutureCastle2At5Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.get_glass_tube = function(index) return get_field_object('glass_tube_' .. index) end

	-- 커스텀 스테이지 State
	self.custom_stage_state =
	{
		save_magiccircle = 0,
	}

	self.magiccircle_custom_state = self.custom_stage_state.save_magiccircle
	self.unfinished_world = false

	-- 마법진으로 워프 중인지 저장
	self.warp_magiccircle = false

	-- marker name
	self.magiccircle_out_marker_name = '_out'

	self.magiccircle_count = 2
	self.magiccircle_zone_name = 'magiccircle_zone_name_'

	-- 마법진 이펙트 리스트
	self.magiccircle_effect_list = nil

	-- 후일담 아이템 리스트
	self.ranpang_end_item_list = nil

	--region 재활 치료 병동
	-- 말 풍선 출력하는 fo 관리용 테이블
	-- key 검색을 고려한 테이블
	self.fo_speech_list = {
		hospital_1_resistance_male = {speech = 'nightmare_futurecastle_2_hospital_1', dir = 'lt'},
		hospital_2_civilian_male= {speech = 'nightmare_futurecastle_2_hospital_2', dir = 'lt'},
		hospital_3_ms_student_male = {speech = 'nightmare_futurecastle_2_hospital_3', dir = 'lt'},
		hospital_4_vampire = {speech = 'nightmare_futurecastle_2_hospital_4', dir = 'lt'},
		clinic_bedside_signboard_1 = {speech = 'nightmare_futurecastle_2_hospital_signboard_3', dir = 'rt'},
		clinic_bedside_signboard_2 = {speech = 'nightmare_futurecastle_2_hospital_signboard_5', dir = 'rt'},
		clinic_bedside_signboard_3 = {speech = 'nightmare_futurecastle_2_hospital_signboard_7', dir = 'rt'},
		clinic_bedside_signboard_4 = {speech = 'nightmare_futurecastle_2_hospital_signboard_8', dir = 'rt'},
	}
	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local prince_mako_quest_progress = user_progress:GetStartedQuest(257)
	-- 노멀 챕터 11 '왕자와 마코' 퀘스트 클리어 시 표지판 문구 변경
	if prince_mako_quest_progress ~= nil and quest_util.get_custom_state(prince_mako_quest_progress, 'prince_mako_quest_clear_new') == 1 then
		local signboard_speech_info_1 = self.fo_speech_list['clinic_bedside_signboard_1']
		local signboard_speech_info_2 = self.fo_speech_list['clinic_bedside_signboard_2']

		signboard_speech_info_1.speech = 'nightmare_futurecastle_2_hospital_signboard_4'
		signboard_speech_info_2.speech = 'nightmare_futurecastle_2_hospital_signboard_6'
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

--region event
function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
		return true
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, get_field_object('ranpang_end_item_'..6)) then
			sp_util.play_normal_screenplay(function()
				field_ui_util.show_narration_async({ key = 'nightmare_futurecastle_2_ranpang_after_5' })
				field_ui_util.show_narration_async({ key = 'nightmare_futurecastle_2_ranpang_after_12' })
				field_ui_util.show_narration_async({ key = 'nightmare_futurecastle_2_ranpang_after_13' })
				field_ui_util.show_narration_async({ key = 'nightmare_futurecastle_2_ranpang_after_14' })
				field_ui_util.show_narration_async(
						{ key = game_string:Format('nightmare_futurecastle_2_ranpang_after_15', user.Name) })
			end, self)
		else
			if self.fo_speech_list[e.Target.Name] ~= nil then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fo_show_speech_bubble_fixed_dir, self, e.Target.Name))
			end
		end
	end
	return false
end

function local_class:on_stage_start_event(e)
	-- 마법진 설정
	self.magiccircle_effect_list = {}

	local center = field:GetZone(self.magiccircle_zone_name..1).Bounds.center + vector(0, -0.5, 0)
	local cur_magiccircle = unity_object_pool.GetOrCreate('MagicCircle_AppearIdle'):Instantiate(center)
	cur_magiccircle.transform.localScale = unity_class.vector3.one * 0.7

	table.insert(self.magiccircle_effect_list, cur_magiccircle)

	local quest_id = 217
	local custom_state_key = 'unfinished_world'
	local quest_progress = user_progress:GetStartedQuest(quest_id)
	self.unfinished_world = quest_util.get_custom_state(quest_progress, custom_state_key) == 1

	if stage_progress:GetCustomData(self.magiccircle_custom_state) or self.unfinished_world then
		center = field:GetZone(self.magiccircle_zone_name..2).Bounds.center + vector(0, -0.5, 0)
		cur_magiccircle = unity_object_pool.GetOrCreate('MagicCircle_AppearIdle'):Instantiate(center)
		cur_magiccircle.transform.localScale = unity_class.vector3.one * 0.7

		table.insert(self.magiccircle_effect_list, cur_magiccircle)
	end

	-- 시험관 색상 변경
	for i = 1, 4 do
		local glass_tube = self.get_glass_tube(i)
		self:change_glass_tube_color(glass_tube)
	end

	-- 란팡 후일담 아이템 세팅
	local ranpang_quest = user_progress:GetStartedQuest(252)
	if ranpang_quest ~= nil and ranpang_quest.IsComplete then
		self.ranpang_end_item_list = {}

		for i = 1, 6 do
			local object_pos = get_field_object('ranpang_end_item_'..i).Position
			local drop_item
			if i == 1 then
				-- 동태 배구공
				drop_item = drop_item_util.create_item(
						{ pos = object_pos, target = nil, itemid = 20277, notforinven = true, lootstate = 'dontfindlooter' })
				drop_item.SpriteTransform.localPosition = vector(0, 0.6, 0.15)
				drop_item.ShadowTransform.localPosition = vector(0, 0.6, 0.15)
			elseif i == 2 then
				-- 박사 배구공
				drop_item = drop_item_util.create_item(
						{ pos = object_pos, target = nil, itemid = 20278, notforinven = true, lootstate = 'dontfindlooter' })
				drop_item.SpriteTransform.localPosition = vector(0, 0.6, 0.15)
				drop_item.ShadowTransform.localPosition = vector(0, 0.6, 0.15)
			elseif i == 3 then
				-- 부단장 배구공
				drop_item = drop_item_util.create_item(
						{ pos = object_pos, target = nil, itemid = 20279, notforinven = true, lootstate = 'dontfindlooter' })
				drop_item.SpriteTransform.localPosition = vector(0, 0.6, 0.3)
				drop_item.ShadowTransform.localPosition = vector(0, 0.6, 0.3)
			else
				-- 진료 기록
				drop_item = drop_item_util.create_item(
						{ pos = object_pos, itemid = 20100, notforinven = true, lootstate = 'dontfindlooter' })
				drop_item.SpriteTransform.localPosition = vector(0, 0.7, 0)
				drop_item.ShadowTransform.localPosition = vector(0, 0.7, 0)
			end

			table.insert(self.ranpang_end_item_list, drop_item)
		end

		get_character('hospital_worker_sweeper').ActiveState = active_state('disabled')
		get_character('hospital_nurse_2').ActiveState = active_state('disabled')
	else
		for i = 1, 6 do
			local cur_obj = get_field_object('ranpang_end_item_'..i)
			cur_obj.ActiveState = active_state('disabled')
		end

		get_character('hospital_nurse').ActiveState = active_state('disabled')
		get_character('hospital_ranpang').ActiveState = active_state('disabled')
	end

	for k, _ in pairs(self.fo_speech_list) do
		local character = get_character(k)
		if character ~= nil then
			character_util.add_listener(character, self)
		end
	end
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then return end
	local zone_name = e.Zone.Name

	if zone_name == self.magiccircle_zone_name .. 1 and not self.warp_magiccircle then
		self.warp_magiccircle = true
		sp_util.play_normal_screenplay(self.enter_magiccircle_event, self, zone_name)
		return true
	elseif zone_name == self.magiccircle_zone_name .. 2 and not self.warp_magiccircle
			and (stage_progress:GetCustomData(self.magiccircle_custom_state) or self.unfinished_world) then
		self.warp_magiccircle = true
		sp_util.play_normal_screenplay(self.enter_magiccircle_event, self, zone_name)
		return true
	end

	return false
end
--endregion

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

--region Magic Circle
-- 마법진 진입 이벤트
function local_class:enter_magiccircle_event(zone_name)

	if not stage_progress:GetCustomData(self.magiccircle_custom_state) then
		stage_progress:SendCustomData(self.magiccircle_custom_state, true)

		local cur_center = field:GetZone(self.magiccircle_zone_name..2).Bounds.center + vector(0, -0.5, 0)
		local cur_magiccircle = unity_object_pool.GetOrCreate('MagicCircle_AppearIdle'):Instantiate(cur_center)
		cur_magiccircle.transform.localScale = unity_class.vector3.one * 0.7

		table.insert(self.magiccircle_effect_list, cur_magiccircle)
	end

	local center = field:GetZone(zone_name).Bounds.center + vector(0, -0.5, 0)

	local out_marker_name = zone_name .. self.magiccircle_out_marker_name
	local out_marker = field:GetMarker(out_marker_name)

	self.warp_magiccircle = true

	local diff_1 = user_party.Leader.Position - center

	character_util.spine_set_alpha_fade(user_party.Leader, 0, 0.5)

	wait_for_sec(0.2)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(user_party.Leader, out_marker.position + diff_1)

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(user_party.Leader, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end
--endregion

--- 시험관 색상 변경
function local_class:change_glass_tube_color(target)
	local cur_bubble_fx = CS.Utils.FindChildRecursively(target.Transform, 'fx_future_glasstube_bubble_inside')
	cur_bubble_fx.gameObject:SetActive(false)

	local cur_renderer = CS.Utils.FindChildRecursively(
		target.Transform, 'obj_glasstube'):GetComponent(typeof(CS.UnityEngine.MeshRenderer))

	local cur_mat = cur_renderer.material
	-- R 0 G 142 B 45 A 36 계산한 수치
	local mesh_color = unity_color({0.34901, 0.20392, 0.45098, 0.30588})
	cur_mat:SetColor('_TintColor', mesh_color)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	if self.ranpang_end_item_list ~= nil then
		for _, item in ipairs(self.ranpang_end_item_list) do
			item:ConsumeComplete()
			item = nil
		end

		self.ranpang_end_item_list = nil
	end

	if self.magiccircle_effect_list ~= nil then
		for _, effect in ipairs(self.magiccircle_effect_list) do
			effect:Dispose()
		end
		self.magiccircle_effect_list = nil
	end

	for k, _ in pairs(self.fo_speech_list) do
		local character = get_character(k)
		if character ~= nil then
			character_util.remove_relate_event(character, self)
		end
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:fo_show_speech_bubble_fixed_dir(fo_name)
	local speech_info = self.fo_speech_list[fo_name]
	local fo = get_character(fo_name) or get_field_object(fo_name)

	speech_bubble_util.remove_bubble(fo)
	speech_bubble_util.show_speech_bubble_async(fo, {key = speech_info.speech, bubble_direction = speech_info.dir})
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
