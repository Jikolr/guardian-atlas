local local_class = newclass("NightmareTeatans1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.ifo_util = CS.Oak.IFieldObjectExtensions

	self.dragon_origin_id = 209
	-- 드래곤이 몇번째 파티원인지 나타내는 index
	self.dragon_member_index = -1

	self.dragon_citizens_name = 'dragon_citizen_'
	self.dragon_girlfriend_name = 'dragon_girlfriend'
	self.warrior_freezer_name = 'warrior_freezer'
	self.freezer_trans_name = 'freezer_trans'

	self.is_talking = false
	self.earned_dragon_star_piece = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	unity_object_pool.GetOrCreate('fx_laser_event_super')
	unity_object_pool.GetOrCreate('fx_laser_event_dark')
	unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	unity_object_pool.GetOrCreate('FX_explosion_dark')
	unity_object_pool.GetOrCreate('FX_dash')
	unity_object_pool.GetOrCreate('FX_reset_object')

	-- 연출을 위해서 싸우지 않도록
	local freezer_trans = get_character(self.freezer_trans_name)
	freezer_trans.FieldObjectController.DontFight = true
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	if self.aura_effect ~= nil then
		self.aura_effect:Dispose()
	end

	self.aura_effect = nil

	self.cs_controller = nil
	self.ifo_util = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

		local zone_name = e.Zone.Name
		if zone_name == 'dragon_and_freezer' and not self.is_talking and not self.earned_dragon_star_piece then
			self.is_talking = true

			for i = 0, user_party.Count - 1 do
				-- 파티원에 드래곤 있는지 체크
				local origin_id = user_party[i].CharacterStatsBehaviour.CharacterSpec.OriginId
				-- 죽어 있으면 드래곤이 없다고 판담함
				local  dragon_dead = user_party[i].FieldObjectStatsBehaviour.IsDead
				if origin_id == self.dragon_origin_id and not dragon_dead then
					self.dragon_member_index = i
					coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.first_battle_freezer, self, user_party[i]))
					return true
				end
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.is_not_dragon, self))
			return true
		end
	end

	if event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		if e.BattleGroupName == "battle_freezer" then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.end_battle, self))
			return true
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		if stage_progress:HasStarPiece('dragon_star_piece') then
			self.earned_dragon_star_piece = true
			local dragon_girlfriend = get_character(self.dragon_girlfriend_name)
			dragon_girlfriend.Position = vector(999, 0, 999)
			local warrior_freezer = get_character(self.warrior_freezer_name)
			warrior_freezer.Position = vector(999, 0, 999)
		end
		return true
	end

	return false
end

