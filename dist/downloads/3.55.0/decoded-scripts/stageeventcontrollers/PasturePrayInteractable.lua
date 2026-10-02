local local_class = newclass('PasturePrayInteractable')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 몬스터 매니저
	self.monster_manager = CS.Oak.HeavenHoldPastureSystem.Instance.MonsterManager

	-- 너굴걸 핸들네임
	self.raccoon_handle_name = 'npc_raccoon'

	-- 너굴걸 초기 위치
	self.raccoon_init_pos = nil

	-- 기다리는 몬스터 핸들 핸들네임
	self.waiting_monster_handle_name = 'ranch_waiting_monster'

	-- C# 작업 대기 여부
	self.wait_c_sharp_process = false

	-- C# 처리 중 네트워크 에러 발생
	self.network_error = false

	-- 몬스터 대기 코루틴
	self.monster_waiting_coroutine = nil

	-- 몬스터 대기 여부
	self.is_monster_waiting = false

	-- 몬스터 인터랙션 Instance
	self.pasture_pray_instance = nil

	-- 기다리는 몬스터 효과음
	self.waiting_monster_sfx = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PasturePrayEvent))

	self:waiting_monster_sfx_off()

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.PasturePrayEvent), 'on_pasture_pray_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end
--endregion

-------------------------------------------------

--region Main

-- 석상 기원
function local_class:pray_statue(instance)
	self.pasture_pray_instance = instance

	CS.Oak.HeavenHoldPastureSystem.Instance.SoundManager:HalfStageBGM()

	-- 이미 몬스터가 나와 있는 상황
	if self.is_monster_waiting == true then
		field_ui_util.show_narration_async({key = 'notice_monster_waiting'})
		instance:OnPrayEnd()
		return
	end

	music_player_util.play_sfx_one_shot('02_sword_01')

	-- 석상 앞에 정렬
	local fo = instance.getFieldObject
	local targetPos = fo.Bounds.center + unity_class.vector3.back * 0.5
	character_util.align_party(targetPos, 'down', 0.5, 'linear')

	--선택지
	local answer = choose_util.play_choose_event({
		{ 'monster_statue_search', 'mercy' },
		{ 'monster_statue_return', 'brutal' }
	})

	-- 석상을 확인한 경우
	if answer == 1 then
		self.wait_c_sharp_process = true
		instance:StartMeetMonsters()
		while self.wait_c_sharp_process == true do
			coroutine.yield()
		end

		self:meet_monster(instance)
	end

	instance:OnPrayEnd()
end

-- 몬스터 선택지
function local_class:meet_monster(instance)
	local fo = instance.getFieldObject
	local monster = instance.waitingMonster
	local rootPos = fo.Position + unity_class.vector3.back * 2.2
	local leaderPos  = rootPos + unity_class.vector3.left * 2
	local monsterPos = rootPos

	-- 페이드 아웃
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 너굴걸 목장 뒤에 숨음
	local master = get_character(self.raccoon_handle_name)
	master.Position = fo.Position + vector(-0.22, 0, 0.5)
	character_util.set_anim(master, { name = 'walk4legs', scale = 0 })
	character_util.set_direction(master, 'left')
	character_util.set_emotion(master, { name = 'greed' })

	-- 플레이어 표정 변화
	character_util.set_direction(user_party.Leader, 'right')
	user_party.Leader.Position = leaderPos
	character_util.set_emotion(user_party.Leader, { name = 'surprise' })

	-- 카메라 이동
	camera_util.move(rootPos, 0)

	-- 페이드 인
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	monster.Position = monsterPos
	CS.Oak.HeavenHoldPastureSystem.Instance.ResourceManager:MonsterSummon(monster)

	character_util.set_anim_and_emotion(monster, { name = 'happy' }, { name = 'smile' })
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'cast2' }, { name = 'awesome' })

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	character_util.show_emoticon_async(monster, nil, 'heart')

	-- 팝업 띄우고 닫힐 때까지 대기
	self.wait_c_sharp_process = true
	instance:StartShowWaitingMonsterPopupProcess()
	while self.wait_c_sharp_process == true do
		coroutine.yield()
	end

	self:process_decision(instance)
end

