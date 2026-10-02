local local_class = newclass("LilithTowerPickpocketController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 이름
	self.stage_2_name = 'lilithtower_1_2'
	self.stage_3_name = 'lilithtower_1_3'

	-- 대사
	self.main_script = 'lilith_tower_pickpocket_'

	-- 소매치기
	self.mugger = nil
	self.mugger_name = 'mugger'

	-- 소매치기 이벤트 발생을 위해 Interact 해야 하는 오브젝트
	self.interact_obj = nil

	-- DropItem
	self.drop_item = nil

	-- 소매치기 소녀 활성화 여부
	self.pickpocket_activated = false

	-- 소매치기 소녀 퀘스트
	self.mugger_quest_id = 261
	self.mugger_quest_cleared_custom_event = 'mugger_quest_cleared'

	-- 2스테이지 이벤트


	-- 3스테이지 이벤트
	self.stage_3_sleep_terrorist = nil
	self.stage_3_sleep_terrorist_name = 'sleep_terrorist'

	self.stage_3_interact_obj_name = 'mugger_key'
	self.stage_3_interact_item_id = 30037

	self.stage_3_floating_item_name = 'mugger_key_item'

	self.stage_3_reset_marker_name = 'pickpocket_reset_marker'

	self.stage_3_keydoor_name = 'machinery_room_entry_door'

	-- 리소스 로드
	self.res_holder = nil
	self.custom_atlas = nil

	-- 프로젝타일
	self.pooled_bullet = nil

	-- 오브젝트 풀
	self.custom_sprite_preset = 'custom_sprite'
	self.hit_projectile_preset = "fx_virus_bullet_proj_groundhit"
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.GotCrashedEvent), 'on_got_crashed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.mugger = get_character(self.mugger_name)

	-- 소매치기 소녀 퀘스트 클리어 여부 체크
	local quest_progress = user_progress:GetStartedQuest(self.mugger_quest_id)

	if quest_progress ~= nil and quest_progress.Grade > -1 then
		self.pickpocket_activated = true

		if self.mugger ~= nil then
			character_util.spine_set_alpha_fade(self.mugger, 0, 0)
		end
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate(self.custom_sprite_preset)
	unity_object_pool.GetOrCreate(self.hit_projectile_preset)

	yield_return(unity_object_pool, 'WaitAll')

	self.res_holder = CS.Foundations.ResourceHolder()

	-- 총알 프리로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'spritesheets/projectiles', 'projectiles_custom', function(prefab)
				self.custom_atlas = prefab.transform:GetComponent(typeof(CS.CustomAtlas))
				self.custom_atlas:Initialize()
			end)

	self.pooled_bullet = unity_object_pool.GetOrCreate('custom_sprite'):Instantiate(unity_class.vector3.one)

	local bullet_sprite = self.pooled_bullet.transform:GetComponent(typeof(CS.CustomSprite))
	bullet_sprite.transform.localPosition = unity_class.vector3.one * 999
	bullet_sprite.transform.localRotation = unity_class.quaternion.Euler(90, 0, 0)
	bullet_sprite.transform.localScale = unity_class.vector3.one
	bullet_sprite.LocalScale = unity_class.vector2.one
	bullet_sprite.Atlas = self.custom_atlas
	bullet_sprite.SpriteName = 'virus_bullet_1.png'
	bullet_sprite:Rebuild()
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	-- 스테이지 3의 경우
	if stage.Name == self.stage_3_name then
		self.stage_3_sleep_terrorist = get_character(self.stage_3_sleep_terrorist_name)

		self.interact_obj = get_field_object(self.stage_3_interact_obj_name)

		-- 아이템을 가지고 있거나 문이 열려 있으면 Interactable Object 비활성화
		local keydoor = get_field_object(self.stage_3_keydoor_name)

		if user:HasItem(self.stage_3_interact_item_id) or keydoor.FieldObjectBehaviour.Opened then
			self.pickpocket_activated = false

			stage_util.set_fo_active_state(self.stage_3_interact_obj_name, 'disabled')
		else
			self.drop_item = drop_item_util.create_item(
					{ itemid = self.stage_3_interact_item_id, notforinven = true, skip_text = true,
					  pos = self.interact_obj.Position, lootstate = "dontfindlooter", sprscale = 0.5 })

			self.drop_item:SetSortingLayer(true)
			self.drop_item:SetPosition(vector(-0.3, 0, 131), true)
			self.drop_item.SpriteTransform.localPosition = vector(0, 0.7, 0)
			self.drop_item.ShadowTransform.localPosition = vector(0, 0.5, 0)
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.interact_obj) then
		if stage.Name == self.stage_3_name then
			sp_util.play_normal_screenplay(self.stage_3_pickpocket_event, self)
		end
	end
