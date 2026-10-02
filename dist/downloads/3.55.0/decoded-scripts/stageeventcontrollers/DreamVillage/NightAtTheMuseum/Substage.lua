local local_class = newclass('DreamVillageNightAtTheMuseumController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 448

	self.block_zone = {
		post_block_zone_1 = 'right',
		post_block_zone_2 = 'down',
		post_block_zone_3 = 'up',
		post_block_zone_4 = 'left',
	}

	self.is_in_block_zone = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
end

function local_class:load_resource()
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	for zone_name, return_dir in pairs(self.block_zone) do
		if not self.is_in_block_zone and type_util.is_zone_full_enter(e, leader, zone_name) then
			self.is_in_block_zone = true

			sp_util.start_scene(self.zone_block_event, self, e.Zone, return_dir):Then(function()
				self.is_in_block_zone = false
			end)

			return true
		end
	end

	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:set_wolf_platform_hitbox()

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		self:post_settings()
		self:set_time_zone(false, 1)

		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s6_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s2_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s3_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s4_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 4 then
		self:post_settings()

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif quest_progress.InnerProgress == 5 then
		self:post_settings()

		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s6_start_pos'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:post_settings()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	self:crow_and_turtle_move_setting()
	self:cat_setting()
	self:monkey_setting()
	self:goblin_setting()
	self:ancient_snowman_setting()
	self:ancient_desertelf_setting()
	self:chris_setting()
	self:wolf_setting()
end

function local_class:crow_and_turtle_move_setting()
	local crow = get_character('crow')
	local turtle = get_character('turtle')

	local wp = function(idx)
		return field_util.get_marker_pos('post_turtle_wp_' .. idx)
	end

	--거북이 까마귀 왕복 이동
	--거북이 스파인이 (right, idle, walk) 상태를 지정된 위치까지 30초로 이동하는 상태.
	--거북이 스파인 위로 까마귀 스파인이 (right, idle, idle)로 배치. 거북이와 함께 지정된 위치까지 30초로 이동하는 상태.
	--목표 위치에 도착하면 방향 left로 바꾸고, 30초간 이동 시작.
	--위 상황을 반복 진행.

	local crow_wp = {
		wp(1) + vector(0, 0.5, 0),
		wp(2) + vector(0, 0.5, 0),
	}

	scene_util.set_anim(crow, self, { name = 'land_idle', loop = false })
	crow.Position = crow_wp[1]
	field_object_util.set_active_state(crow, active_state_type.visible)

	wp_util.move(crow, crow_wp, nil, 30, { run = false, end_type = 'loop' })

	local turtle_wp = {
		wp(1),
		wp(2),
	}

	turtle.Position = turtle_wp[1]
	field_object_util.set_active_state(turtle, active_state_type.visible)

	wp_util.move(turtle, turtle_wp, nil, 30, { run = false, end_type = 'loop' })
end

function local_class:goblin_setting()
	--고블린 1 (right, attack, cast) : 늑대!
	--고블린 2 (left, attack, cast) : 잡는다!
	--고블린 3 (left, attack, cast) : …….
	--고블린 4 (left, attack, cast) : 탄다!
	local goblin = {
		get_character('goblin_leader'),
		get_character('goblin_1'),
		get_character('goblin_2'),
		get_character('goblin_3'),
	}

	for idx = 1, 4 do
		local npc = goblin[idx]
		npc.Position = field_util.get_marker_pos('post_goblin_pos_' .. idx)
		npc.Interactable.Talk = 'dv_night_at_the_museum_goblin_oneline_' .. idx

		npc.SpineController.AlwaysUpdateSpine = true
		scene_util.set_direction(npc, direction_constants.left, false)
		scene_util.set_emotion(npc, self, 'attack')
		scene_util.set_anim(npc, self, { name = 'cast', loop = true })
		field_object_util.set_active_state(npc, active_state_type.enabled)
	end

	scene_util.set_direction(goblin[1], direction_constants.right, false)
end

function local_class:cat_setting()
	--고양이 / 촌장
	local rich_male = get_character('rich_male')
	local cat = get_character('cat')
	local cat_pos = field_util.get_marker_pos('monkey_platform_pos')

	--고양이 (right, idle, seat) happy 이모티콘 출력.
	local monkey_platform = get_field_object('monkey_platform')
	monkey_platform.Hitbox = CS.Oak.Hitbox(vector(1, 2, 1))
	monkey_platform.Interactable = CS.Oak.EmoticonInteractable.Create(CS.Oak.EmoticonType.Happy)
	monkey_platform.Interactable.InteractingSfx = '01_cat_meow_01'

	cat.Position = cat_pos + vector(0, 0.5, 0)
	scene_util.set_anim(cat, self, { name = 'seat' })
	scene_util.set_direction(cat, direction_constants.right, false)
	field_object_util.set_active_state(cat, active_state_type.enabled)

	--촌장 (right, smile, sing) : 아이고 우리 나비! 오랜만에 바깥 나들이는 재밌었니?
	scene_util.set_direction(rich_male, direction_constants.right, false)
	scene_util.set_emotion(rich_male, self, 'smile')
	scene_util.set_anim(rich_male, self, { name = 'sing' })
	rich_male.Position = cat_pos + vector(-1, 0, 0)
	rich_male.Interactable.Talk = 'dv_night_at_the_museum_rich_male_oneline_1'
end

function local_class:monkey_setting()
	local monkey = get_character('monkey')
	local monkey_pos = field_util.get_marker_pos('s3_monkey_pos')

	--인터렉트 시 sleep 이모티콘 출력.
	monkey.Position = monkey_pos
	monkey.Interactable = CS.Oak.EmoticonInteractable.Create(CS.Oak.EmoticonType.Sleep)
	monkey.Interactable.InteractingSfx = '01_sleep_02'
	monkey.Hitbox = CS.Oak.Hitbox(vector(0.5, 0.8, 0.5), vector(1.5, 3, 1.5))

	--원숭이 (right, sleep, dead) 상태로 배치.
	scene_util.set_direction(monkey, direction_constants.right, false)
	scene_util.set_anim(monkey, self, { name = 'dead', loop = false })
	scene_util.set_emotion(monkey, self, 'tired')
end

function local_class:ancient_snowman_setting()
	--설산 1 (right, smile, idle) : 왜 우리가 지금까지 싸웠지?
	--설산 2 (right, smile, idle) : 글쎄. 그쪽이 먼저 시비걸지 않았어?
	for idx = 1, 2 do
		local npc = get_character('ancient_snowman_' .. idx)
		character_util.remove_anim(npc)
		scene_util.set_emotion(npc, self, 'smile')
		npc.Position = field_util.get_marker_pos('post_ancient_snowman_pos_' .. idx)
		scene_util.set_direction(npc, direction_constants.right, false)
		npc.Interactable.Talk = 'dv_night_at_the_museum_ancient_snowman_oneline_' .. idx
	end
end

function local_class:ancient_desertelf_setting()
	--사막 1 (left, smile, idle) : 그러게 말이야… 뭔가 있었던 것 같은….
	--사막 2 (left, smile, idle) : 아니지. 그쪽이 이쪽으로 눈을 던져서….
	for idx = 1, 2 do
		local npc = get_character('ancient_desertelf_' .. idx)
		character_util.remove_anim(npc)
		scene_util.set_emotion(npc, self, 'smile')
		npc.Position = field_util.get_marker_pos('post_ancient_desertelf_pos_' .. idx)
		scene_util.set_direction(npc, direction_constants.left, false)
		npc.Interactable.Talk = 'dv_night_at_the_museum_ancient_desertelf_oneline_' .. idx
	end
end

function local_class:chris_setting()
	local chris = get_character('chris')
	local bard = get_character('museum_bard')
	local pivot_pos = field_util.get_marker_pos('s5_start_pos')

	--이후 링고 / 크리스 아래의 원라인 상태로 배치.
	--크리스 (left, idle, sing) : 그럼 링고, 마지막 약속을 지켜볼까?
	chris.Position = pivot_pos + vector(1, 0, 0)
	scene_util.set_direction(chris, 'left', false)
	scene_util.set_anim(chris, self, { name = 'sing' })

	chris.Interactable = CS.Oak.NPCInteractable.Create()
	chris.Interactable.Talk = 'dv_night_at_the_museum_s5_oneline_1'

	--링고 (right, smile, sing) : 좋아! 내 템포에 자연스럽게 끼어들 수 있지?
	field_object_util.set_active_state(bard, active_state_type.enabled)
	bard.Position = pivot_pos
	scene_util.set_direction(bard, 'right', false)
	scene_util.set_anim(bard, self, { name = 'sing' })
	scene_util.set_emotion(bard, self, 'smile')

	bard.Interactable = CS.Oak.NPCInteractable.Create()
	bard.Interactable.Talk = 'dv_night_at_the_museum_s5_oneline_2'
end

function local_class:wolf_setting()
	local wolf_platform = get_field_object('wolf_platform')

	wolf_platform.Hitbox = CS.Oak.Hitbox(vector(4, 0, 2.5))
	wolf_platform.Interactable = CS.Oak.EmoticonInteractable.Create(CS.Oak.EmoticonType.Heart)
	wolf_platform.Interactable.InteractingSfx = '01_guild_dog_01'

	local wolf = get_character('wolf')
	local wolf_pos = field_util.get_marker_pos('wolf_platform_pos')

	wolf.Position = vector_util.get_x0z(wolf_pos, 0.5)
	character_util.remove_anim_and_emotion(wolf)
	field_object_util.set_active_state(wolf, active_state_type.enabled)
end

function local_class:set_wolf_platform_hitbox()
	--거대 늑대 단상은 크기가 커서 히트 박스 확대
	get_field_object('wolf_platform').Hitbox = CS.Oak.Hitbox(vector(4, 0, 2.5))
end

function local_class:zone_block_event(zone, dir)
	local leader = get_party_leader()

	--트리거 존 진입 시
	--플레이어 현재 위치에서 정지
	--나레이션 : 이제 근무는 끝났습니다. 퇴근하시면 됩니다.
	field_ui_util.show_narration_async({ key = 'dv_night_at_the_museum_block_zone_1' })

	--플레이어 (이탈할 방향, idle, walk) 로 2타일 트리거 존에서 멀어지는 방향으로 1초만에 이동.
	local pos = zone_util.get_return_pos_on_enter(zone, leader, dir, 2)
	wp_util.move_async(leader, pos, nil, 1, { run = false })

	--이후 플레이어 컨트롤 복구.
end

function local_class:set_time_zone(is_daylight, normalized_time)
	local animator_fo = get_field_object('visual_controller')
	local animator = animator_fo:GetComponent(typeof(CS.UnityEngine.Animator))

	local animation_name = is_daylight and 'daylight' or 'night'
	normalized_time = lua_helper.get_or_default(normalized_time, 0)
	animator:Play(animation_name, -1, normalized_time)
end

return local_class
