local local_class = newclass("ShortStoryBari")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	--region merchant

	self.bari_flower_garden_quest_id = 7000505

	-- npc 받는 함수
	self.get_merchant = function() return get_character('flower_garden_merchant') end

	-- 상인이 파는 아이템
	self.sell_item = {
		soil_potion = (1 << 0)
	}
	self.bought_item = 0

	-- 상인 위치
	self.merchant_pos = vector(100.7, 0, -21.25)

	-- (토양 포션, 식물 씨앗) 아이템 정보
	self.item_info = {
		soil_potion = {id = 20296, pos = self.merchant_pos}
	}

	--endregion

	--region red flower tutorial

	-- 튜토리얼 존 이름
	self.red_flower_zone_name = 'red_flower_tutorial_zone'

	-- 튜토리얼에서 사용되는 꽃 헨들네임
	self.red_flower_name = 'tutorial_red_flower'

	self.red_flower_tutorial_cleared = false

	self.shoot_helper = nil

	self.red_flower_tutorial_custom_state_key = 'red_flower_tutorial'
	self.red_flower_tutorial_cleared = false
	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local bari = get_character('bari')
	local mayreel = get_character('mayreel')
	self.main_quest_id = 7000501
	self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	local nol = false
	if self.main_quest_progress == nil or self.main_quest_progress.InnerProgress < 1 then
		nol = true
	end
	local pos = field:GetMarker('default_start').position
	if nol then	pos = field:GetMarker('pre_start').position end
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = true
	character_util.set_position(bari, pos)
	character_util.set_position(mayreel, pos + vector(-0.7, 0, 0))
	character_util.convert_to_manual_character(bari, param)
	character_util.convert_to_party_member(mayreel, user_party, true)

	return nol
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded()
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	end

	return false
end

function local_class:on_stage_loaded()
	local merchant = self.get_merchant()
	character_util.add_listener(merchant, self)
	character_util.set_position(merchant, self.merchant_pos)
	character_util.set_emotion(merchant, {name = 'smile'})

	-- 아이들의 꽃밭 이벤트가 클리어된 상태면 토양 포션을 팔지 않는다.
	if user_progress:ClearedQuest(self.bari_flower_garden_quest_id) == true then
		self.bought_item = self.bought_item | self.sell_item.soil_potion
	end

	-- custom state 로 바꿀 예정
	local qp = user_progress:GetStartedQuest(7000501)
	local custom_state_val = quest_util.get_custom_state(qp, self.red_flower_tutorial_custom_state_key)
	if custom_state_val ~= 1 then
		local spec = CS.Oak.GameDataService.GetData("ProjectileData"):GetSpec('flower_girl_proj_cwp')
		local pattern_Info = CS.Oak.ShootPatternInfo()
		pattern_Info.columns = 1
		pattern_Info.spreadDistance = 0
		pattern_Info.parallel = true

		-- ShootHelper 설정
		local ps = CS.Oak.LuaIProjectileShooter(self, get_character('mayreel'))
		self.shoot_helper = CS.Oak.ShootHelper(CS.Oak.Projectile.MoveType.Directional,
				ps, spec, pattern_Info, CS.Oak.ShootHelperShootEffectType.EachShoot, 0,
				CS.Oak.WeaponType.Custom, CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick)

		self.red_flower_original_pos = get_field_object('tutorial_red_flower').Position
	elseif custom_state_val == 1 then
		self.red_flower_tutorial_cleared = true
	end
end

function local_class:on_interact_event(e)
	local merchant = self.get_merchant()

	if lua_helper.reference_equals(e.Target, merchant) then
		sp_util.play_normal_screenplay(self.merchant_event, self)
	end
end

function local_class:on_zone_enter_event(e)

	if type_util.is_zone_full_enter(e, user_party.Leader, self.red_flower_zone_name)
			and not self.red_flower_tutorial_cleared then
		sp_util.play_normal_screenplay(self.red_flower_tutorial_event, self)
	end
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
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	character_util.remove_relate_event(self.get_merchant(), self)

	self.cs_controller = nil
	self.scene = nil
end

