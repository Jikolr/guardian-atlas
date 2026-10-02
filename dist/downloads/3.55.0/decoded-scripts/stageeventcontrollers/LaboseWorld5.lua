local local_class = newclass('LaboseWorld5Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 386

	self.is_complete = false

	self.fx = {
		hit = function()
			return unity_object_pool.GetOrCreate('FX_hit')
		end,
		last_hit = function()
			return unity_object_pool.GetOrCreate('FX_lasthit')
		end,
		virus_explosion = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_death_explosion')
		end,
		black_liquid = function()
			return unity_object_pool.GetOrCreate('fx_lw_black_liquid')
		end,
		shot_gun = function()
			return unity_object_pool.GetOrCreate('fx_lw_basic_shot_gun')
		end,
		red_ice = function()
			return unity_object_pool.GetOrCreate('fx_red_ice')
		end,
		tanker_shield = function()
			return unity_object_pool.GetOrCreate('fx_lw_tanker_shield')
		end,
		cracked_space = function()
			return unity_object_pool.GetOrCreate('fx_lw_cracked_space')
		end,
		custom_sprite = function()
			return unity_object_pool.GetOrCreate('custom_sprite')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}

	-- 바이러스 폭발 이벤트를 봤는지
	self.ended_explosion_scene_1 = true

	-- 이펙트 테이블
	self.virus_explosion_effect = {}
	self.red_ice_effect = {}
	self.cracked_space_effect = {}

	self.stage_exit_name = 'exit_1'

	-- 아이템
	self.ammo = nil
	self.potion = nil
	self.engineer_basket = nil

	-- 아이템 id
	self.ammo_id = 21143
	self.potion_id = 21144
	self.bullet_id = 21147
	self.engineer_basket_id = 21158

	self.stage_ended = false

	self.scene_version = scene_util.default_version

	 self.eat_sfx_1 = nil
	 self.eat_sfx_2 = nil
	 self.eat_sfx_3 = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	if self.tanker_shield_effect ~= nil then
		self.tanker_shield_effect:Dispose()
		self.tanker_shield_effect = nil
	end

	for i = 1, #self.red_ice_effect do
		if self.red_ice_effect[i] ~= nil then
			self.red_ice_effect[i]:Dispose()
			self.red_ice_effect[i] = nil
		end
	end
	self.red_ice_effect = nil

	for i = 1, #self.cracked_space_effect do
		if self.cracked_space_effect[i] ~= nil then
			self.cracked_space_effect[i]:Dispose()
			self.cracked_space_effect[i] = nil
		end
	end
	self.cracked_space_effect = nil

	for i = 1, #self.virus_explosion_effect do
		if self.virus_explosion_effect[i] ~= nil then
			self.virus_explosion_effect[i]:Dispose()
			self.virus_explosion_effect[i] = nil
		end
	end
	self.virus_explosion_effect = nil

	if self.ammo ~= nil then
		drop_item_util.dispose_item(self.ammo)
		self.ammo = nil
	end

	if self.potion ~= nil then
		drop_item_util.dispose_item(self.potion)
		self.potion = nil
	end

	if self.engineer_basket ~= nil then
		drop_item_util.dispose_item(self.engineer_basket)
		self.engineer_basket = nil
	end

	if self.eat_sfx_1 ~= nil then
		self.eat_sfx_1:FadeOut()
		self.eat_sfx_1 = nil
	end

	if self.eat_sfx_2 ~= nil then
		self.eat_sfx_2:FadeOut()
		self.eat_sfx_2 = nil
	end

	if self.eat_sfx_3 ~= nil then
		self.eat_sfx_3:FadeOut()
		self.eat_sfx_3 = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.fx:load_all()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), 'virus_explosion_event_1') and
		not self.ended_explosion_scene_1 then
		self.ended_explosion_scene_1 = true
		start_coroutine(self.virus_explosion_scene, self,
			{ 's18_police_7', 's18_police_8', 's18_police_9' }, 0.7, false)
		return true
	end
