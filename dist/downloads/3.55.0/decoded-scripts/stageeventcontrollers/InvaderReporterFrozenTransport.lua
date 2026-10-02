local local_class = newclass("InvaderReporterFrozenTransportController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 이벤트용 인베이더
	self.characters = nil

	-- 사진 촬영 Effect
	self.scoop_effect = nil
	-- 마법진 이펙트
	self.magic_circle = nil
	-- 붉은얼음 이펙트
	self.red_ices = nil

	-- 오브젝트 풀 이름
	self.scoop_effect_preset = 'invader_reporter_scoop_target'
	self.magic_circle_prset = 'MagicCircle_AppearIdle'
	self.teleport_effect_preset = 'FX_Event_InvaderBeam'
	self.red_ice_preset = 'fx_red_ice'

	self.cwp_ready_preset = 'fx_cwp_icestorm_cyclone_ready'
	self.cwp_screen_preset = 'fx_cwp_icestorm_screen'
	self.cwp_blue_preset = 'fx_cwp_icestorm_cyclone_blue'
	self.cwp_ice_crown_preset = 'FX_IceCrown'

	-- 커스텀 이벤트 이름
	self.get_photo = 'get_photo16'
	self.take_picture_coco = 'take_picture_coco'

	-- 1. 샘플 전송 이벤트 2. 코코 이벤트
	self.saw_event = { false, false }

	-- 클리어 여부
	self.is_cleared = false

	-- 스테이지 커스텀 State
	self.stage_custom_state = {
		frozen_transport = 6
	}

	-- 사운드
	self.magic_sfx = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate(self.magic_circle_prset)
	unity_object_pool.GetOrCreate(self.scoop_effect_preset)
	unity_object_pool.GetOrCreate(self.teleport_effect_preset)
	unity_object_pool.GetOrCreate(self.red_ice_preset)
	unity_object_pool.GetOrCreate(self.cwp_ready_preset)
	unity_object_pool.GetOrCreate(self.cwp_screen_preset)
	unity_object_pool.GetOrCreate(self.cwp_blue_preset)
	unity_object_pool.GetOrCreate(self.cwp_ice_crown_preset)

	self.characters = load_util.create_optimized_npcs_async({
		--얼려진 포로를 밀어 넣는 인베이더들
		invader_pusher_1 = 'demonwarrior',
		invader_pusher_2 = 'demonwarrior',

		-- 마법진으로 들어갈 얼려진 샘플
		sample = 'invader_transport_sample',

		-- 포로 잡아먹으려는 우측 인베이더
		--invader_1 = 'invader_elite_warrior',
		--invader_2 = 'invader_elite_archer',
		invader_1 = 'future_invader_archer',
		invader_2 = 'future_invader_warrior',

		-- 얼려질 포로들
		ice_bar_1 = 'invader_transport_snowman_male',
		ice_bar_2 = 'invader_transport_innuit_female'
	})
	-- 이펙트 로드 대기
	coroutine.yield(unity_object_pool.WaitAll())

	self.scoop_effect = unity_object_pool.GetOrCreate(self.scoop_effect_preset):Instantiate(
			field:GetMarker('frozen_camera_marker').position)
	self.scoop_effect.transform.gameObject:SetActive(false)

	if stage_progress:GetCustomData(self.stage_custom_state.frozen_transport, false) then
		self.is_cleared = true
	end

	if self.is_cleared == false then
		self:set_environment()
	else
		self:set_end()
	end

end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	-- 이펙트 해제
	if self.scoop_effect ~= nil then
		self.scoop_effect:Dispose()
		self.scoop_effect = nil
	end

	if self.magic_circle ~= nil then
		self.magic_circle:Dispose()
		self.magic_circle = nil
	end

	if self.red_ices ~= nil then
		for i = 1, #self.red_ices do
			self.red_ices[i]:Dispose()
		end
		self.red_ices = nil
	end

	if self.characters ~= nil then
		load_util.dispose_optimized_npcs(self.characters)
		self.characters = nil
	end

	if self.magic_sfx ~= nil then
		self.magic_sfx:Stop()
	end

	self.saw_event = nil

	self.cs_controller = nil
end

--region on event
function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

--function local_class:on_stage_start_event(e)
--end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party.Leader then return end
	local zone_name = e.Zone.Name

	if zone_name == 'frozen_transport_1' and self.saw_event[1] == false and self.is_cleared == false then

		self.saw_event[1] = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.transport, self))
	elseif zone_name == 'frozen_transport_2' and self.saw_event[2] == false and self.is_cleared == false then

		self.saw_event[2] = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.coco, self))
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.get_photo then
			self.scoop_effect:Dispose()
			self.scoop_effect = nil
		end
	end
