local local_class = newclass("NightmareTeatans1At6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.ifo_util = CS.Oak.IFieldObjectExtensions

	self.is_talking = false
	self.bomb_iron_head = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	unity_object_pool.GetOrCreate('laser_Fire_event')
	unity_object_pool.GetOrCreate('FX_Env_BigRock_lv2_destroy')
	unity_object_pool.GetOrCreate('FX_explosion_big_bomb')
	unity_object_pool.GetOrCreate('FX_reset_object')

	-- 아이언 헤드, 암 레벨 UI 제거
	local iron_head = get_character('iron_teatan_head')
	field_ui_manager:RemoveUI(iron_head, CS.Oak.FieldUiType.CharacterStats)
	local iron_arm = get_character('iron_teatan_arm')
	field_ui_manager:RemoveUI(iron_arm, CS.Oak.FieldUiType.CharacterStats)
end

function local_class:need_on_launch()
	-- 티탄왕국 보스가 나타난걸 봤던 경우에만 커스텀 인트로 진행
	local main_quest = user_progress:GetStartedQuest(81)
	return main_quest ~= nil and not main_quest.IsComplete and
			main_quest.InnerProgress == 3 and main_quest:GetCustomState('seen_boss_appear') == 1
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
	self.ifo_util = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	local iron_head = get_character('iron_teatan_head')
	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end
		local zone_name = e.Zone.Name

		local is_holding_iron_head = lua_helper.reference_equals(iron_head.Holdable.Holder, user_party_leader)
		if zone_name == 'iron_teatan_head_laser' and not self.is_talking and is_holding_iron_head then
			self.is_talking = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fire_laser, self))
			return true
		end
	end

	if event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		local zone_name = e.Zone.Name

		if zone_name == 'tdf_room' then
			local is_holding_iron_head = lua_helper.reference_equals(iron_head.Holdable.Holder, user_party_leader)
			-- 플레이어가 아이언 헤드 들고 나가려고 하는지 체크
			if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
				if not self.is_talking and is_holding_iron_head then
					self.is_talking = true
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dont_move_out, self))
					return true
				end
			-- 아이언 헤드가 밖으로 나갔는지 체크
			elseif lua_helper.reference_equals(e.FieldObject, iron_head) and not is_holding_iron_head then
				message_system:SendSync(iron_head, CS.Oak.GetThrownEndEvent.Instance)

				local marker = field:GetMarker('iron_head_start_pos').position
				local fx_reset_pool = unity_object_pool.GetOrCreate('FX_reset_object')

				music_player_util.play_sfx({
					sfx_name = '01_guild_warp_01', play_pos = iron_head.Position
				})

				fx_reset_pool:Instantiate(iron_head.Position)
				fx_reset_pool:Instantiate(marker)
				iron_head.Position = marker
				return true
			end
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		if stage_progress:HasStarPiece('iron_teatan_star_piece') then
			-- 스타피스 먹은 후 처리
			local marker = field:GetMarker('iron_teatan_laser_leader').position
			iron_head.Position = marker + unity_class.vector3.back
			iron_head.Holdable = CS.Oak.NonHoldable.Instance
			local rock = get_field_object('iron_teatan_rock')
			rock.Position = vector(999, 0, 999)
			local engineer = get_character('engineer_4')
			engineer.Position = vector(999, 0, 999)
		else
			-- 스타피스 먹기 전 처리
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tesla_effect_check, self))
		end
		return true
	end

	return false
end