function local_class:red_flower_tutorial_event()
	local mayreel = get_character('mayreel')
	local red_flower = get_field_object(self.red_flower_name)
	local bari = user_party.Leader
	local jump_dur = 0.3

	character_util.move_to_async(mayreel, bari.Position + vector(0, 0, -0.5),
			nil, 2, true, true)

	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(mayreel, 0.5, jump_dur)
	character_util.show_emoticon_async(mayreel, nil, 'notice')

	character_util.move_waypoint_async(mayreel,
			{vector(mayreel.Position.x, 0, red_flower.Position.z), red_flower.Position + vector(1, 0, 0)},
			4, false, nil, nil, 'left', true)

	-- 먹는 게 아니에요, 메이릴!
	speech_bubble_util.show_speech_bubble_async(bari, {key = 'short_story_bari_red_flower_1', skip = true})

	character_util.set_anim(mayreel, {name = 'unique/mayreel_draw'})
	red_flower:Shake(0.1, 9999)

	local timer = 0
	local inhale_time = 1
	local hold_time = 2

	character_util.set_direction(bari, 'down')
	character_util.set_emotion(bari, {name = 'surprise'})

	-- 메이릴 꽃 빨아 들이는 연출
	music_player_util.play_sfx_one_shot('01_fat_gnome_01')
	mayreel.SpineController:AddColor('default_curby', unity_color({ 1, 0.8, 0.8, 1 }), 1, 0.7)

	music_player_util.play_sfx_one_shot('01_mayreel_baloon_01')
	while timer < inhale_time do
		timer = timer + unity_class.time.deltaTime

		self:shrink_and_move(red_flower, mayreel.Position + vector(0, 0.3, 0),
				timer, inhale_time * 0.5, 0.5)

		local progress = unity_class.mathf.Clamp01((timer - inhale_time * 0.5) / inhale_time) * 0.5
		character_util.set_scale_factor(mayreel, 'default_curby_scale', 1 + progress)

		coroutine.yield(nil)
	end

	character_util.set_anim(mayreel, {name = 'unique/mayreel_clamp'})
	red_flower:CancelShake()

	mayreel.Holdable = CS.Oak.Holdable()

	character_util.move_waypoint_async(bari, vector(mayreel.Position.x + 1, 0, mayreel.Position.z),
			4, false, nil, nil, 'left', true)

	command_util.execute_holdup(bari, mayreel, bari.Position)

	-- 바리가 메이릴 들고 당황하는 연출
	timer = 0
	local dir = {'right', 'left', 'right'}
	local dir_change_time = 0.5
	local dir_changed_num = 1
	local mult = 2
	local pt = timer
	while timer < hold_time do
		timer = timer + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01((unity_class.mathf.Cos(timer * mult * 2 * unity_class.mathf.PI) + 1) / 2) * 0.8
		mayreel.SpineController:AddColor('bomb_timer', unity_color({ 1, progress, progress, 1 }), 1, 0)

		if timer - pt >= 0.5 then
			pt = timer
			music_player_util.play_sfx_one_shot('02_bomb_count_tick_01')
		end

		if timer >= dir_change_time * dir_changed_num and dir_changed_num <= table_util.get_size(dir) then
			character_util.set_group_direction({bari, mayreel}, dir[dir_changed_num])
			dir_changed_num = dir_changed_num  + 1
		end

		coroutine.yield(nil)
	end

	character_util.set_anim(mayreel, {name = 'unique/mayreel_spit_start', next_anim = 'unique/mayreel_spit_loop', loop = false})
	local shoot_dir = (direction_util.to_vector3(mayreel.Direction) * 7 - vector(0, mayreel.Position.y + 0.5, 0)).normalized
	self.shoot_helper:ShootDirectionAtPosition(mayreel.Position + vector(0, 0.5, 0), shoot_dir)

	wait_for_sec(0.25)
	character_util.set_anim(mayreel, {name = 'unique/mayreel_spit_end', loop = false})
	wait_for_sec(0.25)

	-- 신속탄 쏘는 연출
	mayreel.SpineController:RemoveColor('default_curby', 0)
	mayreel.SpineController:RemoveColor('bomb_timer', 0)
	local routines = {}
	routines[1] =  coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reset_party, self))
	routines[2] = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.regen_flower, self))

	coroutine_util.wait_coroutines(routines)

	for i = 1, 2 do
		music_player:PlaySfxOneShot('01_small_jump_01')
		character_util.jump(mayreel, 0.5, jump_dur)
		wait_for_sec(jump_dur)
	end

	character_util.set_emotion(bari, {name = 'scared'})
	-- 정말 놀랐어요, 메이릴.
	speech_bubble_util.show_speech_bubble_async(bari, {key = 'short_story_bari_red_flower_2', skip = true})

	character_util.set_emotion(mayreel, {name = 'smile'})
	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(mayreel, 0.5, jump_dur)
	wait_for_sec(jump_dur + 0.1)

	character_util.set_emotion(bari, {name = 'smile'})
	-- 메이릴은 재미있었나보군요?
	speech_bubble_util.show_speech_bubble_async(bari, {key = 'short_story_bari_red_flower_3', skip = true})

	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(mayreel, 0.5, jump_dur)
	wait_for_sec(jump_dur + 0.1)

	-- 좋아요. 그럼 단단한 장애물을 부술 때만이에요. 알았죠?
	speech_bubble_util.show_speech_bubble_async(bari, {key = 'short_story_bari_red_flower_4', skip = true})

	yield_return_func(self.mayreel_rotate, self, 0.5, 0.3)
	character_util.remove_group_emotion({bari, mayreel})

	local qp = user_progress:GetStartedQuest(7000501)
	if quest_util.get_custom_state(qp, self.red_flower_tutorial_custom_state_key) ~= 1 then
		quest_util.set_custom_state(qp, self.red_flower_tutorial_custom_state_key, 1)
		self.red_flower_tutorial_cleared = true
	end
