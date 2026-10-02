-- 선택 버프 주기
local local_class = newclass("TowerSelectDeBuffController")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self.debuff_data = require('stageeventcontrollers/TowerSelectDebuffData.lua')
	self.current_stage = self.debuff_data[stage.Name]
	self.current_zone = nil
	self.debuff_sender = nil
	self.time_remain_limit = 10
	--버튼 종류 저장하는 리스트
	self.branches = nil
	--버튼 선택 대기중
	self.wait_for_branch = true
	--답변 UI 가 열려있는가? 열려있는 상태에서의 시간초과로 인한 종료의 경우에 해당 UI 를 닫아주기 위한 값.
	self.is_answer_ui_open = false

	--한번 들어간 존인지 판별 하기 위해서 가지는 값
	self.zone_dataset = {}
	for i = 1, #self.current_stage do
		self.zone_dataset[self.current_stage[i].zone_name] = true
	end

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
end

--인터렉트 이벤트 들어온 경우에
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.zone_dataset[e.Zone.Name] ~= nil and self.zone_dataset[e.Zone.Name] == true then
				for i = 1, #self.current_stage do
					--현재 들어온 존 정보에따라
					if self.current_stage[i].zone_name == e.Zone.Name then
						-- 존 정보 세팅
						self.current_zone = self.current_stage[i]
						-- 디버프 주는 안드로이드 설정
						self.debuff_sender = stage:GetCharacter(self.current_zone.sender)
						-- 만약 없으면 유저로 세팅.
						if self.debuff_sender == nil then
							self.debuff_sender = user_party_leader
						end
					end
				end
				self.zone_dataset[e.Zone.Name] = false
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.popup_answer_choice, self, e))
			end
		end
	end
	return false
end

--스테이시 시작시
function local_class:on_stage_start_event(e)
	--타이머 시작되어야 함.
	self:start_timer()
end

function local_class:start_timer()
	self.game_timer = CS.Oak.GlobalTimerServiceExtenstion.GetInGameTimer(CS.Oak.GlobalTimerId.SingleGameTimer)
end

--시간제한으로 게임오버 되었을대 선택지 UI 가 열려있다면 끄도록 한다.
function local_class:on_game_over_event(e)
	if self.is_answer_ui_open then
		self.is_answer_ui_open = false
		ui_scene_manager:PopOverlay()
	end
end

function local_class:set_btn_branches(time_btn_open)
	if self.branches == nil then
		self.branches = create_generic_list(CS.Oak.TalkBranch)
	else
		self.branches:Clear()
	end

	self.choice_index = 0
	self.wait_for_branch = true
	self.branches:Add(
			{
				--내용
				Text = game_string:GetString(self.current_zone.selections[1].btn_string),
				--선택지 성향(아이콘 종류)
				Tendency = CS.Oak.TalkTendency.Forced,
				--클릭되었을때 실행될 함수
				Callback = function()
					self.wait_for_branch = false
					self.choice_index = 1
				end
			})

	self.branches:Add(
			{
				Text = game_string:GetString(self.current_zone.selections[2].btn_string),
				Tendency = CS.Oak.TalkTendency.Intellect,
				Callback = function()
					self.wait_for_branch = false
					self.choice_index = 2
				end
			})


	if time_btn_open then
		self.branches:Add(
				{
					Text = game_string:GetString(self.current_zone.selections[3].btn_string),
					Tendency = CS.Oak.TalkTendency.Mercy,
					--클릭되었을때 실행될 함수
					Callback = function()
						self.wait_for_branch = false
						self.choice_index = 3
					end
				})
	end
end

-- 특정 UI (TowerTimer) 를 제외하고 껏다 켜주기 위해서
-- field_ui_manager:Hide() 를 사용하지 않고 필요한 내용들만 껏다 켜줄수 있도록 함.
function local_class:hide_uis()
	if stage.FieldUIMiniMap ~= nil and stage.FieldUIMiniMap.gameObject ~= nil then
		stage.FieldUIMiniMap.gameObject:SetActive(false)
	end
	if CS.Oak.UI.NavigationBar.Instance ~= nil then
		CS.Oak.UI.NavigationBar.Instance:Hide()
	end
	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.PartyState, nil)
end

function local_class:show_uis()
	if stage.FieldUIMiniMap ~= nil and stage.FieldUIMiniMap.gameObject ~= nil then
		stage.FieldUIMiniMap.gameObject:SetActive(true)
	end
	if CS.Oak.UI.NavigationBar.Instance ~= nil then
		CS.Oak.UI.NavigationBar.Instance:Show()
	end
	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.PartyState, nil)
end

