local local_class = newclass('MakingCryOperationController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.starpiece_name = 'making_cry_star_piece'
	self.valentine = nil

	self.valentine_name = 'hollywood_valentine_villain'

	self.juice_clerk_name = 'juice_girl'
	self.juice_sign_board_name = 'juice_signboard'

	-- TODO : 다른 곳에서 가져온 아이디라 퀘스트 아이템으로 새로 만들어야 할듯
	self.hot_sauce_id = 20098
	self.water_id = 20036
	self.lemon_id = 20165

	self.hot_sauce_get_title = 'movie_3_making_cry_operation_2_0'
	self.hot_sauce_get_subtitle = 'movie_3_making_cry_operation_2_1'
	self.hot_sauce_get_desc = 'movie_3_making_cry_operation_2_2'

	self.is_have_hot_sauce = false

	self.seen_first_talk = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	local juice_girl = get_character(self.juice_clerk_name)

	if self.valentine.Interactable ~= nil and self.valentine.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		self.valentine.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if juice_girl.Interactable ~= nil and juice_girl.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		juice_girl.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.valentine = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self.valentine = get_character(self.valentine_name)
		local juice_girl = get_character(self.juice_clerk_name)
		character_util.set_anim_and_emotion(self.valentine, { name = 'idle'}, { name = 'smile'})
		character_util.set_direction(self.valentine, 'left')

		-- 스타피스 획득 여부에 따른 처리
		if CS.Oak.StageProgress.Current:HasStarPiece(self.starpiece_name) then
			-- 획득 세팅
			-- (cry, seat, left)발렌타인이 제자리에서 울고 있다.
			character_util.set_direction(self.valentine, 'left')
			character_util.set_anim_and_emotion(self.valentine, { name = 'seat'}, { name = 'cry'})
			character_util.set_position(get_character(self.juice_clerk_name), vector(999, 0, 999))
			self.valentine.Interactable.Talk = 'movie_main_s11_34'
		else
			-- 미획득 세팅
			get_field_object('juice_signboard').Interactable.Message = 'movie_3_making_cry_operation_36_0'
			if self.valentine.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
				self.valentine.Interactable:AddListener(self.cs_controller)
			end
			if juice_girl.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
				juice_girl.Interactable:AddListener(self.cs_controller)
			end
		end

	elseif event_type == typeof(CS.Oak.InteractEvent) then
		local clerk = get_character(self.juice_clerk_name)
		if lua_helper.reference_equals(e.Target, self.valentine) then
			if not self.seen_first_talk then
				sp_util.play_normal_screenplay(self.talk_to_valentine, self)
			elseif self.is_have_hot_sauce then
				sp_util.play_normal_screenplay(function()
					party_util.align_party(self.valentine, 'left', 1, 'arc')
					yield_return_func(self.last_talk_to_valentine, self)
				end)
			else
				-- 너 필요 없어!
				speech_bubble_util.show_speech_bubble(self.valentine,
						{key = 'movie_3_making_cry_operation_14', skip = true})
			end
		elseif lua_helper.reference_equals(e.Target, clerk) then
			sp_util.play_normal_screenplay(self.talk_to_clerk, self)
		end
		return true
	end
	return false
end

function local_class:talk_to_clerk()

	local clerk = get_character(self.juice_clerk_name)

	local loop_count = user_party.Count - 1

	for i = 0, loop_count do
		if i > 0 then
			character_util.move_to(user_party[i], clerk.Position - vector(i - 2, 0, 4), nil, 1.5, true, true)
			character_util.set_direction(user_party[i], 'up')
		end

	end

	character_util.move_to_async(user_party.Leader, clerk.Position - vector(0, 0, 2), nil, 1.5, true, true)
	character_util.set_direction(user_party.Leader, 'up')

	wait_for_sec(0.5)

	--(idle, down)어서오세요!
	speech_bubble_util.show_speech_bubble_async(clerk, {key = 'movie_3_making_cry_operation_17', skip = true})
	speech_bubble_util.show_speech_bubble_async(clerk, {key = 'movie_3_making_cry_operation_18', skip = true})

	--기간한정 상품인 눈물나게 매운 특제 핫소스 드링크 한 잔 어떠신가요?

	-- 선택지 : 레모네이드 / 생수 / 특제 핫소스 드링크
	local result_1 = choose_util.play_choose_event(
			{{'movie_3_making_cry_operation_talk_branch_9'},
			 {'movie_3_making_cry_operation_talk_branch_10'},
			 {'movie_3_making_cry_operation_talk_branch_11'},
			 {'movie_3_making_cry_operation_talk_branch_14'}})

	if result_1 == 3 then
		-- 이거 매워
		speech_bubble_util.show_speech_bubble_async(clerk, {key = 'movie_3_making_cry_operation_20', skip = true})

		local wait = true
		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		local result_2 = 0

		branches:Add({
			Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_12'),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				result_2 = 1
				wait = false
			end})

		-- 발렌타인과 대화했었으면(쫒겨났으면)
		if self.seen_first_talk then
			branches:Add({
				Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_13'),
				Tendency = CS.Oak.TalkTendency.Brutal,
				Callback = function()
					result_2 = 2
					wait = false
				end})
		end

		branches:Add({
			Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_14'),
			Tendency = CS.Oak.TalkTendency.Normal,
			Callback = function()
				result_2 = 3
				wait = false
			end})

		ui_overlay_util.push_overlay(user_party.Leader, branches)
		while wait do
			coroutine.yield(nil)
		end

		if result_2 == 1 then
			speech_bubble_util.show_speech_bubble_async(clerk,
					{key = 'movie_3_making_cry_operation_21', skip = true})

			character_util.set_anim(clerk, {name = 'throw', loop = false, remove_after = 0.3})

			music_player:PlaySfxOneShot('01_throw_01')
			local hs_item = drop_item_util.create_item(
					{itemid = self.hot_sauce_id, notforinven = true, pos = clerk.Position,
					 lootstate = 'dontfindlooter', target = user_party.Leader.Position
							+ vector(0, 0, 0.5)})

			wait_for_sec(1.5)

			character_util.set_direction(user_party.Leader, 'left')
			character_util.set_anim(user_party.Leader, {name = 'eat'})

			music_player:PlaySfxOneShot('01_drinking_01')

			wait_for_sec(1.0)

			hs_item.ConsumeTarget = user_party.Leader

			character_util.remove_anim_and_emotion(user_party.Leader)

			field_ui_util.show_narration_async({ key = 'movie_3_making_cry_operation_nar_1'})

			music_player:PlaySfxOneShot('01_player_jump_01')
			character_util.jump(user_party.Leader, 0.4, 0.2)
			character_util.set_emotion(user_party.Leader, {name = 'burning'})
			camera_util.shake(0.2, 0.2)
			wait_for_sec(0.2)

			music_player:PlaySfxOneShot('01_player_jump_01')
			character_util.jump(user_party.Leader, 0.4, 0.2)
			camera_util.shake(0.2, 0.2)
			wait_for_sec(0.2)

			local cnt = 0

			local pos = user_party.Leader.Position

			while cnt < 2 do

				character_util.move_to_async(user_party.Leader, pos + vector(1.5, 0, 0),
						nil, 5 + cnt, true, true, true)

				music_player:PlaySfxOneShot('01_player_jump_01')
				character_util.jump(user_party.Leader, 0.4 + cnt / 10, 0.2)
				camera_util.shake(0.2 + cnt / 20, 0.2)
				wait_for_sec(0.2)

				music_player:PlaySfxOneShot('01_player_jump_01')
				character_util.jump(user_party.Leader, 0.4 + cnt / 10, 0.2)
				camera_util.shake(0.2 + cnt / 20, 0.2)
				wait_for_sec(0.2)

				character_util.move_to_async(user_party.Leader, pos - vector(1.5, 0, 0),
						nil, 5 + cnt, true, true, true)

				music_player:PlaySfxOneShot('01_player_jump_01')
				character_util.jump(user_party.Leader, 0.4 + cnt / 10, 0.2)
				camera_util.shake(0.2 + cnt / 20, 0.2)
				wait_for_sec(0.2)

				music_player:PlaySfxOneShot('01_player_jump_01')
				character_util.jump(user_party.Leader, 0.4 + cnt / 10, 0.2)
				camera_util.shake(0.2 + cnt / 20, 0.2)

				if cnt == 1 then
					music_player:PlaySfxOneShot('01_catch_fire_01')
				end

				wait_for_sec(0.2)

				cnt = cnt + 1

			end

			character_util.move_to_async(user_party.Leader, pos, nil, 3, true, true)

			character_util.set_anim(user_party.Leader, {name = 'seat'})
			character_util.set_emotion(user_party.Leader, {name = 'cry'})

			music_player:PlaySfxOneShot('03_dialogue_sadness_01')

			screen_util.fade_out_async(1, unity_class.color.black, 'linear')

			local loop_count = user_party.Count - 1
			for i = 0, loop_count do
				character_util.set_direction(user_party[i], 'right')
				character_util.set_anim(user_party[i], {name = 'prostrate'})
				character_util.set_emotion(user_party[i], {name = 'cry'})

			end

			wait_for_sec(1.0)

			screen_util.fade_in_async(1, unity_class.color.black, 'linear')

			for i = 0, loop_count do
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.party_member_wake_up, self, user_party[i]))
			end

			wait_for_sec(1.2)

			music_player:PlaySfxOneShot('01_player_popup_01')

			wait_for_sec(0.8)

		elseif result_2 == 2 then

			music_player:PlaySfxOneShot('01_throw_01')
			local icecream_dropped_item = drop_item_util.create_item(
			{itemid = self.hot_sauce_id, notforinven = true, pos = clerk.Position,
				target = user_party.Leader.Position + vector(0, 0, 0.5)})

			wait_for_sec(0.5)

			--먹는 이펙트
			character_util.set_anim(user_party.Leader, {name = 'eat', loop = true, scale = 1})
			character_util.set_emotion(user_party.Leader, {name = 'idle', loop = true})
			wait_for_sec(1.0)

			coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent({ItemId = self.hot_sauce_id}, self.hot_sauce_get_title,
			self.hot_sauce_get_subtitle, self.hot_sauce_get_desc))

			self.is_have_hot_sauce = true

		else
			character_util.set_emotion(clerk, {name = 'tired'})
			character_util.show_emoticon_async(clerk, nil, 'question')

		end

	elseif result_1 == 1 then
		-- 맛있게 드세여
		speech_bubble_util.show_speech_bubble_async(clerk, {key = 'movie_3_making_cry_operation_19', skip = true})

		character_util.set_anim(clerk, {name = 'throw', loop = false, remove_after = 0.3})
		music_player:PlaySfxOneShot('01_throw_01')
		drop_item_util.create_item(
				{itemid = self.lemon_id, notforinven = true, pos = clerk.Position,
				 target = user_party.Leader.Position + vector(0, 0, 0.5)}).ConsumeTarget = user_party.Leader

		wait_for_sec(0.3)

	elseif result_1 == 2 then
		-- 맛있게 드세여
		speech_bubble_util.show_speech_bubble_async(clerk, {key = 'movie_3_making_cry_operation_19', skip = true})

		character_util.set_anim(clerk, {name = 'throw', loop = false, remove_after = 0.3})

		music_player:PlaySfxOneShot('01_throw_01')
		drop_item_util.create_item(
				{itemid = self.water_id, notforinven = true, pos = clerk.Position,
				 target = user_party.Leader.Position + vector(0, 0, 0.5)}).ConsumeTarget = user_party.Leader

		wait_for_sec(0.3)
	end

	character_util.remove_anim_and_emotion(clerk)

