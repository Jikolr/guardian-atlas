---@class TimeConversionElementController
local local_class = newclass('TimeConversionElementController')

---@class TimeConversionElement
local tc_base = newclass('TimeConversionElement')

---@field super TimeConversionElement
---@class TimeConversionNpcElement : TimeConversionElement
local tc_npc = newclass('TimeConversionNpc', tc_base)

---@class TimeConversionGimmickElement : TimeConversionElement
local tc_gimmick = newclass('TimeConversionGimmick', tc_base)

---@return TimeConversionNpcElement
local function make_npc_event(name)
	return newclass('TimeConversionNpcEvent' .. name, tc_npc)
end

---@return TimeConversionGimmickElement
local function make_gimmick_event(name)
	return newclass('TimeConversionGimmickEvent' .. name, tc_gimmick)
end

-- 커스텀 npc 이벤트
local npc_event = {
	-- 2스테이지에서 10섹션 ~ 16섹션동안 보일 강림 이벤트
	stage_2_reaper_event = make_npc_event('stage_2_reaper_event'),

	-- 2스테이지 광장 중앙 구역 원라인 이벤트
	stage_2_square_event = make_npc_event('stage_2_square_event'),

	--공주와 칠득이(강림) 이벤트
	stage_2_princess_n_reaper_event = make_npc_event('stage_2_princess_n_reaper_event'),

	-- 2스테이지 낮 여관 이벤트
	stage_2_inn_daylight_event = make_npc_event('stage_2_inn_daylight_event'),

	-- 3스테이지 박물관 홍보 이벤트
	stage_3_museum_daylight_event = make_npc_event('stage_3_museum_daylight_event'),

	-- 4스테이지에서 17섹션 ~ 18섹션동안 보일 공주와 꼬마들 이벤트
	stage_4_princess_n_kids_event = make_npc_event('stage_4_daylight_princess_event'),

	-- 4스테이지 마을 광장 꼬마들 이벤트
	stage_4_village_center_event = make_npc_event('stage_4_daylight_kids_event'),
}

--TODO: 기믹쪽은 굳이 필요 없을지도
-- 커스텀 기믹 이벤트
local gimmick_event = {
}

--- 여러 고정된 이벤트를 일괄 적용해야 할 때 사용, (ex) 유령 이벤트)
--- common_event의 key를 포함하도록 만들면 탐
local common_event = {
	-- 유령 이벤트
	ghost_event = make_npc_event('ghost')
}

--- npc 세팅할 때 고정적으로 들어가야 하는 옵션 프리셋 (ex) 유령)
local npc_setting_preset = {
	-- 유령 (알파값 0.5 / 틴트 추가 / 표정 empty)
	ghost = {
		color = { r = 0.2, g = 0.6, b = 1, a = 0.5 },
		alpha = 0.5,
		emotion = { name = 'empty' },
	},

	-- 1번 타입
	ghost_type_a = {
		color = { r = 0.2, g = 0.6, b = 1, a = 0.5 },
		alpha = 0.5,
		emotion = { name = 'empty' },
		setting_data = {
			hiding = {
				-- 최대 계산 거리
				max_dist = 5,
				-- 최소 계산 거리
				min_dist = 1.5,
				-- 최대 alpha 값
				max_alpha = 0.8,
			},
		}
	},

	-- 2번 타입
	ghost_type_b = {
		color = { r = 0.2, g = 0.6, b = 1, a = 0.5 },
		alpha = 0,
		emotion = { name = 'empty' },
		setting_data = {
			surprise = {
				-- 유령이 감지 하는 범위
				sight = 1.5,
			}
		}
	},
}

local alpha_duration = 1.25

local get_position = function(data)
	if type_util.is_table(data) then
		return field_util.get_marker_pos(data.pivot) + data.offset
	else
		return field_util.get_marker_pos(data)
	end
end

--region EventManager

function local_class:init()
	-- 메인 컨트롤러
	self.main_controller = nil

	-- 밤/낮 변경시 요소들
	self.tc_elements = {}

	-- 적용되어 있는 낮/밤 인덱스
	self.cur_apply_time_zone = 1

	self.ban_event_list = {}
end

function local_class:initialize(main_controller, event_constant)
	self.main_controller = main_controller
	self.cur_apply_time_zone = self.main_controller.current_time_zone

	-- npc 풀링 로드
	local _, npc_pooling_system = global_table_util.try_create_npc_pooling_system()
	npc_pooling_system:init_pools(event_constant.npc_pools)

	local create_common_event = function(custom_event_key)
		for key, value in pairs(common_event) do
			if string.find(custom_event_key, key) then
				return value
			end
		end

		return nil
	end

	local get_event = function(time_data)
		local event = {}

		for event_name, event_data in pairs(time_data.npc) do
			local creator = npc_event[event_name] or create_common_event(event_name) or tc_npc
			event[event_name] = creator(npc_pooling_system, event_data)
		end

		for event_name, event_data in pairs(time_data.gimmick) do
			local creator = gimmick_event[event_name] or tc_gimmick
			event[event_name] = creator(_, event_data)
		end

		return event
	end

	-- 밤/낮 이벤트 세팅
	for _, value in ipairs(event_constant.stage_setting) do
		table.insert(self.tc_elements, get_event(value))
	end
end

function local_class:dispose()
	local cur_group = self.tc_elements[self.cur_apply_time_zone]

	if cur_group == nil then
		self.tc_elements = nil
		return
	end

	for _, group in pairs(cur_group) do
		self:deactivate_group(group)
	end

	self.ban_event_list = nil
	self.tc_elements = nil
end

function local_class:setting_stage_loaded(quest_progress)
	self.quest_progress = quest_progress
	self.cur_apply_time_zone = self.main_controller.current_time_zone
	local target_group = self.tc_elements[self.cur_apply_time_zone]

	for event_name, group in pairs(target_group) do
		if not table_util.contain_value(self.ban_event_list, event_name) and
				group:is_valid_condition(self.quest_progress) then
			self:activate_group(group)
			group:appear()
		end
	end
end

function local_class:activate_group(group)
	if group:is_enabled() then
		return
	end

	group:enter()
end

function local_class:deactivate_group(group)
	if not group:is_showing() then
		return
	end

	group:exit()
end

function local_class:conversion()
	local cur_group = self.tc_elements[self.cur_apply_time_zone]

	for _, group in pairs(cur_group) do
		group:disappear()
	end

	wait_for_sec(alpha_duration)

	for _, group in pairs(cur_group) do
		group:disappear_complete()
		self:deactivate_group(group)
	end

	local target_group = self.tc_elements[self.main_controller.current_time_zone]

	for event_name, group in pairs(target_group) do
		if not table_util.contain_value(self.ban_event_list, event_name) and
				group:is_valid_condition(self.quest_progress) then
			self:activate_group(group)
			group:appear()
		end
	end

	wait_for_sec(alpha_duration)

	self.cur_apply_time_zone = self.main_controller.current_time_zone
end

function local_class:conversion_complete()
	local cur_group = self.tc_elements[self.cur_apply_time_zone]

	for _, group in pairs(cur_group) do
		group:appear_complete()
	end
end

function local_class:quest_condition_changed()
	local cur_group = self.tc_elements[self.cur_apply_time_zone]

	-- 퀘스트 프로그래스가 변경되면서 유효하지 않은 그룹은 제거
	for _, group in pairs(cur_group) do
		if not group:is_valid_condition(self.quest_progress) then
			group:disappear_complete()
			self:deactivate_group(group)
		end
	end

	-- 벤 리스트에 등록되지 않았으면서 유효한 그룹은 세팅
	for event_name, group in pairs(cur_group) do
		if not table_util.contain_value(self.ban_event_list, event_name) and
				group:is_valid_condition(self.quest_progress) and
				not group:is_enabled() then
			group:enter()
			group:appear_complete()
		end
	end
end

function local_class:get_group(group_name)
	local cur_group_list = self.tc_elements[self.cur_apply_time_zone]

	if cur_group_list == nil then
		return
	end

	local group = cur_group_list[group_name]

	if group == nil or not group:is_enabled() then
		return
	end

	return group
end

