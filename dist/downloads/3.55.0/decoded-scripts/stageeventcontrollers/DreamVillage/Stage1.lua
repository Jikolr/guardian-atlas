local local_class = newclass('DreamVillage1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 441
	self.quest_progress = nil

	self.stage_end = false

	self.stage_event = {
		data = {
			play_kid = {
				played = false,
			},
			pray_mother = {
				played = false,
			},
			interact_tower = {
				played = false,
			},
		},

		---@type fun(this:self, key:string):boolean
		is_played = function(this, key)
			return this.data[key].played
		end,

		---@type fun(this:self, key:string)
		check_played = function(this, key)
			this.data[key].played = true
		end,
	}

	self.item = {

		---@type fun(this:self)
		load_narration_obj = function(this)
			for key, info in pairs(this.narration_data) do
				local wall = get_field_object(info.wall_name)
				local narration_interactable = CS.Oak.NarrationInteractable()
				local pos = field_util.get_marker_pos(info.marker_name) + info.offset

				--fo
				wall.Position = pos

				--narration
				narration_interactable.StringKeys = info.narration
				wall.Interactable = narration_interactable

				--item
				local item = quest_drop_item_util.create_item({
					pos = pos,
					item_id = info.id,
					spr_scale = info.scale,
					loot_state = quest_drop_item_loot_state.dont_find_looter,
					show_on_character = false,
				})

				this:insert_item(item)
			end
		end,

		---@type fun(this:self, item:IFieldObject)
		insert_item = function(this, item)
			table.insert(this.item_data, item)
		end,

		---@type fun(this:self)
		dispose = function(this)
			if this.narration_data == nil then
				return
			end

			--fo
			for key, info in pairs(this.narration_data) do
				local wall = get_field_object(info.wall_name)

				wall.Position = vector(999, 0, 999)
			end

			this.narration_data = nil

			--item
			for _, item in pairs(this.item_data) do
				quest_drop_item_util.dispose_item(item)
			end
		end,

		item_data = {},

		narration_data = {
			certificate = {
				id = 21408,
				scale = 1,
				marker_name = 'soulpower_house_item_pos_1',
				offset = vector(0, 0, 0),
				wall_name = 'stage_narration_item_1',
				narration = {
					--모토리 마을 감사패
					'dv_stage_1_item_narration_1',
					--귀하의 가문이 모토리 마을에 공헌한 바를 인정하여 이 감사패를 드립니다.
					'dv_stage_1_item_narration_2',
				},
			},
			merch_laura_diary = {
				id = 21409,
				scale = 0.5,
				marker_name = 'soulpower_house_item_pos_2',
				offset = vector(0, 0, 0),
				wall_name = 'stage_narration_item_2',
				narration = {
					--며칠 전까지 쓰여 있는 가계부다.
					--서화 약값 3만 골드
					--서화 약값 3만 골드 …
					'dv_stage_1_item_narration_4',
					--지출 란에는 매일 같은 내용이 계속해서 이어진다.
					'dv_stage_1_item_narration_5',
				},
			},
			mall_box = {
				id = 21410,
				scale = 1,
				marker_name = 'soulpower_house_item_pos_3',
				offset = vector(0, 0, 2),
				wall_name = 'stage_narration_item_3',
				narration = {
					--며칠 전에 도착한 택배 박스다.
					'dv_stage_1_item_narration_8',
					--어째서인지 뜯지 않은 채로 그대로 있다.
					'dv_stage_1_item_narration_9',
				},
			},
		}
	}
end

function local_class:dispose()
	self.cs_controller = nil

	self.item:dispose()

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	if not self.stage_event:is_played('interact_tower') then
		if lua_helper.reference_equals(e.Target, get_field_object('monster_tower')) then
			self.stage_event:check_played('interact_tower')
			sp_util.start_scene(self.monster_tower_interact_scene, self, true)

		elseif lua_helper.reference_equals(e.Target, get_character('monster_tower_oneline_9')) then
			self.stage_event:check_played('interact_tower')
			sp_util.start_scene(self.monster_tower_interact_scene, self, false)

			return true
		end
	end

	if lua_helper.reference_equals(e.Target, get_character('inn_oneline_7')) then
		start_coroutine(function()
			speech_bubble_util.remove_bubble(e.Target)

			--칠득이 녀석이 안 사온 건 나중에 내가 사러 가야겠네….
			scene_util.show_normal_speech_async(e.Target, 'dv_stage_1_inn_oneline_7', false, {
				bubble_direction = 'rb',
			})
		end)

		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if not self.stage_event:is_played('pray_mother') and
			type_util.is_zone_full_enter(e, get_party_leader(), 'monster_tower_enter_zone') then
		self.stage_event:check_played('pray_mother')
		start_coroutine(self.monster_tower_enter_scene, self)

		return true
	end

	if not self.stage_event:is_played('play_kid') and
			type_util.is_zone_full_enter(e, get_party_leader(), 'kid_ground_enter_zone') then
		self.stage_event:check_played('play_kid')
		start_coroutine(self.kid_play_enter_scene, self)

		return true
	end

	if self.quest_progress ~= nil and
			not self.quest_progress.IsComplete and
			self.quest_progress.InnerProgress >= 3 and type_util.is_zone_full_enter(e, get_party_leader(), 'princess_back_enter_zone') then
		sp_util.start_scene(self.princess_enter_scene, self, e.Zone.Name)

		return true
	end

	return false
end

function local_class:on_stage_end_event(_)
	self.stage_end = true
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:pre_setting(self.quest_progress)

	if self.quest_progress == nil or self.quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	elseif self.quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), false, false)
	elseif self.quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('main_s2_start_pos'), true, false)
	elseif self.quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('main_s3_start_pos'), true, false)
	elseif self.quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s4_start_pos'), true, true)
	elseif self.quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s5_start_pos'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:princess_enter_scene(zone_name)
	local leader = get_party_leader()
	local princess = get_character('princess')

	--공주(기사 바라보고, tired, idle) : $name. 아직 영혼술사를 못 찾았잖아.
	character_util.look_at(princess, leader)
	scene_util.play_normal_speech_action(princess, self, nil,
			nil,
			'tired',
			'dv_stage_1_princess_string_key_1')

	--기사 tired, nod 2회.
	scene_util.set_emotion(leader, self, 'tired')
	scene_util.set_anim_async(leader, self, { name = 'nod', count = 2 })

	character_util.remove_anim_and_emotion(leader)
	--기사 위쪽으로 1초간 3칸 걸어서 이동한다.
	local return_pos = zone_util.get_return_pos_on_enter(zone_name, leader, 'up', 2)
	wp_util.move_async(leader, return_pos, nil, 1)
