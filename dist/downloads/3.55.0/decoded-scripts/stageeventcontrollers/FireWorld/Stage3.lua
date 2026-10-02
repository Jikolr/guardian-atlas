local local_class = newclass('FireWorld3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	self.main_quest_id = 478
	self.quest_progress = nil

	-- character
	self.characters = {
		-- 최초 배치 npc
		before_npc = function(number)
			return get_character('stage_set_npc_' .. number)
		end,
		-- 인간 생존자
		survivor = function(number)
			return get_character('save_human_survivor_' .. number)
		end,
		-- 불정령 꼬마
		harpy_kid_girl = function(number)
			return get_character('save_harpy_kid_girl_' .. number)
		end,
		-- 단절된 가족
		family = function(number)
			return get_character('save_family_npc_' .. number)
		end
	}

	-- marker
	self.markers = {
		before_npc_pos = function(number)
			return field_util.get_marker_pos('stage_set_npc_before_pos_' .. number)
		end,
		after_npc_pos = function(number)
			return field_util.get_marker_pos('stage_set_npc_after_pos_' .. number)
		end,
		survivor_pos = function(number)
			return field_util.get_marker_pos('stage_set_survivor_pos_' .. number)
		end,
		harpy_kid_girl_pos = function(number)
			return field_util.get_marker_pos('stage_set_harpy_kid_girl_pos_' .. number)
		end,
		family_pos = function(number)
			return field_util.get_marker_pos('stage_set_family_pos_' .. number)
		end,
	}

	-- 배치될 npc 수
	self.survivor_count = 7
	self.harpy_kid_girl_count = 3
	self.family_count = 12

	self.set_npc_info = setmetatable({
		custom_state_key = 's10_save_state',
		custom_stage_event_key = 'stage_3_npc_setting'
	}, {
		__index = {
			init_storage = function(this, quest_id)
				local storage_create = require('utils/QuestDataStorage')
				this.data_storage = storage_create.create(quest_id)
			end,
			get_custom_state = function(this)
				local custom_state = this.data_storage:get_data(this.custom_state_key)

				return custom_state < 0 and 0 or custom_state
			end,
			dispose = function(this)
				this.data_storage = nil
			end
		}
	})
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.set_npc_info:dispose()

	self.cs_controller = nil
end

function local_class:load_resource()
	--local is_create, place_controller =
	--global_table_util.try_create('Quest/Etc/CharacterPlaceController/CharacterPlaceController')
	--
	--place_controller:initialize()

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == self.set_npc_info.custom_stage_event_key then
		self:set_stage_npc(false)

		return true
	end

	return false
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

	self.set_npc_info:init_storage(self.main_quest_id)

	self:set_stage_npc(true)

	stage_start_util.start_function(self.quest_progress)
end

-- 스테이지 npc 세팅
function local_class:set_stage_npc(is_stage_start)
	local custom_state = self.set_npc_info:get_custom_state()
	local event_bit = { 1, 2, 4 }

	local set_npc = function(npc, position, dir, anim, emotion, string, sfx)
		character_util.set_position(npc, position)
		character_util.set_direction(npc, dir)
		scene_util.set_emotion(npc, self, emotion)
		scene_util.set_anim(npc, self, anim)
		npc.Interactable.Talk = string
		if sfx then
			npc.Interactable.TalkSfx = sfx
		end
	end

	-- 라크리마 무기 숨김
	local second_bishop = get_character('second_bishop')
	scene_util.hide_weapon(second_bishop)
	message_system:SendSync(second_bishop, CS.Oak.CharacterBehaviourResetEvent.Instance)

	-- 인간 생존자
	if (custom_state & event_bit[1]) ~= 0 then
		--NPC 1번 (left, awesome, cast) : 아이고 다들 살아왔네! 살아왔어!
		set_npc(self.characters.before_npc(1), self.markers.after_npc_pos(1), 'left',
				'cast', 'awesome', 'fw_main_s10_stage_set_npc_after_1', '03_dialogue_positive_01')

		--NPC 2번 (left, smile, cast2) : 내가 말했잖어! 다들 살아 있을 거라니께에!
		set_npc(self.characters.before_npc(2), self.markers.after_npc_pos(2), 'left',
				'cast2', 'smile', 'fw_main_s10_stage_set_npc_after_2')

		--NPC 3번 (left, cry, cast) : 여보오! 무사해서 정말 다행이에요!
		set_npc(self.characters.before_npc(3), self.markers.after_npc_pos(3), 'left',
				'cast', 'cry', 'fw_main_s10_stage_set_npc_after_3', '01_cry_01')

		--NPC 9번 (right, tired, prostrate) : 에휴우… 죽다 살아났네.
		set_npc(self.characters.survivor(1), self.markers.survivor_pos(1), 'right',
				'prostrate', 'tired', 'fw_main_s10_stage_set_npc_after_4')

		--NPC 10번 (right, tired, seat) : 다행이지… 그 사람들 아니었으면 지금 쯤…
		set_npc(self.characters.survivor(2), self.markers.survivor_pos(2), 'right',
				'seat', 'tired', 'fw_main_s10_stage_set_npc_after_5', '01_rustle_01')

		--NPC 11번 (left, damaged, prostrate) : 어우 뜨거워…
		set_npc(self.characters.survivor(3), self.markers.survivor_pos(3), 'left',
				'prostrate', 'damaged', 'fw_main_s10_stage_set_npc_after_6')

		--NPC 12번 (right, tired, prostrate) : 화상으로 끝나서 다행이지…
		set_npc(self.characters.survivor(4), self.markers.survivor_pos(4), 'right',
				'prostrate', 'tired', 'fw_main_s10_stage_set_npc_after_7')

		--NPC 13번 (left, tired, prostrate) : 이번 건은 수당으로 쳐주나…?
		set_npc(self.characters.survivor(5), self.markers.survivor_pos(5), 'left',
				'prostrate', 'tired', 'fw_main_s10_stage_set_npc_after_8', '03_dialogue_bad_01')

		--NPC 14번 (right, tired, prostrate) : 집에 가서 좀 씻고 싶다…
		set_npc(self.characters.survivor(6), self.markers.survivor_pos(6), 'right',
				'prostrate', 'tired', 'fw_main_s10_stage_set_npc_after_9')

		--NPC 15번 (right, damaged, prostrate) : 으으…
		set_npc(self.characters.survivor(7), self.markers.survivor_pos(7), 'right',
				'prostrate', 'damaged', 'fw_main_s10_stage_set_npc_after_10')
	else
		--NPC 1번 (right, attack, cast2) : 그래서! 김씨를 그대로 두고왔다 이말이야?!
		set_npc(self.characters.before_npc(1), self.markers.before_npc_pos(1), 'right',
				'cast2', 'attack', 'fw_main_s10_stage_set_npc_1', '03_dialogue_negative_01')

		--NPC 2번 (left, attack, cast2) : 그럼 나보고 같이 빠져 죽으라고? 어?
		set_npc(self.characters.before_npc(2), self.markers.before_npc_pos(2), 'left',
				'cast2', 'attack', 'fw_main_s10_stage_set_npc_2', '03_dialogue_angry_01')

		--NPC 3번 (left, attack, cast) : 다들 그만 싸워요! 어떻게든 올라가서 구해줄 사람을 찾아야죠!
		set_npc(self.characters.before_npc(3), self.markers.before_npc_pos(3), 'left',
				'cast', 'attack', 'fw_main_s10_stage_set_npc_3', '01_swing_01')
	end

	-- 불정령 꼬마
	if (custom_state & event_bit[2]) ~= 0 then
		--NPC 4번 (down, attack, idle) : 너희들 도대체 어디에 가 있었던 거야?!
		set_npc(self.characters.before_npc(4), self.markers.after_npc_pos(4), 'down',
				'idle', 'attack', 'fw_main_s10_stage_set_npc_after_11', '01_swing_01')

		--NPC 5번 (down, attack, idle) : 엄마가 걱정한 거 몰라?!
		set_npc(self.characters.before_npc(5), self.markers.after_npc_pos(5), 'down',
				'idle', 'attack', 'fw_main_s10_stage_set_npc_after_12')

		--NPC 6번 (down, attack, idle) : 뭐? 뭘하고 온 거라고?
		set_npc(self.characters.before_npc(6), self.markers.after_npc_pos(6), 'down',
				'idle', 'attack', 'fw_main_s10_stage_set_npc_after_13', '03_dialogue_bad_01')

		--NPC 16번 (up, idle, idle) : 엄마! 나 대장이랑 놀고 왔어!
		set_npc(self.characters.harpy_kid_girl(1), self.markers.harpy_kid_girl_pos(1), 'up',
				'idle', 'idle', 'fw_main_s10_stage_set_npc_after_14', '01_swing_01')

		--NPC 17번 (up, idle, idle) : 미안해 엄마! 하지만 우리 보물들 다 찾아왔는 걸!
		set_npc(self.characters.harpy_kid_girl(2), self.markers.harpy_kid_girl_pos(2), 'up',
				'idle', 'idle', 'fw_main_s10_stage_set_npc_after_15', '01_bad_fairy_01')

		--NPC 18번 (up, idle, idle) : 우리 대장 진짜 짱이야! 우리 비밀기지를 전부 통과했다니까?
		set_npc(self.characters.harpy_kid_girl(3), self.markers.harpy_kid_girl_pos(3), 'up',
				'idle', 'idle', 'fw_main_s10_stage_set_npc_after_16', '03_dialogue_positive_01')
	else
		--NPC 4번 (right, cry, idle) : 우리 아이들 어디있는지 못보셨어요?
		set_npc(self.characters.before_npc(4), self.markers.before_npc_pos(4), 'right',
				'idle', 'cry', 'fw_main_s10_stage_set_npc_4', '03_dialogue_sadness_01')

		--NPC 5번 (down, cry, idle) : 저희 아이도 없어졌어요!
		set_npc(self.characters.before_npc(5), self.markers.before_npc_pos(5), 'down',
				'idle', 'cry', 'fw_main_s10_stage_set_npc_5', '01_cry_01')

		--NPC 6번 (left, cry, idle) : 부탁이에요… 그 아이들이 없으면 저희는 떠날 수도 없어요…
		set_npc(self.characters.before_npc(6), self.markers.before_npc_pos(6), 'left',
				'idle', 'cry', 'fw_main_s10_stage_set_npc_6', '03_dialogue_sadness_01')
	end

	-- 단절된 가족
	if (custom_state & event_bit[3]) ~= 0 then
		--NPC 7번 (right, smile, idle) : 아이고! 다들 잘 돌아왔네!
		set_npc(self.characters.before_npc(7), self.markers.after_npc_pos(7), 'right',
				'idle', 'smile', 'fw_main_s10_stage_set_npc_after_17', '03_dialogue_positive_01')

		--NPC 8번 (right, smile, idle) : 우리 지금부터 피난 가는 거야! 자, 그럼 첫째부터 번호해볼까?
		set_npc(self.characters.before_npc(8), self.markers.after_npc_pos(8), 'right',
				'idle', 'smile', 'fw_main_s10_stage_set_npc_after_18')

		--NPC 19번 (left, smile, seat) : 하나!
		set_npc(self.characters.family(1), self.markers.family_pos(1), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_19')

		--NPC 20번 (left, smile, seat) : 둘!
		set_npc(self.characters.family(2), self.markers.family_pos(2), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_20')

		--NPC 21번 (left, smile, seat) : 셋!
		set_npc(self.characters.family(3), self.markers.family_pos(3), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_21')

		--NPC 22번 (left, smile, seat) : 넷!
		set_npc(self.characters.family(4), self.markers.family_pos(4), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_22')

		--NPC 23번 (left, smile, seat) : 다섯!
		set_npc(self.characters.family(5), self.markers.family_pos(5), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_23')

		--NPC 24번 (left, smile, seat) : 여섯!
		set_npc(self.characters.family(6), self.markers.family_pos(6), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_24')

		--NPC 25번 (left, smile, seat) : 일곱!
		set_npc(self.characters.family(7), self.markers.family_pos(7), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_25')

		--NPC 26번 (left, smile, seat) : 여덟!
		set_npc(self.characters.family(8), self.markers.family_pos(8), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_26')

		--NPC 27번 (left, smile, seat) : 아홉!
		set_npc(self.characters.family(9), self.markers.family_pos(9), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_27')

		--NPC 28번 (left, smile, seat) : 열!
		set_npc(self.characters.family(10), self.markers.family_pos(10), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_28')

		--NPC 29번 (left, smile, seat) : 열 하나!
		set_npc(self.characters.family(11), self.markers.family_pos(11), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_29')

		--NPC 30번 (left, smile, seat) : 열 둘! 번호 끝!!
		set_npc(self.characters.family(12), self.markers.family_pos(12), 'left',
				'seat', 'smile', 'fw_main_s10_stage_set_npc_after_30', '01_whistle_01')

		if is_stage_start then
			self:set_family_event_gimmick()
		end
	else
		--NPC 7번 (right, tired, idle) : 영감… 우리도 피난 가야 한다네요…
		set_npc(self.characters.before_npc(7), self.markers.before_npc_pos(7), 'right',
				'idle', 'tired', 'fw_main_s10_stage_set_npc_7', '01_rustle_01')

		--NPC 8번 (left, tired, idle) : 누군가… 우리 애들을 데려와야 나가지…
		set_npc(self.characters.before_npc(8), self.markers.before_npc_pos(8), 'left',
				'idle', 'tired', 'fw_main_s10_stage_set_npc_8', '01_rustle_01')
	end
end

--- 단절된 가족 클리어 시 처리될 기믹들
function local_class:set_family_event_gimmick()
	local plate_count = 12

	--TODO 12개의 바닥을 한번에 터트리면 프레임 드랍이 일어나므로 한 프레임마다 하나씩 터트림
	for i = 1, plate_count do
		local plate = get_field_object('save_family_lava_plate_' .. i)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
		damage_info.sender = plate
		damage_info.target = plate
		damage_info.damage = 1

		command_util.publish_damage(damage_info)

		coroutine.yield()
	end

	local boat_count = 5

	for i = 1, boat_count do
		local boat = get_field_object('save_family_scene_boat_' .. i)

		boat.Position = field_util.get_marker_pos('save_family_boat_pos_' .. i)
		message_system:SendSync(boat, CS.Oak.GetThrownEndEvent.Instance)
	end
end

return local_class