--- 이벤트 벤
---@param event_name string 벤 시킬 이벤트 이름
function local_class:add_ban_list(...)
	local ban_name_list = { ... }

	for _, time_zone_event_groups in ipairs(self.tc_elements) do
		for key, group in pairs(time_zone_event_groups) do
			-- 벤 시킬 그룹이랑 같은 이름의 이벤트가 존재한다면 exit 후 벤 처리
			if table_util.contain_value(ban_name_list, key) then
				self:deactivate_group(group)
				table.insert(self.ban_event_list, key)
			end
		end
	end
end

--- 이벤트 벤 해제
---@param event_name string 벤 해제 시킬 이벤트 이름
function local_class:remove_ban_list(event_name)
	for i = #self.ban_event_list, 1, -1 do
		local ban_event_name = self.ban_event_list[i]

		if ban_event_name == event_name then
			table.remove(self.ban_event_list, i)
		end
	end
end

--endregion EventManager

--region ElementBase

local cleared_value = 'clear'

local disappearing_dispose_actions = {
	speech = function(npc)
		local bubble = speech_bubble.instance:Get(npc)

		if bubble ~= nil then
			bubble:ResetBubble()
		end
	end,
	move = function(npc)
		character_util.stop(npc)
	end
}

function tc_base:init(_, cur_data)
	self.scene_version = scene_util.default_version

	self.state = {
		-- 비활성화 상태
		disabled = 1,
		-- 활성화 상태
		enabled = 2,
		-- 사라지는 상태
		disappearing = 3,
	}

	self.cur_state = self.state.disabled

	self.cur_data = cur_data
end

function tc_base:dispose()
	self.cur_data = nil
end

function tc_base:enter()
	self.cur_state = self.state.enabled
end

function tc_base:exit()
	self.cur_state = self.state.disabled
end

-- 시간대가 변경되어 등장하기 시작
function tc_base:appear()
end

-- 등장 완료 후 처리 함수
function tc_base:appear_complete()
end

-- 시간대가 변경될 때 사라짐
function tc_base:disappear()
	self.cur_state = self.state.disappearing
end

function tc_base:disappear_complete()
end

function tc_base:is_valid_condition(quest_progress)
	local progress_infos = self.cur_data.progress_infos

	if progress_infos == nil then
		return true
	end

	local qp = self:check_override_quest_progress(quest_progress)

	-- 프리섹션에도 제어가 필요할 때가 생겨서 nil 체크 후 세팅
	if qp == nil then
		for i = 1, #progress_infos do
			local info = progress_infos[i]

			-- from이 0보다 작으면 세팅 해주어야 하는 그룹이기에 return true
			if type_util.is_string(info.from) then
				return false
			elseif info.from < 0 then
				return true
			end
		end

		return false
	end

	local progress = qp.InnerProgress
	local is_complete = qp.IsComplete

	for i = 1, #progress_infos do
		local info = progress_infos[i]

		if info.from == cleared_value then
			if is_complete then
				return true
			end
		elseif info.to == cleared_value then
			if info.from <= progress or is_complete then
				return true
			end
		elseif info.from <= progress and progress <= info.to and not is_complete then
			return true
		end
	end

	return false
end

function tc_base:check_override_quest_progress(quest_progress)
	local override_quest_id = self.cur_data.override_quest_id

	-- override 퀘스트가 있다면 그걸로 가져옴
	if override_quest_id == nil then
		return quest_progress
	end

	return user_progress:GetStartedQuest(override_quest_id)
end

function tc_base:is_enabled()
	return self.cur_state == self.state.enabled
end

function tc_base:is_showing()
	return self.cur_state ~= self.state.disabled
end

--endregion ElementBase

--region NpcElementBase

function tc_npc:init(npc_pooling_system, cur_data)
	self.super:init(_, cur_data)

	---@type LuaNpcPoolingSystem
	self.npc_pooling_system = npc_pooling_system

	-- npc 핸들러
	self.pooled_npc_data_list = {}

	-- npc(fo) 리스트
	self.npc_list = cur_data.fo
end

function tc_npc:dispose()
	self.super:dispose()

	self.npc_list = nil

	self.npc_pooling_system = nil

	self.pooled_npc_data_list = nil
end

function tc_npc:enter()
	self.super:enter()

	local function get_npc_info(npc_info)
		local preset = npc_setting_preset[npc_info.preset_key]

		if preset == nil then
			return npc_info
		end

		for key, data in pairs(preset) do
			npc_info[key] = data
		end

		return npc_info
	end

	for npc_name, value in pairs(self.npc_list) do
		local npc_info = get_npc_info(value)

		local position = get_position(npc_info.position)
		local handler = self.npc_pooling_system:get_npc_handler(npc_info.key, position, npc_info.direction)

		-- 애니메이션 세팅
		if npc_info.anim ~= nil then
			--TODO: Contant에서 일일이 빼주기에는 많으니 여기서 일괄 빼줌
			npc_info.anim.sfx_name = false
			npc_info.anim.one_shot_sfx = false

			handler:set_anim(self, npc_info.anim)
		end

		-- 표정 세팅
		if npc_info.emotion ~= nil then
			handler:set_emotion(self, npc_info.emotion)
		end

		-- 원라인 talk or emoticon 세팅
		if npc_info.talk ~= nil then
			if type_util.is_table(npc_info.talk) then
				handler:set_one_line(npc_info.talk.key, npc_info.talk.sfx)
			else
				handler:set_one_line(npc_info.talk)
			end
		elseif npc_info.emoticon ~= nil then
			if type_util.is_table(npc_info.emoticon) then
				handler:set_emoticon(npc_info.emoticon.key, npc_info.emoticon.sfx)
			else
				handler:set_emoticon(npc_info.emoticon)
			end
		end

		-- 색 조정
		if npc_info.color ~= nil then
			local color = unity_color({ npc_info.color.r, npc_info.color.g, npc_info.color.b, npc_info.color.a })
			handler:set_add_color(color)
		end

		self.pooled_npc_data_list[npc_name] = {
			handler = handler,
			alpha = npc_info.alpha == nil and 1 or npc_info.alpha,
			setting_data = npc_info.setting_data
		}
	end
end

-- 해제
function tc_npc:exit()
	self.super:exit()

	for npc_name, data in pairs(self.pooled_npc_data_list) do
		data.handler:dispose()
		self.pooled_npc_data_list[npc_name] = nil
	end
end

-- 시간대가 변경될 때 등장
function tc_npc:appear()
	self.super:appear()

	for _, data in pairs(self.pooled_npc_data_list) do
		local npc = data.handler:get_npc()
		-- 알파가 안빠졌을 수 있으니 0으로 만들고 시작
		character_util.spine_set_alpha_fade(npc, 0, 0)
		character_util.spine_set_alpha_fade(npc, data.alpha, alpha_duration)
	end
end

function tc_npc:appear_complete()
	self.super:appear_complete()

	for _, data in pairs(self.pooled_npc_data_list) do
		-- 등장 완료 되었으면 spine 업데이트 한번 진행
		local npc = data.handler:get_npc()

		character_util.spine_set_alpha_fade(npc, data.alpha, 0)
		npc.SpineController:ForceUpdateSpines(0.1)
	end
end

-- 시간대가 변경될 때 사라짐
function tc_npc:disappear()
	self.super:disappear()

	-- 사라지는 연출 도중에 dispose 되어야 하는 액션들 제거
	local function dispose_disappearing_actions(npc, handler)
		-- 액션이 하나도 등록 안되어 있으면 그냥 return
		if handler.dispose_actions == nil then
			return
		end

		for name, _ in pairs(disappearing_dispose_actions) do
			-- 말풍선은 해당 시점에서 사라져야 해서 제거
			local action = handler.dispose_actions[name]

			if action ~= nil then
				action(npc)
				handler:add_dispose_action(name, nil)
			end
		end
	end

	for _, data in pairs(self.pooled_npc_data_list) do
		local handler = data.handler

		local npc = handler:get_npc()
		dispose_disappearing_actions(npc, handler)

		character_util.spine_set_alpha_fade(npc, 0, alpha_duration)
	end
end

---@return LuaNpcPoolHandler
function tc_npc:get_handler(name)
	local data = self.pooled_npc_data_list[name]

	if data == nil then
		return
	end

	return data.handler
end

---@param handler LuaNpcPoolHandler
function tc_npc:show_stoppable_speech_async(handler, key, data)
	local talker = handler:get_npc()

	if talker == nil then
		return
	end

	if data == nil then
		data = {}
	end

	data.key = key

	handler:add_dispose_action('speech', disappearing_dispose_actions.speech)

	speech_bubble_util.show_speech_bubble_async(talker, data)

	if self.cur_state == self.state.enabled then
		handler:add_dispose_action('speech', nil)
	end
