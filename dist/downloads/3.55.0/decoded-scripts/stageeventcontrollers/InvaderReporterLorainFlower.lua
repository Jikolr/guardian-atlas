local local_class = newclass("InvaderReporterLorainFlowerController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.scientists = nil

	self.lorains = nil

	-- 꽃
	self.flower = nil

	-- 필드오브젝트 꽃
	self.fo_flower = nil

	-- 꽃 애니메이션
	self.flower_animator = nil

	-- 리소스 홀더
	self.resholder = nil

	-- 스타피스 이펙트
	self.star_piece_effect = nil

	-- 사진 촬영 Effect
	self.scoop_effect_1 = nil
	self.scoop_effect_2 = nil

	-- 이벤트 중복 실행 방지 플래그
	self.see_flower_event = false
	self.see_appear_star_piece_event = false

	-- 스테이지 커스텀 State
	self.stage_custom_state = {
		lorain_1 = 3,
		lorain_2 = 5,
	}

	-- 기타 상수
	self.flower_scientist_num = 2

	-- 타일맵 캐릭터 이름
	self.flower_scientist_name = 'flower_scientist_'

	-- 타일맵 존 이름
	self.lorain_flower_event_zone_name = 'flower'
	self.underground_event_zone_name = 'underground'
	self.basement_zone_name = 'basement'

	-- 타일맵 필드오브젝트 이름
	self.star_piece_name = 'flower_star_piece'
	self.flower_name = 'maiden_flower'
	self.flower_damaged_behaviour_name = 'flower_damaged_behaviour'

	-- 커스텀 이벤트 이름
	self.get_photo_1 = 'get_photo7'
	self.get_photo_2 = 'get_photo13'

	-- 오브젝트 풀 이름
	self.hit_effect_preset = "FX_hit"
	self.star_piece_effect_preset = 'FX_starpiece_in_character'
	self.scoop_effect_preset = 'invader_reporter_scoop_target'

	-- 사운드
	self.clone_sfx = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.scientists = create_generic_list(CS.Oak.Character)
	for i = 1, 2 do
		self.scientists:Add(get_character(self.flower_scientist_name..i))
	end

	for i = 0, self.scientists.Count - 1 do
		character_util.set_position(self.scientists[i], vector(3 + 4 * i, 0, 57))

		if i == 0 then
			character_util.set_direction(self.scientists[i], 'right')
			character_util.set_anim(self.scientists[i], { name = 'cross_arm' })
		else
			character_util.set_direction(self.scientists[i], 'left')
			character_util.set_anim(self.scientists[i], { name = 'question', loop = false })
		end
	end

	self.fo_flower = get_field_object(self.flower_name)

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local star_piece_effect_pool = unity_object_pool.GetOrCreate(self.star_piece_effect_preset)
	local scoop_effect_pool = unity_object_pool.GetOrCreate(self.scoop_effect_preset)

	-- 꽃 오브젝트 생성
	self.resholder = CS.Foundations.ResourceHolder()
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, "theatres/maiden_flower", "flower", function(prefab)
				local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
				local t =  obj.transform
				t.position = vector(5, 0, 57) + vector(0, 0.2, 0)
				t.rotation = unity_class.quaternion.Euler(0, 0, 0)
				t.localScale = vector(1.5, 1.5, 1.5)
				self.flower = obj
				self.flower_animator = t:GetChild(0):GetComponent(typeof(CS.UnityEngine.Animator))

				self.flower_animator:Play('bud', -1)

				local tile = CS.Oak.VirtualFieldObject()
				tile.Position = t.position
				tile.Hitbox = CS.Oak.Hitbox(vector(1, 1.5, 1))
				tile.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
				tile.ActiveState = CS.Oak.ActiveState.InField
				message_system:Send(field, CS.Oak.AddFieldObjectEvent.Create(tile))
			end)

	local optimized_npcs = load_util.create_optimized_npcs_async({
		lorain_clone_1 = 'maiden_clone',
		lorain_clone_2 = 'maiden_clone',
		lorain_clone_3 = 'maiden_clone',
		lorain_clone_4 = 'maiden_clone',
		lorain_clone_5 = 'maiden_clone',
		lorain_clone_6 = 'maiden_clone',
		lorain_clone_7 = 'maiden_clone',
		lorain_clone_8 = 'maiden_clone',
		lorain_clone_9 = 'maiden_clone',
		lorain_clone_10 = 'maiden_clone',
		lorain_clone_11 = 'maiden_clone',
		lorain_clone_12 = 'maiden_clone',
		lorain_clone_13 = 'maiden_clone',
		lorain_clone_14 = 'maiden_clone',
		lorain_clone_15 = 'maiden_clone',
		lorain_clone_16 = 'maiden_clone',
		lorain_clone_17 = 'maiden_clone',
		lorain_clone_18 = 'maiden_clone',
		lorain_clone_19 = 'maiden_clone',
		lorain_clone_20 = 'maiden_clone'
	})

	self.lorains = create_generic_list(CS.Oak.Character)
	for i = 1, 20 do
		self.lorains:Add(optimized_npcs['lorain_clone_'..i])
	end

	local lorain_pos_list = create_generic_list(unity_class.vector3)
	lorain_pos_list:Add(vector(-15.2, 0, -54))
	lorain_pos_list:Add(vector(-16.2, 0, -54.8))
	lorain_pos_list:Add(vector(-15.2, 0, -56.1))
	lorain_pos_list:Add(vector(-17.2, 0, -56.8))
	lorain_pos_list:Add(vector(-15.5, 0, -57.5))
	lorain_pos_list:Add(vector(-16.5, 0, -58.4))
	lorain_pos_list:Add(vector(-15, 0, -59))
	lorain_pos_list:Add(vector(-15.9, 0, -52.7))
	lorain_pos_list:Add(vector(-16.7, 0, -59.7))
	lorain_pos_list:Add(vector(-15.1, 0, -60.5))
	lorain_pos_list:Add(vector(-7.9, 0, -53.2))
	lorain_pos_list:Add(vector(-6.8, 0, -52.6))
	lorain_pos_list:Add(vector(-5, 0, -52.9))
	lorain_pos_list:Add(vector(-7.1, 0, -54.1))
	lorain_pos_list:Add(vector(-5.9, 0, -53.8))
	lorain_pos_list:Add(vector(-7.7, 0, -59.3))
	lorain_pos_list:Add(vector(-7.2, 0, -60.6))
	lorain_pos_list:Add(vector(-6.4, 0, -59.7))
	lorain_pos_list:Add(vector(-4.9, 0, -60))
	lorain_pos_list:Add(vector(-5.6, 0, -60.4))

	for i = 0, self.lorains.Count - 1 do
		character_util.set_position(self.lorains[i], lorain_pos_list[i])

		if i < 10 then
			character_util.set_direction(self.lorains[i], 'right')
		elseif i < 15 then
			character_util.set_direction(self.lorains[i], 'down')
		else
			character_util.set_direction(self.lorains[i], 'up')
		end
	end

	if stage_progress:HasStarPiece(self.star_piece_name) then
		self.see_appear_star_piece_event = true

		self.flower_animator:Play('bloom', -1)

		self.fo_flower.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(3, 1, 3))
	else
		-- 이펙트 로드 대기
		while not object_pool_extensions.IsLoaded(star_piece_effect_pool) do
			coroutine.yield(nil)
		end

		-- 스타피스 미획득 시에는 꽃에 스타피스 이펙트 붙여줌
		self.star_piece_effect = unity_object_pool.GetOrCreate(
				self.star_piece_effect_preset):Instantiate(vector(5, 0, 57))
	end

	-- 이펙트 로드 대기
	while not object_pool_extensions.IsLoaded(scoop_effect_pool) do
		coroutine.yield(nil)
	end

	if not stage_progress:GetCustomData(self.stage_custom_state.lorain_1, false) then
		self.scoop_effect_1 = unity_object_pool.GetOrCreate(self.scoop_effect_preset):Instantiate(vector(-16.5, 0, -56))
	end

	if not stage_progress:GetCustomData(self.stage_custom_state.lorain_2, false) then
		self.scoop_effect_2 = unity_object_pool.GetOrCreate(self.scoop_effect_preset):Instantiate(vector(5, 0,  57.5))
	else
		self.see_flower_event = true
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.scientists = nil

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.lorains ~= nil and self.experimental_destroy_character == true then
		load_util.dispose_optimized_npcs(self.lorains)
		self.lorains = nil
	end

	-- 꽃 오브젝트 dispose
	if self.flower ~= nil then
		CS.UnityEngine.Object.Destroy(self.flower)
	end

	self.flower = nil
	self.flower_animator = nil

	if self.resholder ~= nil then
		self.resholder:Dispose()
	end

	if self.star_piece_effect ~= nil then
		self.star_piece_effect:Dispose()
		self.star_piece_effect = nil
	end

	if self.scoop_effect_1 ~= nil then
		self.scoop_effect_1:Dispose()
		self.scoop_effect_1 = nil
	end

	if self.scoop_effect_2 ~= nil then
		self.scoop_effect_2:Dispose()
		self.scoop_effect_2 = nil
	end

	if self.clone_sfx ~= nil then
		self.clone_sfx:Stop()
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageStartEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.lorain_event, self))
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.lorain_flower_event_zone_name then
		if not self.see_flower_event and not self.see_appear_star_piece_event then
			self.see_flower_event = true

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.flower_event, self))
		end
	elseif zone_name == self.basement_zone_name then
		if self.clone_sfx == nil then
			self.clone_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_toil_01', loop = true,
														  play_pos = field:GetZone(self.underground_event_zone_name).Bounds.center})
		end
	end
