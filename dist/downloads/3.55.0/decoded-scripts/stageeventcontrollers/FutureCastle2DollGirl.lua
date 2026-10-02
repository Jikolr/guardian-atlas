local local_class = newclass('FutureCastle2DollGirlController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- npc
	self.get_invader = function(index) return get_character('doll_girl_invader_' .. index) end

	-- 오브젝트
	self.get_switch = function() return get_field_object('doll_girl_switch') end
	self.get_food = function(index) return get_field_object('doll_girl_food_' .. index) end

	-- 마커
	self.get_reset_pos = function() return field:GetMarker('doll_girl_reset_pos').position end
	self.get_hole_pos = function() return field:GetMarker('doll_girl_hole_pos').position end
	self.get_doll_girl_camera_pos = function() return field:GetMarker('doll_girl_camera_pos').position end
	self.get_doll_girl_meal_pos = function() return field:GetMarker('doll_girl_meal_pos').position end

	-- 이펙트
	self.get_reset_effect = function() return unity_object_pool.GetOrCreate('FX_reset_object') end

	-- 란팡 방에 있는 아이템 데이터
	self.item_data = {
		-- 동태 배구공
		volleyball = {
			object_name = 'doll_girl_volleyball',
			item_id = 20277,
			narration_key = { 'futurecastle_doll_girl_14' }
		},

		-- 박사 배구공
		doctor_volleyball = {
			object_name = 'doll_girl_doctor_volleyball',
			item_id = 20278,
			narration_key = { 'futurecastle_doll_girl_15' }
		},

		-- 기사 배구공
		knight_volleyball = {
			object_name = 'doll_girl_knight_volleyball',
			item_id = 20279,
			narration_key = { 'futurecastle_doll_girl_16' }
		},

		-- 책상 위 종이
		paper = {
			object_name = 'doll_girl_paper',
			item_id = 20022,
			narration_key = {
				'futurecastle_doll_girl_18',
				'futurecastle_doll_girl_19',
				'futurecastle_doll_girl_20'
			}
		}
	}

	-- 인베이더 식탁 위의 음식 아이템 데이터
	self.food_data = {
		turkey = {
			item_id = 20280,
			pos_offset = vector(-0.1, 1, 0)
		},

		sandwich = {
			item_id = 20281,
			pos_offset = vector(-1.7, 1, 0)
		},

		buldojang = {
			item_id = 20282,
			pos_offset = vector(-0.2, 1, -1)
		}
	}

	self.progress_enum = {
		-- 초기 상태
		none = 1,
		-- 인베이더들이 식사하는 것을 본 상태
		show_meal = 2,
		-- 인베이더가 이동중인 상태
		move_invader = 3
	}

	self.current_progress = self.progress_enum.none

	-- 플레이어가 감시에 걸렸을 때 오는 이벤트 이름
	self.guard_event_name = 'doll_girl_guard'

	-- 마법진으로 워프 중인지 저장
	self.warp_magic_circle = false

	-- 감시에 걸렸는지
	self.leader_detected = false

	-- 이벤트를 봤는지
	self.show_first_meal = false

	-- 카메라 이동 존에 있는지
	self.in_camera_zone_full_enter = false

	-- 감시 인베이더가 음식을 들고있는지
	self.hold_up_food = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_fo_event')

	self.origin_pos = self.get_invader(2).Position

	-- 감시하면서 이동하는 인베이더
	self.move_invader = self.get_invader(2)
	self.move_invader_spine_transform =  self.move_invader.SpineController.SpineContainerTransform

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	quest_util.load_pool_resource(
		'MagicCircle_AppearIdle',
		'FX_reset_object'
	)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))

	if self.drop_item then
		self.drop_item:ConsumeComplete()
		self.drop_item = nil
	end

	self.item_data = nil
	self.food_data = nil
	self.progress_enum = nil
	self.move_invader = nil
	self.move_invader_spine_transform = nil

	self.cs_controller = nil
end

--- OnEvent
function local_class:on_event(e)
	return false
end