end

function local_class:on_got_crashed_event(e)
	if stage.Name == self.stage_3_name then
		if lua_helper.reference_equals(e.Crash.other, get_party_leader()) and
				lua_helper.reference_equals(e.Crash.self, self.stage_3_sleep_terrorist) then
			sp_util.play_normal_screenplay(self.stage_3_detect_event, self)
		end
	end
end

function local_class:on_custom_stage_event(e)
	-- 소매치기 소녀 퀘스트 클리어 여부 체크
	if e:GetParamAt(0) == self.mugger_quest_cleared_custom_event then
		self.pickpocket_activated = true

		if self.mugger ~= nil then
			character_util.spine_set_alpha_fade(self.mugger, 0, 0)
		end
	end
end

-- 3스테이지 소매치기 이벤트
function local_class:stage_3_pickpocket_event()
	party_util.align_party(
			vector(self.stage_3_sleep_terrorist.Position.x, 0, self.stage_3_sleep_terrorist.Position.z),
			'right', 1, 'arc')

	field_ui_util.show_narration_async({ key = self.main_script..1 })

	local choose_result

	if self.pickpocket_activated then
		choose_result = choose_util.play_choose_event(
				{ { self.main_script..2, 'intellect' }, { self.main_script..3, 'forced' },
				  { self.main_script..6, 'mercy' }, { self.main_script..7, 'normal' } })
	else
		choose_result = choose_util.play_choose_event(
				{ { self.main_script..2, 'intellect' }, { self.main_script..3, 'forced' },
				  { self.main_script..7, 'normal' } })
	end

	if choose_result <= 2 then
		self:stage_3_pickpocket_fail_event()

		return
	elseif (self.pickpocket_activated and choose_result == 4) or
			(not self.pickpocket_activated and choose_result == 3) then
		return
	end

	music_player_util.play_sfx_one_shot('01_phone_receive_02')

	character_util.set_anim(get_party_leader(), { name = 'dualgun_reload_start', loop = false, upper = true })

	wait_for_sec(0.3)

	local phone = drop_item_util.create_item(
			{itemid = 20017, pos = get_party_leader().Position + vector(0.15, 0, -0.1),
			 notforinven = true, lootstate = 'dontfindlooter', showoncharacter = true, sprscale = 0.6})
	phone.SpriteTransform.localPosition = vector(0, 0.8, 0)
	phone.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 90, 0)

	wait_for_sec(1.2)

	character_util.set_anim(get_party_leader(), { name = 'nod' })

	wait_for_sec(1)

	phone:ConsumeComplete()

	character_util.set_direction(get_party_leader(), 'right')
	character_util.remove_anim(get_party_leader())
	character_util.remove_anim(get_party_leader(), true)

	character_util.set_position(self.mugger, get_party_leader().Position + vector(12, 0, -1))
	character_util.set_active_state(self.mugger, 'enabled')
	character_util.spine_set_alpha_fade(self.mugger, 1, 0)

	wait_for_sec(0.5)

	character_util.set_anim(self.mugger, { name = 'run' })
	character_util.move_to_async(self.mugger, self.mugger.Position + vector(-10, 0, 0),
			2, nil, true, false, true)

	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')

	character_util.set_anim(self.mugger, { name = 'cast2' })
	character_util.set_emotion(self.mugger, { name = 'smile' })

	character_util.remove_anim(get_party_leader())

	speech_bubble_util.show_speech_bubble_async(self.mugger, { key = self.main_script..4, skip = true })

	character_util.remove_anim(self.mugger)
	character_util.remove_emotion(self.mugger)

	character_util.nod_twice(get_party_leader())

	character_util.set_direction(get_party_leader(), 'left')
	character_util.move_to(get_party_leader(), get_party_leader().Position + vector(2, 0, 0),
			2, nil, false, true)

	character_util.move_to_async(self.mugger, self.mugger.Position + vector(0, 0, -1),
			0.5, nil, true, true)

	character_util.move_to_async(self.mugger, self.mugger.Position + vector(-4, 0, 0),
			2, nil, true, true)

	character_util.move_to_async(self.mugger, self.mugger.Position + vector(0, 0, 2),
			2, nil, true, true)

	character_util.set_direction(self.mugger, 'right')
	character_util.set_anim(self.mugger, { name = 'cast' })

	wait_for_sec(1)

	local eat_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_grass_slide_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.mugger, { name = 'eat' })
	character_util.set_emotion(self.mugger, { name = 'attack' })

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('01_rustle_01')

	character_util.shake(self.stage_3_sleep_terrorist, 0.02, 1)

	wait_for_sec(2)

	eat_sfx:FadeOut()

	self.drop_item.ConsumeTarget = self.mugger
	self.drop_item:Fly()

	character_util.remove_anim(self.mugger)
	character_util.set_emotion(self.mugger, { name = 'smile' })

	wait_for_sec(1)

	character_util.move_to_async(self.mugger, self.mugger.Position + vector(0, 0, -2),
			2, nil, true, true)

	character_util.move_to_async(self.mugger, self.mugger.Position + vector(4, 0, 0),
			2, nil, true, true)

	character_util.set_direction(self.mugger, 'up')
	character_util.set_anim(self.mugger, { name = 'throw', sfx_name = '01_swing_01', loop = false, next_anim = 'idle' })

	character_util.set_direction(get_party_leader(), 'down')
	character_util.set_emotion(get_party_leader(), { name = 'smile' })

	wait_for_sec(0.3)

	local key = drop_item_util.create_item({ pos = self.mugger.Position, target = get_party_leader().Position,
	                                        itemid = self.stage_3_interact_item_id, notforinven = true,
	                                        lootstate = 'dontfindlooter', sprscale = 0.5 })
	key:SetSortingLayer(true)

	wait_for_sec(1)

	key.ConsumeTarget = get_party_leader()
	key:Fly()

	wait_for_sec(1)

	local clap_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_clap_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	music_player_util.play_sfx_one_shot('01_bad_fairy_01')

	character_util.set_anim(get_party_leader(), { name = 'clap' })

	character_util.set_side_direction(self.mugger)
	character_util.set_anim(self.mugger, { name = 'dance' })
	character_util.set_emotion(self.mugger, { name = 'doyagao' })

	wait_for_sec(2)

	clap_sfx:FadeOut()

	character_util.remove_anim(get_party_leader())
	character_util.remove_emotion(get_party_leader())

	character_util.set_anim(self.mugger, { name = 'run' })
	character_util.remove_emotion(self.mugger)
	character_util.move_to_async(self.mugger, self.mugger.Position + vector(10, 0, 0),
			1.67, nil, true, false, true)

	character_util.set_active_state(self.mugger, 'disabled')

	if not user:HasItem(self.stage_3_interact_item_id) then
		local floating_item = get_field_object(self.stage_3_floating_item_name)

		-- floating 아이템 획득처리
		stage:SendPickStageItem(floating_item.Name, nil, function(data)
			local has_value, value = data:TryGetValue('AddedItem')
			local added_item = value

			if added_item ~= nil then
				CS.Oak.StageProgress.Current:AddItem(floating_item.KeyIndex)

				has_value, value = added_item:TryGetValue('Id')
				local item_id = value

				has_value, value = user.Items:TryGetValue(item_id)
				if has_value then
					CS.Oak.AddItemStageLogic.Execute(value, get_party_leader())
				end
			end
		end)
	end

	self.pickpocket_activated = false

	stage_util.set_fo_active_state(self.stage_3_interact_obj_name, 'disabled')