-- 대기 몬스터를 어떻게 할지 선택
function local_class:process_decision(instance)
	local fo = instance.getFieldObject
	local monster = instance.waitingMonster

	local choice_end = false
	while choice_end == false do
		character_util.set_anim_and_emotion(user_party.Leader, { name = 'idle' }, { name = 'idle' })
		character_util.set_anim_and_emotion(monster, { name = 'idle' }, { name = 'idle' })

		--선택지
		local answer = choose_util.play_choose_event({
			{ 'acquire_monster_btn', 'mercy' },
			{ 'reject_monster_btn', 'brutal' },
			{ 'wait_monster_btn', 'forced' }
		})

		-- 변수 초기화
		choice_end = true
		self.is_monster_waiting = false

		-- 획득
		if answer == 1 then
			-- 몬스터가 한계까지 찼을 때
			if CS.Oak.UserPasture.Me:IsMaxMonsterCount() then
				self:monster_limit_count_over_event(fo)
				choice_end = false
			else
				self:accept_monster(instance)
			end
			-- 거절
		elseif answer == 2 then
			choice_end = self:reject_monster(instance)
			-- 대기
		elseif answer == 3 then
			self:close_monster(instance)
		end
	end

	CS.Oak.HeavenHoldPastureSystem.Instance.SoundManager:ResetStageBGM()
	CS.Oak.PastureMonsterController:EnableRunAway(self.pasture_pray_instance)
	instance:CheckMarkerCondition()
end

-- 몬스터 가득 찼을 때 이벤트
function local_class:monster_limit_count_over_event(fo)
	local master = get_character(self.raccoon_handle_name)
	local curPos = master.Position
	local targetPos = fo.Position + vector(-1, 0, -2.2)
	local firstPos = vector(targetPos.x, 0, master.Position.z)

	-- 너굴걸 달려옴
	self:raccoon_reveal(master, firstPos, targetPos)

	-- 목장이 가득 찼다고 말함
	scene_util.show_normal_speech_async(master, 'monster_limit_count_over_desc')
	scene_util.show_normal_speech_async(master, 'monster_limit_count_over_desc_2')
	if CS.Oak.UserPasture.Me:IsMaxLevelMonsterHouse() == false then
		scene_util.show_normal_speech_async(master, 'monster_limit_count_over_desc_3')
	end

	-- 나레이션
	field_ui_util.show_narration_async({key = 'notice_monster_limit_count_over'})

	-- 너굴걸 돌아감
	self:raccoon_hide(master, firstPos, curPos)
end

-- 몬스터 획득
function local_class:accept_monster(instance)
	local monster = instance.waitingMonster
	local fosb = monster.FieldObjectStatsBehaviour
	local name_key = fosb.CharacterSpec.NameWithoutRank
	local monsterName = CS.GameStrings.Instance:GetString(name_key)
	local master = get_character(self.raccoon_handle_name)

	-- 서버에 회득 사실 보내고 응답 대기
	self.wait_c_sharp_process = true
	instance:StartAcceptMonster()
	while self.wait_c_sharp_process == true do
		coroutine.yield()
	end

	-- 통신 에러 발생
	if self.network_error == true then
		self.network_error = false
		self:process_decision(instance)
		return
	end

	-- 플레이어와 몬스터가 좋아함
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'sing' }, { name = 'smile' })
	wait_for_sec(1)
	character_util.set_anim_and_emotion(monster, { name = 'sing' }, { name = 'smile' })
	character_util.show_emoticon(monster, nil, 'heart')
	character_util.set_emotion(master, { name = 'love' })

	-- 나레이션
	field_ui_util.show_narration_async({key = 'narration_acquire_monster_desc', parameters = { monsterName }})

	-- 페이드 아웃
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 플레이어, 너굴걸 초기화
	self:reset_pray()

	-- 몬스터 캐릭터 교체
	self.wait_c_sharp_process = true
	instance:StartChangeWaitMonster()
	while self.wait_c_sharp_process == true do
		coroutine.yield()
	end

	instance:UpdateHead()

	-- 페이드 인
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	-- 목장 갱신 이벤트 보냄
	message_system:Publish(CS.Oak.RefreshPastureMonsterInfoEvent.Instance)
end

-- 몬스터 거절
function local_class:reject_monster(instance)
	local fo = instance.getFieldObject
	local master = get_character(self.raccoon_handle_name)
	local curPos = master.Position
	local targetPos = fo.Position + vector(-1, 0, -2.2)
	local firstPos = vector(targetPos.x, 0, master.Position.z)

	--  너굴걸 달려옴
	self:raccoon_reveal(master, firstPos, targetPos)

	-- 다시 생각해보라고 함
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	scene_util.show_normal_speech_async(master, 'monster_reject_desc')

	--선택지
	local answer = choose_util.play_choose_event({
		{ 'confirm_reject_monster_btn', 'brutal' },
		{ 'rethink_reject_monster_btn', 'mercy' }
	})

	-- 거절 확정
	if answer == 1 then
		self:reject_monster_confirm(instance, master, curPos)
		-- 취소
	else
		self:reject_monster_cancel(master, firstPos, curPos)
		return false
	end

	return true
end