end

function tc_npc:move(handler, waypoints, speed, duration, data)
	local npc = handler:get_npc()

	if npc == nil then
		return
	end

	handler:add_dispose_action('move', disappearing_dispose_actions.move)

	wp_util.move_async(npc, waypoints, speed, duration, data)

	if self.cur_state == self.state.enabled then
		handler:add_dispose_action('move', nil)
	end
end

--endregion NpcElementBase

--region GimmickElementBase

function tc_gimmick:init(_, cur_data)
	self.super:init(_, cur_data)
	self.gimmick_data = cur_data.fo

	self.show_func = {
		anim = function(gimmick, _)
			local animator = gimmick:GetComponent(typeof(CS.UnityEngine.Animator))
			animator:Play('daylight', -1, 0)
		end,
		--effect 등장 추가될지도
	}

	self.hide_func = {
		anim = function(gimmick, _)
			local animator = gimmick:GetComponent(typeof(CS.UnityEngine.Animator))
			animator:Play('night', -1, 0)
		end,
	}
end

function tc_gimmick:dispose()
	self.super:dispose()
	self.gimmick_data = nil
end

function tc_gimmick:enter()
	self.super:enter()

	for _, gimmick_data in ipairs(self.gimmick_data) do
		local gimmick = get_field_object(gimmick_data.name)
		field_object_util.set_active_state(gimmick, active_state_type.enabled)
		message_system:Send(gimmick, CS.Oak.GimmickResetEvent.Instance)
	end
end

function tc_gimmick:exit()
	self.super:exit()
end

function tc_gimmick:appear()
	self.super:appear()

	for _, gimmick_data in ipairs(self.gimmick_data) do
		if gimmick_data.show_type ~= nil then
			local gimmick = get_field_object(gimmick_data.name)
			self.show_func[gimmick_data.show_type](gimmick, gimmick_data.value)
		end
	end
end

function tc_gimmick:disappear()
	self.super:disappear()

	for _, gimmick_data in ipairs(self.gimmick_data) do
		if gimmick_data.show_type ~= nil then
			local gimmick = get_field_object(gimmick_data.name)
			self.hide_func[gimmick_data.show_type](gimmick, gimmick_data.value)
		end
	end
end

function tc_gimmick:disappear_complete()
	for _, gimmick_data in ipairs(self.gimmick_data) do
		local gimmick = get_field_object(gimmick_data.name)
		field_object_util.set_active_state(gimmick, active_state_type.disabled)
	end
end

--endregion GimmickElementBase

do
	-- 2스테이지에서 10섹션 ~ 16섹션동안 보일 강림 이벤트
	local event = npc_event.stage_2_reaper_event

	function event:init(npc_pooling_system, constants)
		self.super:init(npc_pooling_system, constants)

		self.fx = {
			loop_effect = function()
				return unity_object_pool.GetOrCreate('fx_dv_reaper_restraint_loop')
			end,
			end_effect = function()
				return unity_object_pool.GetOrCreate('fx_dv_reaper_restraint_end')
			end,
			load_all = function(this)
				for name, load_func in pairs(this) do
					if name ~= 'load_all' then
						load_func()
					end
				end
			end
		}

		self.loop_effect = nil

		self.fx:load_all()
	end

	function event:enter()
		self.super:enter()

		local pos = self:get_handler('reaper'):get_npc().Position + vector(0, 5, -3.2)
		self.loop_effect = self.fx.loop_effect():Instantiate(pos)
	end

	function event:disappear()
		if self.loop_effect ~= nil then
			self.loop_effect:Dispose()

			local zone_bounds = field:GetZone('s10_event_zone').Bounds
			local leader_bounds = get_party_leader().Bounds

			-- 리더가 존 안에 있다면 end 이펙트 재생
			if bounds_util.is_overlapping_xz(zone_bounds, leader_bounds) then
				local pos = self:get_handler('reaper'):get_npc().Position + vector(0, 5, -3.2)
				self.fx.end_effect():Instantiate(pos)
			end

			self.loop_effect = nil
		end

		self.super:disappear()
	end

	function event:exit()
		self.super:exit()
	end
end