end

-- 스테이지 3 소매치기 실패하는 이벤트
function local_class:stage_3_pickpocket_fail_event()
	local eat_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_grass_slide_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	music_player_util.play_sfx_one_shot('01_slide_01')

	character_util.set_side_direction(get_party_leader())
	character_util.set_anim(get_party_leader(), { name = 'eat' })

	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_rustle_01')

	character_util.shake(self.stage_3_sleep_terrorist, 0.02, 1)
	character_util.set_emotion(self.stage_3_sleep_terrorist, { name = 'damaged' })

	wait_for_sec(1)

	character_util.set_emotion(self.stage_3_sleep_terrorist, { name = 'sleep' })

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('01_rustle_01')

	character_util.shake(self.stage_3_sleep_terrorist, 0.04, 2)
	character_util.set_emotion(self.stage_3_sleep_terrorist, { name = 'damaged' })

	wait_for_sec(2)

	eat_sfx:FadeOut()

	coroutine.yield(self:stage_3_detect_event())
end

-- 스테이지 3 걸리는 이벤트
function local_class:stage_3_detect_event()
	music_player_util.play_sfx_one_shot('01_player_popup_01')
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')

	character_util.show_emoticon(self.stage_3_sleep_terrorist, nil, 'notice')
	character_util.look_at(self.stage_3_sleep_terrorist, get_party_leader())
	character_util.remove_anim(self.stage_3_sleep_terrorist)
	character_util.set_emotion(self.stage_3_sleep_terrorist, { name = 'surprise' })

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	music_player_util.play_sfx_one_shot('03_runaway_01')

	character_util.set_anim(self.stage_3_sleep_terrorist, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(self.stage_3_sleep_terrorist, { name = 'mad' })

	character_util.look_at(get_party_leader(), self.stage_3_sleep_terrorist)
	character_util.jump(get_party_leader(), 1, 0.5)
	character_util.set_anim(get_party_leader(), { name = 'embarrassed' })
	character_util.set_emotion(get_party_leader(), { name = 'scared' })

	speech_bubble_util.show_speech_bubble_async(
			self.stage_3_sleep_terrorist, { key = self.main_script..5, skip = true })

	character_util.set_anim(self.stage_3_sleep_terrorist,
			{ name = 'rifle_shoot', loop = false, next_anim = 'rifle_idle' })

	wait_for_sec(0.1)

	local target_pos = get_party_leader().Bounds.center
	local sniper_pos = self.stage_3_sleep_terrorist.Bounds.center
	local bullet_sprite = self.pooled_bullet.transform:GetComponent(typeof(CS.CustomSprite))

	music_player_util.play_sfx_one_shot('02_gun_shoot_08')

	bullet_sprite.transform.position = sniper_pos

	local look_rotation = unity_class.quaternion.LookRotation(target_pos - sniper_pos)
	bullet_sprite.transform.localRotation = look_rotation * unity_class.quaternion.Euler(90, 0, 0)

	local move_distance = (sniper_pos - target_pos).magnitude
	local speed = 12

	local timer = 0
	local duration = move_distance / speed

	while timer < duration do
		timer = timer + unity_class.time.deltaTime

		local current_pos = unity_class.vector3.Lerp(sniper_pos, target_pos, 1 - ((duration - timer) / duration))

		bullet_sprite.transform.position = current_pos

		coroutine.yield(nil)
	end

	-- 피격
	unity_object_pool.GetOrCreate(self.hit_projectile_preset):Instantiate(
			get_party_leader().Position + vector(0, 0.3, 0))

	bullet_sprite.transform.position = vector(999, 0, 999)

	CS.DamageNumber.ShowDamageNumber(get_party_leader(), 999999, unity_class.color.red, get_party_leader().Position)

	get_party_leader().SpineController:AddColor(get_party_leader().Name, unity_color({0, 0, 0, 1}), 1, 3)
	character_util.spine_deviate_local(get_party_leader(),
			CS.Oak.DirectionExtensions.ToVector3(self.stage_3_sleep_terrorist.Direction).normalized * 0.3,
			0.3, 0.2)
	character_util.spine_pulse_color(
			get_party_leader(), CS.Oak.Constants.DamageColor, 1, 1, 1)
	character_util.spine_damage_squish(
			get_party_leader(), 1.3, 0.7, 1, 0.3)
	character_util.set_anim(get_party_leader(), { name = "dead", loop = false })
	character_util.set_emotion(get_party_leader(), { name = "damaged" })

	wait_for_sec(3)

	music_player_util.play_sfx_one_shot('01_drown_01')

	screen_util.fade_out_circular_async(0.5, 'linear')

	-- 초기화
	local reset_marker = field:GetMarker(self.stage_3_reset_marker_name)

	get_party_leader().SpineController:RemoveColor(get_party_leader().Name, 0)
	character_util.set_position(get_party_leader(), reset_marker.position)
	character_util.set_direction(get_party_leader(), reset_marker.direction)
	character_util.remove_anim(get_party_leader())
	character_util.remove_emotion(get_party_leader())

	character_util.set_direction(self.stage_3_sleep_terrorist, 'down')
	character_util.set_anim(self.stage_3_sleep_terrorist, { name = 'sleep' })
	character_util.set_emotion(self.stage_3_sleep_terrorist, { name = 'sleep' })

	wait_for_sec(1)

	screen_util.fade_in_circular_async(0.5, 'linear')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GotCrashedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.mugger = nil
	self.interact_obj = nil

	self.drop_item = nil

	self.stage_3_sleep_terrorist = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
