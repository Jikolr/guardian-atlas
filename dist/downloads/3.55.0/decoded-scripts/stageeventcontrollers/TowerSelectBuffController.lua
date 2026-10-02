-- 선택 버프 주기
local local_class = newclass("TowerSelectBuffController")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	self.buff_data = require('stageeventcontrollers/TowerSelectBuffData.lua')
	self.current_stage = self.buff_data[stage.Name]
	self.current_zone = nil
	self.buff_sender = nil
	self.zone_dataset = {}
	for i = 1, #self.current_stage do
		self.zone_dataset[self.current_stage[i].zone_name] = true
	end
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

--인터렉트 이벤트 들어온 경우에
function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.zone_dataset[e.Zone.Name] ~= nil and self.zone_dataset[e.Zone.Name] == true then
				for i = 1, #self.current_stage do
					if self.current_stage[i].zone_name == e.Zone.Name then
						self.current_zone = self.current_stage[i]
						self.buff_sender = stage:GetCharacter(self.current_zone.sender)
						if self.buff_sender == nil then
							self.buff_sender = user_party_leader
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

function local_class:popup_answer_choice(e)

	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	if self.buff_sender ~= nil then
		-- 캐릭터와 안드로이드 간에 방향 계산하여 방향전환 (4-way)
		local dirVec = user_party_leader.Position -  self.buff_sender.Position
		local dir = vector_util.to_direction(dirVec)
		local dir_str = direction_util.to_str(dir)
		character_util.set_direction(self.buff_sender, dir_str)
		--시작 메세지
		speech_bubble_util.show_speech_bubble_async(self.buff_sender, {key =self.current_zone.talk_start , skip = true } )
	end

	local choice_index = 0
	local branches = create_generic_list(CS.Oak.TalkBranch)
	local wait_for_branch = true
	branches:Add(
		{
			--내용
			Text = game_string:GetString(self.current_zone.selections[1].btn_string),
			--선택지 성향(아이콘 종류)
			Tendency = CS.Oak.TalkTendency.Forced,
			--클릭되었을때 실행될 함수
			Callback = function()
				wait_for_branch = false
				choice_index = 1
			end
		})

	branches:Add(
		{
			Text = game_string:GetString(self.current_zone.selections[2].btn_string),
			Tendency = CS.Oak.TalkTendency.Intellect,
			Callback = function()
				wait_for_branch = false
				choice_index = 2
			end
		})

	branches:Add(
		{
			Text = game_string:GetString(self.current_zone.selections[3].btn_string),
			Tendency = CS.Oak.TalkTendency.Mercy,
			--클릭되었을때 실행될 함수
			Callback = function()
				wait_for_branch = false
				choice_index = 3
			end
		})

	--질문창 띄워 선택 이후 다음단계로
	local answer_choice_state = CS.Oak.UI.AnswerChoiceState()
	answer_choice_state.Branchs = branches
	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, answer_choice_state)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	-- 종료 메세지 띄움/ 선택에 따른 다른 메세지 출력
	if self.buff_sender ~= nil then
		speech_bubble_util.show_speech_bubble_async(self.buff_sender, {key =self.current_zone.talk_end[choice_index], skip = true } )
	end

	--그 후 버프 실행
	if choice_index == 1 then
		self:choice_attack_up()
	elseif choice_index == 2 then
		self:choice_defence_up()
	elseif choice_index == 3 then
		self:choice_instant_heal()
	end

	--다시 캐릭터 움직이도록
	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:choice_attack_up()
	music_player:PlaySfxOneShot('01_enhance_light_01')
	for i = 0 , user_party.Characters.Count - 1 do
		buff_manager:AddBuff(self.buff_sender, CS.Oak.EquipmentSlot.None, user_party.Characters[i], self.current_zone.selections[1].buff_id, self.current_zone.selections[1].buff_level, true, false )
	end
end

function local_class:choice_defence_up()
	music_player:PlaySfxOneShot('01_enhance_light_01')
	for i = 0 , user_party.Characters.Count - 1 do
		buff_manager:AddBuff(self.buff_sender, CS.Oak.EquipmentSlot.None, user_party.Characters[i], self.current_zone.selections[2].buff_id, self.current_zone.selections[2].buff_level, true, false )
	end
end

function local_class:choice_instant_heal()
	music_player:PlaySfxOneShot('02_magic_heal_02')
	for i = 0 , user_party.Characters.Count - 1 do
		local heal_info = CS.Oak.HealInfo()
		heal_info.heal = math.floor(user_party.Characters[i].FieldObjectStatsBehaviour.MaxHP * self.current_zone.selections[3].heal_ratio)
		heal_info.isRevive = self.current_zone.selections[3].is_revive
		heal_info.sender = self.buff_sender
		heal_info.target = user_party.Characters[i]
		command_util.execute_heal(heal_info)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	self.cs_controller = nil
	self.scene = nil
	self.buff_data = nil
	self.buff_sender = nil
	self.current_stage = nil
	self.current_zone = nil
	self.zone_dataset = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