-- 스테이지4 섹션 17 ~ 18 이벤트
do
	local event = npc_event.stage_4_princess_n_kids_event

	function event:init(npc_pooling_system, constants)
		self.super:init(npc_pooling_system, constants)

		self.zone_name = 'princess_n_kids'
		self.is_show_end = false
	end

	function event:enter()
		self.super:enter()

		local npc_1_handler = self:get_handler('princess')
		local npc_1 = npc_1_handler:get_npc()

		local npc_2_handler = self:get_handler('kid_female_friend')
		local npc_2 = npc_2_handler:get_npc()

		local npc_3_handler = self:get_handler('kid_male_friend')
		local npc_3 = npc_3_handler:get_npc()

		if self.is_show_end then
			npc_1_handler:set_one_line('dv_main_stage_4_princess_event_oneline_1')
			npc_1_handler:set_anim(self, 'sing')
			npc_1_handler:set_emotion(self, 'smile')
			scene_util.set_direction(npc_1, 'left', false)

			npc_2_handler:set_emotion(self, 'smile')
			scene_util.set_direction(npc_2, 'right', false)
			character_util.set_position(npc_2, npc_1.Position + vector(-2, 0, 0))
			npc_2_handler:set_one_line('dv_main_stage_4_princess_event_oneline_2')

			scene_util.set_direction(npc_3, 'left', false)
			npc_3_handler:set_emotion(self, 'sleep_deep')

			npc_3.Interactable = CS.Oak.EmoticonInteractable.Create(CS.Oak.EmoticonType.Annoyed)
		else
			self.triggered = false

			if not self.triggered and not self.is_show_end and
					zone_util.contains_fo(self.zone_name, get_party_leader(), false) then

				self.triggered = true
				start_coroutine(self.play_princess_n_kids_event, self)
			end

			npc_1.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			npc_2.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			npc_3.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
		end

		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	end

	function event:exit()
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

		self.super:exit()
	end

	function event:on_zone_enter_event(e)
		if not self.triggered and not self.is_show_end and
				type_util.is_zone_full_enter(e, get_party_leader(), self.zone_name) then

			self.triggered = true
			start_coroutine(self.play_princess_n_kids_event, self)
			return true
		end

		return false
	end

	function event:play_princess_n_kids_event()
		local princess_handler = self:get_handler('princess')
		local princess = princess_handler:get_npc()
		local kid_1_handler = self:get_handler('kid_female_friend')
		local kid_1 = kid_1_handler:get_npc()
		local kid_2_handler = self:get_handler('kid_male_friend')
		local kid_2 = kid_2_handler:get_npc()

		-- 꼬마 공주 (right, smile, idle) : 좋아! 이번엔 어디로 가볼까?
		self:show_stoppable_speech_async(princess_handler, 'dv_main_stage_4_princess_event_1', { skip = false })

		if not self:is_enabled() then
			return
		end

		-- 여자 꼬마 (left, tired, idle) : 으으…! 우리 아까까지 놀고 있었잖아…!
		music_player_util.play_sfx({
			sfx_name = '03_dialogue_tipsy_01', parent = kid_1,
			loop = false, player_priority = 'npc',
		})
		kid_1_handler:set_emotion(self, 'tired')
		self:show_stoppable_speech_async(kid_1_handler, 'dv_main_stage_4_princess_event_2', { skip = false })

		if not self:is_enabled() then
			return
		end

		-- 꼬마 공주 (right, smile, idle) : 뭐? 이제 시작이지! 저기 가게들도 가고 싶어!
		self:show_stoppable_speech_async(princess_handler, 'dv_main_stage_4_princess_event_3', { skip = false })

		if not self:is_enabled() then
			return
		end

		-- 여자 꼬마 (left, smile, idle) : …알았어 알았어! 그럼 가자!
		kid_1_handler:set_emotion(self, 'smile')
		self:show_stoppable_speech_async(kid_1_handler, 'dv_main_stage_4_princess_event_4', { skip = false })

		if not self:is_enabled() then
			return
		end

		-- 꼬마 공주 (left, idle, idle) question 이모티콘 사용 후 완료까지 대기.
		music_player_util.play_sfx({
			sfx_name = '01_swing_01', parent = princess,
			loop = false, player_priority = 'npc',
		})
		character_util.remove_anim_and_emotion(princess)
		scene_util.set_direction(princess, 'left', false)
		character_util.show_emoticon_async(princess, nil, 'question')

		-- 0.5초 대기
		if not self:wait_for_sec_during_active_state(0.5) then
			return
		end

		if not self:is_enabled() then
			return
		end

		start_coroutine(function()
			-- 2초간 여자 꼬마 빠르게 달려가는 파트
			-- 여자 꼬마 (left, attack, jump 1회)를 0.5초간 실행.
			music_player_util.play_sfx({
				sfx_name = '01_small_jump_01', parent = kid_1,
				loop = false, player_priority = 'npc',
			})
			character_util.normal_jump_async(kid_1, false)
			-- 이후 여자 꼬마 (left, attack, run) 상태로 지정된 동선을 1.5초만에 이동.
			local move_list = {
				field_util.get_marker_pos('day_event_1_friend_kid_girl_2'),
				field_util.get_marker_pos('day_event_1_friend_kid_girl_3')
			}
			local run_sfx = music_player_util.play_sfx({
				sfx_name = '01_dash_01', parent = kid_1,
				loop = true, player_priority = 'npc',
			})
			wp_util.move(kid_1, { vector(kid_1.Position.x, 0, move_list[1].z), vector(move_list[2].x, 0, move_list[1].z), move_list[2] },
					nil, 1.7, { run = true, last_direction = 'right' })

			if not self:wait_for_sec_during_active_state(1.7, function()
				character_util.stop(kid_1)
				run_sfx:Stop()
				run_sfx = nil
			end) then
				return
			end

			run_sfx:Stop()
			run_sfx = nil

			if not self:is_enabled() then
				return
			end

			-- 도착하면 여자 꼬마 (right, attack, idle) 실행.
			kid_1_handler:set_emotion(self, 'attack')
		end)

		-- 2초간 꼬마 공주 천천히 다가가는 파트.
		-- 꼬마 공주 (left, smile, walk) 상태로 2초간 1타일 좌측으로 이동.
		local princess_move_end = false
		start_coroutine(function()
			princess_handler:set_emotion(self, 'smile')
			wp_util.move(princess, princess.Position + vector(-1, 0, 0), nil, 2)

			if not self:wait_for_sec_during_active_state(2, function()
				character_util.stop(princess)
			end) then
				return
			end

			princess_handler:remove_emotion()

			princess_move_end = true
		end)

		-- 꼬마 공주 (left, smile, walk) : 거기 꼬마야! 너도 같이….
		self:show_stoppable_speech_async(princess_handler, 'dv_main_stage_4_princess_event_5', { skip = false })

		princess_handler:remove_emotion()

		while not princess_move_end do
			if not self:is_enabled() then
				return
			end

			coroutine.yield(nil)
		end

		if not self:is_enabled() then
			return
		end

		-- 여자 꼬마 (right, tired, idle) : 자… 잠깐. 쟤는 그냥 빼고 놀자.
		kid_1_handler:set_emotion(self, 'tired')
		self:show_stoppable_speech_async(kid_1_handler, 'dv_main_stage_4_princess_event_6', { skip = false })

		if not self:is_enabled() then
			return
		end

		-- 꼬마 공주 (left, idle, idle) : 왜? 같이 놀면 좋잖아?
		character_util.remove_anim_and_emotion(princess)
		self:show_stoppable_speech_async(princess_handler, 'dv_main_stage_4_princess_event_7', { skip = false })

		if not self:is_enabled() then
			return
		end

		-- 여자 꼬마 (right, tired, idle) : 음… 쟤는 그냥…
		self:show_stoppable_speech_async(kid_1_handler, 'dv_main_stage_4_princess_event_8', { skip = false })

		-- 아래 사항 동시에 실행.
		-- * 여자 꼬마 (right, sleep_deep, idle) silence 이모티콘 출력 후 완료까지 대기.
		-- * 남자 꼬마 (left, sleep_deep, idle) annoyed 이모티콘 출력 후 완료까지 대기.
		music_player_util.play_sfx({
			sfx_name = '03_dialogue_angry_01', parent = kid_1,
			loop = false, player_priority = 'npc',
		})
		kid_1_handler:set_emotion(self, 'sleep_deep')
		kid_2_handler:set_emotion(self, 'sleep_deep')
		character_util.show_emoticon(kid_1, nil, 'silence')
		character_util.show_emoticon_async(kid_2, nil, 'annoyed')

		-- 여자 꼬마 (right, smile, idle) : 그냥 우리랑 놀기 싫어할 거야. 그러니 우리끼리 놀자.
		kid_1_handler:set_emotion(self, 'smile')
		self:show_stoppable_speech_async(kid_1_handler, 'dv_main_stage_4_princess_event_9', { skip = false })

		-- 꼬마 공주 (left, tired, idle) : 그래? 음… 아쉽네….
		princess_handler:set_emotion(self, 'tired')
		self:show_stoppable_speech_async(princess_handler, 'dv_main_stage_4_princess_event_10', { skip = false })

		-- 마지막 셋팅
		princess_handler:set_one_line('dv_main_stage_4_princess_event_oneline_1')
		princess_handler:set_anim(self, 'sing')
		princess_handler:set_emotion(self, 'smile')

		kid_1_handler:set_emotion(self, 'smile')
		scene_util.set_direction(kid_1, 'right', false)
		kid_1_handler:set_one_line('dv_main_stage_4_princess_event_oneline_2')

		kid_2_handler:set_emotion(self, 'sleep_deep')

		kid_2.Interactable = CS.Oak.EmoticonInteractable.Create(CS.Oak.EmoticonType.Annoyed)

		princess.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		kid_1.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		kid_2.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

		self.is_show_end = true
	end

	-- 파라메터로 입력받은 시간만큼 대기하는 함수, 루프 중간 탈출 시 false 반환
	function event:wait_for_sec_during_active_state(duration, execute_func_when_deactivated_state)
		local time_passed = 0

		while time_passed < duration do
			time_passed = time_passed + unity_class.time.deltaTime

			if not self:is_enabled() then
				if execute_func_when_deactivated_state ~= nil then
					execute_func_when_deactivated_state()
				end

				return false
			end

			coroutine.yield(nil)
		end

		return true
	end
end

