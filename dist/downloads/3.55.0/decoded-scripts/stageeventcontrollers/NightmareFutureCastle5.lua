local local_class = newclass('NightmareFutureCastle5Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 퀘스트 id
	self.main_quest_id = 208

	-- 이벤트 존 이름
	self.bombard_shot_zone_name = 'bombard_shot_area'
	self.tradition_area_name = 'tradition_area'
	self.teatan_fat_event_zone_name = 'teatan_fat'

	-- 카메라 그리드 이름
	self.teatan_fat_camera_grid_name = 'teatan_fat_grid'

	-- 캐릭터를 가져오는 함수
	self.get_teatan_zaco = function(num) return get_character('teatan_zaco_' .. num) end
	self.get_teatan_kid = function(num) return get_character('teatan_kid_' .. num) end
	self.get_teatan_daughter = function() return get_character('teatan_tradition_daughter') end
	self.get_teatan_dad = function() return get_character('teatan_tradition_dad') end
	self.get_princess = function() return get_character('princess') end

	-- 필드오브젝트를 가져오는 함수
	self.get_tradition_door = function() return get_field_object('door_market_6') end
	self.get_invader_fight_teatan = function(num) return get_character('invader_warrior_fight_teatan_' .. num) end

	-- 이펙트를 가져오는 함수
	self.get_dark_magic_missile_effect = function() return unity_object_pool.GetOrCreate('FX_DarkMagicMissile_Proj') end
	self.get_dark_magic_missile_explosion_effect = function() return unity_object_pool.GetOrCreate('FX_DarkMagicMissile_Proj_Explosion') end
	self.get_hit_effect = function() return unity_object_pool.GetOrCreate('FX_hit') end

	self.is_saw_start_area_bombard_shot = false
	self.is_enter_tradition_area = false
	self.is_saw_tradition_trap = false
	self.is_play_teatan_fight_sfx = false

	self.bombard_shot_req_id = 0
	self.teatan_robot_and_invader_fight_req_id = 0

	self.war_sfx = nil
end

function local_class:dispose()
	character_util.remove_relate_event(self.get_teatan_dad(), self.cs_controller)

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.DoorClosedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')

	if self.war_sfx then
		self.war_sfx:Stop()
		self.war_sfx = nil
	end

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DoorClosedEvent), 'on_door_closed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')

	field:Tint('bombard', unity_color({ 1, 0.8, 0.8, 1 }), 0)

	local teatan_kid = self.get_teatan_kid(1)
	character_util.shake(teatan_kid, 0.02, 9999)

	self.get_teatan_dad().Interactable:AddListener(self.cs_controller)

	--region teatan_fat init
	for i = 1, 3 do
		local invader = self.get_invader_fight_teatan(i)
		invader.SpineController:SetAttachment('[base]weapon1', 'fire_sword')
		character_util.set_anim(invader, { name = 'attack_dash', scale = 0.5 })
	end
	--endregion

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.get_dark_magic_missile_effect()
	self.get_dark_magic_missile_explosion_effect()

	yield_return(unity_object_pool, 'WaitAll')
end
--endregion

--region launch
function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		return self:on_camera_grid_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		return self:on_camera_grid_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		return self:on_field_object_destroyed_event(e)
	end
	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.bombard_shot_zone_name then
				self:start_bombard_shot()

				if not self.is_saw_start_area_bombard_shot then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_area_bombard_shot, self))
				end
				return true
			elseif not self.is_play_teatan_fight_sfx and e.Zone.Name == self.teatan_fat_event_zone_name then
				self.is_play_teatan_fight_sfx = true
				music_player_util.play_sfx_one_shot('02_goblin_appear_01')
				return true
			end

			if e.Zone.Name == self.tradition_area_name then
				if not self.is_enter_tradition_area then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_tradition_area, self))
				end
				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.bombard_shot_zone_name then
				self:stop_bombard_shot()
				return true
			end
		end
	end

	return false
end

function local_class:on_interact_event(e)
	local dad = self.get_teatan_dad()

	if lua_helper.reference_equals(e.Target, dad) then
		if self.is_saw_tradition_trap then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					speech_bubble_util.show_speech_bubble_async, dad, { key = 'nightmare_futurecastle_tradition_2'}))
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					speech_bubble_util.show_speech_bubble_async, dad, { key = 'nightmare_futurecastle_tradition_3'}))
		end
		return true
	end
	return false
end

function local_class:on_door_closed_event(e)
	if e.DoorHandleName == 'door_market_6' then
		if self.get_princess().Position.z > self.get_tradition_door().Position.z + 0.5 and not self.is_saw_tradition_trap then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.stuck_trap, self))
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == self.teatan_fat_camera_grid_name then
			self:start_teatan_robot_and_invader_fight()
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == self.teatan_fat_camera_grid_name then
			self:stop_teatan_robot_and_invader_fight()
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		self.bombard_shot_req_id = self.bombard_shot_req_id + 1
		return true
	end

	return false