end

function local_class:on_stage_end_event()
	self.stage_ended = true
end
--endregion

--region late_update_frame
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
--endregion

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:set_dead_npc(quest_progress)
	self:set_swat_event(quest_progress)
	self:set_stage_object(quest_progress)
	self:set_cracked_space_effect()

	if quest_progress.InnerProgress > 18 then
		self:create_red_ice()
		if not quest_progress.IsComplete then
			self:set_tanker()
		end
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 18 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s19_start')
		, true, true)
	elseif quest_progress.InnerProgress == 19 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s20_start')
		, true, true)
	elseif quest_progress.InnerProgress == 20 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s20_1_knight_1')
		, false, false)
	else
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

-- 경찰 세팅
function local_class:set_dead_npc(quest_progress)
	-- 클리어하지 않은 경우에만
	if not quest_progress.IsComplete then
		self.eat_sfx_1 = music_player_util.play_sfx({ sfx_name = '01_eat_01', loop = true, play_pos = vector(10, 0, -10), type_priority =
		'loop' })
		for i = 1, 10 do
			local police = get_character('s18_police_' .. i)
			character_util.add_color(police, police.Name, unity_class.color.black, 1, 0)
			police.SpineController.AlwaysUpdateSpine = true
		end

		coroutine.yield(nil)
		for i = 1, 10 do
			local police = get_character('s18_police_' .. i)
			police.SpineController.AlwaysUpdateSpine = false
		end

		-- 섹션18 전용 연출
		if quest_progress.InnerProgress < 18 then
			self.ended_explosion_scene_1 = false
			for i = 7, 9 do
				local police = get_character('s18_police_' .. i)
				character_util.add_color(police, police.Name, unity_class.color.black, 1, 0)
			end
		else
			for i = 7, 9 do
				local police = get_character('s18_police_' .. i)
				local effect = self.fx:black_liquid():Instantiate(police.Position)
				local angle = police.Direction == CS.Oak.Direction.Left and 180 or 0
				effect.transform.rotation = unity_class.quaternion.Euler(0, angle, 0)
				table.insert(self.virus_explosion_effect, effect)
				character_util.set_active_state(police, 'disabled')
			end
		end
	end
end

-- 특공대 세팅
function local_class:set_swat_event(quest_progress)
	-- 클리어하지 않은 경우에만
	if not quest_progress.IsComplete then
		local ammo_pos = field_util.get_marker_pos('s19_ammo_pos')
		local potion_pos = field_util.get_marker_pos('s19_potion_pos')
		local engineer_basket_pos = get_character('teatan_hero').Position + vector(1, 0, 0)
		self.ammo = drop_item_util.create_item({
			itemid = self.ammo_id,
			pos = ammo_pos,
			notforinven = true,
			skip_text = true,
			lootstate = 'dontfindlooter'
		})

		self.potion = drop_item_util.create_item({
			itemid = self.potion_id,
			pos = potion_pos,
			notforinven = true,
			skip_text = true,
			lootstate = 'dontfindlooter'
		})

		self.engineer_basket = drop_item_util.create_item({
			itemid = self.engineer_basket_id,
			pos = engineer_basket_pos,
			notforinven = true,
			skip_text = true,
			lootstate = 'dontfindlooter'
		})

		self.eat_sfx_2 = music_player_util.play_sfx({ sfx_name = '03_equipping_01',
			loop = true,
			play_pos = get_character('teatan_hero').Position,
			volume = 0.3,
			type_priority = 'loop'
		})
		self.eat_sfx_3 = music_player_util.play_sfx({ sfx_name = '03_equipping_01',
			loop = true,
			play_pos = ammo_pos + vector(-1, 0, 0),
			volume = 0.3,
			type_priority = 'loop'
		})

		start_coroutine(self.swat_fight_routine, self, 1, 0)
		start_coroutine(self.swat_fight_routine, self, 2, 3.6)
		start_coroutine(self.set_swat_shield, self)
	end