do
	-- 유령 이벤트
	local event = common_event.ghost_event

	local function lerp(a, b, t)
		return a + (b - a) * t
	end

	function event:init(npc_pooling_system, constants)
		self.super:init(npc_pooling_system, constants)

		-- 유령들의 등록될 루틴 리스트
		self.func_list = {
			hiding = {
				func = self.hiding_routine,
			},
			surprise = {
				start = function(_, ghost, constant_data)
					ghost.EntityGroup = CS.Oak.EntityGroups.Obstacle
				end,
				exit = function(_, ghost)
					ghost.EntityGroup = CS.Oak.EntityGroups.Neutral0
				end,
				func = self.surprise_routine,
			},
		}

		-- 유령 로직이 돌아갈 존 이름
		self.start_event_zone_name = constants.zone_name

		-- 리퀘스트 id
		self.cur_req_id = 0

		-- 최대 리퀘스트 id
		self.max_req_id = 10

		-- 존에 들어가서 이벤트가 활성화 되었는지 여부
		self.is_active_event = false

		-- 유령에게 도망가고 있는지 여부
		self.is_running = false
	end

	function event:enter()
		self.super:enter()

		for key, value in pairs(self.pooled_npc_data_list) do
			local ghost = value.handler:get_npc()

			ghost.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

			-- 유령들을 캐릭터 스텟 ui가 없어야 한다.
			field_ui_manager:RemoveUI(ghost, CS.Oak.FieldUiType.CharacterStats)

			local setting_data = value.setting_data

			-- 세팅 데이터가 있으면
			if setting_data ~= nil then
				self.pooled_npc_data_list[key].func_dict = {}

				-- routine_types 만큼 로직에 넣어준다
				for type_key, constant_data in pairs(setting_data) do
					local func_data = self.func_list[type_key]

					-- 없는 루틴이라면 안 넣어줌
					if func_data ~= nil then
						if func_data.start ~= nil then
							func_data:start(ghost, constant_data)
						end

						if func_data.func ~= nil then
							self.pooled_npc_data_list[key].func_dict[type_key] = func_data.func
						end
					end
				end
			end
		end

		if self.start_event_zone_name ~= nil then
			message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
			message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
		end
	end

	function event:exit()
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

		for _, value in pairs(self.pooled_npc_data_list) do
			local ghost = value.handler:get_npc()
			local setting_data = value.setting_data

			if setting_data ~= nil then
				for type_key, _ in pairs(setting_data) do
					local func_data = self.func_list[type_key]

					if func_data ~= nil and func_data.exit ~= nil then
						func_data:exit(ghost)
					end
				end
			end

			ghost.OverrideCrashBehaviour = nil
			field_ui_manager:SetUI(ghost, CS.Oak.FieldUiType.CharacterStats)
		end

		self.is_running = false
		self.is_active_event = false
		self.super:exit()
	end

	function event:appear()
		local leader = get_party_leader()

		for _, data in pairs(self.pooled_npc_data_list) do
			local npc = data.handler:get_npc()
			character_util.spine_set_alpha_fade(npc, 0, 0)

			local func_dict = data.func_dict
			local alpha = data.alpha

			if func_dict ~= nil then
				if table_util.contain_key(func_dict, 'hiding') then
					local setting_data = data.setting_data['hiding']
					local dist = (npc.Position - leader.Position).magnitude
					local progress = math.min(dist, setting_data.max_dist) / setting_data.max_dist

					alpha = lerp(setting_data.max_alpha, 0, progress)
				elseif table_util.contain_key(func_dict, 'surprise') then
					alpha = 0
				end
			end

			character_util.spine_set_alpha_fade(npc, alpha, 1)

			npc.SpineController:ForceUpdateSpines(0.1)
		end
	end

	function event:disappear()
		self.is_active_event = false
		self.super:disappear()
	end

	function event:appear_complete()
		if self.start_event_zone_name == nil then
			return
		end

		local zone_bounds = field:GetZone(self.start_event_zone_name).Bounds
		local leader_bounds = get_party_leader().Bounds

		-- 리더가 존 안에 있었다면 로직 시작
		if bounds_util.is_overlapping_xz(zone_bounds, leader_bounds) then
			self.is_active_event = true
			start_coroutine(self.ghosts_routine, self)
		end
	end

	function event:on_zone_enter_event(e)
		if not self.is_active_event and
				type_util.is_zone_full_enter(e, get_party_leader(), self.start_event_zone_name) then

			self.is_active_event = true
			start_coroutine(self.ghosts_routine, self)
			return true
		end

		return false
	end

	function event:on_zone_leave_event(e)
		if type_util.is_zone_full_leave(e, get_party_leader(), self.start_event_zone_name) then
			self.is_active_event = false
			return true
		end

		return false
	end

	--- 리퀘스트 아이디 세팅
	function event:set_request_id()
		self.cur_req_id = self.cur_req_id + 1

		if self.cur_req_id > self.max_req_id then
			self.cur_req_id = 0
		end
	end

	--- 존 안에 있는 유령들 루틴 시작
	function event:ghosts_routine()
		local leader = get_party_leader()

		self:set_request_id()
		local req_id = self.cur_req_id

		while req_id == self.cur_req_id and self.is_active_event do
			for _, value in pairs(self.pooled_npc_data_list) do
				if value.func_dict ~= nil then
					self:process_ghost_routine(leader, value.handler:get_npc(),
							value.setting_data, value.func_dict)
				end
			end

			coroutine.yield(nil)
		end
	end

	--- 유령 로직 처리
	---@param leader Character 리더 캐릭터
	---@param ghost_spec_list table 유령
	function event:process_ghost_routine(leader, ghost, setting_data, func_dict)
		-- 유령과 리더의 거리
		local dist = (ghost.Position - leader.Position).magnitude

		-- 등록된 함수들 로직 작동
		for func_key, func in pairs(func_dict) do
			func(self, ghost, dist, setting_data[func_key])
		end
	end

	--- 유령 놀래키기 (hiding)
	---@param npc Character 놀래키는 유령 캐릭터
	---@param dist number 유령과의 거리
	---@param data table 유령의 스팩
	function event:hiding_routine(ghost_npc, dist, data)
		local progress = math.min(dist, data.max_dist) / data.max_dist
		local alpha = lerp(data.max_alpha, 0, progress)

		character_util.spine_set_alpha_fade(ghost_npc, alpha, 0)
	end

	--- 유령 놀래키기 (surprise)
	---@param npc Character 놀래키는 유령 캐릭터
	---@param dist number 유령과의 거리
	---@param data table 유령의 스팩
	function event:surprise_routine(ghost_npc, dist, data)
		-- 도망가는 로직이 작동중일 때는 제외
		--TODO: 지금 같은 그룹의 유령은 다 안돌도록 되어 있는데, 튕기고 튕기는걸 윈하면 유령별로 막아야할듯
		if self.is_running then
			return
		end

		-- 일정 범위 안으로 들어왔을 때 도망가는 로직 재생
		if dist <= data.sight then
			self.is_running = true
			start_coroutine(self.scream_logic, self, ghost_npc, data.dir, data.dist)
		end
	end

	function event:scream_logic(fo, dir, dist)
		local leader = get_party_leader()

		dist = lua_helper.get_or_default(dist, 4)

		if dir == nil then
			dir = vector_util.to_direction(leader.Position - fo.Position)

			if dir == CS.Oak.Direction.None then
				dir = fo.Direction
			end
		end

		-- 커스텀버튼이라 해당 state 때 사라지지 않아서 추가 처리
		field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.CustomButton1, leader)

		-- 아래의 사항을 0.3초간 동시에 실행.
		character_util.stop(leader)

		-- 유령은 0.3초에 걸쳐 틴트값이 0.8로 상승.
		character_util.spine_set_alpha_fade(fo, 0.8, 0.3)

		-- 플레이어는 (유령 방향, surprise, idle, jump 1회[0.3초 소모])
		music_player_util.play_sfx_one_shot('01_ghost_detect_01')
		character_util.look_at(leader, fo)
		character_util.set_emotion(leader, { name = 'surprise' })
		character_util.normal_jump_async(leader, '01_small_jump_01')

		if not self.is_running then
			return
		end

		character_util.spine_set_alpha_fade(fo, 0, 0.7)

		-- CharacterControllerScreamState로 변경
		music_player_util.play_sfx_one_shot('03_runaway_01')
		leader:SetLockedDirection(leader, CS.Oak.LockDirectionRequest.Create(dir, CS.Oak.LockDirectionPriorities.Custom + 1))

		character_util.remove_emotion(leader)
		local state = CS.Oak.CharacterControllerScreamState.Create(leader, fo, dir, dist, 0.6, 0.7)
		message_system:SendSync(leader.FieldObjectController, CS.Oak.StateChangeEvent.Create(state))

		-- 유령에게 도망가는 로직이 종료될 때까지 대기
		while self.is_running and lua_helper.type_compare(leader.FieldObjectController.CurrentState,
				CS.Oak.CharacterControllerScreamState) do
			coroutine.yield(nil)
		end

		-- 버튼 다시 활성화
		leader:RemoveLockedDirection(leader)
		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CustomButton1, leader)
		self.is_running = false
	end
end