end
--endregion

--region bombard_shot
function local_class:start_bombard_shot()
	self.bombard_shot_req_id = self.bombard_shot_req_id + 1
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bombard_shot_area, self))
end

function local_class:stop_bombard_shot()
	self.bombard_shot_req_id = self.bombard_shot_req_id + 1
end

function local_class:bombard_shot_area()
	local req_id = self.bombard_shot_req_id

	wait_for_sec(1)

	while req_id == self.bombard_shot_req_id do
		yield_return_func(self.bombard_shot, self, user_party.Leader.Position)

		wait_for_sec(1)
	end
end

-- 공용 포격 루틴
function local_class:bombard_shot(pos)
	local radius = 1

	music_player_util.play_sfx({ sfx_name = '02_dark_magician_shoot_01', type_priority = 'event', player_priority = 'npc' })

	local missile_height = 15
	local cur_y = stage_util.get_height(pos)

	local bombard_range = CS.AttackRange.CreateCircle(vector(pos.x, cur_y + 0.01, pos.z), radius)

	bombard_range:Show()

	local missile = self.get_dark_magic_missile_effect():Instantiate(pos + vector(0, missile_height, 0))

	local cur_time = unity_class.time.time
	local fall_time = 1.75
	local freefall = CS.CalculatorFreeFall(fall_time, missile_height, 0)

	while unity_class.time.time - cur_time < fall_time do
		freefall:Proceed(unity_class.time.deltaTime)
		missile.transform.position = pos + vector(0, missile_height + freefall:GetDistance(), 0)

		coroutine.yield(nil)
	end

	music_player_util.play_sfx({ sfx_name = '02_explosion_01', type_priority = 'event', player_priority = 'npc' })

	missile:Dispose()

	camera_util.shake(0.15, 0.15)

	local explosion = self.get_dark_magic_missile_explosion_effect():Instantiate(pos)
	explosion.transform.localScale = vector(1.5, 1.5, 1.5)

	bombard_range:Hide()

	-- 공격 범위에 Rock 오브젝트가 존재할 경우 데미지를 줘서 폭파시킴
	local collide_objs = field:GetFieldObjectsInRadius(pos, radius)

	for i = 0, collide_objs.Count - 1 do
		local fo = collide_objs[i]

		if lua_helper.type_compare(fo.DamagedBehaviour, CS.Oak.RockDamagedBehaviour) then
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
			damage_info.sender = nil
			damage_info.target = fo
			damage_info.damage = 100

			command_util.execute_damage(damage_info)
		end

		for j = 0, user_party.Count - 1 do
			if lua_helper.reference_equals(fo, user_party[j]) then
				local damage_info = CS.Oak.DamageInfo()
				damage_info.type = CS.Oak.DamageType.Trap
				damage_info.sender = user_party[j]
				damage_info.target = user_party[j]
				damage_info.damage = math.floor(user_party[j].FieldObjectStatsBehaviour.MaxHP * 0.1)

				command_util.execute_damage(damage_info)
			end
		end
	end
end
--endregion

--region start_area_bombard_shot
function local_class:start_area_bombard_shot()
	local pos = vector(0.5, 0, 8.5)
	local radius = 1

	self.is_saw_start_area_bombard_shot = true

	music_player_util.play_sfx({ sfx_name = '02_dark_magician_shoot_01', type_priority = 'event', player_priority = 'npc' })

	local missile_height = 15
	local cur_y = stage_util.get_height(pos)

	local bombard_range = CS.AttackRange.CreateCircle(vector(pos.x, cur_y + 0.01, pos.z), radius)

	bombard_range:Show()

	local missile = self.get_dark_magic_missile_effect():Instantiate(pos + vector(0, missile_height, 0))

	local cur_time = unity_class.time.time
	local fall_time = 1
	local freefall = CS.CalculatorFreeFall(fall_time, missile_height, 0)

	while unity_class.time.time - cur_time < fall_time do
		freefall:Proceed(unity_class.time.deltaTime)
		missile.transform.position = pos + vector(0, missile_height + freefall:GetDistance(), 0)

		coroutine.yield(nil)
	end

	music_player_util.play_sfx({ sfx_name = '02_explosion_01', type_priority = 'event', player_priority = 'npc' })

	missile:Dispose()

	camera_util.shake(0.15, 0.15)

	local explosion = self.get_dark_magic_missile_explosion_effect():Instantiate(pos)
	explosion.transform.localScale = vector(1.5, 1.5, 1.5)

	bombard_range:Hide()

	-- 공격 범위에 Rock 오브젝트가 존재할 경우 데미지를 줘서 폭파시킴
	local teatan_zaco_1 = self.get_teatan_zaco(1)
	local teatan_zaco_2 = self.get_teatan_zaco(2)

	character_util.spine_damage_red_pulse(teatan_zaco_1)
	character_util.spine_damage_squish_default(teatan_zaco_1)
	character_util.air_spin(teatan_zaco_1, { offset = vector(-1, 0, 0) })

	character_util.spine_damage_red_pulse(teatan_zaco_2)
	character_util.spine_damage_squish_default(teatan_zaco_2)
	character_util.air_spin(teatan_zaco_2, { offset = vector(1, 0, 0) })