end

function local_class:pre_setting(progress)
	--item
	self.item:load_narration_obj()

	--npc
	local keeper = get_character('inn_oneline_7')
	keeper.Hitbox = CS.Oak.Hitbox(vector(2.5, 0, 2.5))
	keeper.Interactable.Talk = nil
	character_util.add_listener(keeper, self.cs_controller)

	local oldman = get_character('monster_tower_oneline_9')
	character_util.add_listener(oldman, self.cs_controller)

	local statue = get_character('center_statue')
	field_ui_manager:RemoveUI(statue, field_ui_type.character_stats)
	statue.SpineController.ShadowTransform.localScale = unity_class.vector3.one * 2

	--fo
	local picture = get_field_object('stage_item_family_picture')
	local pivot = picture.Hitbox.pivot
	local offset = vector(-0.5, 0, 0)
	local size = vector(1, 1, 1)
	picture.Hitbox = CS.Oak.Hitbox(pivot + offset, size)

	--gimmick
	--영혼 술사 집 오픈
	if progress == nil or progress.IsComplete or progress.InnerProgress > 4 then
		local gate = get_field_object('s5_house_gate')

		animator_util.play(gate, 'gate_open')
		gate.ActiveState = active_state('visible')
	end

	--타워 인터랙터블 설정
	local monster_tower = get_field_object('monster_tower')
	local publish_interactable = CS.Oak.PublishInteractable.Create()

	monster_tower.Interactable = publish_interactable

	--routine
	start_coroutine(self.shopping_street_routine, self)