do
	--광장 중앙 구역 원라인 NPC(낮)
	local event = npc_event.stage_2_square_event

	function event:init(npc_pooling_system, constants)
		self.super:init(npc_pooling_system, constants)

		self.zone_name = 'daylight_square_zone'
		self.is_show_end = false

		self.fx = setmetatable({
			hit = function()
				return unity_object_pool.GetOrCreate('FX_hit')
			end,
		}, {
			__index = {
				load_all = function(this)
					for _, func in pairs(this) do
						func()
					end
				end
			}
		})

		self.fx:load_all()
	end

	function event:enter()
		self.super:enter()
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
		--9번, 10번 관련
		local npc_9_handler = self:get_handler('sq_npc_9')
		local npc_9 = npc_9_handler:get_npc()

		local npc_10_handler = self:get_handler('sq_npc_10')
		local npc_10 = npc_10_handler:get_npc()

		character_util.spine_set_attachment(npc_9, '[base]weapon1', 'club')

		if self.is_show_end then

			--9번(right, attack, attack 1회, 마지막 자세 유지) : 나는 겁 없는 용사님이다!!
			scene_util.set_direction(npc_9, 'right', false)
			npc_9_handler:set_emotion(self, 'attack')
			npc_9_handler:set_anim(self, { name = 'sword_attack', loop = false, scale = 999 })
			npc_9_handler:set_one_line('dv_stage2_daylight_oneline_3_9')

			--10번(right, smile, clap) : 아유, 우리 아들 씩씩하네.
			scene_util.set_direction(npc_10, 'right', false)
			npc_10_handler:set_emotion(self, 'smile')
			npc_10_handler:set_anim(self, { name = 'clap', one_shot_sfx = false })
			npc_10_handler:set_one_line('dv_stage2_daylight_oneline_3_10')
		else

			self.triggered = false
		end

		--6번 길막관련
		local npc_6 = self:get_handler('sq_npc_6'):get_npc()
		npc_6.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(1.1, 0.75, 2))
	end

	function event:exit()
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

		local npc_9_handler = self:get_handler('sq_npc_9')
		local npc_9 = npc_9_handler:get_npc()
		character_util.spine_set_attachment(npc_9, '[base]weapon1', 'empty')

		--6번 길막관련
		local npc_6 = self:get_handler('sq_npc_6'):get_npc()
		npc_6.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(1.1, 0.75, 1.1))

		self.super:exit()
	end

	function event:on_zone_enter_event(e)
		if not self.triggered and not self.is_show_end and
				type_util.is_zone_full_enter(e, get_party_leader(), self.zone_name) then
			self.triggered = true
			start_coroutine(self.play_club_kid_event, self)
			return true
		end

		return false
	end

	function event:play_club_kid_event()
		local npc_9_handler = self:get_handler('sq_npc_9')
		local npc_10_handler = self:get_handler('sq_npc_10')

		local npc_9 = npc_9_handler:get_npc()
		local npc_10 = npc_10_handler:get_npc()

		--존 엔터하면 컨트롤 뺏지 않은 채로 이벤트 진행.
		--9번(right, attack, attack 1회, 마지막 자세 유지) : 나는 겁 없는 용사님이다!!
		npc_9_handler:set_anim(self, { name = 'sword_attack', loop = false, sfx_name = function()

			music_player_util.play_sfx({ sfx_name = '01_hit_comic_01', parent = npc_9, loop = false })

			--attack 1회 하여 앞에 오브젝트 때리는 순간에 fx_hit 이펙트 배치.
			self.fx.hit():Instantiate(
					field_util.get_marker_pos('daylight_square_pos_9') + vector(1, 0.03, 0))

		end })
		npc_9_handler:set_emotion(self, 'attack')
		self:show_stoppable_speech_async(npc_9_handler, 'dv_stage2_daylight_oneline_3_9', { skip = false })

		--0.5초 대기.
		if not self:wait_for_sec_during_active_state(0.5) then
			return
		end

		if not self:is_enabled() then
			return
		end

		--10번(right, smile, clap) : 아유, 우리 아들 씩씩하네.
		music_player_util.play_sfx({ sfx_name = '01_clap_02', parent = npc_10, loop = false })
		npc_10_handler:set_emotion(self, 'smile')
		npc_10_handler:set_anim(self, { name = 'clap', one_shot_sfx = false })
		self:show_stoppable_speech_async(npc_10_handler, 'dv_stage2_daylight_oneline_3_10', { skip = false })

		if not self:is_enabled() then
			return
		end

		--이후 둘 다 원라인
		--9번(right, attack, attack 1회, 마지막 자세 유지) : 나는 겁 없는 용사님이다!!
		npc_9_handler:set_one_line('dv_stage2_daylight_oneline_3_9')

		--10번(right, smile, clap) : 아유, 우리 아들 씩씩하네.
		npc_10_handler:set_one_line('dv_stage2_daylight_oneline_3_10')

		self.is_show_end = true
	end

	-- 파라메터로 입력받은 시간만큼 대기하는 함수, 루프 중간 탈출 시 false 반환
	function event:wait_for_sec_during_active_state(duration, execute_func_when_deactivated_state)
		local time_passed = 0

		while time_passed < duration do
			time_passed = time_passed + unity_class.time.deltaTime

			if not self:is_enabled() then
				if execute_func_when_deactivated_state ~= nil then
					execute_func_when_deactivated_state()
				end

				return false
			end

			coroutine.yield(nil)
		end

		return true
	end
end