-- 파티에 드래곤이 없을 때
function local_class:is_not_dragon()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local warrior_freezer = get_character(self.warrior_freezer_name)
	local pos = warrior_freezer.Position + 2 * unity_class.vector3.forward
	user_party:PositionParty(pos, CS.Oak.Direction.Down, 1, CS.Oak.Party.AlignType.Arc)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	character_util.set_anim(warrior_freezer, { name = 'jingak', loop = false, remove_after = 1 })

	music_player:PlaySfxOneShot('02_goblin_appear_01')

	-- 드래곤… 드래곤은 어디있습니까?
	local string_key = 'nightmare_teatan_5_battle_freezer_1'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	character_util.remove_anim(warrior_freezer)
	character_util.set_direction(warrior_freezer, 'up')

	-- 당신은… 드래곤과 함께 있었던 기사.
	string_key = 'nightmare_teatan_5_battle_freezer_2'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	-- 드래곤에게 전하세요. 빨리 오지 않으면...
	string_key = 'nightmare_teatan_5_battle_freezer_3'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	music_player:PlaySfxOneShot('03_dialogue_negative_01')

	-- 일라이자의 목숨이 위험하다고!
	string_key = 'nightmare_teatan_5_battle_freezer_22'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	character_util.set_anim(warrior_freezer, { name = 'attack', loop = false })
	coroutine.yield(coroutine_class.wait_for_sec(0.2))

	music_player:PlaySfxOneShot('02_hit_dark_01')
	music_player:PlaySfxOneShot('02_explosion_01')

	local explosion_dark_effect_pool = unity_object_pool.GetOrCreate('FX_explosion_dark')
	explosion_dark_effect_pool:Instantiate(user_party_leader.Position)
	camera_util.shake(0.5, 0.5)

	-- 파티원들 넉백
	for i = 0, user_party.Count - 1 do
		pos = user_party[i].Position + 3 * unity_class.vector3.forward
		character_util.set_emotion(user_party[i], { name = 'hurt' })
		character_util.set_anim(user_party[i], { name = 'damaged' })
		user_party[i].SpineController:DamageSquish(1)
		user_party[i].SpineController:DamageRedPulse()
		coroutine_manager:StartCoroutine(stage.StageGameObject,
			self.ifo_util.MoveTo(user_party[i], pos, 0.5, nil, false, false))
	end
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 넘어지는 sfx
	music_player:PlaySfxOneShot('01_hit_npc_01')

	character_util.remove_anim(warrior_freezer)

	for i = 0, user_party.Count - 1 do
		character_util.set_direction(user_party[i], 'right')
		character_util.remove_anim(user_party[i])
		character_util.set_anim(user_party[i], { name = 'prostrate' })
	end

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 부르르 떠는 sfx
	music_player:PlaySfxOneShot('01_rustle_01')

	-- 파티원들 일어남
	for i = 0, user_party.Count - 1 do
		character_util.shake(user_party[i], 0.05, 1)
	end
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 팝업 sfx
	music_player:PlaySfxOneShot('01_player_popup_01')

	for i = 0, user_party.Count - 1 do
		character_util.remove_anim(user_party[i])
		character_util.remove_emotion(user_party[i])
		character_util.set_direction(user_party[i], 'down')
		character_util.jump(user_party[i], 0.4, 0.4)
	end

	character_util.set_direction(warrior_freezer, 'left')

	self.is_talking = false

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 드래곤이 파티원이 있을 때
function local_class:first_battle_freezer(dragon)
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local warrior_freezer = get_character(self.warrior_freezer_name)
	local pos = warrior_freezer.Position
	coroutine.yield(self:party_move_up_down(dragon, pos, 2, CS.Oak.Direction.Up, 1))

	character_util.set_emotion(dragon, { name = 'attack' })

	-- bgm_transition: Field(bgm_teatans_main) -> Muted, 1.3
	music_player_util.play_stage_music({
		state = 'muted', mix = 1.3
	})

	-- 푸리자!
	local string_key = 'nightmare_teatan_5_battle_freezer_24'
	speech_bubble_util.show_speech_bubble_async(dragon, { key = string_key, skip = true })

	character_util.set_direction(warrior_freezer, 'up')

	-- bgm_transition: Muted -> Event(bgm_battle_event), 0
	music_player_util.play_stage_music({
		name = 'bgm_battle_event', state = 'event', mix = 0
	})

	-- 이기는… 드래곤! 드디어 나타났군요.
	string_key = 'nightmare_teatan_5_battle_freezer_4'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	character_util.set_anim(warrior_freezer, { name = 'attack', loop = false })

	music_player:PlaySfxOneShot('02_hit_dark_01')

	local explosion_dark_effect_pool = unity_object_pool.GetOrCreate('FX_explosion_dark')
	explosion_dark_effect_pool:Instantiate(dragon.Position)

	camera_util.move(user_party_leader.Position, 0)

	-- 순간이동 sfx
	music_player:PlaySfxOneShot('01_guild_warp_01')

	-- 드래곤 순간이동
	local teleport_effect_pool = unity_object_pool.GetOrCreate('FX_reset_object')
	teleport_effect_pool:Instantiate(dragon.Position)
	dragon.Position = warrior_freezer.Position + 4 * unity_class.vector3.left
	teleport_effect_pool:Instantiate(dragon.Position)
	character_util.set_direction(dragon, 'right')

	-- 카메라 이동
	local marker = field:GetMarker('camera_freezer').position
	camera_util.move_async(marker, 1)

	local dragon_girlfriend = get_character('dragon_girlfriend')
	character_util.set_direction(dragon_girlfriend, 'left')

	character_util.set_direction(warrior_freezer, 'left')
	character_util.remove_anim(warrior_freezer)

	pos = warrior_freezer.Position
	coroutine.yield(self:party_move(dragon, pos, 4, CS.Oak.Direction.Left, 1))

	coroutine.yield(coroutine_class.wait_for_sec(0.7))

	-- 소용없다. 푸리자!
	string_key = 'nightmare_teatan_5_battle_freezer_34'
	speech_bubble_util.show_speech_bubble_async(dragon, { key = string_key, skip = true })

	character_util.remove_emotion(dragon)

	-- 잔재주가 늘었군요.
	string_key = 'nightmare_teatan_5_battle_freezer_35'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	-- 비겁하게 나의 연인 일라이자와 시민들을 납치하다니!
	string_key = 'nightmare_teatan_5_battle_freezer_5'
	speech_bubble_util.show_speech_bubble_async(dragon, { key = string_key, skip = true })

	character_util.set_emotion(dragon, { name = 'mad'})
	character_util.set_anim(dragon, { name = 'jingak', loop = false, sfx_name = '01_hit_npc_01' })
	coroutine.yield(coroutine_class.wait_for_sec(0.7))

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')

	-- 용서할 수 없다!
	string_key = 'nightmare_teatan_5_battle_freezer_6'
	speech_bubble_util.show_speech_bubble_async(dragon, { key = string_key, skip = true })

	character_util.remove_anim(dragon)
	character_util.remove_emotion(dragon)

	music_player:PlaySfxOneShot('02_die_goblin_01')

	-- 오호호호호!!! 자비를 베풀어드리죠.
	string_key = 'nightmare_teatan_5_battle_freezer_7'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	character_util.set_anim(warrior_freezer, { name = 'jingak', loop = false })
	character_util.set_emotion(warrior_freezer, { name = 'mad' })
	coroutine.yield(coroutine_class.wait_for_sec(0.7))

	music_player:PlaySfxOneShot('01_player_jump_01')
	music_player:PlaySfxOneShot('03_dialogue_negative_01')

	character_util.set_emotion(dragon_girlfriend, { name = 'surprise' })
	character_util.jump(dragon_girlfriend, 0.3, 0.3)

	-- 어서 꺼져!
	string_key = 'nightmare_teatan_5_battle_freezer_8'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	character_util.remove_anim(warrior_freezer)
	character_util.remove_emotion(warrior_freezer)
	character_util.remove_emotion(dragon_girlfriend)
	character_util.remove_anim(dragon_girlfriend)

	character_util.set_emotion(dragon_girlfriend, { name = 'scared' })

	dragon_girlfriend.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	-- 드래곤...
	string_key = 'nightmare_teatan_5_battle_freezer_23'
	speech_bubble_util.show_speech_bubble(dragon_girlfriend, { key = string_key })

	-- 일라이자 밑으로 내려감
	pos = dragon_girlfriend.Position + 3.5 * unity_class.vector3.back
	coroutine.yield(self.ifo_util.MoveTo(dragon_girlfriend, pos, nil, 7, true, true, true))

	character_util.remove_emotion(dragon_girlfriend)
	character_util.set_direction(dragon_girlfriend, 'up')
	coroutine.yield(coroutine_class.wait_for_sec(0.3))

	character_util.remove_anim(warrior_freezer)
	character_util.set_anim(warrior_freezer, { name = 'cast' })

	-- 자 이제… 결착을 낼 때가 된 것 같군요.
	string_key = 'nightmare_teatan_5_battle_freezer_9'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key, skip = true })

	music_player:PlaySfxOneShot('01_earthquake_01')

	camera_util.shake(0.05, 4)
	-- 보여주지… 나의 진정한 모습을…!
	string_key = 'nightmare_teatan_5_battle_freezer_12'
	speech_bubble_util.show_speech_bubble_async(warrior_freezer, { key = string_key })

	character_util.remove_emotion(dragon)

	music_player:PlaySfxOneShot('02_magic_shield_01')

	-- bgm_transition: Event(bgm_battle_event) -> Muted
	music_player_util.play_stage_music({
		state = 'muted'
	})

	-- 전투 후에 Muted (정확히는 Fanfare State에서 멈춰있음) 상태로 바로 바뀌도록 필드 bgm을 비워둔다.
	music_player_util.remove_stage_music_clip({
		state = 'field'
	})

	-- 프리저 변신 씬
	screen_util.fade_out_async(1, unity_class.color.white, CS.Oak.Interpolations.Linear)

	local aura_effect_pool = unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	local freezer_trans = get_character(self.freezer_trans_name)
	self.aura_effect = aura_effect_pool:Instantiate(freezer_trans.Position,
		unity_class.quaternion.identity, freezer_trans.Transform)
	freezer_trans.Position = warrior_freezer.Position
	warrior_freezer.Position = vector(999, 0, 999)

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 기 루프 sfx 재생
	local cast_sfx = music_player_util.play_sfx({
		sfx_name = '02_cast_magic_01', loop = true, fade_in_time = 1, type_priority = 'loop'
	})

	screen_util.fade_in_async(2, unity_class.color.white, CS.Oak.Interpolations.Linear)

	for k, v in pairs(user_party) do
		character_util.set_emotion(v, { name = 'surprise' })
	end

	music_player:PlaySfxOneShot('03_dialogue_negative_01')

	-- 엄청난 기… 위험해!
	string_key = 'nightmare_teatan_5_battle_freezer_13'
	speech_bubble_util.show_speech_bubble_async(dragon, { key = string_key, skip = true })

	for k, v in pairs(user_party) do
		character_util.remove_emotion(v)
		character_util.set_emotion(v, { name = 'attack' })
	end

	-- 죽음보다 두려운 공포가 무엇인지 가르쳐주지.
	string_key = 'nightmare_teatan_5_battle_freezer_14'
	speech_bubble_util.show_speech_bubble_async(freezer_trans, { key = string_key, skip = true })

	for k, v in pairs(user_party) do
		character_util.remove_emotion(v)
	end

	-- 기 루프 sfx 중지
	cast_sfx:FadeOut()

	character_util.remove_anim(freezer_trans)
	character_util.remove_emotion(freezer_trans)
	camera_util.move(user_party_leader.Position, 0.5, { end_target = user_party_leader })

	field_ui_manager:Show()
	user_party:ResetControllers()

	freezer_trans.FieldObjectController.DontFight = false
