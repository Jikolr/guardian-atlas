local local_class = newclass('TowerPlagueCountController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.stage_battle_info = require('stageeventcontrollers/TowerPlagueCountData.lua')

	self.current_stage_info = nil
	self.battle_groups = {}
	self.monster_list = {}
	self.cleared_groups = {}

	self.progress = {
		none = 1,
		playing = 2,
		stop = 3,
		cleared = 4,
	}

	-- 현재 컨트롤러 진행 상태
	self.current_progress = self.progress.none
	-- 틴트 타임 초기화
	self.tint_time = 0
	self.time_passed = 0
	self.plague_time = 0
	self.narration_key = 'tower_light_elite_10_narration'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	-- 연출중엔 카운트 멈추기용, 연출용 이벤트를 따로 분리해야 할지 판단이 가질 않아 가장 적합한 이벤트 선정
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerRequestPauseEvent), 'on_timer_pause_event')
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerRequestResumeEvent), 'on_timer_resume_event')

	unity_object_pool.GetOrCreate('FX_levelup_new')
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end
--- late update frame 사용
function local_class:use_late_update_frame(_)
	return true
end
--- late update frame 우선순위
function local_class:late_update_frame_priority(_)
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:on_event(_)
	return false
end

-- 나레이션 출력
function local_class:on_stage_start_event(_)
	-- 나레이션 출력
	sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.narration_key })
	self.pause_count = false
end

function local_class:on_game_over_event(_)
	-- 게임 오버 된 경우에 중지 처리
	if self.current_progress == self.progress.playing then
		self.current_progress = self.progress.stop
		self:stop_counting_ui()
	end
end

function local_class:on_timer_pause_event(_)
	self.pause_count = true
end

function local_class:on_timer_resume_event(_)
	self.pause_count = false
end

function local_class:late_update_frame(dt)
	if self.pause_count then
		return
	end

	--- 싫제로 플레이 시에만 타임 체크
	if self.current_progress == self.progress.playing then
		self.time_passed = self.time_passed + dt
		--- 카운트 ui 갱신
		self:update_count_ui(math.ceil(self.plague_time - self.time_passed))
		if self.time_passed > self.plague_time then
			self:plague_options()
		end
	end

	-- 틴트 종료
	if self.current_progress == self.progress.stop then
		if self.tint_time > 0 then
			self.tint_time = self.tint_time - dt
			if self.tint_time <= 0 then
				field:RemoveTint('plague_tint', self.tint_duration)
			end
		end
	end

end

function local_class:on_stage_loaded_event(_)
	self.battle_groups = {}
	local battle_manager = stage.BattleManager
	local num_battle_groups = #self.current_stage_info.battle_group_names
	for i = 1, num_battle_groups do
		local battle_group_name = self.current_stage_info.battle_group_names[i]
		--- 배틀 그룹 찾아두기
		self.battle_groups[i] = battle_manager:GetBattleGroup(battle_group_name)
		--- 해당 배틀 그룹내 몬스터 리스트 찾아두기
		self.monster_list[battle_group_name] = self.battle_groups[i]:GetMonsters()
	end
end

function local_class:on_zone_enter_event(e)
	-- 존 안에 들어왔을때 존 이름으로 현재 배틀 존에 할당된 그룹 찾기
	if e.FullEnter and lua_helper.reference_equals(user_party_leader, e.FieldObject) then
		-- 현재 진행상태 none 일 경우에
		if self.current_progress ~= self.progress.playing then
			-- 이미 들어가서 기믹 종료된 존이라면 재입장 처리되지 않음.
			if table_util.contain_value(self.cleared_groups, e.Zone.Name) then
				return
			end

			local num_battle_groups = #self.current_stage_info.battle_group_names
			for i = 1, num_battle_groups do
				--- 지금 들어온 존이 정의된 배틀 존 이름과 같다면
				if e.Zone.Name == self.current_stage_info.battle_group_names[i] then
					-- 현재 액션 진행되는 존이 어떤 존인지 캐싱
					self.current_battle_zone_name = e.Zone.Name
					-- 해당 배틀에 관한 정보를 가져옴
					self.current_battle_info = self.current_stage_info[self.current_battle_zone_name]
					-- 플레이 상태 변경
					self.current_progress = self.progress.playing
					-- 숫자 카운팅 시작
					self:start_counting_ui()
				end
			end
		end
	end