end

function local_class:shopping_street_routine()
	local npc = get_character('shopping_street_oneline_4')

	field_object_util.set_active_state(npc, active_state_type.visible)

	while not self.stage_end do
		--up, idle, idle, jump 2회
		scene_util.set_direction(npc, 'up', false)
		music_player_util.play_sfx({ sfx_name = '01_small_jump_01', loop = false, parent = npc })
		character_util.normal_jump_async(npc, false)

		music_player_util.play_sfx({ sfx_name = '01_small_jump_01', loop = false, parent = npc })
		character_util.normal_jump_async(npc, false)

		if self.stage_end then
			return
		end

		--0.5초 대기.
		self:wait_for_sec(0.5)

		if self.stage_end then
			return
		end

		--run 애니메이션, 표정 smile, 먼지구름 안 나오도록.
		scene_util.set_direction(npc, 'right', false)
		scene_util.set_emotion(npc, self, 'smile')
		scene_util.set_anim(npc, self, 'run')

		--속도 3으로 오른쪽 위치로 이동.
		self:move_async(npc, npc.Position + vector(5, 0, 0), 3)

		if self.stage_end then
			return
		end

		--up, idle, idle.
		scene_util.set_direction(npc, 'up', false)
		character_util.remove_anim_and_emotion(npc)

		--1초 대기
		self:wait_for_sec(1)

		if self.stage_end then
			return
		end

		--up, idle, idle, jump 2회
		music_player_util.play_sfx({ sfx_name = '01_small_jump_01', loop = false, parent = npc })
		character_util.normal_jump_async(npc, false)

		music_player_util.play_sfx({ sfx_name = '01_small_jump_01', loop = false, parent = npc })
		character_util.normal_jump_async(npc, false)

		if self.stage_end then
			return
		end

		--0.5초 대기.
		self:wait_for_sec(0.5)

		--속도 3으로 왼쪽 위치로 이동.
		--run 애니메이션, 표정 smile, 먼지구름 안 나오도록.
		scene_util.set_direction(npc, 'left', false)
		scene_util.set_emotion(npc, self, 'smile')
		scene_util.set_anim(npc, self, 'run')

		self:move_async(npc, npc.Position + vector(-5, 0, 0), 3)

		if self.stage_end then
			return
		end

		--up, idle, idle.
		scene_util.set_direction(npc, 'up', false)
		character_util.remove_anim_and_emotion(npc)

		--1초 대기
		self:wait_for_sec(1)
	end
end