-- 몬스터 거절 확정
function local_class:reject_monster_confirm(instance, master, curPos)
	-- 서버에 거절 사실 보내고 응답 기다림
	self.wait_c_sharp_process = true
	instance:StartRejectMonster()
	while self.wait_c_sharp_process == true do
		coroutine.yield()
	end

	-- 통신 에러 발생
	if self.network_error == true then
		master.Position = curPos
		character_util.set_direction(master, 'down')

		self.network_error = false
		self:process_decision(instance)
		return
	end

	-- 너굴걸 동작
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'idle' }, { name = 'tired' })
	character_util.set_direction(master, 'right')
	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true })
	character_util.set_anim_and_emotion(master, { name = 'eat' }, { name = 'tired' })
	wait_for_sec(2)

	-- 좋은 곳으로 보내준다고 함
	scene_util.show_normal_speech_async(master, 'monster_reject_desc_2')
	eat_sfx:Stop()

	-- 나레이션
	field_ui_util.show_narration_async({key = 'narration_monster_reject_desc'})

	-- 페이드 아웃
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	self:reset_pray()

	-- 대기 몬스터 삭제
	self.wait_c_sharp_process = true
	instance:StartDestroyWaitMonster()
	while self.wait_c_sharp_process == true do
		coroutine.yield()
	end

	-- 석상 외형 업데이트
	instance:UpdateHead()

	-- 페이드 인
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
end

-- 몬스터 거절 취소
function local_class:reject_monster_cancel(master, firstPos, curPos)
	-- 잘생각했다고 말함
	character_util.remove_anim(master)
	scene_util.show_normal_speech_async(master, 'monster_rethink_desc')

	-- 너굴걸 돌아감
	self:raccoon_hide(master, firstPos, curPos)
end

-- 몬스터 대기
function local_class:close_monster(instance)
	local fo = instance.getFieldObject
	local monster = instance.waitingMonster

	-- 페이드 아웃
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 플레이어, 너굴걸 초기화
	self:reset_pray()

	-- 몬스터 대기 시작
	self.monster_waiting_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_waiting, self, monster, fo))

	-- 페이드 인
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	-- 몬스터 대기 상태로 기억
	self.is_monster_waiting = true
end

-- 몬스터 기다리는 액션
function local_class:start_waiting(monster, fo)
	-- 석상 옆으로 이동
	monster.Position = fo.Position + vector(1, 0, 0)
	character_util.set_direction(monster, 'down')
	wait_for_sec(20)

	-- 초조
	for _ = 1, 10 do
		character_util.set_direction(monster, 'left')
		self:play_waiting_monster_sfx(monster, '01_swing_01')
		wait_for_sec(1)
		character_util.set_direction(monster, 'right')
		self:play_waiting_monster_sfx(monster, '01_swing_01')
		wait_for_sec(1)
	end
	character_util.set_direction(monster, 'down')
	-- 불안
	character_util.set_emotion(monster, { name = 'damaged' })
	self:play_waiting_monster_sfx(monster, '01_rustle_01')
	wait_for_sec(20)
	-- 분노
	character_util.set_emotion(monster, { name = 'bite' })
	self:play_waiting_monster_sfx(monster, '03_dialogue_negative_02')
	self.monster_waiting_coroutine = nil
end

-- 기다리는 몬스터에게 말 걸기
function local_class:talk_to_waiting_monster()
	local instance = self.pasture_pray_instance
	local fo = instance.getFieldObject
	local monster = instance.waitingMonster
	local rootPos = fo.Position + unity_class.vector3.back * 2.2
	local leaderPos  = rootPos + unity_class.vector3.left * 2
	local monsterPos = rootPos

	-- 대기 몬스터가 좋아함
	stop_coroutine(self.monster_waiting_coroutine)
	self:waiting_monster_sfx_off()
	coroutine.yield()

	character_util.remove_anim_and_emotion(monster)
	character_util.set_direction(monster, 'down')
	local targetPos = monster.Bounds.center + unity_class.vector3.back * 0.5
	character_util.align_party(targetPos, 'down', 0.5, 'linear')

	character_util.normal_double_jump(monster, true)
	character_util.set_anim_and_emotion(monster, { name = 'happy' }, { name = 'happy' })
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	character_util.show_emoticon(monster, nil, 'heart')
	wait_for_sec(2)

	coroutine.yield()

	CS.Oak.HeavenHoldPastureSystem.Instance.SoundManager:HalfStageBGM()

	-- 페이드 아웃
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 너굴걸 목장 뒤에 숨음
	local master = get_character(self.raccoon_handle_name)
	master.Position = fo.Position + vector(-0.22, 0, 0.5)
	character_util.set_anim(master, { name = 'walk4legs', scale = 0 })
	character_util.set_direction(master, 'left')
	character_util.set_emotion(master, { name = 'greed' })

	-- 플레이어 표정 변화
	character_util.set_direction(user_party.Leader, 'right')
	user_party.Leader.Position = leaderPos
	character_util.remove_anim_and_emotion(user_party.Leader)

	-- 몬스터 위치 이동
	monster.Position = monsterPos
	character_util.set_direction(monster, 'left')
	character_util.remove_anim_and_emotion(monster)

	-- 카메라 이동
	camera_util.move(rootPos, 0)

	-- 페이드 인
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	self:process_decision(instance)
end

