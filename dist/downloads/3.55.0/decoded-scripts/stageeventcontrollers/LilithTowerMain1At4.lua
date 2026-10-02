local local_class = newclass("LilithTowerMain1At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 이름
	self.stage_name = 'lilithtower_1_4'

	-- 윈도우 브레이커 이벤트 key
	self.windows_breaker_key = 'windows_breaker'

	-- 기사 리턴
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 수트 맨손 기사
	self.get_knight_suit = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_suit')
		else
			return get_character('knight_female_suit')
		end
	end

	-- 수트 배트 기사
	self.get_knight_suit_bat = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_suit_bat')
		else
			return get_character('knight_female_suit_bat')
		end
	end

	-- 세이프 하우스 빛
	self.light_name = 'safe_house_light'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 바위 터질때 사용할 이팩트 미리 로드
	unity_object_pool.GetOrCreate('FX_Env_SmallRock_lv1_destroy_gray')

	-- 리소스 로드를 기다림
	yield_return(unity_object_pool, 'WaitAll')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local progress_list = {
		11, 12, 13, 14, 15
	}

	-- 리더를 기사로 바꿈
	-- 방망이를 얻었다면 방망이를 든 기사로
	local character_spec_id = 302922
	if user_util.has_knight_male() then
		character_spec_id = 302921
	end

	local leader
	if quest_util.get_custom_state(quest_progress, self.windows_breaker_key) >= 1 then
		leader = self.get_knight_suit_bat()
	else
		leader = self.get_knight_suit()
	end

	character_util.convert_to_manual_character(leader)
	user_party.Leader.CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)

	field_ui_manager:SetUI(leader, CS.Oak.FieldUiType.TopHpBar)

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	-- 도중에 시작하면 세이프 하우스의 시작하므로 Light 색상 변화시킴
	local light_fo = get_field_object(self.light_name)
	local light = light_fo.Transform:GetChild(0):GetComponent(typeof(CS.UnityEngine.Light))
	light.color = unity_color({ 130 / 255, 130 / 255, 130 / 255, 0 })

	-- 세이프 하우스 이벤트 진행 중에는 테러 BGM이 나오도록 설정
	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	if quest_progress ~= nil and not quest_progress.IsComplete then
		if quest_progress.InnerProgress > 10 and quest_progress.InnerProgress < 15 then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.change_field_bgm, self, quest_progress.InnerProgress))
		end
	end
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_stage_loaded_event(e)
end

function local_class:change_field_bgm(inner_progress)
	wait_for_sec(0.5)

	if inner_progress == 11 then
		wait_for_sec(0.8)

		music_player_util.play_stage_music(
				{ name = 'ondemand/v2_22_lilithtower/audio:bgm_lilith_safehouse', state = 'event', mix = 0 })
	elseif inner_progress < 13 then
		music_player_util.play_stage_music(
				{ name = 'ondemand/v2_22_lilithtower/audio:bgm_lilith_terror_01', state = 'event', mix = 1 })
	elseif inner_progress == 14 then
		music_player_util.play_stage_music(
				{ name = 'ondemand/v2_22_lilithtower/audio:bgm_lilith_terror_02', state = 'event', mix = 0 })
	else
		music_player_util.play_stage_music(
				{ name = 'ondemand/v2_22_lilithtower/audio:bgm_lilith_terror_02', state = 'event', mix = 1 })
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