end

function local_class:set_stage_object(quest_progress)
	if quest_progress ~= nil then
		if quest_progress.IsComplete or quest_progress.InnerProgress > 20 then
			-- 스테이지 클리어 이후에는 exit로 변경
			local exit_fo = get_field_object(self.stage_exit_name)
			local entrance = get_field_object('other_world_entrance_in')

			exit_fo.Position = entrance.Position
			entrance.Position = vector(999, 0, 999)
		end
	end
end

-- 라보스 바이러스 폭발 연출
function local_class:virus_explosion_scene(npcs, term, is_main)
	for i = 1, #npcs do
		start_coroutine(function()
			local npc = get_character(npcs[i])
			if is_main then
				music_player_util.play_sfx({ sfx_name = '02_hit_sneak_blood_01', play_pos = npc.Position })
			end
			character_util.shake(npc, 0.03, 0.5)
			character_util.spine_scale(npc, unity_class.vector3.one * 0.7, 0.5)
			wait_for_sec(0.5)

			if self.stage_ended then
				return
			end

			if is_main then
				camera_util.shake(0.07, 0.2)
			end
			self.fx:virus_explosion():Instantiate(npc.Position)
			music_player_util.play_sfx({ sfx_name = '01_fly_explosion_02', play_pos = npc.Position })

			if self.virus_explosion_effect ~= nil then
				local effect = self.fx:black_liquid():Instantiate(npc.Position)
				local angle = npc.Direction == CS.Oak.Direction.Left and 180 or 0
				effect.transform.rotation = unity_class.quaternion.Euler(0, angle, 0)
				table.insert(self.virus_explosion_effect, effect)
			end
			character_util.set_position(npc, vector(999, 0, 999))
		end)
		wait_for_sec(term)

		if self.stage_ended then
			return
		end
	end
end

-- 크랙 이펙트 세팅
function local_class:set_cracked_space_effect()
	local cracked_space_pos = {
		vector(62.5, 3, -27.25),
		vector(17, 3, -86.5),
		vector(48.5, 3, -108.5),
		vector(96.5, 3, -89.5),
		vector(84, 3, -100)
	}
	for i = 1, #cracked_space_pos do
		table.insert(self.cracked_space_effect, self.fx:cracked_space():Instantiate(cracked_space_pos[i]))
	end
end

-- 코코 얼음 이펙트 세팅
function local_class:create_red_ice()
	local pos = field_util.get_marker_pos('red_ice_pos_1')
	local row = 2
	local col = 4

	for i = 1, row do
		for k = 1, col do
			table.insert(self.red_ice_effect, self.fx:red_ice():Instantiate(pos + vector(i, 0.1, k)))
		end
	end
end

-- 방패 swat npc 세팅
function local_class:set_swat_shield()
	local swat_3 = get_character('s19_swat_3')
	local swat_4 = get_character('s19_swat_4')

	character_util.set_anim(swat_3, { name = 'spear_shield_guard' })
	character_util.set_anim(swat_4, { name = 'spear_shield_guard' })
	character_util.spine_set_attachment(swat_3, '[base]weapon1', 'empty')
	character_util.spine_set_attachment(swat_3, '[base]weapon2', 'shield_police_shield')
	character_util.spine_set_attachment(swat_4, '[base]weapon1', 'empty')
	character_util.spine_set_attachment(swat_4, '[base]weapon2', 'shield_police_shield')
	character_util.shake(swat_3, 0.03, 99999)
	character_util.shake(swat_4, 0.03, 99999)

	for i = 3, 5 do
		local creature = get_character('s19_labose_creature_' .. i)
		local start_pos = field_util.get_marker_pos('s19_labose_creature_start_' .. i)
		character_util.set_position(creature, start_pos)
		character_util.set_direction(creature, 'left')
		character_util.set_anim(creature, {
			name = 'bomb_attack',
			sfx_name = function()
				self.fx:last_hit():Instantiate(creature.Position + vector(-1, 0.03, 0))
				self.fx:hit():Instantiate(creature.Position + vector(-1, 0.03, 0))
				music_player_util.play_sfx({ sfx_name = '02_hit_big_01', parent = creature, volume = 0.4 })
			end
		})
		wait_for_sec(0.2)
	end