end

function local_class:plague_options()

	self.tint_time = self.current_stage_info.tint_time
	self.tint_duration = self.current_stage_info.tint_time
	
	field:Tint('plague_tint',  unity_color(self.current_stage_info.tint_color), self.tint_duration)

	-- 옵션 전파 되는 타이밍에 카메라 셰이킹
	camera_util.shake(self.current_battle_info.cam_magnitude, self.current_battle_info.cam_duration)
	--- 타겟 몬스터를 찾음
	local target = get_character(self.current_stage_info[self.current_battle_zone_name].target_name)
	--- 타겟 몬스터가 가지는 옵션들 파악
	local stage_options = target.FieldObjectBehaviour.StageOptions
	-- 파괴된 몬스터가 가지고 있는 스테이지 옵션을 검사
	local get_options = {}
	for i = 0, stage_options.Count - 1 do
		local option = stage_options[i]
		table.insert(get_options, option)
	end

	for _,v in pairs(get_options) do
		local option_id = v.Option.Id
		local option_level = v.Option.Level
		local option = CS.Oak.OptionManager.CreateOption(option_id, option_level)
		for _, monster in pairs(self.monster_list[self.current_battle_zone_name]) do
			--엘리트옵션 추가할때 중복체크, 죽지 않은 몬스터에게 부여한다.
			if not self:check_contain_options(monster, option_id) and
					not monster.FieldObjectStatsBehaviour.IsDead and
					monster.ActiveState ~= CS.Oak.ActiveState.Disabled then
				monster.EliteOptions:Add(option)
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
						self.elite_option_refresh, self, monster))
				unity_object_pool.GetOrCreate('FX_levelup_new'):Instantiate(monster.Position,
						unity_class.quaternion.identity, monster.Transform)
			end
		end
	end
	-- 전파 되었으므로 정지
	self.current_progress = self.progress.stop
	-- ui 도 정지
	self:stop_counting_ui()
end

--- 타겟 몬스터가 파괴되었을때 카운팅 중지한다.
function local_class:on_field_object_destroyed_event(e)
	if table_util.contain_value(self.monster_list[self.current_battle_zone_name], e.FieldObject)
			and e.FieldObject.Name == self.current_stage_info[self.current_battle_zone_name].target_name then
		self.current_progress = self.progress.stop
		self:stop_counting_ui()
	end
end

function local_class:start_counting_ui()
	-- 카운팅 ui 타겟 몬스터 대상으로 하도록 수정
	local target = get_character(self.current_stage_info[self.current_battle_zone_name].target_name)
	self.time_passed = 0
	self.plague_time = self.current_battle_info.plague_count
	self:attach_count_ui(target, self.plague_time)
end

function local_class:stop_counting_ui()
	table.insert(self.cleared_groups, self.current_battle_zone_name)
	self:detach_count_ui()
end

function local_class:check_contain_options(monster, option_id)
	for _,v in pairs(monster.FieldObjectBehaviour.StageOptions) do
		if v.Option.Id == option_id then
			return true
		end
	end
	return false
end

function local_class:elite_option_refresh(monster)
	yield_return_func(monster.CharacterBehaviour.RefreshStageOptions,
			monster.CharacterBehaviour)
end

-- 카운트 UI 시작하기 위해 붙임
function local_class:attach_count_ui(target, count)
	-- FIXME: 2.10에 X축 0 -> 0.25로 변경
	local offset = vector(0, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = count
end

-- 카운트 UI 갱신
function local_class:update_count_ui(value)
	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = value
end

-- 카운트 UI 해제
function local_class:detach_count_ui()
	if self.count_ui ~= nil then
		self.count_ui.transform:Find('Offset').gameObject:SetActive(true)
		self.count_ui:Dispose()
		self.count_ui = nil
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerRequestPauseEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerRequestResumeEvent))

	-- pooled list 라 직접 Dispose 하도록 한다.
	for i = 1, #self.current_stage_info.battle_group_names do
		self.monster_list[self.current_stage_info.battle_group_names[i]]:Dispose()
	end
	self.monster_list = nil

	self.cs_controller = nil
	self.stage_battle_info = nil
	self.current_stage_info = nil
	self.battle_groups = nil

	self:detach_count_ui()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