end

function local_class:mayreel_rotate(height, duration)
	local mayreel = get_character('mayreel')
	local bari = user_party.Leader

	character_util.set_direction(mayreel, 'left')
	music_player:PlaySfxOneShot('01_small_jump_01')
	mayreel:Jump(height, duration)
	character_util.move_to_async(mayreel, bari.Position + vector(0, 0, 1), duration,
			nil, false, false, false)

	coroutine.yield(nil)

	character_util.set_direction(mayreel, 'left')
	music_player:PlaySfxOneShot('01_small_jump_01')
	mayreel:Jump(height, duration)
	character_util.move_to_async(mayreel, bari.Position + vector(-1, 0, 0), duration,
			nil, false, false, false)

	coroutine.yield(nil)

	character_util.set_direction(mayreel, 'right')
	music_player:PlaySfxOneShot('01_small_jump_01')
	mayreel:Jump(height, duration)
	character_util.move_to_async(mayreel, bari.Position + vector(0, 0, -1), duration,
			nil, false, false, false)

	coroutine.yield(nil)

	character_util.set_direction(mayreel, 'right')
	music_player:PlaySfxOneShot('01_small_jump_01')
	mayreel:Jump(height, duration)
	character_util.move_to_async(mayreel, bari.Position + vector(1, 0, 0), duration,
			nil, false, false, false)

	coroutine.yield(nil)

end

function local_class:reset_party()
	local mayreel = get_character('mayreel')
	local bari = user_party.Leader

	character_util.remove_scale_factor(mayreel, 'default_curby_scale')

	music_player_util.play_sfx({sfx_name = '02_bomb_respawn_01', play_pos = self.red_flower_original_pos})
	wait_for_sec(0.2)

	character_util.clear_holdup_state(bari, mayreel)
	character_util.remove_anim_and_emotion(mayreel)
	character_util.set_active_shadow(mayreel, true)
	music_player_util.play_sfx_one_shot('01_throw_01')
	character_util.set_direction(bari, 'right')
	character_util.set_animation_n_times(bari, {name = 'throw', count = 1})
	character_util.jump_move(mayreel, bari.Position + vector(0.7, 0, 0), 4, 0.7, true, 'left')

	wait_for_sec(0.2)
	mayreel.Holdable = CS.Oak.NonHoldable.Instance
end

function local_class:regen_flower()
	local red_flower = get_field_object(self.red_flower_name)
	local timer = 0

	red_flower.Position = self.red_flower_original_pos
	red_flower.transform.localScale = unity_class.vector3.zero

	while timer < 1 do
		timer = timer + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01(timer / 1)

		red_flower.transform.localScale = vector(progress, progress, progress)
		coroutine.yield(nil)
	end
end

function local_class:shrink_and_move(target, destination, timer, duration, t_offset)
	local final_duration = duration

	local progress = unity_class.mathf.Clamp01((timer - t_offset) / final_duration)

	local scale_prog = unity_class.mathf.Clamp01(1 - progress * 1.2)
	target.Transform.localScale = vector(scale_prog, scale_prog, scale_prog)
	target.Position = target.Position + (destination - target.Position) * (progress * 0.5)
end