end

-- 크레이그 세팅
function local_class:set_tanker()
	local tanker = get_character('tanker')

	character_util.shake(tanker, 0.03, 99999)
	character_util.spine_set_attachment(tanker, '[base]weapon1', 'empty')
	character_util.spine_set_attachment(tanker, '[base]weapon2', 'empty')

	if self.tanker_shield_effect == nil then
		self.tanker_shield_effect = self.fx:tanker_shield():Instantiate(tanker.Position +
			vector(0.3, 0, 0))
		self.tanker_shield_effect.transform.rotation = unity_class.quaternion.Euler(0, 90, 0)
	end
end

-- 특공대 전투 연출
function local_class:swat_fight_routine(idx, wait)
	local swat = get_character('s19_swat_' .. idx)
	local creature = get_character('s19_labose_creature_' .. idx)
	local start_pos = field_util.get_marker_pos('s19_labose_creature_start_' .. idx)
	local end_pos = field_util.get_marker_pos('s19_labose_creature_end_' .. idx)
	local creature_dir = 'right'
	local bullet_angle = -90
	local effect_angle = 180
	local bullet_speed = 12
	local bullet_start_pos = swat.Position + vector(-0.6, 1, -0.4)
	local bullet_dir_vec = unity_class.vector3.left

	swat.SpineController.AlwaysUpdateSpine = true
	creature.SpineController.AlwaysUpdateSpine = true

	field_ui_manager:RemoveUI(creature, CS.Oak.FieldUiType.CharacterStats)
	character_util.set_direction(creature, creature_dir)
	swat.CustomIdleAnimationName = 'rifle_idle'
	CS.Oak.CharacterControllerScreenplayState.Stop(swat)

	local fight_state = {
		appear = 1,
		aiming = 2,
		shoot = 3,
		kill = 4,
		wait = 5,
	}
	local state = fight_state.appear

	local bullets = {
		{
			pool = nil,
			sprite = nil,
			shot = false,
			hit = false,
		},
		{
			pool = nil,
			sprite = nil,
			shot = false,
			hit = false,
		},
		{
			pool = nil,
			sprite = nil,
			shot = false,
			hit = false,
		},
		{
			pool = nil,
			sprite = nil,
			shot = false,
			hit = false,
		},
		{
			pool = nil,
			sprite = nil,
			shot = false,
			hit = false,
		},
		{
			pool = nil,
			sprite = nil,
			shot = false,
			hit = false,
		},
	}

	-- 총알 프로젝타일 스프라이트 생성
	local res_holder = CS.Foundations.ResourceHolder()
	local custom_atlas
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
		res_holder, 'spritesheets/projectiles', 'projectiles_custom', function(prefab)
			custom_atlas = prefab.transform:GetComponent(typeof(CS.CustomAtlas))
			custom_atlas:Initialize()
		end)

	for i = 1, #bullets do
		bullets[i].pool = self.fx:custom_sprite():Instantiate(unity_class.vector3.one)
		bullets[i].sprite = bullets[i].pool.transform:GetComponent(typeof(CS.CustomSprite))
		bullets[i].sprite.transform.localPosition = vector(999, 0, 999)
		bullets[i].sprite.transform.localRotation = unity_class.quaternion.Euler(90, bullet_angle, 0)
		bullets[i].sprite.transform.localScale = unity_class.vector3.one
		bullets[i].sprite.LocalScale = unity_class.vector2.one
		bullets[i].sprite.Atlas = custom_atlas
		bullets[i].sprite.SpriteName = 'small_shot_normal.png'
		bullets[i].sprite:Rebuild()
	end

	self:custom_wait_for_sec(wait)

	local appear_wait_time = 0.5
	local move_duration = 2.5
	local time_passed = 0
	local creature_alive = true
	local shoot_period = 0.33
	local shoot_time = 0.6 - shoot_period
	local is_hit = nil
	local kill_time = 0
	local kill_duration = 2
	local wait_time = 0
	local wait_duration = 3

	while not self.stage_ended do
		if creature_alive then
			creature.Position = unity_class.vector3.Lerp(start_pos, end_pos,
				unity_class.mathf.Clamp01(time_passed / move_duration))
		end

		if state == fight_state.appear then
			character_util.set_position(creature, start_pos)
			scene_util.set_anim(creature, self, 'walk')
			character_util.spine_set_alpha_fade(creature, 1, 0)
			creature_alive = true
			shoot_time = 0.6 - shoot_period
			time_passed = 0

			for i = 1, #bullets do
				bullets[i].shot = false
				bullets[i].hit = false
			end

			state = fight_state.aiming
		elseif state == fight_state.aiming then
			if time_passed >= appear_wait_time then
				scene_util.set_anim(swat, self, 'rifle_shoot')
				state = fight_state.shoot
			end
		elseif state == fight_state.shoot then
			for i = 1, #bullets do
				if not bullets[i].shot then
					if time_passed >= shoot_time + (shoot_period * i) then
						bullets[i].shot = true
						self.fx:shot_gun():Instantiate(bullet_start_pos,
							unity_class.quaternion.Euler(vector(0, effect_angle, 0)), swat.Transform)
						bullets[i].sprite.transform.position = bullet_start_pos
						music_player_util.play_sfx({ sfx_name = '02_gun_shoot_01', parent = swat, volume = 0.4 })
					end
				elseif not bullets[i].hit then
					is_hit = creature.Position.x >= bullets[i].sprite.transform.position.x and true or false

					if is_hit then
						bullets[i].hit = true
						self.fx:hit():Instantiate(creature.Position + vector(0, 0.1, 0))
						self.fx:last_hit():Instantiate(creature.Position + vector(0, 0.1, 0))

						character_util.spine_damage_squish(creature, 1.3, 0.7, 1, 0.2)
						character_util.spine_pulse_color(creature,
							CS.Oak.Constants.DamageColor, 1, 1, 0.5)

						bullets[i].sprite.transform.position = vector(999, 0, 999)

						if i == #bullets then
							scene_util.set_anim(creature, self, { name = 'dead', sfx_name = false })
							music_player_util.play_sfx({ sfx_name = '02_gun_reload_03', parent = swat, volume = 0.3 })
							scene_util.set_anim(swat, self, { name = 'rifle_reload', count = 1 })
							creature_alive = false
							kill_time = time_passed
							state = fight_state.kill
						end
					else
						bullets[i].sprite.transform.position = bullets[i].sprite.transform.position +
							(bullet_dir_vec * bullet_speed * unity_class.time.deltaTime)
					end
				end
			end
		elseif state == fight_state.kill then
			if time_passed >= kill_time + kill_duration then
				wait_time = time_passed
				character_util.spine_set_alpha_fade(creature, 0, 1)
				state = fight_state.wait
			end
		elseif state == fight_state.wait then
			if time_passed >= wait_time + wait_duration then
				state = fight_state.appear
			end
		end

		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield(nil)
	end

	for i = 1, #bullets do
		if bullets[i].pool ~= nil then
			bullets[i].sprite = nil
			bullets[i].pool:Dispose()
		end
	end
	bullets = nil
end

function local_class:custom_wait_for_sec(duration)
	local end_time = unity_class.time.time + duration
	while not self.stage_ended and unity_class.time.time < end_time do
		coroutine.yield()
	end
	return
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