end

function local_class:on_zone_leave_event(e)
	if not e.FullLeave then return end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.basement_zone_name then
		if self.clone_sfx ~= nil then
			self.clone_sfx:Stop()
			self.clone_sfx = nil
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	local flower_damaged_behaviour = get_field_object(self.flower_damaged_behaviour_name)

	if not self.see_appear_star_piece_event and lua_helper.reference_equals(e.FieldObject, flower_damaged_behaviour) then
		self.see_appear_star_piece_event = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.appear_star_piece_event, self))
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.get_photo_1 then
			self.scoop_effect_1:Dispose()
			self.scoop_effect_1 = nil
		elseif e.Params[0] == self.get_photo_2 then
			self.scoop_effect_2:Dispose()
			self.scoop_effect_2 = nil
		end
	end
end

-- 꽃 이벤트
function local_class:flower_event()
	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_lorain_flower_0' })

	if self.see_appear_star_piece_event then
		return
	end

	speech_bubble_util.show_speech_bubble_async(self.scientists[1], { key = 'invader_reporter_lorain_flower_1' })

	if self.see_appear_star_piece_event then
		return
	end

	character_util.set_anim(self.scientists[0], { name = 'cast' })
	character_util.set_emotion(self.scientists[0], { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_lorain_flower_2' })

	if self.see_appear_star_piece_event then
		return
	end

	character_util.set_anim(self.scientists[0], { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(self.scientists[0], { name = 'attack' })

	character_util.remove_anim(self.scientists[1])

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_lorain_flower_3' })

	if self.see_appear_star_piece_event then
		return
	end

	character_util.remove_anim(self.scientists[0])
	character_util.remove_emotion(self.scientists[0])

	character_util.set_anim(self.scientists[1], { name = 'bomb_idle' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[1], { key = 'invader_reporter_lorain_flower_4' })

	if self.see_appear_star_piece_event then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_player_jump_01', parent = self.scientists[0]})
	character_util.jump(self.scientists[0], 1, 0.5)
	character_util.set_anim(self.scientists[0], { name = 'cast' })
	character_util.set_emotion(self.scientists[0], { name = 'tired' })

	character_util.remove_anim(self.scientists[1])

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_lorain_flower_5' })

	if self.see_appear_star_piece_event then
		return
	end

	character_util.set_anim(self.scientists[0], { name = 'cross_arm' })
	character_util.remove_emotion(self.scientists[0])

	character_util.set_anim(self.scientists[1], { name = 'question', loop = false })
end

-- 스타피스 등장 이벤트
function local_class:appear_star_piece_event()
	-- 연구원 폭발
	for i = 0, self.scientists.Count - 1 do
		local dir = CS.Oak.DirectionExtensions.ToVector3(CS.Oak.DirectionExtensions.GetOpposite(self.scientists[i].Direction))

		character_util.air_spin(self.scientists[i], { offset = dir, speed = 1.5, stay_time = 0.5 })
	end

	self.star_piece_effect:Dispose()
	self.star_piece_effect = nil

	self.flower_animator:Play('bloom', -1)

	self.fo_flower.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(3, 1, 3))

	local star_piece = get_field_object(self.star_piece_name)
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(star_piece.Position + vector(0, 0, -2)))

	coroutine.yield(coroutine_class.wait_for_sec(2.5))

	--self.flower_animator:Play('idle', -1)
end

-- 로레인 이벤트
function local_class:lorain_event()
	for i = 0, self.lorains.Count - 1 do
		local mod = i % 3

		if mod == 0 then
			local target_wall_pos

			if i < 10 then
				target_wall_pos = vector(-14.5, 0, self.lorains[i].Position.z)
			elseif i < 15 then
				target_wall_pos = vector(self.lorains[i].Position.x, 0, -54.5)
			else
				target_wall_pos = vector(self.lorains[i].Position.x, 0, -58.7)
			end

			local rand_knockback_pos = unity_class.random.Range(10000, 16000)

			local rand_delay = unity_class.random.Range(0, 1)

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.crash_wall_repeat, self,
					self.lorains[i], target_wall_pos, rand_knockback_pos, rand_delay))
		elseif mod == 1 then
			local rand_delay = unity_class.random.Range(0, 1)

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.jump_repeat, self,
					self.lorains[i], rand_delay))
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shake_repeat, self,
					self.lorains[i]))
		end
	end