end
--endregion

-- 이벤트 발생 전 스테이지 세팅
function local_class:set_environment()

	self.red_ices = {}
	for i = 1, 4 do
		local marker = field:GetMarker('frozen_ice_' .. i)
		unity_object_pool.GetOrCreate(self.red_ice_preset):Instantiate(marker.position)
	end

	-- 앞부분
	local push_npc = {self.characters['sample'], self.characters['invader_pusher_1'], self.characters['invader_pusher_2']}
	local push_marker = {field:GetMarker('frozen_sample'), field:GetMarker('frozen_pusher_1'), field:GetMarker('frozen_pusher_2')}

	for i = 1, 3 do
		character_util.set_position(push_npc[i], push_marker[i].position)
		character_util.set_direction(push_npc[i], push_marker[i].direction)

		if i == 1 then
			character_util.set_locked_dir(push_npc[i], 'right')
			character_util.set_anim_and_emotion(push_npc[i], {name = 'unique/ice'}, {name = 'scared'})
		else
			character_util.set_anim(push_npc[i], {name = 'push', upper = true})
		end
	end

	local magic_pos = field:GetMarker('frozen_magic_circle').position
	self.magic_circle = unity_object_pool.GetOrCreate(self.magic_circle_prset):Instantiate(magic_pos)
	self.magic_sfx = music_player_util.play_sfx({ sfx_name = '02_cast_magic_01', loop = true,
												  play_pos = magic_pos, volume = 0.1})

	-- 뒷부분
	local names = {'ice_bar_1', 'ice_bar_2', 'invader_1', 'invader_2'}
	for i = 1, #names do
		local npc = self.characters[names[i]]
		local marker = field:GetMarker('frozen_' .. names[i])
		character_util.set_position(npc, marker.position)

		character_util.set_direction(npc, marker.direction)

		-- TODO : 마커 조정
		if i == 1 then
			character_util.set_position(npc, npc.Position + vector(-0.5, 0, 0))
		end
		if i <= 2 then
			character_util.set_emotion(npc, {name = 'scared'})
			character_util.shake(npc, 0.04, 9999)
		end
	end
end

-- 이벤트 발생 후 스테이지 세팅
function local_class:set_end()

	self.red_ices = {}
	for i = 1, 4 do
		local marker = field:GetMarker('frozen_ice_' .. i)
		unity_object_pool.GetOrCreate(self.red_ice_preset):Instantiate(marker.position)
	end

	local magic_pos = field:GetMarker('frozen_magic_circle').position
	self.magic_circle = unity_object_pool.GetOrCreate(self.magic_circle_prset):Instantiate(magic_pos)
	self.magic_sfx = music_player_util.play_sfx({ sfx_name = '02_cast_magic_01', loop = true,
												  play_pos = magic_pos, volume = 0.1})

	-- 뒷부분
	local names = {'ice_bar_1', 'ice_bar_2'}
	local target_pos = nil
	for i = 1, #names do
		local npc = self.characters[names[i]]
		local marker = field:GetMarker('frozen_' .. names[i])
		character_util.set_position(npc, marker.position)

		character_util.set_direction(npc, marker.direction)

		-- TODO : 마커 조정
		if i == 1 then
			character_util.set_position(npc, npc.Position + vector(-0.5, 0, 0))
			character_util.set_emotion(npc, {name = 'scared'})
			character_util.set_anim(npc, {name = 'ice'})
		elseif i == 2 then
			target_pos = npc.Position + vector(-2.5, 0, 0)
			character_util.set_position(npc, target_pos)
			character_util.set_emotion(npc, {name = 'tired'})
			character_util.set_anim(npc, {name = 'release', loop = false, scale = 0})

			local red_ice = unity_object_pool.GetOrCreate(self.red_ice_preset)
											 :Instantiate(npc.Position + vector(0, 0, 0.1))
			red_ice.transform.localScale = vector(1.1, 1.1, 1.1)
			table.insert(self.red_ices, red_ice)
		end
	end

	local coco = get_character('coco')

	coco.SpineController:SetAttachment('[base]weapon1', 'cwp_innuit')
	character_util.set_anim(coco, {name = 'staff_idle'})
	character_util.set_position(coco, target_pos + vector(-1.2, 0, 0))