--- StageLoadedEvent
function local_class:on_stage_loaded()
	-- 란팡 방에 아이템 배치
	for _, v in pairs(self.item_data) do
		local obj = get_field_object(v.object_name)
		local drop_item = drop_item_util.create_item(
			{ pos = obj.Position, itemid = v.item_id, notforinven = true, lootstate = 'dontfindlooter' })
		obj.Hitbox = CS.Oak.Hitbox(vector(0.5, 0.75, 0.5), vector(1, 1.5, 1))
		drop_item.ShadowTransform.localPosition = vector(0, 1, -0.03)
	end

	-- 1.고기, 2.터키, 3.바나나, 4.감자, 5.당근, 6.브로콜리, 7.햄
	local item_id = { 20032, 20280, 20048, 20136, 20283, 20284, 20285 }

	local doll_girl_food = drop_item_util.create_item(
		{ pos = self.get_food(1).Position + vector(0.15, 0, 0.2), itemid = item_id[1],
		  notforinven = true, lootstate = 'dontfindlooter' })

	doll_girl_food.ShadowTransform.localPosition = vector(0, 1, -0.03)

	-- 란팡 방에 음식물 쓰레기 배치
	local index = 2
	while true do
		local food = self.get_food(index)

		if not food then break end

		drop_item_util.create_item(
			{ pos = food.Position, itemid = item_id[index], notforinven = true, lootstate = 'dontfindlooter' })

		index = index + 1
	end

	-- 인베이더 식탁 위에 음식 배치
	local food_pos = self.get_doll_girl_meal_pos()

	for _, v in pairs(self.food_data) do
		local drop_item = drop_item_util.create_item(
			{ pos = food_pos + v.pos_offset, itemid = v.item_id, notforinven = true,
			  lootstate = 'dontfindlooter', showoncharacter = true })

		drop_item.ShadowTransform.localPosition = vector(0, 1, -0.03)

		if v.item_id == 20280 then
			self.drop_item = drop_item
		end
	end

	-- 마법진 생성
	local doll_girl_magic_circle_pos = field:GetMarker('doll_girl_magic_circle_pos').position
	unity_object_pool.GetOrCreate('MagicCircle_AppearIdle'):Instantiate(doll_girl_magic_circle_pos)

	return true
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	-- 카메라 이동 존에 들어왔을 때
	if type_util.is_zone_full_enter(e, user_party.Leader, 'doll_girl_eat_food_camera_zone') then
		self.in_camera_zone_full_enter = true
		camera_util.move(self.get_doll_girl_camera_pos(), 1)
		return true
	end

	-- 란팡 이벤트 존에 들어왔을 때
	if type_util.is_zone_full_enter(e, user_party.Leader, 'doll_girl_invader_eat_food_zone') then
		if self.current_progress == self.progress_enum.none then
			self.current_progress = self.current_progress + 1

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_meal, self))
		end

		return true
	end

	-- 마법진 존에 들어왔을 때
	if type_util.is_zone_full_enter(e, user_party.Leader, 'doll_girl_magic_circle_zone') and
		not self.warp_magic_circle then

		sp_util.play_normal_screenplay(self.enter_magiccircle_event, self)

		return true
	end

	return false
end

--- ZoneLeaveEvent
function local_class:on_zone_leave_event(e)
	-- 카메라 이동 존에서 나갈 때
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
		e.Zone.Name == 'doll_girl_eat_food_camera_zone' then

		self.in_camera_zone_full_enter = false

		stage_camera:CancelMove()

		-- 카메라가 플레이어 따라감
		stage_camera:Move(user_party.Leader, 0.3, user_party.Leader)

		return true
	end

	return false
end

--- CustomStageEvent
function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == self.guard_event_name then
		self.leader_detected = true
		sp_util.play_normal_screenplay(self.detected_and_setting, self)
		return true
	end
	return false
end