end

-- 벽에 부딪히는 것 반복
function local_class:crash_wall_repeat(clone, pos, knockback_force, delay)
	wait_for_sec(delay)

	while true do
		character_util.set_anim(clone, { name = 'run' })
		character_util.move_to_async(clone, pos, nil, 6, true, false)

		music_player_util.play_sfx({ sfx_name = '02_hit_big_01', parent = clone})
		unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
				clone.Position + vector(0, 0.3, 0))

		character_util.set_anim(clone, { name = 'damaged' })

		local dir = CS.Oak.DirectionExtensions.ToVector3(CS.Oak.DirectionExtensions.GetOpposite(clone.Direction))

		local knock_back_info = character_util.knockback_info('physics', true, dir,
				knockback_force, 0.05, CS.Oak.Constants.DefaultFrictionCoefficient)

		command_util.publish_knock_back(user_party_leader.Owner, clone, knock_back_info, nil)

		wait_for_sec(0.7)

		character_util.remove_anim(clone)

		wait_for_sec(0.3)
	end
end

-- 점프 반복
function local_class:jump_repeat(clone, delay)
	wait_for_sec(delay)

	while true do
		character_util.jump(clone, 0.5, 0.3)

		wait_for_sec(0.3)

		character_util.jump(clone, 0.5, 0.3)

		wait_for_sec(0.3)

		if delay > 0.3 then
			wait_for_sec(delay - 0.3)
		end
	end
end

-- 진동 반복
function local_class:shake_repeat(clone)
	local base_pos = clone.Position

	character_util.set_anim(clone, { name = 'walk4legs' })

	local timer = 0
	local duration = 0

	while true do
		timer = timer + unity_class.time.deltaTime

		if timer > duration then
			timer = 0

			local rand_x = unity_class.random.Range(0, 0.04)
			local rand_z = unity_class.random.Range(0, 0.04)

			local cur_pos = base_pos + vector(rand_x, 0, rand_z)

			character_util.set_position(clone, cur_pos)
		end

		coroutine.yield(nil)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
