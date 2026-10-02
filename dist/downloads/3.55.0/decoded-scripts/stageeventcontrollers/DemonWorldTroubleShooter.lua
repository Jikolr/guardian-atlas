local local_class = newclass("DemonWorldTroubleShooterController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.stage_name = 'demonworld_part1_1_3'

	self.get_trouble_shooter = function() return get_character('trouble_shooter') end
	self.get_desk = function() return get_field_object('ordeal_desk') end

--region Main Quest
	-- 메인 퀘스트 ID
	self.main_quest_id = 216

	-- 메인 퀘스트 처리 완료 플래그
	self.main_quest_progress_end = false

	-- 메인 퀘스트 처리 시작 알리는 커스텀 이벤트
	self.start_main_quest_custom_event = 'start_main_quest_progress'

	-- 메인 퀘스트 처리 종료 알리는 커스텀 이벤트
	self.end_main_quest_custom_event = 'end_main_quest_progress'
--endregion

--region Adultery Quest
	-- 불륜 조사 퀘스트 ID
	self.adultery_quest_id = 233

	-- 불륜 조사 퀘스트 처리 완료 플래그
	self.adultery_quest_progress_end = false

	-- 불륜 조사 퀘스트 처리 시작 알리는 커스텀 이벤트
	self.start_adultery_quest_custom_event = 'start_adultery_quest_progress'

	-- 불륜 조사 퀘스트 처리 종료 알리는 커스텀 이벤트
	self.end_adultery_quest_custom_event = 'end_adultery_quest_progress'

	self.adultery_quest_marker_key = 'adultery'
--endregion

	self.dollar_data_key = 'dollar'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')

	local main_quest = user_progress:GetStartedQuest(self.main_quest_id)
	if (main_quest.InnerProgress >= 7 and main_quest.InnerProgress ~= 9) or main_quest.IsComplete then
		local odile = self.get_trouble_shooter()

		character_util.add_listener(odile, self.cs_controller)
		odile.Direction = CS.Oak.Direction.Down

		self.get_desk().Interactable = CS.Oak.PublishInteractable.Create()
	end

	quest_icon_util.pre_load()

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == self.stage_name then
		quest_util.load_pool_resource(
		-- 'stage_item'
		)
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_loaded(_)
	self:set_odile_quest_icon()
end

function local_class:on_interact_event(e)
	-- 오딜과 상호작용
	if type_util.is_interacted_target(e, self.get_trouble_shooter()) or
			type_util.is_interacted_target(e, self.get_desk()) then

		-- 메인 퀘스트 progress 확인
		local main_quest_inner_progress = user_progress:GetStartedQuest(self.main_quest_id).InnerProgress

		-- 메인 퀘스트 섹션이 7 이하거나 10, 18이면 아무 이벤트도 발생하지 않음
		if main_quest_inner_progress > 7 and main_quest_inner_progress ~= 9 and main_quest_inner_progress ~= 18 then
			sp_util.play_normal_screenplay(self.interact_with_trouble_shooter, self)
		end

		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == self.end_main_quest_custom_event then
		self.main_quest_progress_end = true
	elseif e:GetParamAt(0) == self.end_adultery_quest_custom_event then
		self.adultery_quest_progress_end = true
	end
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id and e.CurrentProgress == 8 then	-- 섹션 9로 넘어왔을 때
		self:set_odile_quest_icon()
		return true
	elseif e.QuestId == self.main_quest_id and e.CurrentProgress == 9 then	-- 섹션 10으로 넘어왔을 때
		quest_icon_util.remove(self.get_trouble_shooter())
		character_util.remove_relate_event(self.get_trouble_shooter(), self.cs_controller)

		self.get_desk().Interactable = CS.Oak.NonInteractable.Instance

		return true
	elseif e.QuestId == self.main_quest_id and e.CurrentProgress == 10 then	-- 섹션 11로 넘어왔을 때
		self:set_odile_quest_icon()
		character_util.add_listener(self.get_trouble_shooter(), self.cs_controller)

		self.get_desk().Interactable = CS.Oak.PublishInteractable.Create()

		return true
	elseif e.QuestId == self.main_quest_id and e.CurrentProgress == 19 then	-- 섹션 19로 넘어왔을 때
		self:set_odile_quest_icon()
		character_util.add_listener(self.get_trouble_shooter(), self.cs_controller)

		self.get_desk().Interactable = CS.Oak.PublishInteractable.Create()

		return true
	end

	return false
end

--- 오딜과 상호작용하면 발생하는 이벤트
function local_class:interact_with_trouble_shooter()
	quest_icon_util.remove(self.get_trouble_shooter())

	party_util.align_to_target(self.get_desk().Position + vector(1, 0, 0),
			'down', 1, 'arc')

	speech_bubble_util.show_speech_bubble_async(
			self.get_trouble_shooter(), { key = 'demonworld_part1_ordeal_talk_1', skip = true })

	local wait = true
	local talk_branch = -1

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))

	-- 메인 퀘스트 활성화되어있는지 Progress 확인
	-- 메인 퀘스트 InnerProgress 확인
	local main_quest_inner_progress = user_progress:GetStartedQuest(self.main_quest_id).InnerProgress
	local main_quest_condition_ok = main_quest_inner_progress == 8

	-- 메인 퀘스트 섹션이 9면 작동
	if main_quest_condition_ok then
		branches:Add({
			Text = game_string:GetString('demonworld_part1_ordeal_talk_2'),
			Tendency = CS.Oak.TalkTendency.Mercy,
			Callback = function()
				talk_branch = 0
				wait = false;
			end
		})
	end

	-- 불륜 조사 퀘스트 활성화되어있는지 Progress 확인
	local adultery_quest_activated = user_progress:GetStartedQuest(self.adultery_quest_id)

	if adultery_quest_activated then
		local adultery_quest_inner_progress = adultery_quest_activated.InnerProgress
		local adultery_quest_condition_ok = adultery_quest_inner_progress >= 0

		local string_key = nil

		if adultery_quest_activated.IsComplete == false then
			if adultery_quest_inner_progress == 0 then
				string_key = 'demonworld_adultery_26'
			elseif adultery_quest_inner_progress == 1 then
				string_key = 'demonworld_adultery_43'
			elseif adultery_quest_inner_progress == 3 then
				string_key = 'demonworld_adultery_80'
			end
		end

		-- 불륜 조사 이벤트 조건
		if adultery_quest_condition_ok and string_key ~= nil then
			branches:Add({
				Text = game_string:GetString(string_key),
				Tendency = CS.Oak.TalkTendency.Intellect,
				Callback = function()
					talk_branch = 1
					wait = false;
				end
			})
		end
	else
		-- 불륜 조사 이벤트 조건
		branches:Add({
			Text = game_string:GetString('demonworld_adultery_2'),
			Tendency = CS.Oak.TalkTendency.Intellect,
			Callback = function()
				talk_branch = 1
				wait = false;
			end
		})
	end

	-- 취소
	branches:Add({
		Text = game_string:GetString('demonworld_part1_ordeal_talk_4'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			talk_branch = 2
			wait = false;
		end
	})

	local u = ui_overlay_util
	u.push_overlay(nil, branches)

	while wait do
		coroutine.yield(nil)
	end

	if talk_branch == 0 then
		-- 플래그 false로 설정
		self.main_quest_progress_end = false

		message_system:Publish(CS.Oak.CustomStageEvent.Create(
				user_party_leader, { self.start_main_quest_custom_event }))

		-- 메인 퀘스트에서 커스텀 이벤트 받아서 이벤트 진행 후 커스텀 이벤트 날려서 플래그 변경될 때까지 대기
		while not self.main_quest_progress_end do
			coroutine.yield(nil)
		end
	elseif talk_branch == 1 then
		-- 플래그 false로 설정
		self.adultery_quest_progress_end = false

		message_system:Publish(CS.Oak.CustomStageEvent.Create(
				user_party_leader, { self.start_adultery_quest_custom_event }))

		-- 서브 퀘스트에서 커스텀 이벤트 받아서 이벤트 진행 후 커스텀 이벤트 날려서 플래그 변경될 때까지 대기
		while not self.adultery_quest_progress_end do
			coroutine.yield(nil)
		end
	end

	self:set_odile_quest_icon()
end

-- 달러 로드
function local_class:load_dollar()
	local storage_create = require('utils/QuestDataStorage')
	local data_storage = storage_create.create(221)

	local dollar_val = data_storage:get_data(self.dollar_data_key)

	return dollar_val
end

function local_class:set_odile_quest_icon()
	local main_quest = user_progress:GetStartedQuest(self.main_quest_id)
	local adultery_quest = user_progress:GetStartedQuest(self.adultery_quest_id)
	local main_quest_condition_ok = main_quest.InnerProgress == 8

	if main_quest_condition_ok then
		local dollar_val = self:load_dollar()

		-- 우선순위 : 메인 50000원 > 불륜 추적 의뢰 받기 > 돈 없음
		if dollar_val >= 50000 then
			quest_icon_util.set_quest_cleared(self.get_trouble_shooter())
		elseif adultery_quest == nil then
			quest_icon_util.set_quest_notice(self.get_trouble_shooter())
		else
			quest_icon_util.set_quest_accepted(self.get_trouble_shooter())
		end

		-- 불륜 추적 의뢰 서브 퀘스트 마커 처리
		if adultery_quest ~= nil and adultery_quest.InnerProgress == 1 then
			quest_marker_util.remove(self.adultery_quest_marker_key)
		end

	elseif main_quest.InnerProgress > 8 and adultery_quest == nil and main_quest.InnerProgress ~= 18 then
		quest_icon_util.set_quest_notice(self.get_trouble_shooter())
	end
	-- 섹션 8일때는 처리하지 않음.
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