end

-- 얼려져있는 포로를 옮기는 첫번째 이벤트
function local_class:transport()
	local ice_bars = {self.characters['ice_bar_1'], self.characters['ice_bar_2']}
	for i = 1, #ice_bars do
		local npc = ice_bars[i]
		character_util.set_emotion(npc, {name = 'scared'})
	end

	local push_npc = {self.characters['sample'], self.characters['invader_pusher_1'], self.characters['invader_pusher_2']}

	for _ = 1, 4 do

		wait_for_sec(0.7)

		music_player_util.play_sfx({ sfx_name = '01_push_rock_unit_01', parent = push_npc[1]})
		for i = 1, #push_npc do
			local npc = push_npc[i]
			character_util.shake(npc, 0.02, 99)
			character_util.move_waypoint(npc, npc.Position + vector(-1, 0, 0), 1, false)
		end

		wait_for_sec(1)

		for i = 1, #push_npc do
			local npc = push_npc[i]
			character_util.stop_shake(npc)
		end

	end

	unity_object_pool.GetOrCreate(self.teleport_effect_preset):Instantiate(push_npc[1].Position)
	music_player_util.play_sfx({ sfx_name = '01_invader_beam_01', parent = push_npc[2]})

	-- 샘플 제외
	for i = 2, #push_npc do
		local npc = push_npc[i]
		character_util.remove_anim(npc, true)
	end

	wait_for_sec(0.2)

	character_util.set_position(push_npc[1], vector(999, 0, 999))

	wait_for_sec(1)

	for i = 2, #push_npc do
		local npc = push_npc[i]
		character_util.move_waypoint(npc, npc.Position + vector(2, 0, 0), 2, false)
	end

	wait_for_sec(1)

	character_util.move_waypoint_async(push_npc[3], { push_npc[3].Position + vector(1, 0, 0),
												push_npc[3].Position + vector(1, 0, 0.6) },
			2, false, nil, nil, 'left')

	character_util.set_animation_n_times(push_npc[2], {name = 'nod', count = 2})
	speech_bubble_util.show_speech_bubble_async(push_npc[2], { key = 'invader_reporter_transport_0' })
	--냉동 수단이 생겨서 모선에 신선한 샘플을 제공할 수 있게 됐어.

	character_util.set_anim(push_npc[3], {name = 'question', loop = false})
	speech_bubble_util.show_speech_bubble_async(push_npc[3], { key = 'invader_reporter_transport_1' })
	--그건 좋은데, 오염 생물의 손을 빌리는 건 조금…
end