--- InteractEvent
function local_class:on_interact_event(e)
	-- 식탁 위 음식 상호작용 시
	if string.find(e.Target.Name, 'doll_girl_food') then
		sp_util.play_normal_screenplay(function()
			field_ui_util.show_narration_async({ key = 'futurecastle_doll_girl_17', mintotalduration = 1 })
		end)
		return true
	end

	-- 란팡방의 물건 상호작용 시
	for _, v in pairs(self.item_data) do
		if e.Target.Name == v.object_name then
			sp_util.play_normal_screenplay(function()
				for _, narration_key in pairs(v.narration_key) do
					field_ui_util.show_narration_async({ key = narration_key, mintotalduration = 1 })
				end
			end)
			return true
		end
	end
	return false
end

--- MoveFieldObjectEvent
function local_class:on_move_fo_event(e)
	if self.drop_item and self.hold_up_food and lua_helper.reference_equals(e.FieldObject, self.move_invader) then
		self.drop_item.Position =
			self.move_invader.Position + vector(0, 1.4, 0) + self.move_invader_spine_transform.localPosition
		return true
	end
	return false
end

--- 인베이더들이 식사하는 것을 봤을 때
function local_class:show_meal()
	local move_duration = 5

	if not self.show_first_meal then
		-- 이벤트는 한번도 안 봤을 때
		wait_for_sec(1)

		local invader_1 = self.get_invader(1)
		local invader_3 = self.get_invader(3)

		-- 들었어?
		speech_bubble_util.show_speech_bubble_async(invader_1, { key = 'futurecastle_doll_girl_1' })

		music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = invader_1,
									 type_priority = 'event', player_priority = 'npc' })
		-- …이번엔 빅터와 리사가 시체로 발견됐어.
		speech_bubble_util.show_speech_bubble_async(invader_1, { key = 'futurecastle_doll_girl_2' })

		-- 젠장 이게 대체 몇명째야?
		speech_bubble_util.show_speech_bubble_async(self.move_invader, { key = 'futurecastle_doll_girl_3' })

		-- 레지스탕스 놈들은 부유성에 얼씬도 못하는거 아니었어?
		speech_bubble_util.show_speech_bubble_async(self.move_invader, { key = 'futurecastle_doll_girl_4' })

		music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = invader_3,
									 type_priority = 'event', player_priority = 'npc' })
		-- 유령이야…유령이라고…
		speech_bubble_util.show_speech_bubble_async(invader_3, { key = 'futurecastle_doll_girl_5' })

		-- 부유성의 유령이 우릴 저주한거야…
		speech_bubble_util.show_speech_bubble_async(invader_3, { key = 'futurecastle_doll_girl_6' })

		-- 젠장 차라리 유령이면 좋겠군.
		speech_bubble_util.show_speech_bubble_async(invader_1, { key = 'futurecastle_doll_girl_7' })

		-- 유령이 아니라면, 몇년 동안 그저 우릴 죽이는 것에만 집착하는 미치광이가 있다는 소리잖아.
		speech_bubble_util.show_speech_bubble_async(invader_1, { key = 'futurecastle_doll_girl_8' })

		music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', parent = self.move_invader,
									 type_priority = 'event', player_priority = 'npc' })
		-- …속이 안좋아.
		speech_bubble_util.show_speech_bubble_async(self.move_invader, { key = 'futurecastle_doll_girl_9' })

		self.show_first_meal = true
	else
		-- 이벤트를 처음 보는 게 아닐 때
		wait_for_sec(2)

		music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', parent = self.move_invader,
									 type_priority = 'event', player_priority = 'npc' })
		-- 젠장 역시 식욕이 생기질 않아.
		speech_bubble_util.show_speech_bubble_async(self.move_invader, { key = 'futurecastle_doll_girl_11' })
	end

	-- 음식 들어올림
	music_player_util.play_sfx({ sfx_name = '01_holdup_01', parent = self.move_invader,
								 type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(self.move_invader, { name = 'hold_loop', loop = false, upper = true })
	self.drop_item.ShadowTransform.localScale = unity_class.vector3.zero
	sp_util.sine_move(self.drop_item,
		{ from = self.drop_item.Position, to = self.move_invader.Position + vector(0, 1.4, 0),
		  duration =  0.2, height = 0.5 })

	wait_for_sec(0.3)

	self.hold_up_food = true

	-- 의자에서 내려옴
	music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = self.move_invader,
								 type_priority = 'event', player_priority = 'npc' })
	character_util.normal_jump(self.move_invader)
	self:move_to_async(self.move_invader,
		self.move_invader.Position + vector(1, -0.7, 0), 0.3)

	music_player_util.play_sfx({ sfx_name = '01_land_01', parent = self.move_invader,
								 type_priority = 'event', player_priority = 'npc' })

	-- 이거 버리고 올게.
	speech_bubble_util.show_speech_bubble_async(self.move_invader, { key = 'futurecastle_doll_girl_12' })

	-- 감시 설정
	self.move_invader.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(
		self.move_invader, self.guard_event_name, 3, 60)

	-- 쓰레기장 앞으로 이동
	self:move_to_async(self.move_invader,
		self.move_invader.Position + vector(13, 0, -0.5), move_duration)

	if self.leader_detected then return end

	-- 타이머를 사용하기 위해서 스위치를 이용하여 문 열기
	message_system:Publish(CS.Oak.SwitchOnOffEvent.Create(self.get_switch(), true, self.move_invader))
	wait_for_sec(2)

	if self.leader_detected then return end

	-- 쓰레기 구멍에 쓰레기 던짐
	character_util.remove_anim(self.move_invader, true)
	music_player_util.play_sfx({ sfx_name = '01_throw_01', parent = self.move_invader,
								 type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(self.move_invader, { name = 'throw' })
	self.hold_up_food = false
	sp_util.sine_move(self.drop_item, { from = self.drop_item.Position, to = self.get_hole_pos(), duration =  0.4 })

	if not self.leader_detected then
		character_util.remove_anim(self.move_invader)
	end

	-- 아이템이 구멍에 빠지는 연출
	local duration = 0.8
	local time_passed = 0

	local end_pos = self.drop_item.Position + vector(0, -0.3, -0.4)
	music_player_util.play_sfx({ sfx_name = '01_fall_down_01', play_pos = end_pos,
								 type_priority = 'event', player_priority = 'npc' })

	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime

		self.drop_item.SpriteTransform.localScale =
		unity_class.vector3.Lerp(unity_class.vector3.one, unity_class.vector3.zero, time_passed / duration)

		local cur_z = unity_class.mathf.Lerp(0, 360 * 3, time_passed / duration)
		self.drop_item.SpriteTransform.localRotation = unity_class.quaternion.Euler(0, 0, cur_z)

		local cur_pos = unity_class.vector3.Lerp(self.drop_item.Position, end_pos, time_passed / duration)
		self.drop_item.Position = cur_pos

		coroutine.yield(nil)
	end

	message_system:Publish(CS.Oak.SwitchOnOffEvent.Create(self.get_switch(), false, self.move_invader))

	self.drop_item:ConsumeComplete()
	self.drop_item = nil

	if self.leader_detected then return end

	-- 제자리로 돌아가는 인베이더
	self:move_to_async(self.move_invader,
		self.move_invader.Position + vector(-13, 0, 0.5), move_duration)

	if self.leader_detected then return end

	-- 의자에 앉음
	character_util.normal_jump(self.move_invader)
	self:move_to_async(self.move_invader,
		self.move_invader.Position + vector(-1, 0.7, 0), 0.3)

	character_util.set_anim(self.move_invader, { name = 'seat' })

	-- 음식 재생성
	music_player_util.play_sfx({ sfx_name = '01_guild_warp_01', parent = self.move_invader,
								 type_priority = 'event', player_priority = 'npc' })
	local food_pos = self.get_doll_girl_meal_pos() + self.food_data.turkey.pos_offset
	self.get_reset_effect():Instantiate(food_pos)

	self.drop_item = drop_item_util.create_item(
		{ pos = food_pos, itemid = self.food_data.turkey.item_id, notforinven = true,
		  lootstate = 'dontfindlooter', showoncharacter = true })

	self.drop_item.ShadowTransform.localPosition = vector(0, 1, -0.03)

	self.leader_detected = false
	self.current_progress = self.progress_enum.none
	self.move_invader.FieldObjectController = CS.Oak.NPCCharacterController()
end

--- 이동 함수(감시에 걸리면 정지)
function local_class:move_to_async(target, end_pos, duration)
	local start_pos = target.Position
	local time_passed = 0

	local dir = vector_util.to_direction(end_pos - target.Position)
	if dir ~= CS.Oak.Direction.None then
		target.Direction = dir
	end

	character_util.set_anim(target, { name = 'walk' })

	while time_passed < duration and not self.leader_detected do
		time_passed = time_passed + unity_class.time.deltaTime

		target.Position = unity_class.vector3.Lerp(start_pos, end_pos, time_passed / duration)

		coroutine.yield(nil)
	end

	if not self.leader_detected then
		character_util.remove_anim(target)
	end
end

--- 감시에 걸렸을 때 초기화 세팅
function local_class:detected_and_setting()
	if self.hold_up_food then
		music_player_util.play_sfx({ sfx_name = '01_guild_warp_01', parent = self.move_invader,
									 type_priority = 'event', player_priority = 'npc' })
		self.get_reset_effect():Instantiate(self.drop_item.Position)
		self.drop_item:ConsumeComplete()
		self.drop_item = nil
	end

	self.hold_up_food = false

	character_util.remove_anim(self.move_invader, true)

	character_util.set_anim(self.move_invader, { name = 'attack' })
	character_util.set_emotion(self.move_invader, { name = 'attack' })

	music_player:PlaySfxOneShot('03_runaway_01')
	party_util.set_anim({ name = 'embarrassed' })
	party_util.set_emotion({ name = 'damaged' })

	character_util.normal_jump(user_party.Leader)

	music_player:PlaySfxOneShot('01_siren_oneshot_01')
	field:Tint('detected_tint', unity_class.color(1, 0, 0), 0.25)

	camera_util.shake(0.07, 0.25)

	music_player:PlaySfxOneShot('02_goblin_appear_01')
	-- 침입자 발견!!
	speech_bubble_util.show_speech_bubble_async(self.move_invader, { key = 'futurecastle_doll_girl_21' })

	music_player:PlaySfxOneShot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	field:RemoveTint('detected_tint', 0)

	message_system:Publish(CS.Oak.DoorCloseEvent.Create('doll_girl_door'))

	-- 음식 재생성
	self.drop_item = drop_item_util.create_item(
		{ pos = self.get_doll_girl_meal_pos() + self.food_data.turkey.pos_offset,
		  itemid = self.food_data.turkey.item_id, notforinven = true,
		  lootstate = 'dontfindlooter', showoncharacter = true })

	self.drop_item.ShadowTransform.localPosition = vector(0, 1, -0.03)

	-- npc들 세팅
	self.move_invader.FieldObjectController = CS.Oak.NPCCharacterController()

	party_util.remove_animation()
	party_util.remove_emotion()
	party_util.position_party(self.get_reset_pos(), 'down', 'linear')
	get_character('princess').Position =
		user_party.Leader.Position + direction_util.to_vector3(direction_util.get_opposite(user_party.Leader.Direction))

	self.move_invader.Position = self.origin_pos
	character_util.remove_anim_and_emotion()
	character_util.set_direction(self.move_invader, 'left')
	character_util.set_anim(self.move_invader, { name = 'seat' })

	self.leader_detected = false
	self.current_progress = self.progress_enum.none
	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')
end

--- 마법진 진입 이벤트
function local_class:enter_magiccircle_event()
	local princess = get_character('princess')
	local leader = user_party.Leader

	self.warp_magic_circle = true

	character_util.spine_set_alpha_fade(leader, 0, 0.5)
	character_util.spine_set_alpha_fade(princess, 0, 0.5)
	wait_for_sec(0.2)

	music_player_util.play_sfx(
		{ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	leader.Position = field:GetMarker('doll_girl_out').position
	princess.Position = leader.Position + direction_util.to_vector3(direction_util.get_opposite(leader.Direction))

	message_system:SendSync(princess, CS.Oak.StateResetEvent.Instance)
	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(leader, 1, 0.5)
	character_util.spine_set_alpha_fade(princess, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magic_circle = false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
