local local_class = newclass("NightmareFutureCastle2At3Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.get_convert_switch = function() return get_field_object('convert_switch') end

	--region 괴식 스튜 & 전자레인지 메이드 관련 변수

	-- 전자레인지 메이드
	self.microwave = nil

	-- 전자레인지 메이드 불
	self.microwave_light = nil

	-- 음식 아이템 담을 테이블
	self.foods = {}

	self.soup_zone = 'soup_zone'

	self.soup_sfx_holder = nil

	self.microwave_emoticon = nil

	self.bunny_girl_quest = user_progress:GetStartedQuest(200)
	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ConvertWallChangedEvent), 'on_convert_wall_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	local gate = get_field_object('key_open_door_1')
	gate.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	local gate_animator = gate:GetComponent(typeof(CS.UnityEngine.Animator))
	gate_animator.speed = 30
	gate_animator:Play("open", -1, 0)

	gate = get_field_object('key_open_door_2')
	gate.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	gate_animator = gate:GetComponent(typeof(CS.UnityEngine.Animator))
	gate_animator.speed = 30
	gate_animator:Play("open", -1, 0)
	gate.ActiveState = active_state('visible')

	local board = get_field_object('talk_sign_board')
	board.Interactable.Message = game_string:Format('nightmare_futurecastle_2_stage3_signboard', user.Name)
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	self.main_quest_id = 217
	self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if self.main_quest_progress == nil or self.main_quest_progress.InnerProgress < 1 then
		return true
	end
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

--region event
function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded()
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded()
	--region 괴식 스튜 & 전자레인지 메이드 관련 초기 설정

	-- 괴식 스튜 전자레인지 설정
	self.microwave = get_field_object('kitchen_microwave')
	self.microwave_light = self.microwave.transform:GetChild(0)
	self.microwave_light.gameObject:SetActive(true)

	-- 필라프
	local food_pilaf = { id = 20343, scale = 1 }

	-- 괴식 스튜
	local gem_stew = { id = 20070, scale = 0.65 }

	-- 음식 먹는 사람들 idx
	local eating_npc_idx = { 3, 6, 7, 8 }

	-- 음식 타입
	local food_type = { gem_stew, food_pilaf, food_pilaf, food_pilaf }

	for i = 1, table_util.get_size(eating_npc_idx) do
		local eater = get_character('microwave_' .. eating_npc_idx[i])
		local pos = eater.Position + direction_util.to_vector3(eater.Direction) * 0.5

		local food = drop_item_util.create_item({ pos = pos, itemid = food_type[i].id,
												  notforinven = true, lootstate = 'dontfindlooter',
												  sprscale = food_type[i].scale })

		table.insert(self.foods, food)
	end

	--endregion

end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.microwave) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_with_microwave, self))
	end
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.soup_zone) then
		if self.soup_sfx_holder == nil then
			self.soup_sfx_holder = music_player_util.play_sfx({
				sfx_name = '01_boiling_01', type_priority = 'loop',
				player_priority = 'npc', loop = true, fade_in_time = 1.5,
				play_pos = vector(21, 0, 124)
			})
		end
	end
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, self.soup_zone) then
		if self.soup_sfx_holder ~= nil then
			self.soup_sfx_holder:FadeOut(1)
			self.soup_sfx_holder = nil
		end
	end
end

--- ConvertWallChangedEvent
function local_class:on_convert_wall_changed_event(_)
	local convert_switch = self.get_convert_switch()

	music_player_util.play_sfx(
		{ sfx_name = '01_blueredwall_01', play_pos = convert_switch.Position,
		  max_distance = 12, type_priority = 'default', player_priority = 'default' })

	return true
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

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ConvertWallChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	--region 괴식 스튜 & 전자레인지 메이드 관련 제거

	-- 음식 아이템 제거
	for i = 1, table_util.get_size(self.foods) do
		local food = self.foods[i]
		if food ~= nil then
			food:ConsumeComplete()
		end
	end
	--endregion

	self.cs_controller = nil
	self.scene = nil
end

function local_class:interact_with_microwave()
	-- bunny_girl_quest를 클리어 했고 베드 앤딩을 봤을 때
	if self.bunny_girl_quest ~= nil then
		if self.bunny_girl_quest.IsComplete and self.bunny_girl_quest.Grade ~= 2 then
			if self.microwave_emoticon ~= nil then
				self.microwave_emoticon:Dispose()
				self.microwave_emoticon = nil
			end
			self.microwave_emoticon = character_util.show_emoticon_with_data(self.microwave.transform, nil,
					'silence', nil, {offset = vector(0, 0, 1.4)} )
			return
		end
	end

	-- 냉동식품 조리도 서빙만큼이나 즐거운 거 같군요.
	speech_bubble_util.remove_bubble(self.microwave)
	speech_bubble_util.show_speech_bubble(self.microwave, { key = 'nightmare_futurecastle_2_microwave_9' })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