-- 코코가 등장하는 두번째 이벤트
function local_class:coco()
	local coco = get_character('coco')
	local invaders = {self.characters['invader_1'], self.characters['invader_2']}
	local ice_bars = {self.characters['ice_bar_1'], self.characters['ice_bar_2']}

	coco.SpineController:SetAttachment('[base]weapon1', 'cwp_innuit')

	character_util.set_anim(invaders[1], {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(invaders[1], { key = 'invader_reporter_transport_2' })
	--톰슨, 이 놈들은 모선에 보낼 샘플이야.
	character_util.remove_anim(invaders[1])

	speech_bubble_util.show_speech_bubble_async(invaders[1], { key = 'invader_reporter_transport_3' })
	--우리가 손을 대선…

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = invaders[2]})
	camera_util.shake(0.3, 0.5)
	character_util.set_anim(invaders[2], {name = 'cast2'})
	speech_bubble_util.show_speech_bubble_async(invaders[2], { key = 'invader_reporter_transport_4', bubble_type = 'shout' })
	--시끄러! 난 지금 항체 수치가 지나치게 낮아져 있다고…

	character_util.set_animation_n_times(invaders[2], {name = 'nod', count = 2})
	speech_bubble_util.show_speech_bubble_async(invaders[2], { key = 'invader_reporter_transport_5' })
	--딱 한 놈이면 돼, 한 놈만 먹으면…

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = invaders[2]})
	character_util.set_anim(invaders[2], {name = 'push', upper = true})
	character_util.move_waypoint(invaders[2], invaders[2].Position + vector(1, 0, 0), 1)

	wait_for_sec(0.8)

	character_util.set_direction(invaders[1], 'right')

	character_util.stop_shake(ice_bars[1])
	local ice_effect = unity_object_pool.GetOrCreate(self.cwp_ice_crown_preset):Instantiate(ice_bars[1].Position + vector(0, 0, 0.5))
	music_player_util.play_sfx({ sfx_name = '02_ice_ridge_01', parent = ice_bars[1]})
	ice_effect.transform.localScale = vector(0.3, 0.3, 0.3)
	character_util.set_anim(ice_bars[1], {name = 'ice_start', loop = false})

	wait_for_sec(0.2)

	character_util.set_emotion(ice_bars[2], {name = 'surprise'})
	character_util.remove_anim(ice_bars[2])
	character_util.set_locked_dir(ice_bars[2], 'left')
	character_util.remove_anim(invaders[2], true)
	character_util.jump_move(ice_bars[2], ice_bars[2].Position + vector(1, 0, 0), 3,
			0.5, false, 'left')

	character_util.normal_jump(invaders[2])

	speech_bubble_util.show_speech_bubble_async(invaders[2], { key = 'invader_reporter_transport_6' })
	--…!

	character_util.spine_set_alpha_fade(coco, 0, 0)
	character_util.set_position(coco, field:GetMarker('frozen_coco').position)
	character_util.spine_set_alpha_fade(coco, 1, 0.5)

	character_util.set_anim(coco, {name = 'staff_walk'})
	character_util.move_waypoint_async(coco, coco.Position + vector(9, 0, 0), 3, false)

	character_util.set_anim(coco, {name = 'staff_idle'})

	character_util.set_emotion(ice_bars[2], {name = 'scared'})
	character_util.set_direction(invaders[1], 'left')
	character_util.set_direction(invaders[2], 'left')

	wait_for_sec(0.5)

	speech_bubble_util.show_speech_bubble_async(coco, { key = 'invader_reporter_transport_7' })
	--…군율 위반이야.

	speech_bubble_util.show_speech_bubble_async(invaders[2], { key = 'invader_reporter_transport_8' })
	--너…

	character_util.move_waypoint(invaders[2], coco.Position + vector(1, 0, 0), 4)
	speech_bubble_util.show_speech_bubble_async(invaders[2], { key = 'invader_reporter_transport_9' })
	--오염 종족 주제에 콧대만 높아서…

	character_util.set_emotion(coco, {name = 'tired'})
	character_util.set_anim(coco, {name = 'question', loop = false})
	speech_bubble_util.show_speech_bubble_async(coco, { key = 'invader_reporter_transport_10' })
	--…베스가 싫어할텐데?
	character_util.set_anim(coco, {name = 'staff_idle'})

	speech_bubble_util.show_speech_bubble_async(invaders[2], { key = 'invader_reporter_transport_11' })
	--…!!

	character_util.set_emotion(coco, {name = 'doyagao'})
	character_util.set_anim(coco, {name = 'bomb_idle'})
	speech_bubble_util.show_speech_bubble_async(coco, { key = 'invader_reporter_transport_12' })
	--감당할 수 있겠어?
	character_util.set_anim(coco, {name = 'staff_idle'})

	wait_for_sec(0.5)
	speech_bubble_util.show_speech_bubble_async(invaders[2], { key = 'invader_reporter_transport_13' })
	--……

	wait_for_sec(0.5)
	character_util.set_direction(invaders[2], 'right')
	speech_bubble_util.show_speech_bubble_async(invaders[2], { key = 'invader_reporter_transport_14' })
	--…가자.

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_and_fade,
			self, invaders[2], {invaders[2].Position + vector(0, 0, 0.5),
								invaders[2].Position + vector(-11, 0, 0.5)}))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_and_fade,
			self, invaders[1], {invaders[1].Position + vector(-13, 0, 0)}))

	character_util.remove_emotion(coco)
	wait_for_sec(1)

	character_util.stop_shake(ice_bars[2])
	character_util.set_emotion(ice_bars[2], {name = 'tired'})
	character_util.set_locked_dir(ice_bars[2], 'none')
	character_util.move_waypoint(ice_bars[2], {ice_bars[2].Position + vector(0, 0, -1),
													ice_bars[2].Position + vector(-3.5, 0, -1),
													ice_bars[2].Position + vector(-3.5, 0, 0)},
			5, true, nil, nil, 'left', true)

	character_util.set_anim(coco, {name = 'staff_walk'})
	character_util.move_waypoint_async(coco, coco.Position + vector(2, 0, 0), 2, false)
	character_util.set_anim(coco, {name = 'staff_idle'})

	character_util.set_anim(ice_bars[2], {name = 'sing'})

	speech_bubble_util.show_speech_bubble_async(ice_bars[2], { key = 'invader_reporter_transport_15' })
	--코, 코코…!

	speech_bubble_util.show_speech_bubble_async(ice_bars[2], { key = 'invader_reporter_transport_16' })
	--제발 목숨만은…

	character_util.set_anim(ice_bars[2], {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(ice_bars[2], { key = 'invader_reporter_transport_17' })
	--우, 우리 같은 고향 사람이잖…

	character_util.set_anim(coco, {name = 'staff_cast'})

	unity_object_pool.GetOrCreate(self.cwp_ready_preset):Instantiate(coco.Position)
	wait_for_sec(0.5)

	music_player_util.play_sfx({ sfx_name = '02_ice_cyclone_01', parent = coco})
	music_player_util.play_sfx({ sfx_name = '01_blizzard_02', parent = coco})

	unity_object_pool.GetOrCreate(self.cwp_screen_preset):Instantiate(coco.Position)
	unity_object_pool.GetOrCreate(self.cwp_blue_preset):Instantiate(coco.Position)
	wait_for_sec(0.5)

	character_util.set_anim(ice_bars[2], {name = 'release', loop = false, scale = 0})
	local red_ice = unity_object_pool.GetOrCreate(self.red_ice_preset)
			:Instantiate(ice_bars[2].Position + vector(0, 0, 0.1))
	red_ice.transform.localScale = vector(1.1, 1.1, 1.1)
	table.insert(self.red_ices, red_ice)

	self.scoop_effect.transform.gameObject:SetActive(true)

	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.take_picture_coco }))

	character_util.set_anim(coco, {name = 'staff_idle'})
end

function local_class:move_and_fade(character, waypoint)
	character_util.move_waypoint_async(character, waypoint, 4, false)
	character_util.spine_set_alpha_fade(character, 0, 0.5)

	wait_for_sec(0.5)

	character_util.set_position(character, vector(999, 0, 999))
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
