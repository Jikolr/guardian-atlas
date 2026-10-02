local local_class = newclass("FutureCastle1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.smoke_off = nil
	self.camera_smoke_effect = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == 'futurecastle_1_5' then
		quest_util.load_pool_resource(

		)
	end
end
function local_class:need_on_launch()
	local main_quest_id = 151
	local q = user_progress:GetStartedQuest(main_quest_id)

	return true
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	local futurecastle_main_quest_id = 151
	local q = user_progress:GetStartedQuest(futurecastle_main_quest_id)

	--공주 파티 합류 및 파티원 전원 날리기
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self, q.InnerProgress, q.IsComplete))
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)

	return false
end

function local_class:on_stage_loaded(_)
	-- 메인퀘스트를 클리어못했으면 스테이지 내 재화 UI를 꺼버린다.
	local main_quest = user_progress:GetStartedQuest(151)
	if main_quest ~= nil and not main_quest.IsComplete then
		local navi_bar = CS.Oak.UI.NavigationBar.Instance
		if not is_unity_null(navi_bar) then
			local field = CS.Utils.FindChildRecursively(navi_bar.transform, 'Field')
			local resource = CS.Utils.FindChildRecursively(field, 'Resources')
			resource.gameObject:SetActive(false)
		end
	end

	return false
end

--주인공 혼자 들어오도록 하는 함수
function local_class:opening_routine(innerprogress, IsComplete)
	local party_list = {}

	for i = 0, user_party.Count - 1 do
		local cur_party_member = user_party[i]

		table.insert(party_list, cur_party_member)
	end

	for i = 1, #party_list do
		if i ~= 1 then
			character_util.convert_to_npc(party_list[i])
			party_list[i].ActiveState = CS.Oak.ActiveState.Disabled
		end
	end

	if not IsComplete then
		for i = 1, 30 do
			if i <= 5 then
				local piece = get_field_object('star_piece_'..i)
				if piece ~= nil then
					piece.ActiveState = active_state('disabled')
				end
			end
		end
	else
		for i = 1, 8 do
			if i <= 3 or i == 6 or i == 7 then
				message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('section_21_23_battlegate_'..i, true))
			end
		end
	end

	if innerprogress == 20 and not IsComplete then
		local princess = get_character('future_princess')
		character_util.remove_anim_and_emotion(princess)
		character_util.convert_to_party_member(princess, user_party, true)
		character_util.remove_anim_and_emotion(princess)
		character_util.set_position(princess, vector(-1, 0, 0))
	end

	if innerprogress == 21 and not IsComplete then
		character_util.set_position(user_party_leader, vector(-43.5, 0, -12.5))

		camera_util.move(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(-43.5, 0, -12.5),
		CS.Oak.Direction.Left, game_string:GetString(stage.Name)))

	elseif not IsComplete and (innerprogress == 20 or innerprogress == 22) then
		-- 퀘스트를 클리어 하지 않았으면서 Progress 20 이거나 22일 때는 스테이지 시작 시퀀스 실행하지 않고 return
		return
	elseif innerprogress == 23 and not IsComplete then
		character_util.set_position(user_party_leader, vector(-42, 0, 6.5))
		camera_util.move(user_party.Leader.Position, 0, {end_target = user_party.Leader})

	else
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(0, 0, -0.5),
		CS.Oak.Direction.Left, game_string:GetString(stage.Name)))
	end

	stage.FieldUIManager:Show()
	user_party:ResetControllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