-- 너굴걸 석상 뒤에서 달려나옴
function local_class:raccoon_reveal(master, firstPos, targetPos)
	music_player_util.play_sfx_one_shot('03_runaway_02')
	character_util.remove_emotion(master)
	self:face_to(master, firstPos)
	character_util.set_anim(master, { name = 'run' })
	character_util.move_to_async(master, firstPos, 0.5)
	self:face_to(master, targetPos)
	character_util.move_to_async(master, targetPos, 0.5)
	self:face_to(master, user_party.Leader.Position)
	character_util.set_animation_n_times(master, { name = 'release', count = 2, sfx = '01_swing_01' })
	character_util.set_emotion(master, { name = 'attack' })
	wait_for_sec(1)
	character_util.remove_anim_and_emotion(master)
end

-- 너굴걸 석상 뒤에 숨음
function local_class:raccoon_hide(master, firstPos, curPos)
	music_player_util.play_sfx_one_shot('03_runaway_02')
	character_util.remove_anim_and_emotion(master)
	self:face_to(master, firstPos)
	character_util.set_anim(master, { name = 'run' })
	character_util.move_to_async(master, firstPos, 0.5)
	self:face_to(master, curPos)
	character_util.move_to_async(master, curPos, 0.5)
	character_util.set_direction(master, 'down')
	character_util.set_anim(master, { name = 'walk4legs', scale = 0 })
	character_util.set_direction(master, 'left')
	character_util.set_emotion(master, { name = 'greed' })
	music_player_util.play_sfx_one_shot('01_gatcha_point_01')
end

-- 위치, 애니메이션 초기화
function local_class:reset_pray()
	local master = get_character(self.raccoon_handle_name)
	master.Position = self.raccoon_init_pos
	character_util.set_direction(master, 'down')
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.remove_anim_and_emotion(master)

	-- 카메라 리더에게 되돌림
	camera_util.move_async(get_party_leader().Position, 0, { end_target = user_party })
end

-- 대기 몬스터 효과음 재생
function local_class:play_waiting_monster_sfx(monster, sfx_name)
	self.waiting_monster_sfx = music_player_util.play_sfx({ sfx_name = sfx_name, loop = false, parent = monster,
															type_priority = 'event', player_priority = 'npc', max_distance = 5 })
end

-- 대기 몬스터 효과음 끄기
function local_class:waiting_monster_sfx_off()
	if self.waiting_monster_sfx ~= nil then
		self.waiting_monster_sfx:Stop()
		self.waiting_monster_sfx = nil
	end
end

-- endregion

-----------------------------------------------------------------------------------------------------------------

--region Event

function local_class:on_custom_stage_event(e)
	-- C#에 요청했던 작업이 완료됨
	if e:GetParamAt(0) == CS.Oak.PasturePrayInteractable.CSharpProcessEndParam[0] then
		self.wait_c_sharp_process = false
	elseif e:GetParamAt(0) == CS.Oak.PasturePrayInteractable.NetworkErrorParam[0] then
		self.wait_c_sharp_process = false
		self.network_error = true
	end

	return false
end

function local_class:on_interact_event(e)
	local target_name = e.Target.Name

	-- 대기 몬스터 인터랙션
	if target_name == self.waiting_monster_handle_name then
		self.raccoon_init_pos = get_character(self.raccoon_handle_name).Position
		CS.Oak.PastureMonsterController:BlockRunAway(self.pasture_pray_instance)
		sp_util.play_normal_screenplay(self.talk_to_waiting_monster, self)
	end

	return false
end

-- 석상에 기도했을 때 이벤트
function local_class:on_pasture_pray_event(e)
	self.raccoon_init_pos = get_character(self.raccoon_handle_name).Position
	sp_util.play_normal_screenplay(self.pray_statue, self, e.Instance)

	return true
end

-- 특정 위치를 바라봄
function local_class:face_to(fo, target_pos)
	local dir = vector_util.to_direction(target_pos - fo.Position)
	if dir ~= CS.Oak.Direction.None then
		fo.Direction = dir
	end
end

--endregion

return {
	create = function(data_path, data_key, cs_behaviour)
		return local_class(data_path, data_key, cs_behaviour)
	end
}