end

-- 프리저와 전투 종료
function local_class:end_battle()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 화면 전환
	screen_util.fade_out_async(0.7, unity_class.color.black, CS.Oak.Interpolations.Linear)

	local marker = field:GetMarker('camera_freezer').position
	camera_util.move(marker, 0)

	local freezer_trans = get_character(self.freezer_trans_name)
	marker = field:GetMarker('end_battle_freezer').position
	freezer_trans.Position = marker + 5.5 * unity_class.vector3.right
	character_util.set_direction(freezer_trans, 'left')

	local dragon = user_party[self.dragon_member_index]
	coroutine.yield(self:party_move(dragon, marker, 4.5, CS.Oak.Direction.Left, 0))
	character_util.set_emotion(freezer_trans, { name = 'tired' })

	local party_pos_index = 0
	for i = 0, user_party.Count - 1 do
		if not lua_helper.reference_equals(user_party[i], dragon) then
			marker = field:GetMarker('prostrate_party_' .. party_pos_index).position
			user_party[i].Position = marker
			character_util.set_emotion(user_party[i], { name = 'hurt' })
			character_util.set_anim(user_party[i], { name = 'prostrate', loop = false, scale = 100 })
			party_pos_index = party_pos_index + 1
		end
	end

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	screen_util.fade_in_async(0.7, unity_class.color.black, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 어째서… 우주 최강인 내가…
	local string_key = 'nightmare_teatan_5_battle_freezer_15'
	speech_bubble_util.show_speech_bubble_async(freezer_trans, { key = string_key, skip = true })

	-- 푸리자… 그 정도 힘으로는 날 이길 수 없다!
	string_key = 'nightmare_teatan_5_battle_freezer_16'
	speech_bubble_util.show_speech_bubble_async(dragon, { key = string_key, skip = true })

	character_util.remove_emotion(freezer_trans)
	character_util.set_emotion(freezer_trans, { name = 'mad' })

	-- 우...  웃기지마!
	string_key = 'nightmare_teatan_5_battle_freezer_17'
	speech_bubble_util.show_speech_bubble_async(freezer_trans, { key = string_key, skip = true })

	character_util.set_anim(freezer_trans, { name = 'boong_attack_ready_loop' })

	music_player:PlaySfxOneShot('01_rustle_01')

	-- 난… 우주 최강…
	string_key = 'nightmare_teatan_5_battle_freezer_18'
	speech_bubble_util.show_speech_bubble_async(freezer_trans, { key = string_key, skip = true })

	-- 지진 sfx 루프 재생
	local shake_sfx = music_player_util.play_sfx({
		sfx_name = '01_earthquake_03', loop = true, fade_in_time = 0.5, type_priority = 'loop'
	})

	-- 넌 나에게…
	string_key = 'nightmare_teatan_5_battle_freezer_25'

	-- TODO: skip가능해지면 force_sfx 해제할것
	speech_bubble_util.show_speech_bubble_async(freezer_trans, { key = string_key, force_sfx = true })

	music_player:PlaySfxOneShot('03_dialogue_negative_01')

	-- 쓰러져야만 한단 말이다!
	string_key = 'nightmare_teatan_5_battle_freezer_19'

	-- TODO: skip가능해지면 force_sfx 해제할것
	speech_bubble_util.show_speech_bubble(freezer_trans, { key = string_key, force_sfx = true })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	camera_util.resize_to(3, 0.5)
	camera_util.move_async(dragon.Position, 0.5)

	character_util.set_direction(dragon, 'down')

	character_util.set_anim(dragon, { name = 'idle', scale = 3 })
	character_util.set_emotion(dragon, { name = 'mad' })

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	music_player:PlaySfxOneShot('02_hit_light_01')

	-- 지진 sfx 중지
	shake_sfx:FadeOut()

	-- 변신 번쩍번쩍 연출
	screen_util.fade_in_async(0.1, unity_class.color.white, CS.Oak.Interpolations.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(0.1))
	screen_util.fade_in_async(0.1, unity_class.color.white, CS.Oak.Interpolations.Linear)

	-- 드래곤 변신
	local dragon_trans = get_character('dargon_saiyan_trans')
	character_util.set_direction(dragon_trans, 'down')
	character_util.set_anim(dragon_trans, { name = 'idle', scale = 4 })
	character_util.set_emotion(dragon_trans, { name = 'mad' })
	dragon_trans.Position = dragon.Position
	dragon.Position = vector(999, 0, 999)

	music_player:PlaySfxOneShot('02_stomp_fire_01')

	-- bgm_transition: Muted -> Event(bgm_battle_event), 0
	music_player_util.play_stage_music({
		name = 'bgm_battle_event', state = 'event', mix = 0
	})

	local fx_dash_pool = unity_object_pool.GetOrCreate('FX_dash')
	local dash_effect = fx_dash_pool:Instantiate(dragon_trans.Position + 0.2 * unity_class.vector3.forward)
	dash_effect.transform.localRotation = unity_class.quaternion.Euler(0, -90, 0)
	dash_effect.transform.localScale = unity_class.vector3.one * 1.2
	camera_util.shake(0.3, 1)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 레이저 기 모으기
	character_util.set_direction(dragon_trans, 'right')
	character_util.set_anim(dragon_trans, { name = 'boong_attack_ready_loop' })

	-- 카메라 센터로 이동
	camera_util.resize_to(CS.Oak.StageCamera.DefaultCameraSize, 0.5)
	marker = field:GetMarker('camera_freezer').position
	camera_util.move(marker, 0.5)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	music_player:PlaySfxOneShot('03_dialogue_negative_01')

	-- 멍청한 놈!
	string_key = 'nightmare_teatan_5_battle_freezer_26'
	speech_bubble_util.show_speech_bubble(dragon_trans, { key = string_key, life_time = 3, bubble_type = 'shout' })
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 드래곤 레이저 발사
	character_util.remove_anim(dragon_trans)
	character_util.set_anim(dragon_trans, { name = 'boong_attack', loop = false })
	dash_effect.transform.position = dash_effect.transform.position + 0.1 * unity_class.vector3.right

	-- 레이저 sfx 재생 (연출이 먼저 끝날경우 끊어주기위해 오디오소스 홀더로 재생)
	local laser_sfx = music_player_util.play_sfx({
		sfx_name = '02_light_laser_03'
	})

	-- 레이저 영향 앰비언스 sfx 재생
	local fire_sfx = music_player_util.play_sfx({
		sfx_name = '01_fire_02', loop = true, fade_in_time = 0.5, type_priority = 'loop'
	})

	local pos = dragon_trans.Position + vector(1.3, 0, 0.3)
	local laser_super_effect_pool = unity_object_pool.GetOrCreate('fx_laser_event_super')
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.laser, self, pos, 0, 0.3, 0.1, 0, 1.2, 180, laser_super_effect_pool))

	-- 프리저 레이저 발사
	character_util.remove_anim(freezer_trans)
	character_util.set_anim(freezer_trans, { name = 'boong_attack', loop = false })

	local laser_dark_effect_pool = unity_object_pool.GetOrCreate('fx_laser_event_dark')
	pos = freezer_trans.Position + vector(-1, 0, 0.3)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.laser, self, pos, 0, 0.5, 0.1, 0, 0.8, 0, laser_dark_effect_pool))

	coroutine.yield(coroutine_class.wait_for_sec(0.1))

	camera_util.shake(0.08, 3.5)
	coroutine.yield(coroutine_class.wait_for_sec(0.6))

	-- 프리저가 살짝 이기는 레이저
	pos = dragon_trans.Position + vector(1.3, 0, 0.3)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.laser, self, pos, 0.3, 0.2, 1.2, 0.2, 0.7, 180, laser_super_effect_pool))

	pos = freezer_trans.Position + vector(-1, 0, 0.3)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.laser, self, pos, 0.5, 0.62, 1.2, 0.2, 0.7, 0, laser_dark_effect_pool))

	coroutine.yield(coroutine_class.wait_for_sec(1.9))

	-- 드래곤 살짝 이기는 레이저
	pos = dragon_trans.Position + vector(1.3, 0, 0.3)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.laser, self, pos, 0.2, 0.35, 1.2, 0.2, 0, 180, laser_super_effect_pool))

	pos = freezer_trans.Position + vector(-1, 0, 0.3)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.laser, self, pos, 0.62, 0.45, 1.2, 0.2, 0, 0, laser_dark_effect_pool))

	coroutine.yield(coroutine_class.wait_for_sec(1.2))

	camera_util.shake(0.3, 2.5)

	music_player:PlaySfxOneShot('02_impact_lightning_01')

	-- 레이저 sfx 중지
	laser_sfx:FadeOut()

	-- 레이저 영향 앰비언스 sfx 중지
	fire_sfx:FadeOut()

	-- 드래곤이 압도적인 레이저
	pos = dragon_trans.Position + vector(1.3, 0, 0.3)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.laser, self, pos, 0.35, 1.5, 0.2, 0.2, 3, 180, laser_super_effect_pool))

	pos = freezer_trans.Position + vector(-1, 0, 0.3)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.laser, self, pos, 0.45, 0, 0.05, 0.2, 0, 0, laser_dark_effect_pool))

	coroutine.yield(coroutine_class.wait_for_sec(0.2))

	self.aura_effect:Dispose()

	-- 스타피스 배치
	local star_piece = get_field_object('dragon_star_piece')
	star_piece.Position = freezer_trans.Position

	-- 일라이자 기뻐함
	local dragon_girlfriend = get_character(self.dragon_girlfriend_name)
	character_util.remove_emotion(dragon_girlfriend)
	character_util.set_direction(dragon_girlfriend, 'left')
	character_util.set_emotion(dragon_girlfriend, { name = 'love' })
	character_util.set_anim(dragon_girlfriend, { name = 'sing' })

	-- 프리저 날아감
	character_util.remove_anim(freezer_trans)
	character_util.remove_emotion(freezer_trans)
	character_util.set_emotion(freezer_trans, 'damaged')

	character_util.jump(freezer_trans, 2, 1)
	character_util.spine_rotate(freezer_trans, 360 * 3, 1)
	pos = freezer_trans.Position + vector(5, 0, 3)
	coroutine.yield(self.ifo_util.MoveTo(freezer_trans, pos, 1, nil, false, false))

	freezer_trans.Position = vector(999, 0, 999)
	coroutine.yield(coroutine_class.wait_for_sec(2.4))

	character_util.remove_anim(dragon_trans)
	character_util.remove_emotion(dragon_trans)
	coroutine.yield(coroutine_class.wait_for_sec(2))

	-- 전투 시작전에 필드음악 비워주었으므로 name 같이 넘겨야함!
	-- bgm_transition: Event(bgm_battle_event) -> Field(bgm_teatans_main)
	music_player_util.play_stage_music({
		name = 'bgm_teatans_main', state = 'field'
	})

	-- 화면 전환
	screen_util.fade_out_async(0.7, unity_class.color.black, CS.Oak.Interpolations.Linear)

	character_util.remove_anim(dragon_girlfriend)
	character_util.remove_emotion(dragon_girlfriend)

	dash_effect:Dispose()
	dragon_trans.Position = vector(999, 0, 999)

	marker = field:GetMarker('camera_freezer').position
	dragon.Position = marker + 0.5 * unity_class.vector3.left
	dragon_girlfriend.Position = marker + 0.5 * unity_class.vector3.right
	dragon_girlfriend.OverrideCrashBehaviour = nil

	local party_pos = {marker + vector(0, 0, 1), marker + vector(-1, 0, 1),
					   marker + vector(1, 0, 1), marker + vector(-2, 0, 1)}

	local pos_index = 1
	for k, v in pairs(user_party) do
		if not lua_helper.reference_equals(v, dragon) then
			v.Position = party_pos[pos_index]
			pos_index = pos_index + 1
			character_util.remove_anim(v)
			character_util.remove_emotion(v)
			character_util.set_direction(v, 'down')
		end
	end

	character_util.remove_anim(dragon)
	character_util.remove_emotion(dragon)
	character_util.set_direction(dragon, 'right')
	character_util.set_emotion(dragon, { name = 'smile' })
	character_util.set_emotion(dragon_girlfriend, { name = 'smile' })

	dash_effect:Dispose()

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	screen_util.fade_in_async(0.7, unity_class.color.black, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 일라이자! 괜찮아?
	string_key = 'nightmare_teatan_5_battle_freezer_36'
	speech_bubble_util.show_speech_bubble_async(dragon, { key = string_key, skip = true })

	-- 물론이지!
	string_key = 'nightmare_teatan_5_battle_freezer_37'
	speech_bubble_util.show_speech_bubble_async(dragon_girlfriend, { key = string_key, skip = true })

	-- 푸리자는 사라졌으니 이제 더 이상 걱정하지마.
	string_key = 'nightmare_teatan_5_battle_freezer_38'
	speech_bubble_util.show_speech_bubble_async(dragon, { key = string_key, skip = true })

	character_util.set_emotion(dragon_girlfriend, { name = 'love' })
	character_util.set_anim(dragon_girlfriend, { name = 'sing' })

	music_player:PlaySfxOneShot('03_dialogue_positive_01')

	-- 고마워. 드래곤!
	string_key = 'nightmare_teatan_5_battle_freezer_39'
	speech_bubble_util.show_speech_bubble_async(dragon_girlfriend, { key = string_key, skip = true })

	music_player:PlaySfxOneShot('01_gatcha_point_01')

	-- 강한 드래곤의 모습은 언제나 멋있어!
	string_key = 'nightmare_teatan_5_battle_freezer_40'
	speech_bubble_util.show_speech_bubble_async(dragon_girlfriend, { key = string_key, skip = true })

	camera_util.move(user_party_leader.Position, 0.5, { end_target = user_party_leader })
	dragon_girlfriend.Interactable.Talk = 'nightmare_teatan_5_battle_freezer_40'

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 파티원 특정 정렬 (리더가 중심이 아닌 특정 캐릭터를 중심으로 정렬)
-- target = 중심이 되는 캐릭터
-- pos = 정렬할 위치
-- dist = 정할 위치로 부터 거리
-- direction = 이동 방향
-- move_duration = 이동 시간
function local_class:party_move(target, pos, dist, direction, move_duration)
	-- 방향 값 (default = left)
	local dir = -1
	if direction == CS.Oak.Direction.Right then
		dir = 1
	end

	local target_pos = pos + vector(dir * dist, 0, 0)

	-- 중심 캐릭터 이동
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		self.ifo_util.MoveTo(target, target_pos, move_duration, nil, false, false))

	-- 파티원들 지정 위치로 이동
	local party_pos = {
		target_pos + vector(0.75 * dir, 0, -0.5),
		target_pos + vector(0.75 * dir, 0, 0.5),
		target_pos + vector(1.5 * dir, 0, 0),
		target_pos + vector(1.75 * dir, 0, 0.5)}

	-- 중심이 아닌 캐릭터는 지나가기 때문에 새로운 index 값 사용 (continue가 없어서)
	local party_pos_index = 1
	for k, v in pairs(user_party) do
		-- 중심이 아닌 캐릭터들 이동
		if not lua_helper.reference_equals(v, target) then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
				self.ifo_util.MoveTo(v, party_pos[party_pos_index], move_duration, nil, true, true))
			party_pos_index = party_pos_index + 1
		end
	end

	coroutine.yield(coroutine_class.wait_for_sec(move_duration))

	-- 캐릭터들 방향 바꾸기
	for k, v in pairs(user_party) do
		if dir == 1 then
			character_util.set_direction(v, 'left')
		else
			character_util.set_direction(v, 'right')
		end
	end