function local_class:popup_answer_choice(e)
	self:hide_uis()
	user_party:StopAndDisableControl()

	if self.debuff_sender ~= nil then
		-- 캐릭터와 안드로이드 간에 방향 계산하여 방향전환 (4-way)
		local dirVec = user_party_leader.Position -  self.debuff_sender.Position
		local dir = vector_util.to_direction(dirVec)
		local dir_str = direction_util.to_str(dir)
		character_util.set_direction(self.debuff_sender, dir_str)
		--시작 메세지
		speech_bubble_util.show_speech_bubble_async(self.debuff_sender, {key =self.current_zone.talk_start , skip = true } )
	end

	--세번째 메뉴 : 시간감소 를 특정 시간 이하가 되면 보여주지 않을 것이기 때문에 해당 시간 + time_remain_limit(10) 을 기준으로 하여
	-- 해당 시간 이하일때 시간 버튼을 보여주지 않도록 한다.
	local time_limit = self.current_zone.selections[3].time_sec + self.time_remain_limit
	local is_time_btn_open = self.game_timer.RemainTime > time_limit
	local answer_choice_state = CS.Oak.UI.AnswerChoiceState()

	--버튼 설정
	self:set_btn_branches(is_time_btn_open)
	answer_choice_state.Branchs = self.branches
	self.is_answer_ui_open = true
	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, answer_choice_state)
	--세번째 버튼 없이 진행하는 경우 차후 추가 이벤트 없이 진행하고 종료
	if not is_time_btn_open then
		while self.wait_for_branch do
			coroutine.yield(nil)
		end
	else
		-- 세번째 버튼 포함하여 진행 되는 경우 버튼선택 이벤트 중 시간 이하가 된다면 시간 감소에 대한 클릭이 없어야 하므로
		-- 대기중 시간체크를 계속 하여 time_limit 이하가 되면 세번째 버튼을 없애는 이벤트를 발생시킨다.
		while self.wait_for_branch do
			coroutine.yield(nil)
			is_time_btn_open = self.game_timer.RemainTime > time_limit
			if  is_time_btn_open == false then
				if self.is_answer_ui_open then
					self.is_answer_ui_open = false
					--현재 떠있는 버튼 UI 를 없앰..
					ui_scene_manager:PopOverlay()
				end
				break
			end
		end

		if is_time_btn_open == false then -- 타임 오버 공지
			if self.debuff_sender ~= nil then
				speech_bubble_util.show_speech_bubble_async(self.debuff_sender, {key =self.current_zone.talk_time_over, skip = true } )
			end
			--현재 버튼에서 타임버튼을 제거하여 다시 로드함.
			self:set_btn_branches(false)
			answer_choice_state.Branchs = self.branches
			self.is_answer_ui_open = true
			ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, answer_choice_state)

			--최후의 버튼 선택 대기
			while self.wait_for_branch do
				coroutine.yield(nil)
			end
		end
	end

	-- 종료 메세지 띄움/ 선택에 따른 다른 메세지 출력
	if self.debuff_sender ~= nil then
		speech_bubble_util.show_speech_bubble_async(self.debuff_sender, {key =self.current_zone.talk_end[self.choice_index], skip = true } )
	end

	--그 후 버프 실행
	if self.choice_index == 1 then
		self:choice_attack_down()
	elseif self.choice_index == 2 then
		self:choice_defence_down()
	elseif self.choice_index == 3 then
		self:choice_decrease_time()
	end

	--다시 캐릭터 움직이도록
	self:show_uis()
	user_party:ResetControllers()
end

function local_class:choice_attack_down()
	music_player:PlaySfxOneShot('01_enhance_light_01')
	for i = 0 , user_party.Characters.Count - 1 do
		buff_manager:AddBuff(self.debuff_sender, CS.Oak.EquipmentSlot.None, user_party.Characters[i],
				self.current_zone.selections[1].debuff_id, self.current_zone.selections[1].debuff_level, true, false )
	end
end

function local_class:choice_defence_down()
	music_player:PlaySfxOneShot('01_enhance_light_01')
	for i = 0 , user_party.Characters.Count - 1 do
		buff_manager:AddBuff(self.debuff_sender, CS.Oak.EquipmentSlot.None, user_party.Characters[i],
				self.current_zone.selections[2].debuff_id, self.current_zone.selections[2].debuff_level, true, false )
	end
end

function local_class:choice_decrease_time()
	music_player:PlaySfxOneShot('02_magic_heal_02')
	local additional_time = -self.current_zone.selections[3].time_sec
	message_system:Publish(CS.Oak.GlobalTimerModifiedEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer,
			additional_time))
end

function local_class:dispose()

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	self.cs_controller = nil
	self.scene = nil
	self.debuff_data = nil
	self.debuff_sender = nil
	self.current_stage = nil
	self.current_zone = nil
	self.branches = nil
	self.zone_dataset = nil
	self.choice_index = nil
	self.is_answer_ui_open = nil
	self.game_timer = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