do
	--공주와 칠득이(강림) 이벤트
	local event = npc_event.stage_2_princess_n_reaper_event

	function event:init(npc_pooling_system, constants)
		self.super:init(npc_pooling_system, constants)

		self.triggered = false
		self.is_un_subscribe = false

		self.is_check_custom_state = false
		self.main_quest_id = 441
		self.main_quest_custom_key = 'stage_2_princess_n_reaper'
	end

	function event:enter()
		self.super:enter()

		--1회 감상 이후에는 다시 이벤트 진행되지 않도록 처리
		--감상 여부를 저장해서, 두 번 보지 않도록 처리 필요합니다.
		--스테이지 종료 이후에도 아직 안 본 상태라면 이벤트 진행가능하도록 처리
		if not self.is_check_custom_state then
			local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

			local custom_state = quest_util.get_custom_state(quest_progress, self.main_quest_custom_key)

			if custom_state ~= -1 then
				self.triggered = true
			end

			self.is_check_custom_state = true
		end

		local princess_handler = self:get_handler('pnr_princess')
		local princess_npc = princess_handler:get_npc()

		local reaper_handler = self:get_handler('pnr_reaper')
		local reaper_npc = reaper_handler:get_npc()

		if self.triggered then
			--공주(left, smile, idle) : 내 걱정은 말고 다녀와!
			scene_util.set_direction(princess_npc, 'left', false)
			princess_handler:set_emotion(self, 'smile')
			princess_handler:set_anim(self, 'smile')
			princess_handler:set_one_line('dv_stage2_princess_n_reaper_oneline_1')

			--칠득이(left, dumb_idle, idle) : 그래서… 우리 뭐하러 나온 거죠?
			scene_util.set_direction(reaper_npc, 'left', false)
			reaper_handler:set_emotion(self, 'dumb_idle')
			reaper_handler:set_anim(self, 'idle')
			reaper_handler:set_one_line('dv_stage2_princess_n_reaper_oneline_2')

		else
			character_util.add_lua_listener(princess_npc, self)
			character_util.add_lua_listener(reaper_npc, self)

			message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
		end

	end

	function event:exit()
		self:un_subscribe_interact_event()

		self.super:exit()
	end

	function event:un_subscribe_interact_event()

		message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

		local princess = self:get_handler('pnr_princess'):get_npc()
		local reaper = self:get_handler('pnr_reaper'):get_npc()

		character_util.remove_lua_listener(princess, self)
		character_util.remove_lua_listener(reaper, self)

		self.is_un_subscribe = true
	end

	function event:on_event(e)
		local princess = self:get_handler('pnr_princess'):get_npc()
		local reaper = self:get_handler('pnr_reaper'):get_npc()

		if not self.triggered and
				(type_util.is_interacted_target(e, princess) or
						type_util.is_interacted_target(e, reaper)) then
			self.triggered = true

			sp_util.start_scene(self.princess_n_reaper_scene, self)

			return true
		end

		return false
	end

	function event:princess_n_reaper_scene()
		local pivot_pos = field_util.get_marker_pos('princess_n_reaper_pos_1')

		local princess_handler = self:get_handler('pnr_princess')
		local princess_npc = princess_handler:get_npc()
		local reaper_handler = self:get_handler('pnr_reaper')
		local reaper_npc = reaper_handler:get_npc()

		local knight = get_party_leader()
		local twins_younger = get_character('twins_younger')

		music_player_util.change_stage_music_volume('field', 0.6)

		--1초간 위 위치로 기사, 도화 정렬.
		wp_util.move(knight, pivot_pos + vector(-1, 0, 0), nil, 1, { last_direction = 'right' })
		wp_util.move_async(twins_younger, pivot_pos + vector(-2, 0, 0), nil, 1, { last_direction = 'right' })

		--공주(left, smile, idle, jump 1회) : $name! 자리에 없길래 칠득이랑 찾으러 왔었는데…
		character_util.normal_jump(princess_npc, true)
		scene_util.play_normal_speech_action(princess_npc, self, 'left',
				nil, 'smile', 'dv_stage2_princess_n_reaper_1')

		--공주(left, smile, bomb_idle) : 도화랑 같이 있었구나!
		scene_util.play_normal_speech_action(princess_npc, self, 'left',
				'bomb_idle', 'smile', 'dv_stage2_princess_n_reaper_2')

		--가디언 선택지
		local choose_result = choose_util.play_choose_event({
			--(mercy)말 없이 사라져서 죄송해요.
			{ 'dv_stage2_princess_n_reaper_3', 'mercy' },
			--(brutal)공주님 들어보세요, 이 세상이…
			{ 'dv_stage2_princess_n_reaper_4', 'brutal' },
		})
		if choose_result == 1 then

			--(mercy)말 없이 사라져서 죄송해요.

			--기사 (right, tired, cast)
			music_player_util.play_sfx_one_shot('01_rustle_01')
			scene_util.set_direction(knight, 'right', false)
			scene_util.set_emotion(knight, self, 'tired')
			scene_util.set_anim(knight, self, 'cast')

			--1초 대기
			wait_for_sec(1)

			--기사 right, tired, idle.
			scene_util.set_direction(knight, 'right', false)
			scene_util.set_emotion(knight, self, 'tired')
			scene_util.set_anim(knight, self, 'idle')

			--도화(right, tired, idle) : 제… 제가 용사님한테 부탁할 게 있어서 멋대로….
			scene_util.play_normal_speech_action(twins_younger, self, 'right',
					nil, 'tired', 'dv_stage2_princess_n_reaper_5')

			--공주(left, smile, release 3회) : 아니야, 히히. 그래도 덕분에 칠득이랑 재밌게 놀고 있었어.
			scene_util.play_normal_speech_action(princess_npc, self, 'left',
					{ name = 'release', count = 3 }, 'smile', 'dv_stage2_princess_n_reaper_6')

			--표정 유지.
		else
			--(brutal)공주님 들어보세요, 이 세상이…

			--기사 (right, scared, release 3회)
			music_player_util.play_sfx_one_shot('03_runaway_01')
			scene_util.set_direction(knight, 'right', false)
			scene_util.set_emotion(knight, self, 'scared')
			scene_util.set_anim_async(knight, self, { name = 'release', count = 3 })

			--도화(right, damaged, cast) : 요… 용사님…! 얘기하면 큰일나요…!
			music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
			scene_util.play_normal_speech_action(twins_younger, self, 'right',
					'cast', 'damaged', 'dv_stage2_princess_n_reaper_7')

			--기사 (right, tired, idle).
			scene_util.set_direction(knight, 'right', false)
			scene_util.set_emotion(knight, self, 'tired')
			character_util.remove_anim(knight)

			--공주 (left, idle, idle, question 이모티콘)
			scene_util.play_emoticon_action(princess_npc, self, 'left',
					'idle', 'idle', 'question')

			--공주(left, idle, bomb_idle) : 응…? 뭐라구?
			scene_util.play_normal_speech_action(princess_npc, self, 'left',
					'bomb_idle', nil, 'dv_stage2_princess_n_reaper_8')
		end

		--기사 (right, idle, idle)
		scene_util.set_direction(knight, 'right', false)
		character_util.remove_anim_and_emotion(knight)

		--칠득이(left, dumb_idle, idle) : 어라…? 이 나으리를 찾고 계셨어요?
		scene_util.play_normal_speech_action(reaper_npc, self, 'left',
				nil, { name = 'dumb_idle' }, 'dv_stage2_princess_n_reaper_9')

		--칠득이(left, dumb_smile, release 3회) : 저는 예언가 아저씨 찾으시는 줄 알았는데!
		scene_util.play_normal_speech_action(reaper_npc, self, 'left',
				{ name = 'release', count = 3 },
				{ name = 'dumb_smile', keep = true },
				'dv_stage2_princess_n_reaper_10')

		--표정 유지.

		--공주(right, smile, nod 2회) : 헤헤, 예언가 아저씨는 어제 덕분에 만났어!
		scene_util.play_normal_speech_action(princess_npc, self, 'right',
				{ name = 'nod', count = 2 }, 'smile', 'dv_stage2_princess_n_reaper_11')

		--공주(left, smile, bomb_idle) : $name도 칠득이 덕에 만났구.
		scene_util.play_normal_speech_action(princess_npc, self, 'left',
				'bomb_idle', 'smile', 'dv_stage2_princess_n_reaper_12')

		--1초 대기.
		wait_for_sec(1)

		--공주(left, idle, cast) : $name. 잘은 모르겠지만…
		scene_util.play_normal_speech_action(princess_npc, self, 'left',
				'cast', nil, 'dv_stage2_princess_n_reaper_13')

		--공주(left, idle, bomb_idle) : 도화랑 할 일이 있는 거지?
		scene_util.play_normal_speech_action(princess_npc, self, 'left',
				'bomb_idle', nil, 'dv_stage2_princess_n_reaper_14')

		--기사 고개 끄덕.
		scene_util.set_anim_async(knight, self, { name = 'nod', count = 1 })

		--공주(left, smile, idle) : 내 걱정은 말고 다녀와.
		music_player_util.play_sfx_one_shot('01_bad_fairy_01')
		scene_util.play_normal_speech_action(princess_npc, self, 'left',
				nil, { name = 'smile', keep = true }, 'dv_stage2_princess_n_reaper_15')

		--커스텀 스테이트 저장
		local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
		quest_util.set_custom_state(quest_progress, self.main_quest_custom_key, 1)

		--이후, 공주 칠득이 원라인으로 남는다.
		self:un_subscribe_interact_event()

		--공주(left, smile, idle) : 내 걱정은 말고 다녀와!
		scene_util.set_direction(princess_npc, 'left', false)
		princess_handler:set_emotion(self, 'smile')
		princess_handler:set_anim(self, 'smile')
		princess_handler:set_one_line('dv_stage2_princess_n_reaper_oneline_1')

		--칠득이(left, dumb_idle, idle) : 그래서… 우리 뭐하러 나온 거죠?
		scene_util.set_direction(reaper_npc, 'left', false)
		reaper_handler:set_emotion(self, 'dumb_idle')
		reaper_handler:set_anim(self, 'idle')
		reaper_handler:set_one_line('dv_stage2_princess_n_reaper_oneline_2')

		--컨트롤 복귀에 BGM 볼륨 1로 조절, 믹스 디폴트값	bgm_dreamvillage_day
		music_player_util.change_stage_music_volume('field', 1)
	end
end

do
	local event = npc_event.stage_2_inn_daylight_event

	function event:init(npc_pooling_system, constants)
		self.super:init(npc_pooling_system, constants)
		self.inn_keeper_name = 'inn_keeper'
	end

	function event:enter()
		self.super:enter()

		local npc = self:get_handler(self.inn_keeper_name):get_npc()
		npc.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 2.2))
	end

	function event:exit()
		local npc = self:get_handler(self.inn_keeper_name):get_npc()
		npc.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1))

		self.super:exit()
	end
end

