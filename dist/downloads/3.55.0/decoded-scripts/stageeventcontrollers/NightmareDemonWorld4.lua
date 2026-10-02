local local_class = newclass('NightmareDemonWorld4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	self.get_chris = function() return get_character('adventurer_chris') end

	self.is_interact_chris = false

	self.chris_key = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	if stage_progress:GetCustomData(self.chris_key) then
		self.is_interact_chris = true
	else
		local chris = self.get_chris()
		character_util.add_listener(chris, self.cs_controller)
		character_util.set_direction(chris, 'right')
		character_util.set_anim(chris, { name = 'eat' })
	end
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	if e:GetType() == typeof(CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	local chris = self.get_chris()

	if lua_helper.reference_equals(e.Target, chris) and not self.is_interact_chris then
		sp_util.play_normal_screenplay(self.interact_chris, self)
		return true
	end
	return false
end

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

function local_class:interact_chris()
	local chris = self.get_chris()
	local lilith = user_party.Leader

	self.is_interact_chris = true
	character_util.remove_relate_event(chris, self.cs_controller)

	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	party_util.align_party(chris.Position, 'down', 0.5, 'linear')

	character_util.normal_jump(lilith, '01_small_jump_01')

	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	-- 크리스?!
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_1', skip = true })

	eat_sfx:Stop()
	character_util.remove_anim_and_emotion(chris)
	character_util.set_direction(chris, 'down')
	character_util.normal_jump(chris, '01_small_jump_01')

	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	-- 리리스! 어쩐지 121초만 더 이곳에 서 있으면 마주칠 것 같더라니.
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_2', skip = true })
	-- 어디 보자… 실제로는 117.3초만에 마주쳤으니까 ±4.1초의 오차 범위 안에서 적중했군.
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_3', skip = true })

	character_util.normal_double_jump(lilith, '01_small_jump_01')
	-- 뭐야, 마계엔 언제 온 거야!
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_4', skip = true })

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(lilith, 'right')
	character_util.set_anim_and_emotion(lilith, { name = 'cross_arm' }, { name = 'doyagao'})
	--내가 맞춰볼까?
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_5', skip = true })

	character_util.set_anim(lilith, { name = 'bomb_idle' })
	-- 마계 도시 대기 중 금속원소 성분의 특성을 연구하러 온 거야?
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_6', skip = true })

	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	character_util.set_anim(lilith, { name = 'cast2' })
	--아니면 방법론적 특징을 통해 마족 청소년들을 교육인류학적으로 분석하려고?
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_7', skip = true })

	character_util.remove_anim_and_emotion(lilith)
	character_util.set_direction(lilith, 'up')

	character_util.set_anim(chris, { name = 'cast' })
	--하하하. 리리스, 아무 어려운 말이나 붙이면 내가 하는 일인 줄 알아?
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_8', skip = true })
	-- …….
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_9', skip = true })

	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	character_util.remove_anim(chris)
	-- 사실 둘 다 맞아.
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_9_1', skip = true })

	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	-- 역시 한결같아, 크리스.
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_9_2', skip = true })
	--그런데…
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_10', skip = true })

	character_util.normal_jump(chris, '01_player_jump_01')
	camera_util.shake(0.1, 0.2)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	character_util.set_anim(chris, { name = 'cast', scale = 2 })
	-- 그 하트 모양 안경은 도대체 뭐야?!
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_11', skip = true })

	character_util.set_anim(chris, { name = 'cast' })
	--에리나가 500년 전에 선물해준 걸 아직도 쓰고 다녀?
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_12', skip = true })

	character_util.remove_anim(chris)
	character_util.set_animation_n_times(lilith, {name = 'release', count = 2, sfx = '01_swing_01'})
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	--그, 그게 뭐 어쨌다는 거야!
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_13', skip = true })

	-- 아무튼, 마계엔 언제까지 머무르려고?
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_14', skip = true })
	-- 사실 이제 곧 떠나려던 참이야. 이번에는 독특한 기후를 가진 설산이란 곳을 가볼까 해. 일 평균 기온이 -32.75도라더군.
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_15', skip = true })

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(lilith, 'right')
	character_util.set_anim(lilith, { name = 'cross_arm' })
	-- 인간 세계 말이지…? 현재로서 교신이 조금 어렵긴 하겠어.
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_16', skip = true })

	character_util.remove_anim_and_emotion(lilith)
	-- 그치만 뭐, 시도해볼 수는 있을 테니까.
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_17', skip = true })

	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_direction(lilith, 'up')
	character_util.nod_twice(lilith)
	-- 그쪽으로 연락할게.
	speech_bubble_util.show_speech_bubble_async(lilith, { key = 'nightmare_demonworld_chris_18', skip = true })

	character_util.set_anim(chris, { name = 'cast' })
	--그래, 리리스. 연락 기다리고 있을게.
	speech_bubble_util.show_speech_bubble_async(chris, { key = 'nightmare_demonworld_chris_19', skip = true })

	character_util.remove_anim(chris)

	local stage_custom = stage_progress:SetCustomData(self.chris_key, true)
	local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
	coroutine.yield(req)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}