end

function local_class:party_member_wake_up(party_member)

	wait_for_sec(1.0)

	character_util.shake(party_member, 0.04, 0.2)

	wait_for_sec(0.2)

	character_util.remove_emotion(party_member)

	character_util.mario_jump_async(party_member, 'right', 0.5, 0.3)

	wait_for_sec(0.3)
end

function local_class:talk_to_valentine()
	character_util.align_party(self.valentine, 'left')

	--(smile, idle, left)거기 너! 나 좀 도와줘!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim_and_emotion(self.valentine, { name = 'idle'}, { name = 'smile'})
	speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_1', skip = true})
	--(smile, cast, left)우는 연기를 해야하는데 최근에 행복한 일밖에 없어서 울음이 통 나오질 않아
	character_util.set_anim(self.valentine, { name = 'cast'})
	speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_2', skip = true})
	--(smile, release, left)네가 나 좀 울게 도와줘!
	character_util.set_anim(self.valentine, { name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_3', skip = true})

	local wait = true
	local branch = 0

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	-- 그래! 내가 도와줄게!
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_1'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			branch = 0
			wait = false
		end})
	-- 싫어! 지금 난 바빠!
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_2'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			branch = 1
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	if branch == 0 then
		--(smile, victory_get, left)좋아! 바로 시작해보자!
		character_util.set_anim(self.valentine, { name = 'victory_get', sfx_name = '01_player_jump_01'})
		speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_4', skip = true})
		--(smile, cast, left)우선 슬픈 이야기를 해줘. 그러면 내가 울지도 몰라.
		character_util.set_anim(self.valentine, { name = 'cast'})
		speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_5', skip = true})
	else
		-- (mad, release, left)건방진…
		music_player:PlaySfxOneShot('01_beep_01')
		character_util.set_anim_and_emotion(self.valentine, { name = 'release'}, { name = 'mad'})
		speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_6', skip = true})
		-- 인터랙트 종료
		character_util.set_anim_and_emotion(self.valentine, { name = 'idle'}, { name = 'smile'})
		party_util.reset_controllers()
		field_ui_manager:Show()
		return
	end

	wait = true
	branches:Clear()

	-- 티탄왕국의 배신자 아버지와 아들 이야기
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_3'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})
	-- 티탄왕국의 마리안과 마티 이야기
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_4'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})
	-- 캔터베리 공주 자매의 생이별 이야기
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_5'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	--캐릭터 슬픈 표정으로 시작
	character_util.set_anim(user_party.Leader, {name = 'cast', loop = true, scale = 1})
	character_util.set_emotion(user_party.Leader, {name = 'sleep_deep', loop = true})

	wait_for_sec(0.3)

	character_util.set_anim(self.valentine, {name = 'nod', loop = true, scale = 1})
	character_util.set_emotion(self.valentine, {name = 'smile', loop = true})

	wait_for_sec(0.7)

	--이모티콘 띄우고
	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	character_util.set_anim(user_party.Leader, {name = 'hurt', loop = true, scale = 1})
	character_util.set_emotion(user_party.Leader, {name = 'tired', loop = true})
	character_util.show_emoticon(user_party.Leader, nil, 'annoyed')

	wait_for_sec(1.0)

	character_util.set_anim(self.valentine, {name = 'bomb_idle', loop = true, scale = 1})
	character_util.set_emotion(self.valentine, {name = 'smile', loop = true})

	wait_for_sec(1.0)

	--엉엉 울지만 발렌타인은 해피!
	music_player:PlaySfxOneShot('03_dialogue_sadness_01')
	character_util.set_anim(user_party.Leader, {name = 'seat', loop = true, scale = 1})
	character_util.set_emotion(user_party.Leader, {name = 'cry', loop = true})

	wait_for_sec(0.5)

	character_util.set_anim(self.valentine, {name = 'victory_get', loop = false, scale = 1, sfx_name = '01_player_jump_01'})
	character_util.set_emotion(self.valentine, {name = 'smile', loop = true})

	wait_for_sec(1.5)

	--다시 원래 표정으로 엔딩
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.remove_anim_and_emotion(self.valentine)

	--(idle, idle, left)하하하! 이런 귀여운 자식.
	music_player:PlaySfxOneShot('01_bad_fairy_01')
	character_util.set_anim(self.valentine, { name = 'idle'})
	speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_7', skip = true})
	--(idle, question, left)이런 게 슬프다고 생각했어? 진심으로?
	character_util.set_anim(self.valentine, { name = 'question', loop = false})
	character_util.set_emotion(self.valentine, {name = 'idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_8', skip = true})
	--(idle, idle, left)안되겠어…
	character_util.set_anim(self.valentine, { name = 'idle'})
	character_util.set_emotion(self.valentine, {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_9', skip = true})
	--(attack, cast, left)이번엔 욕을 하고 협박을 해 봐. 내가 겁을 먹을 정도로.
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim_and_emotion(self.valentine, { name = 'cast'}, { name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(self.valentine, { key = 'movie_3_making_cry_operation_10', skip = true})

	wait = true
	branches:Clear()

	-- 주먹을 들이밀며 화를 낸다
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_6'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			branch = 0
		end})
	-- 무기를 들이밀며 화를 낸다
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_7'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			branch = 1
		end})
	-- 쿠아아아아!(소리지른다)
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_8'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			branch = 2
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	if branch == 0 then
		--주먹을 들이 민다.
		character_util.set_anim(user_party.Leader, {name = 'gauntlet_combo_attack2', loop = true,
													sfx_name = '02_normal_slash_01', scale = 1})
		character_util.set_emotion(user_party.Leader, {name = 'mad', loop = true})

		character_util.set_emotion(self.valentine, {name = 'surprise', loop = true})
		character_util.normal_jump(self.valentine)
		wait_for_sec(1.0)

	elseif branch == 1 then
		user_party.Leader:HideWeapon(true)
		--무기를 들이 민다.
		user_party.Leader.SpineController:SetAttachment('[base]weapon1', 'head_crusher')
		character_util.set_emotion(user_party.Leader, {name = 'mad', loop = true})
		character_util.set_anim(user_party.Leader, {name = 'twohand_attack', loop = true,
													sfx_name = '02_normal_slash_01', scale = 1})

		user_party.Leader.SpineController:SetAttachment('[base]weapon1', 'empty')
		user_party.Leader:HideWeapon(false)
	else
		--점프를 뛴다.
		character_util.set_anim(user_party.Leader, {name = 'cast2', loop = true, scale = 1})
		character_util.set_emotion(user_party.Leader, {name = 'mad', loop = true})

		for i = 1, 5 do
			character_util.jump(user_party.Leader, 0.4, 0.3)
			music_player:PlaySfxOneShot('03_mech_stomp_01')
			camera_util.shake(0.2, 0.15)
			wait_for_sec(0.3)
		end

	end

	-- 하하!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_anim_and_emotion(self.valentine,
			{ name = 'success', loop = true, sfx_name = '01_player_jump_01'}, { name = 'smile'})
	speech_bubble_util.show_speech_bubble_async(self.valentine,
			{ key = 'movie_3_making_cry_operation_11', skip = true})

	character_util.remove_anim_and_emotion(user_party.Leader)

	-- 그걸 험상궂은 얼굴이라고 짓는 거라니...
	character_util.remove_anim(self.valentine)
	speech_bubble_util.show_speech_bubble_async(self.valentine,
			{ key = 'movie_3_making_cry_operation_12', skip = true})
	character_util.remove_anim_and_emotion(self.valentine)

	--네 얼굴 보고 안 웃는 게 더 힘들겠군.
	character_util.set_anim(self.valentine, {name = 'idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(self.valentine,
			{ key = 'movie_3_making_cry_operation_13', skip = true})
	character_util.remove_anim_and_emotion(self.valentine)

	--이 따위로 할 거면 그냥 꺼져!
	character_util.set_anim_and_emotion(self.valentine,
			{ name = 'release', loop = true, sfx_name = '01_swing_01'}, { name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(self.valentine,
			{ key = 'movie_3_making_cry_operation_14', skip = true})

	character_util.remove_anim_and_emotion(user_party.Leader)

	character_util.remove_anim_and_emotion(self.valentine)

	self.seen_first_talk = true
end

-- 핫소스 가지고 발렌타인한테 말걸었을 때
function local_class:last_talk_to_valentine()

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	local choice = 0

	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_15'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_16'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})

	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = hulk_jerk_1
	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	if choice == 0 then
		--내 소중한 시간 낭비하지마!
		character_util.set_anim(self.valentine, {name = 'release', loop = true, scale = 1})
		character_util.set_emotion(self.valentine, {name = 'mad', loop = true})
		speech_bubble_util.show_speech_bubble_async(self.valentine,
			{ key = 'movie_3_making_cry_operation_37', skip = true})
		character_util.remove_anim_and_emotion(self.valentine)

		return

	end

	music_player:PlaySfxOneShot('01_throw_01')
	drop_item_util.create_item(
			{itemid = self.hot_sauce_id, notforinven = true, pos = user_party.Leader.Position,
				target = self.valentine.Position - vector(0.3, 0, 0)}).ConsumeTarget = self.valentine

	wait_for_sec(0.5)

	character_util.set_anim(self.valentine, {name = 'eat', loop = true, scale = 1})
	wait_for_sec(1.0)

	character_util.remove_anim(self.valentine)

	character_util.show_emoticon_async(self.valentine, nil, 'question')

	--핫소스잖아?
	character_util.set_anim(self.valentine, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(self.valentine, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(self.valentine,
		{ key = 'movie_3_making_cry_operation_25', skip = true})

	--너의 쓸모없음을 사과하는 거야?
	character_util.set_anim(self.valentine, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(self.valentine, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(self.valentine,
		{ key = 'movie_3_making_cry_operation_26', skip = true})

	branches:Clear()
	wait_for_branch = true
	choice = 0

	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_17'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	branches:Add({
		Text = game_string:GetString('movie_3_making_cry_operation_talk_branch_18'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})

	choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = hulk_jerk_1
	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	--플레이어 미안해 하는 척
	character_util.set_anim(user_party.Leader, {name = 'cast', loop = true, scale = 1})
	character_util.set_emotion(user_party.Leader, {name = 'tired', loop = true})
	wait_for_sec(1.0)

	character_util.remove_anim_and_emotion(user_party.Leader)

	--그래! 특별히 네 사과를 받아주지!
	character_util.set_anim(self.valentine, {name = 'nod', loop = true, scale = 1})
	character_util.set_emotion(self.valentine, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(self.valentine,
		{ key = 'movie_3_making_cry_operation_27', skip = true})

	--벌컥벌컥
	music_player:PlaySfxOneShot('01_drinking_01')
	character_util.set_anim(self.valentine, {name = 'eat', loop = true, scale = 1})
	character_util.set_emotion(self.valentine, {name = 'greed', loop = true})

	wait_for_sec(1.0)

	character_util.remove_anim_and_emotion(self.valentine)

	music_player_util.play_stage_music({state = 'muted', mix = 2})

	--눈에 불이 나고
	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4, 0.2)
	character_util.set_anim(self.valentine, {name = 'embarrassed', loop = true, scale = 1})
	character_util.set_emotion(self.valentine, {name = 'burning'})
	camera_util.shake(0.2, 0.2)
	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4, 0.2)
	camera_util.shake(0.2, 0.2)
	wait_for_sec(0.2)

	--매워어어!!
	music_player:PlaySfxOneShot('01_catch_fire_01')
	music_player:PlaySfxOneShot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(self.valentine,
		{ key = 'movie_3_making_cry_operation_28', skip = true})

	local cnt = 0
	local pos = self.valentine.Position

	local loop_sfx = music_player_util.play_sfx({sfx_name = '03_pet_bite_loop_01',
												 loop = true, type_priority = 'event', player_priority = 'npc'})

	character_util.move_to_async(self.valentine, pos + vector(0, 0, 2),
			nil, 5 + cnt, true, false, true)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	cnt = cnt + 1

	character_util.move_to_async(self.valentine, pos + vector(-4, 0, 2),
			nil, 5 + cnt, true, false, true)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	cnt = cnt + 1

	character_util.move_to_async(self.valentine, pos + vector(-4, 0, -2),
			nil, 5 + cnt, true, false, true)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	cnt = cnt + 1

	character_util.move_to_async(self.valentine, pos - vector(0, 0, 2), nil, 5 + cnt, true, false)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	character_util.move_to_async(self.valentine, pos, nil, 3, true, false)

	--신이시여!
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	camera_util.shake(0.5, 0.5)
	speech_bubble_util.show_speech_bubble_async(self.valentine,
		{ key = 'movie_3_making_cry_operation_29', skip = true})

	character_util.jump(self.valentine, 0.4 + cnt / 10, 0.2)
	camera_util.shake(0.2 + cnt / 20, 0.2)
	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('01_catch_fire_01')
	character_util.set_direction(self.valentine, 'left')
	character_util.set_anim(self.valentine, {name = 'seat', loop = false, scale = 1})

	loop_sfx:FadeOut(1)

	wait_for_sec(1.0)

	music_player:PlaySfxOneShot('03_dialogue_sadness_01')
	character_util.set_anim(self.valentine, {name = 'seat', loop = true, scale = 1})
	character_util.set_emotion(self.valentine, {name = 'cry'})

	wait_for_sec(1.0)

	music_player_util.play_stage_music({state = 'field', mix = 2})

	--그래… 네 덕분에 우는 데 성공했어…
	speech_bubble_util.show_speech_bubble_async(self.valentine,
		{ key = 'movie_3_making_cry_operation_30', skip = true})

	--이거나 받아...
	speech_bubble_util.show_speech_bubble_async(self.valentine,
		{ key = 'movie_3_making_cry_operation_31', skip = true})

	local star_piece = get_field_object(self.starpiece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(
		self.valentine.Position + vector(0, 1, 0), false))

	character_util.set_position(get_character(self.juice_clerk_name), vector(999, 0, 999))

	if self.valentine ~= nil then
		if lua_helper.type_compare(self.valentine.Interactable, CS.Oak.NPCInteractable) then
			self.valentine.Interactable:RemoveRelatedEvent(self.cs_controller)
		end
	end

	self.valentine.Interactable.Talk = 'movie_main_s11_34'

	get_field_object('juice_signboard').Interactable.Message = 'movie_3_making_cry_operation_36'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