--광장 중앙 탑에 인터랙트 하면 컨트롤 뺏고 이벤트 진행.
function local_class:monster_tower_interact_scene(tower_interact)
	local leader = get_party_leader()
	local princess = get_character('princess')
	local oldman = get_character('monster_tower_oneline_9')
	local center_pos = field_util.get_marker_pos('main_s4_monster_top_pos')
	local is_left = leader.Position.x < oldman.Position.x

	music_player_util.change_stage_music_volume('field', 0.6)

	character_util.remove_relate_event(oldman, self.cs_controller)

	if tower_interact then
		--내레이션 박스 : 여러가지 동물들의 형상이 합쳐진 형상을 하고 있는 요괴의 모습이다.
		field_ui_util.show_narration_async({ key = 'dv_stage_1_monster_tower_1' })
	end

	if is_left then
		scene_util.set_direction(oldman, 'left', false)
	else
		scene_util.set_direction(oldman, 'right', false)
	end

	--할아버지(남)(가디언 방향 바라보고(left/right 둘 중 하나로만), idle, idle) : 자네는… 이 마을 사람이 아닌 것 같군, 그래. 관광객인가?
	scene_util.play_normal_speech_action(oldman, self, nil,
			nil, nil, 'dv_stage_1_monster_tower_2')

	--가디언 인터랙트한 위치(괴물 탑 주변이면 어디든지 가능.)에서 속도 3으로 이동해, 할아버지의 왼쪽/오른쪽 1칸 거리에 선다.
	--가디언의 최종 위치는 괴물 탑에 인터랙트 한 위치가 할아버지의 왼쪽이었나 오른쪽이었나를 기준으로
	do
		local speed = 3
		local wp_key = 'align_tower'
		local dir = is_left and 'right' or 'left'
		local wp = {}
		local princess_wp = {}

		--플레이어 정렬용 waypoint 계산
		if is_left then
			wp = self:optimize_waypoint(leader.Position, {
				center_pos + vector(-2.5, 0, 2.5),
				center_pos + vector(-2.5, 0, -2.5),
				oldman.Position + vector(-1, 0, 0),
			})

			princess_wp = self:optimize_waypoint(leader.Position, {
				center_pos + vector(-2.5, 0, 2.5),
				center_pos + vector(-2.5, 0, -2.5),
				oldman.Position + vector(-1, 0, 0),
			})

			princess_wp[#princess_wp] = princess_wp[#princess_wp] + unity_class.vector3.left
		else
			wp = self:optimize_waypoint(leader.Position, {
				center_pos + vector(2.5, 0, 2.5),
				center_pos + vector(2.5, 0, -2.5),
				oldman.Position + vector(1, 0, 0),
			})

			princess_wp = self:optimize_waypoint(leader.Position, {
				center_pos + vector(2.5, 0, 2.5),
				center_pos + vector(2.5, 0, -2.5),
				oldman.Position + vector(1, 0, 0),
			})
			princess_wp[#princess_wp] = princess_wp[#princess_wp] + unity_class.vector3.right
		end

		wp_util.move_with_end_callback(leader, wp, speed, nil, self, wp_key, { last_direction = dir })

		wait_for_sec(0.3)

		wp_util.move_with_end_callback(princess, princess_wp, speed, nil, self, wp_key, { last_direction = dir })

		wp_util.wait_move_end(self, wp_key)
	end

	--가디언 선택지
	do
		--(intellect)네, 모토리 산 무전여행 브이로그 찍는 중이에요.
		--(mercy)영혼술사를 찾으러 왔어요.
		local choose_result = choose_util.play_choose_event({
			{ 'dv_stage_1_monster_tower_choose_1', 'intellect' },
			{ 'dv_stage_1_monster_tower_choose_2', 'mercy' }
		})

		if choose_result == 1 then
			--가디언 (할아버지 바라보고, smile, release 3회)
			scene_util.set_emotion(leader, self, 'smile')
			scene_util.set_anim_async(leader, self, { name = 'release', count = 3 })

			character_util.remove_emotion(leader)

			--할아버지(남)(가디언 바라보고, smile, nod 2회) : 허허, 잘 모르겠지만 재밌는 일을 하는군.
			music_player_util.play_sfx_one_shot('01_rustle_01')
			scene_util.play_normal_speech_action(oldman, self, nil,
					{ name = 'nod', count = 2 }, 'smile', 'dv_stage_1_monster_tower_3')

		elseif choose_result == 2 then
			--가디언 (할아버지 바라보고, smile, bomb_idle 1초)
			scene_util.play_wait_action(leader, self,
					nil,
					'bomb_idle',
					'smile',
					1)

			--할아버지(남)(가디언 바라보고, smile, nod 2회) : 영혼술사? 허허, 정말 오랜만에 듣는구만.
			scene_util.play_normal_speech_action(oldman, self, nil,
					{ name = 'nod', count = 2 }, 'smile', 'dv_stage_1_monster_tower_4')

			--가디언 tired, release 2회.
			scene_util.set_emotion(leader, self, 'tired')
			scene_util.set_anim_async(leader, self, { name = 'release', count = 2 })

			character_util.remove_emotion(leader)

			--할아버지(남)(가디언 바라보고, idle, idle) : 아니. 나도 알고 있는 건 없네.
			scene_util.play_normal_speech_action(oldman, self, nil,
					nil, nil, 'dv_stage_1_monster_tower_5')

		end
	end

	--할아버지(남)(up, idle, idle) : 이 동상은… 아주 오래 전 모토리 산을 지배했던 거대한 요괴의 형상을 본딴 것일세.
	scene_util.play_normal_speech_action(oldman, self, 'up',
			nil, nil, 'dv_stage_1_monster_tower_6')

	--카메라 포커스 1초간 동상 스파인으로 이동.
	camera_util.move_async(center_pos, 1)

	--1초 대기.
	wait_for_sec(1)

	--카메라 포커스 1초간 기사에게로 복귀.
	camera_util.return_to_leader(1)

	--할아버지(남)(가디언 바라보고, idle, idle) : 지금은 사라졌다고 하지만, 이 석상만 봐도 다른 요괴들은 벌벌 떨었거든.
	character_util.look_at(oldman, leader)
	scene_util.play_normal_speech_action(oldman, self, nil,
			nil, nil, 'dv_stage_1_monster_tower_7')

	--할아버지(남)(가디언 바라보고, idle, bomb_idle) : 이제는 그냥… 관광 상품이 되었네만…
	scene_util.play_normal_speech_action(oldman, self, nil,
			'bomb_idle', nil, 'dv_stage_1_monster_tower_8')

	--할아버지 (down, idle, idle) : 봐도봐도 무섭게 생겼지 않나? 잘 만들었어.
	scene_util.set_direction(oldman, 'down', false)
	oldman.Interactable.Talk = 'dv_stage_1_monster_tower_9'

	--나레이션 박스 원라인 설정
	local monster_tower = get_field_object('monster_tower')
	local narration_interactable = CS.Oak.NarrationInteractable()

	narration_interactable.StringKeys = { 'dv_stage_1_monster_tower_1', }
	--narration_interactable.InteractingSfx = '01_turn_page_01'
	monster_tower.Interactable = narration_interactable

	music_player_util.change_stage_music_volume('field', 1)
end

function local_class:monster_tower_enter_scene()
	local kid = get_character('monster_tower_oneline_10')
	local woman = get_character('monster_tower_oneline_11')

	--남자 꼬마1(right, smile, sing) : 엄마! 석상 부수기 할래!
	scene_util.show_normal_speech_async(kid, 'dv_stage_1_monster_tower_oneline_8', false)

	--여자 어른1(right, sleep_deep, cast) : 그래, 다음에 몽둥이 들고 와서 하자?
	scene_util.show_normal_speech_async(woman, 'dv_stage_1_monster_tower_oneline_9', false)

	kid.Interactable.Talk = 'dv_stage_1_monster_tower_oneline_8'
	woman.Interactable.Talk = 'dv_stage_1_monster_tower_oneline_9'
end

function local_class:kid_play_enter_scene()
	local npc_1 = get_character('monster_tower_oneline_1')
	local npc_2 = get_character('monster_tower_oneline_2')
	local npc_3 = get_character('monster_tower_oneline_3')

	--아래 연출 동시에 진행
	do
		local duration = 3
		local wait = true

		scene_util.set_group_anim({ npc_2, npc_3 }, self, 'walk')

		--2번 3초간 왼쪽으로 4.5칸 이동.
		start_coroutine(function()
			self:move_async(npc_2, npc_2.Position + vector(-5, 0, 0), 1, duration)

			if self.stage_end then
				return
			end

			--2번(left, tired, cast(루프 없이)) : 안 움직였어….
			scene_util.set_anim(npc_2, self, { name = 'cast', loop = false })
			scene_util.set_emotion(npc_2, self, { name = 'tired' })

			wait = false
		end)

		--3번 3초간 왼쪽으로 3칸 이동.
		start_coroutine(function()
			self:move_async(npc_3, npc_3.Position + vector(-2.5, 0, 0), 1, duration)

			if self.stage_end then
				return
			end

			--3번(left, attack, idle(루프 없이)) : 까… 깐깐하긴….
			scene_util.set_anim(npc_3, self, { name = 'idle', loop = false })
			scene_util.set_emotion(npc_3, self, { name = 'attack' })

			wait = false
		end)

		--1번(한번에 모두 등장, 3초간 유지, 스킵불가, left, sleep_deep, idle) : 무궁화 꽃이 피었습니다!
		scene_util.show_normal_speech_async(npc_1, 'dv_stage_1_monster_tower_oneline_0', false)

		if self.stage_end then
			return
		end

		while not self.stage_end and wait do
			coroutine.yield(nil)
		end
	end

	--1번 right, attack, idle, jump 1회
	scene_util.set_direction(npc_1, 'right', false)
	scene_util.set_emotion(npc_1, self, 'attack')
	music_player_util.play_sfx({ sfx_name = '01_small_jump_01', loop = false, parent = npc_1 })
	character_util.normal_jump_async(npc_1, false)

	--0.5초 대기
	wait_for_sec(0.5)

	if self.stage_end then
		return
	end

	--1번(right, attack, cast2) : 너 움직인 거 아니야?
	scene_util.set_anim(npc_1, self, 'cast2')
	npc_1.Interactable.Talk = 'dv_stage_1_monster_tower_oneline_1'
	npc_2.Interactable.Talk = 'dv_stage_1_monster_tower_oneline_2'
	npc_3.Interactable.Talk = 'dv_stage_1_monster_tower_oneline_3'
end

function local_class:wait_for_sec(duration)
	local time_passed = 0

	while not self.stage_end do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed >= duration then
			return
		end

		coroutine.yield(nil)
	end
end

--현재 위치에서 waypoint 진행 경로를 최적화 하도록 다시 계산한다.
function local_class:optimize_waypoint(position, waypoint_data)
	local near_distance = 99999
	local near_wp = 1

	--가장 근접한 wp 계산
	for i = 1, #waypoint_data do
		local cur_wp = waypoint_data[i]
		local cur_distance = vector_util.distance(position, cur_wp)

		if cur_distance < near_distance then
			near_distance = cur_distance
			near_wp = i
		end
	end

	--자연스러운 이동을 위해 가장가까운 wp와 다음 wp중 적절한 곳 탐색.
	--이등변 삼각형에 아이디어를 얻어 특정 위치에 있다면 다음 wp로 지정.
	if near_wp < #waypoint_data then
		local cur_distance = vector_util.distance(position, waypoint_data[near_wp])
		local next_distance = vector_util.distance(position, waypoint_data[near_wp + 1])

		local theta = vector_util.dot(waypoint_data[near_wp] - position, waypoint_data[near_wp + 1] - position)

		if theta > 0 and cur_distance > next_distance then
			near_wp = near_wp + 1
		end
	end

	local result_waypoint = {}

	for i = near_wp, #waypoint_data do
		table.insert(result_waypoint, waypoint_data[i])
	end

	return result_waypoint
end

--duration 값이 있을 경우 speed 값을 무시한다.
function local_class:move_async(fo, target_pos, speed, duration)
	local time_passed = 0
	local progress = 0
	local start_pos = fo.Position
	local distance = vector_util.distance(start_pos, target_pos)
	local to_duration = distance / speed

	if type_util.is_number(duration) then
		to_duration = duration
	end

	while not self.stage_end do
		time_passed = time_passed + unity_class.time.deltaTime
		progress = time_passed / to_duration

		if time_passed < to_duration then
			fo.Position = unity_class.vector3.Lerp(start_pos, target_pos, progress)
		else
			fo.Position = target_pos
			break
		end

		coroutine.yield(nil)
	end
end

return local_class