-- 특정 위치로 이동 시 iron teatan head에서 레이저 발사
function local_class:fire_laser()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local iron_head = get_character('iron_teatan_head')

	-- 테슬라 이펙트 sfx 재생
	music_player_util.play_sfx({
		sfx_name = '02_lightning_strike_02', play_pos = iron_head.Position
	})

	local marker = field:GetMarker('iron_teatan_laser_leader').position
	user_party:PositionParty(marker, CS.Oak.Direction.Down, 1, CS.Oak.Party.AlignType.Arc)
	coroutine.yield(coroutine_class.wait_for_sec(1.3))

	coroutine.yield(coroutine_class.wait_for_sec(1))

	local rock = get_field_object('iron_teatan_rock')
	camera_util.resize_to(5, 0.5)
	camera_util.move(user_party_leader.Position + 2 * unity_class.vector3.back, 0.5)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 아이언 헤드 흔들리는 sfx
	music_player_util.play_sfx({
		sfx_name = '01_clang_01', loop = true, fade_out_time = 0.2, duration = 1
	})

	character_util.shake(iron_head, 0.05, 1)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 레이저 sfx 재생
	music_player_util.play_sfx({
		sfx_name = '02_light_laser_01', duration = 2, fade_out_time = 0.3
	})

	-- 레이저 발사
	local pos = iron_head.Position + vector(0, 0.5, -0.5)
	local laser_fire_pool = unity_object_pool.GetOrCreate('laser_Fire_event')
	local laser_effect = laser_fire_pool:Instantiate(pos)
	laser_effect.transform.localRotation = unity_class.quaternion.Euler(0, -90, 0)
	laser_effect.transform.localScale = vector(0.8, 1, 1)

	camera_util.shake(0.03, 2)

	coroutine.yield(coroutine_class.wait_for_sec(2))

	-- 레이저 제거
	laser_effect:Dispose()

	-- 바위 파괴 sfx
	music_player:PlaySfxOneShot('02_explosion_02')

	-- 바위 파괴
	local fx_rock_destroy_pool = unity_object_pool.GetOrCreate('FX_Env_BigRock_lv2_destroy')
	fx_rock_destroy_pool:Instantiate(rock.Position)
	rock.Position = vector(999, 0, 999)

	camera_util.shake(0.2, 0.5)

	-- 엔지니어들 놀람
	local engineers = {}
	for i = 1, 4 do
		engineers[i] = get_character('engineer_' .. i)
		character_util.set_emotion(engineers[i], { name = 'surprise' })
	end

	character_util.set_direction(engineers[2], 'right')

	-- 바위 옆 엔지니어4는 날라감
	character_util.jump(engineers[4], 2, 1)
	character_util.spine_rotate(engineers[4], 360 * 3, 1)
	pos = engineers[4].Position + vector(-12, 0, 6)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		self.ifo_util.MoveTo(engineers[4], pos, 1, nil, true, false))

	-- 스타피스 등장
	local star_piece = get_field_object('iron_teatan_star_piece')
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(star_piece.Position))

	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	engineers[4].Position = vector(999, 0, 999)

	-- 카메라 연출
	camera_util.resize_to(CS.Oak.StageCamera.DefaultCameraSize, 0.5)
	camera_util.move(user_party_leader.Position, 0.5, { end_target = user_party_leader })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 아이언 헤드 흔들리는 sfx
	music_player_util.play_sfx({
		sfx_name = '01_clang_01', loop = true, fade_out_time = 0.2, duration = 1
	})

	character_util.shake(iron_head, 0.1, 1)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	music_player:PlaySfxOneShot('02_stomp_fire_01')

	local fx_explosion_pool = unity_object_pool.GetOrCreate('FX_explosion_big_bomb')
	fx_explosion_pool:Instantiate(iron_head.Position + unity_class.vector3.up)

	self.bomb_iron_head = true

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 들고있던 로봇을 놓은 상태로 함
	iron_head.Holdable:GetThrownBy(user_party_leader)
	message_system:SendSync(iron_head, CS.Oak.GetThrownEndEvent.Instance)
	message_system:SendSync(user_party_leader, CS.Oak.ReleaseHoldingObjectEvent.Create(user_party_leader))

	-- 아이언 헤드 던짐
	character_util.set_anim(user_party_leader, { name = 'throw' })

	local passed_time = 0
	local fall_time = 0.3
	local start_pos = iron_head.Position:GetX0z()
	local end_pos = user_party_leader.Position + unity_class.vector3.back

	while passed_time < fall_time do
		passed_time = passed_time + unity_class.time.deltaTime

		local progress = unity_class.mathf.Clamp01(passed_time / fall_time)
		local current_y = unity_class.mathf.Sin(unity_class.mathf.PI / 3 * (1 + 2 * progress)) * 1.3
		local current_xz = unity_class.vector3.Lerp(start_pos, end_pos, progress)

		iron_head.Position = current_xz + current_y * unity_class.vector3.up

		coroutine.yield(nil)
	end

	for k, v in pairs(user_party) do
		character_util.set_emotion(v, { name = 'surprise' })
	end

	character_util.remove_anim(user_party_leader)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	for k, v in pairs(user_party) do
		character_util.remove_emotion(v)
	end

	iron_head.Holdable = CS.Oak.NonHoldable.Instance

	engineers[1].Interactable.Talk = 'nightmare_teatans_6_engineer_5'
	engineers[2].Interactable.Talk = 'nightmare_teatans_6_engineer_6'
	engineers[3].Interactable.Talk = 'nightmare_teatans_6_engineer_7'

	self.is_talking = false

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 플레이어가 iron teatan head 들고 나가려고 하면 못 나가게 함
function local_class:dont_move_out()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local engineer = get_character('engineer_3')

	camera_util.move_async(engineer.Position, 0.5)

	-- 플레이어의 위치에 따라 엔지니어가 보는 방향 변경
	local direction = (user_party_leader.Position - engineer.Position):ToDirection()
	character_util.set_direction(engineer, direction)

	character_util.set_anim(engineer, { name = 'release' })
	character_util.set_emotion(engineer, { name = 'mad' })
	-- 그거 들고 나가지 마세요.
	local string_key = 'nightmare_teatans_6_engineer_8'
	speech_bubble_util.show_speech_bubble_async(engineer, { key = string_key, skip = true })

	character_util.remove_anim(engineer)
	character_util.remove_emotion(engineer)

	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader })

	-- 플레이어가 뒤로 물러남
	local pos
	if direction == CS.Oak.Direction.Up or direction == CS.Oak.Direction.Right then
		pos = user_party_leader.Position + unity_class.vector3.left
		user_party:PositionParty(pos, CS.Oak.Direction.Right, 0.3, CS.Oak.Party.AlignType.Linear)
	else
		pos = user_party_leader.Position + unity_class.vector3.forward
		user_party:PositionParty(pos, CS.Oak.Direction.Down, 0.3, CS.Oak.Party.AlignType.Linear)
	end
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	character_util.set_direction(engineer, 'left')

	self.is_talking = false

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 테슬라 이펙트 생성을 위한 거리 체크
function local_class:tesla_effect_check()
	local iron_head = get_character('iron_teatan_head')
	local tesla = {get_field_object('iron_teatan_tesla_1'), get_field_object('iron_teatan_tesla_2')}

	local tesla_sfx = {}

	while true do
		for k, v in pairs(tesla) do
			local dist =  (iron_head.Position - v.Position):GetX0z().magnitude
			local ray_effect = CS.Oak.TeslaRayEffect.GetOrCreate(v, iron_head)

			if dist < 4.62 then
				ray_effect.Enabled = true
				ray_effect:SetRay(v.Position + unity_class.vector3.up, iron_head.Position + unity_class.vector3.up, true)

				-- 각 코일 처음 연결시에만 소리 재생
				if tesla_sfx[k] == nil then
					tesla_sfx[k] = music_player_util.play_sfx({
						sfx_name = '02_spark_01', play_pos = iron_head.Position
					})
				end
			else
				-- 테슬라 sfx 중지
				if tesla_sfx[k] ~= nil then
					tesla_sfx[k]:FadeOut(0.1)
					tesla_sfx[k] = nil
				end

				CS.Oak.TeslaRayEffect.Return(ray_effect)
			end

			if self.bomb_iron_head then
				-- 테슬라 sfx 중지
				if tesla_sfx[k] ~= nil then
					tesla_sfx[k]:FadeOut(0.1)
					tesla_sfx[k] = nil
				end

				CS.Oak.TeslaRayEffect.Return(ray_effect)
				if k > 1 then
					tesla_sfx = nil
					return
				end
			end
		end
		coroutine.yield(nil)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