end
--endregion

-- 전통 구역 입장 연출
function local_class:enter_tradition_area()
	self.is_enter_tradition_area = true

	local dad = self.get_teatan_dad()
	local daughter = self.get_teatan_daughter()

	-- 아빠… 거기 어떻게 들어가셨어요…
	speech_bubble_util.show_speech_bubble(daughter, { key = 'nightmare_futurecastle_tradition_1' })
	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = dad, type_priority = 'event' })
	-- 아이고… 어쩌다 이런 데 갇혔나…
	speech_bubble_util.show_speech_bubble(dad, { key = 'nightmare_futurecastle_tradition_2' })
end

-- 트랩에 갇히는 이벤트
function local_class:stuck_trap()
	self.is_saw_tradition_trap = true
	local dad = self.get_teatan_dad()
	character_util.remove_relate_event(dad, self.cs_controller)

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.set_direction(dad, 'left')
	character_util.set_emotion(dad, { name = 'smile' })
	--허허… 꼬마 아가씨도 갇혀버렸구먼.
	speech_bubble_util.show_speech_bubble_async(dad, { key = 'nightmare_futurecastle_tradition_4', skip = false })

	music_player:PlaySfxOneShot('03_dialogue_sadness_01')
	character_util.set_emotion(dad, { name = 'tired' })
	--나갈 방법은 없다네…
	speech_bubble_util.show_speech_bubble_async(dad, { key = 'nightmare_futurecastle_tradition_5', skip = false })
	--예전에는 웬 젊은 청년이 와서 구해주곤 했는데 이번엔 웬일인지 보이질 않는구먼.
	speech_bubble_util.show_speech_bubble_async(dad, { key = 'nightmare_futurecastle_tradition_6', skip = false })

	wait_for_sec(5)

	character_util.remove_emotion(dad)
	--아무리 기다려봤자 소용없다네. 나갈 방법은 없으니…
	speech_bubble_util.show_speech_bubble_async(dad, { key = 'nightmare_futurecastle_tradition_7', skip = false })

	dad.Interactable:AddListener(self.cs_controller)
end

--region teatan_air_spin
function local_class:start_teatan_robot_and_invader_fight()
	self.teatan_robot_and_invader_fight_req_id = self.teatan_robot_and_invader_fight_req_id + 1

	if self.war_sfx then
		self.war_sfx:Stop()
		self.war_sfx = nil
	end
	self.war_sfx = music_player_util.play_sfx({ sfx_name = '01_war_loop_02', loop = true, type_priority = 'loop', player_priority = 'default' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.teatan_robot_and_invader_fight_routine, self))
end

function local_class:stop_teatan_robot_and_invader_fight()
	self.teatan_robot_and_invader_fight_req_id = self.teatan_robot_and_invader_fight_req_id + 1

	if self.war_sfx then
		self.war_sfx:FadeOut(2)
		self.war_sfx = nil
	end
end

function local_class:teatan_robot_and_invader_fight_routine()
	local req_id = self.teatan_robot_and_invader_fight_req_id

	local effect_position_list = {
		self.get_invader_fight_teatan(1).Position + vector(0.5, 0, 0),
		self.get_invader_fight_teatan(2).Position + vector(-0.5, 0, 0),
		self.get_invader_fight_teatan(3).Position + vector(-0.5, 0, 0),
	}
	local effect_offset_list = {
		vector(-0.25, 0.3, 0),
		vector(0.3, 0.8, 0),
		vector(-0.1, 0.5, 0)
	}

	while req_id == self.teatan_robot_and_invader_fight_req_id do
		for i = 1, #effect_offset_list do
			local effect_offset = effect_offset_list[i]

			for j = 1, #effect_position_list do
				local effect_position = effect_position_list[j]

				if j == 1 then
					music_player_util.play_sfx({ sfx_name = '02_hit_big_01', play_pos = effect_position, type_priority = 'event', player_priority = 'npc' })
				end
				self.get_hit_effect():Instantiate(effect_position + effect_offset)
			end

			wait_for_sec(0.2)

			if req_id ~= self.teatan_robot_and_invader_fight_req_id then
				break
			end
		end
	end
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