end

-- 파티원 특정 정렬 (리더가 중심이 아닌 특정 캐릭터를 중심으로 정렬) 추가 연출이 필요해서 위 아래 정렬 추가
-- target = 중심이 되는 캐릭터
-- pos = 정렬할 위치
-- dist = 정할 위치로 부터 거리
-- direction = 이동 방향
-- move_duration = 이동 시간
function local_class:party_move_up_down(target, pos, dist, direction, move_duration)
	-- 방향 값 (default = down)
	local dir = -1
	if direction == CS.Oak.Direction.Up then
		dir = 1
	end

	local target_pos = pos + vector(0, 0, dir * dist)

	-- 중심 캐릭터 이동
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		self.ifo_util.MoveTo(target, target_pos, move_duration, nil, true, true))

	-- 파티원들 지정 위치로 이동
	local party_pos = {
		target_pos + vector(0.5, 0, 0.5 * dir),
		target_pos + vector(-0.5, 0, 0.5 * dir),
		target_pos + vector(0, 0, 1 * dir),
		target_pos + vector(-0.5, 0, 1.5 * dir)}

	-- 중심이 아닌 캐릭터는 지나가기 때문에 새로운 index 값 사용 (continue가 없어서)
	local party_pos_index = 1
	for k, v in pairs(user_party) do
		-- 중심이 아닌 캐릭터들 이동
		if not lua_helper.reference_equals(v, target) then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
				self.ifo_util.MoveTo(v, party_pos[party_pos_index], move_duration, nil, true, true))
			party_pos_index = party_pos_index + 1
		end
	end

	coroutine.yield(coroutine_class.wait_for_sec(move_duration))

	-- 캐릭터들 방향 바꾸기
	for k, v in pairs(user_party) do
		if dir == 1 then
			character_util.set_direction(v, 'down')
		else
			character_util.set_direction(v, 'up')
		end
	end