function local_class:on_hit(move_info, hit_info, label)
	if self.shoot_helper == nil then return true end

	self.shoot_helper:OnHit(hit_info)

	local pos = hit_info.position
	local fo_list = field:GetFieldObjectsInRadius(vector_util.get_x0z(pos), 2)

	for _,v2 in pairs(fo_list) do
		damaged_behaviour = v2.DamagedBehaviour
		if lua_helper.type_compare(damaged_behaviour, CS.Oak.RockDamagedBehaviour) or
				lua_helper.type_compare(damaged_behaviour, CS.Oak.PotDamagedBehaviour) then

			--- 대미지 적용
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
			damage_info.sender = user_party.Leader
			damage_info.target = v2
			damage_info.damage = 100

			command_util.execute_damage(damage_info)
		end
	end

	return true
end

function local_class:merchant_event()
	local merchant = self.get_merchant()
	local bari = user_party.Leader
	-- enum의 number는 선택지 ans와 동일하게 설정 해야함
	local enum = {soil_potion = 1, seed = 2, none = 3}

	party_util.align_party(merchant.Position, 'down', 1)

	-- 선택지 정보 테이블: 대사, 성향, ans 넘버
	local choice_info = {
		-- 토양 포션(10골드)
		{'shortstory_bari_flower_garden_37', CS.Oak.TalkTendency.Mercy, enum.soil_potion},
		-- 아무것도 필요없다.
		{'shortstory_bari_flower_garden_39', CS.Oak.TalkTendency.Normal, enum.none}
	}

	-- 실제로 표시할 선택지 테이블에 담기
	local display_choice = {}
	for i = 1, table_util.get_size(self.sell_item) do
		local sell_num = 1 << (i - 1)
		if sell_num ~= (self.bought_item & sell_num) then
			table.insert(display_choice, choice_info[i])
		end
	end

	if table_util.get_size(display_choice) == 0 then
		-- 준비한 화훼 상품이 다 떨어졌네요. 다음에 찾아주세요.
		speech_bubble_util.show_speech_bubble_async(merchant, {key = 'shortstory_bari_flower_garden_78', skip = true})
		return
	end

	music_player_util.play_sfx_one_shot('01_bell_02')
	-- 어서오세요, 어떤 화훼 용품이 필요하신가요?
	speech_bubble_util.show_speech_bubble_async(merchant, {key = 'shortstory_bari_flower_garden_36', skip = true})

	-- 마지막 선택지 '아무것도 필요없다' 추가
	table.insert(display_choice, choice_info[table_util.get_size(choice_info)])

	-- display_choice에 담긴 선택지 출력
	local wait = true
	local ans = enum.none

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	for i = 1, table_util.get_size(display_choice) do
		local info = display_choice[i]
		branches:Add({
			Text = game_string:GetString(info[1]),
			Tendency = info[2],
			Callback = function()
				wait = false
				ans = info[3]
			end
		})
	end

	ui_overlay_util.push_overlay(nil, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- 선택지에 따른 연출
	if ans ~= enum.none then
		local item_name = nil
		local item = nil

		if ans == enum.soil_potion then
			music_player_util.play_sfx_one_shot('03_drop_gold_01')
			item_name = 'soil_potion'
			self.bought_item = self.bought_item | self.sell_item.soil_potion
		elseif ans == enum.seed then
			item_name = 'seed'
			self.bought_item = self.bought_item | self.sell_item.seed
		end

		wait_for_sec(0.5)
		music_player_util.play_sfx_one_shot('01_small_jump_01')
		character_util.set_emotion(merchant, {name = 'awesome'})
		character_util.jump(merchant, 0.5, 0.3)
		wait_for_sec(0.5)

		local equip_sfx = music_player_util.play_sfx({sfx_name = '03_equipping_01', loop = true})
		character_util.set_direction(merchant, 'left');
		character_util.set_anim(merchant, {name = 'eat', loop = true})
		wait_for_sec(1.5)
		equip_sfx:FadeOut(0)
		character_util.remove_anim(merchant)
		character_util.set_emotion(merchant, {name = 'smile'})
		character_util.look_at(merchant, bari)
		character_util.set_anim(merchant, {name = 'release', loop = false, next_anim = 'idle', sfx_name = '01_throw_01'})

		item = drop_item_util.create_item({
			pos = self.item_info[item_name].pos, target = bari.Position + vector(0, 0, 0.3), itemid = self.item_info[item_name].id,
			notforinven = true, lootstate = 'dontfindlooter', showoncharacter = true })

		wait_for_sec(1)
		character_util.remove_anim(bari)
		item.ConsumeTarget = bari
		item:Fly()
	end

	-- 감사합니다. 또 찾아주세요!
	speech_bubble_util.show_speech_bubble_async(merchant, {key = 'shortstory_bari_flower_garden_40', skip = true})
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
