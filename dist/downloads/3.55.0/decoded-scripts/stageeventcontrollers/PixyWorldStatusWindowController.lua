local local_class = newclass('StatusWindowController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	if scene ~= nil then
		self.scene = scene()
	end

	self.status_window_system = CS.Oak.PixyWorldStatusWindowsSystem()
	self.constants = get_or_create_global_variable('Quest/Main/PixyWorld/Common/PixyWorldStatusWindowConstants.lua')
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	yield_return_func(self.status_window_system.PreLoad, self.status_window_system)
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
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
	self.status_window_system:Dispose()
	
	self.cs_controller = nil
	self.scene = nil
end

function local_class:on_stage_loaded_event(e)
	-- 맵에서 그룹핑이 필요한 캐릭터 정보들 미리 저장 처리
	self:register_searchble_info()

	local main_quest_id = 412
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local main_quest_inner_progress = quest_progress.InnerProgress
	
	if main_quest_inner_progress < 6 then
		return
	end
	
	-- 시스템 활성화
	self:initialize_system()
	
	return true
end

function local_class:register_searchble_info()
	local current_stage_zone_data = self.constants[stage.Name]
	
	if current_stage_zone_data == nil then
		logger_util.error(("You much add constant data of stage: %s before using Pixy World Status Window System"):format(stage.Name))
		return
	end

	for zone_name, zone_data in pairs(current_stage_zone_data) do
		self.status_window_system:GroupCharactersByZone(zone_name)
		
		if zone_data.active_condition ~= nil then
			local quest_id = zone_data.active_condition.quest_id
			local checking_progress = create_generic_list(CS.System.Int32)

			for i = 1, #zone_data.active_condition.progress do
				checking_progress:Add(zone_data.active_condition.progress[i])
			end

			self.status_window_system:AddSystemActiveCondition(zone_name, quest_id, checking_progress)
		end

		local specs = zone_data.specs

		for character_name, stat_data in pairs(specs) do
			local character = get_character(character_name)
			local status_info = CS.Oak.PixyStatusInfo()
			status_info.Health = stat_data.health
			status_info.Mana = stat_data.mana
			status_info.Sanity = stat_data.sanity
			status_info.SkillRank = stat_data.skill_rank
			status_info.UniqueSkill = stat_data.unique_skill

			self.status_window_system:AddCharacterStatInfo(character, status_info)
		end
	end
end

-- 시스템 활성화
function local_class:initialize_system()
	local window_life_time = CS.Oak.PixyStatusWindowLifeTime()
	window_life_time.AppearTime = self.constants.system_setting.appear_time
	window_life_time.LifeTime = self.constants.system_setting.life_time
	window_life_time.DisappearTime = self.constants.system_setting.disappear_time

	local system_setting = CS.Oak.PixyStatusWindowSetting()
	system_setting.Distance = self.constants.system_setting.distance
	system_setting.WindowLifeTime = window_life_time

	self.status_window_system:Initialize(system_setting)
end

-- 버튼 UI 활성화
function local_class:active_button()
	self.status_window_system:ChangeCustomButtonIcon()
	self.status_window_system.IsButtonActive = true
end

-- 버튼 UI 비활성화
function local_class:deactive_button()
	self.status_window_system.IsButtonActive = false
end

--- 내부 데이터 셋
--- {
	-- target                    ICharacter                                    상태창을 띄워줄 대상
	-- health                    number                                        체력
	-- mana                      number                                        마나
	-- sanity                    number                                        정신력
	-- skill_rank                CS.Oak.PixyStatRank                           캐릭터가 가지고 있는 유니크 스킬 랭크
	-- unique_skill              string                                        캐릭터가 가지고 있는 유니크 스킬 이름 
	-- is_right                  boolean                                       UI가 캐릭터 기준 우측에 생성되는지?
	-- overriden_life_time       CS.Oak.PixyStatusWindowLifeTime               오버라이드 하려는 UI 관련 생명 시간들
	-- color_state               string                                        UI 색상
-- }
function local_class:show_status_window(data)
	local status_info = CS.Oak.PixyStatusInfo()
	status_info.Health = data.health
	status_info.Mana = data.mana
	status_info.Sanity = data.sanity
	status_info.SkillRank = data.skill_rank
	status_info.UniqueSkill = data.unique_skill

	local set_focus_target = lua_helper.get_or_default(data.set_focus_target, false)

	-- 이 함수를 통해 스테이터스 창을 활성화하는 것은, 임의의 데이터로 강제로 넣어주었다는 것을 의미
	-- 포커스 이펙트는 업데이트 로직 활성화 후, 거리 기반 탐색이 동작할 시에 사용되는 이펙트.
	-- 따라서 이 함수처럼 임의의 타겟을 직접 지정하는 경우는 해당 이펙트를 틀어주지 않도록 함.
	self.status_window_system:ShowStatusWindow(
		data.target,
		status_info,
		data.overriden_life_time,
		data.color_state,
		set_focus_target,
		data.is_right
	)
end

function local_class:close_status_window(target)
	self.status_window_system:CloseStatusWindow(target)
end

function local_class:create_break_effect_on(target)
	self.status_window_system:CreateBreakEffectOn(target)
end

function local_class:dispose_break_effect()
	self.status_window_system:DisposeBreakEffect()
end

function local_class:creat_bomb_effect_on(target)
	self.status_window_system:CreatBombEffectOn(target)
end

function local_class:find_focus_target()
	self.status_window_system:FindFocusTarget()
end

function local_class:stop_showing_focus_effect()
	self.status_window_system.ShouldShowFocusEffect = false
	self.status_window_system.IsButtonActive = false
end

function local_class:start_showing_focus_effect()
	self.status_window_system.ShouldShowFocusEffect = true
	self.status_window_system.IsButtonActive = true
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