do
	local event = npc_event.stage_3_museum_daylight_event

	function event:init(npc_pooling_system, constants)
		self.super:init(npc_pooling_system, constants)

		self.triggered = false
		self.play_ended = false
		self.zone_name = 'museum_zone'
	end

	function event:enter()
		self.super:enter()

		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
		message_system:Subscribe(self, typeof(CS.Oak.TimeConversionChangingEvent), 'on_time_conversion_changing_event')
	end

	function event:exit()
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.TimeConversionChangingEvent))

		self.super:exit()
	end

	function event:on_zone_enter_event(e)
		if not self.triggered and
				type_util.is_zone_full_enter(e, get_party_leader(), self.zone_name) then
			self.triggered = true
			start_coroutine(self.play_museum_male_talk, self)

			return true
		end

		return false
	end

	function event:on_time_conversion_changing_event(e)
		if self.triggered and not self.play_ended then
			self:end_setting()
			return true
		end

		return false
	end

	function event:end_setting()
		local male_1 = self:get_handler('museum_group_1_male_1'):get_npc()
		local male_2 = self:get_handler('museum_group_1_male_2'):get_npc()

		male_1.Interactable.Talk = 'dv_night_at_the_museum_pre_3'
		male_2.Interactable.Talk = 'dv_night_at_the_museum_pre_4'

		self.play_ended = true
	end

	function event:play_museum_male_talk()
		local male_1 = self:get_handler('museum_group_1_male_1'):get_npc()
		local male_2 = self:get_handler('museum_group_1_male_2'):get_npc()

		male_1.Interactable.Talk = nil
		male_2.Interactable.Talk = nil

		--NPC 1 (left, smile, dance) : 모토리산 역사 박물관이 드디어 개장했습니다!
		scene_util.show_normal_speech_async(male_1, 'dv_night_at_the_museum_pre_1', false)

		if self.play_ended then
			return
		end

		--NPC 2 (right, smile, dance) : 이 안에서 수백년 전 과거 역사들을 체험해볼 수 있어요!
		scene_util.show_normal_speech_async(male_2, 'dv_night_at_the_museum_pre_2', false)

		if self.play_ended then
			return
		end

		--NPC 1 (left, smile, dance) : 연인과의 데이트, 가족들과 친목 도모에도 안성맞춤!
		scene_util.show_normal_speech_async(male_1, 'dv_night_at_the_museum_pre_3', false)

		if self.play_ended then
			return
		end

		--NPC 2 (right, smile, dance) : 모토리산 역사 박물관으로 놀러오세요!
		scene_util.show_normal_speech_async(male_2, 'dv_night_at_the_museum_pre_4', false)

		if self.play_ended then
			return
		end

		self:end_setting()
	end
end

-- 스테이지4 마을 광장 꼬마들 이벤트
do
	local event = npc_event.stage_4_village_center_event

	function event:init(npc_pooling_system, constants)
		self.super:init(npc_pooling_system, constants)
	end

	function event:enter()
		self.super:enter()

		self.triggered = false

		self.play_loop = true

		-- npc들 현재 플레이하고 있는 액션 인덱스 저장
		self.action_step = 1

		self.zone_name = 'two_kids_circling_around'

		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

		local kid_1_handler = self:get_handler('center_kid_1')
		local kid_1 = kid_1_handler:get_npc()
		local kid_2_handler = self:get_handler('center_kid_2')
		local kid_2 = kid_2_handler:get_npc()

		kid_1.OverrideCrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
		kid_2.OverrideCrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance

		self.kids_event_info = {
			{
				handler = kid_1_handler,
				fo = kid_1,

				move_list = {
					field_util.get_marker_pos('oneline_day_5_1_2'),
					field_util.get_marker_pos('oneline_day_5_1_1')
				},

				cur_action_index = 1,

				actions = {
					[1] = function(this)
						local handler = this.handler
						local fo = this.fo

						-- 1-1번 위치에서 (right, smile, idle) 상태 적용.
						handler:set_emotion(self, 'smile')
						scene_util.set_direction(fo, 'right', false)

						-- 1번 (right, attack, idle, jump 1회) : 뭐야! 어디야!
						music_player_util.play_sfx({
							sfx_name = '01_small_jump_01', parent = fo,
							loop = false, player_priority = 'npc',
						})
						handler:set_emotion(self, 'attack')
						character_util.normal_jump(fo, false)
						self:show_stoppable_speech_async(handler, 'dv_stage_4_oneline_day_5_1_1', { skip = false })

						this.cur_action_index = 2
					end,

					[2] = function(this)
						local handler = this.handler
						local fo = this.fo

						wp_util.move_async(fo, this.move_list[1],
								nil, 2, { run = true })

						this.cur_action_index = 3
					end,

					[3] = function(this)
						local handler = this.handler
						local fo = this.fo

						-- 1번 (right, attack, idle, jump 1회) : 이잇! 얼른 나와! 진짜 혼난다!
						music_player_util.play_sfx({
							sfx_name = '01_small_jump_01', parent = fo,
							loop = false, player_priority = 'npc',
						})
						scene_util.set_direction(fo, 'right', false)
						handler:set_emotion(self, 'attack')
						character_util.normal_jump(fo, false)
						self:show_stoppable_speech_async(handler, 'dv_stage_4_oneline_day_5_1_2', { skip = false })

						this.cur_action_index = 4
					end,

					[4] = function(this)
						local handler = this.handler
						local fo = this.fo

						wp_util.move_async(fo, this.move_list[2],
								nil, 2, { run = true })

						this.cur_action_index = 1
					end,
				}
			},

			{
				handler = kid_2_handler,
				fo = kid_2,

				move_list = {
					field_util.get_marker_pos('oneline_day_5_2_2'),
					field_util.get_marker_pos('oneline_day_5_2_1')
				},

				cur_action_index = 1,

				actions = {
					[1] = function(this)
						local handler = this.handler
						local fo = this.fo

						-- 2-1번 위치에서 (left, smile, idle) 상태 적용.
						handler:set_emotion(self, 'smile')
						scene_util.set_direction(fo, 'left', false)

						-- 2번 (left, smile, sing) happy 이모티콘 출력 후 완료까지 대기.
						music_player_util.play_sfx({
							sfx_name = '01_bad_fairy_01', parent = fo,
							loop = false, player_priority = 'npc',
						})
						handler:set_emotion(self, 'smile')
						handler:set_anim(self, { name = 'sing', one_shot_sfx = false })
						character_util.show_emoticon_async(fo, nil, 'happy')

						this.cur_action_index = 2
					end,

					[2] = function(this)
						local handler = this.handler
						local fo = this.fo

						-- 2번 캐릭터 2-2번 위치까지 (up, idle, run)을 2초 안에 이동.
						wp_util.move_async(fo, this.move_list[1],
								nil, 2, { run = true })

						this.cur_action_index = 3
					end,

					[3] = function(this)
						local handler = this.handler
						local fo = this.fo

						-- 2번 (left, doyagao, cast) tease 이모티콘 출력 후 완료까지 대기.
						music_player_util.play_sfx({
							sfx_name = '01_bad_fairy_01', parent = fo,
							loop = false, player_priority = 'npc',
						})
						scene_util.set_direction(fo, 'left', false)
						handler:set_emotion(self, 'doyagao')
						handler:set_anim(self, 'cast')
						character_util.show_emoticon_async(fo, nil, 'tease')

						this.cur_action_index = 4
					end,

					[4] = function(this)
						local handler = this.handler
						local fo = this.fo

						-- 2번 캐릭터 2-1번 위치까지 (down, smile, run)을 2초 안에 이동.
						handler:set_emotion(self, 'smile')
						wp_util.move_async(fo, this.move_list[2],
								nil, 2, { run = true })

						this.cur_action_index = 1
					end,
				}
			},
		}

		if not self.triggered and not self.is_show_end and
				zone_util.contains_fo(self.zone_name, get_party_leader(), false) then

			self.triggered = true
			for i = 1, #self.kids_event_info do
				start_coroutine(self.play_two_kids_event, self, i)
			end
		end
	end

	function event:exit()
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

		self.super:exit()

		self.play_loop = false
	end

	function event:on_zone_enter_event(e)
		if not self.triggered and
				type_util.is_zone_full_enter(e, get_party_leader(), self.zone_name) then

			self.triggered = true
			self.play_loop = true

			for i = 1, #self.kids_event_info do
				start_coroutine(self.play_two_kids_event, self, i)
			end

			return true
		end

		return false
	end

	function event:play_two_kids_event(event_info_index)
		local event_info = self.kids_event_info[event_info_index]
		local first = true

		local function checkStepsEqual(info, value)
			local check_value = (#event_info.actions > value) and value + 1 or 1
			for i = 1, #info do
				if info[i].cur_action_index ~= check_value then
					return false
				end
			end

			return true
		end

		while self.play_loop do
			if not self:is_enabled() or not self.play_loop then
				return
			end

			for i = 1, #event_info.actions do
				if first then
					i = self.action_step

					first = false
				end

				event_info.actions[i](event_info)

				-- 각 캐릭터 현재 단계의 액션이 모두 끝나는 것을 기다림
				while true do
					if checkStepsEqual(self.kids_event_info, i) then
						break
					end

					if not self:is_enabled() or not self.play_loop then
						return
					end

					coroutine.yield(nil)
				end

				if not self:is_enabled() or not self.play_loop then
					self.action_step = i

					return
				end
			end

			coroutine.yield(nil)
		end

		if not self:is_enabled() or not self.play_loop then
			return
		end
	end
end

return {
	create = function()
		return local_class()
	end
}