end

-- 레이저 발사 연출
-- pos = 쏘는 위치
-- start_scale_x = 레이저 시작 크기
-- end_scale_x = 레이저 끝 크기
-- duration = 시작부터 끝까지 가는 시간
-- wait_time = 기 모으는 시간
-- dispose_time = 레이저를 끝까지 쏘고 머무르는 시간
-- direction = 레이저가 나가는 방향
-- pool = 어떤 이펙트를 쏠 건지
function local_class:laser(pos, start_scale_x, end_scale_x, duration, wait_time, dispose_time, direction, pool)
	local start_scale = vector(start_scale_x, 1, 1)
	local end_scale = vector(end_scale_x, 1, 1)

	local laser_effect = pool:Instantiate(pos)
	laser_effect.transform.localScale = start_scale
	laser_effect.transform.localRotation = unity_class.quaternion.Euler(0, direction, 0)

	coroutine.yield(coroutine_class.wait_for_sec(wait_time))

	local current_time = 0

	while current_time < duration do
		current_time = current_time + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01(current_time / duration)
		local laser_scale = unity_class.vector3.Lerp(start_scale, end_scale, progress)

		laser_effect.transform.localScale = laser_scale

		coroutine.yield(nil)
	end

	coroutine.yield(coroutine_class.wait_for_sec(dispose_time))
	laser_effect:Dispose()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
