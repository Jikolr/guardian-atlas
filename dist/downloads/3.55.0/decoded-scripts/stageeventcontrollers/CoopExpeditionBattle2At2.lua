local local_class = newclass('CoopExpeditionBattle2At2Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 스테이지 id
	self.stage_id = 320020002

	-- fx
	self.fx = setmetatable({
		big_slash = function()
			return unity_object_pool.GetOrCreate('fx_co_ex_bigslash_black_white')
		end,
	}, {
		__index = {
			create_all = function(this)
				for _, func in pairs(this) do
					func()
				end
			end
		}
	})

	-- 동적 npc
	self.monster_key = 'co_monster'
	self.saya_key = 'co_saya'
	self.dynamic_npc = setmetatable({
		monster_key = self.monster_key,
		saya_key = self.monster_key,
		count = 2,
		container = nil,
		specs = {
			[self.monster_key] = 'co_exp_season1_monster',
			[self.saya_key] = 'co_exp_season1_saya',
		},
	}, {
		__index = {
			get = function(this, key)
				return this.container[key]
			end,
			load_async = function(this)
				if this.container == nil then
					this.container = load_util.create_dynamic_npcs_async(this.specs)
				end
			end,
			dispose = function(this)
				if this.container ~= nil then
					load_util.dispose_dynamic_npcs(this.container)
					this.container = nil
				end
			end,
		}
	})
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CoopExpeditionIngameSequenceStartEvent), 'on_coop_ex_sequence_start_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

--region Event

function local_class:on_event(e)
	return false
end

function local_class:on_coop_ex_sequence_start_event(e)
	-- 연출 시작
	start_coroutine(self.start_first_clear_event, self)

	return true
end

--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopExpeditionIngameSequenceStartEvent))

	self.dynamic_npc:dispose()
	self.dynamic_npc = nil

	self.cs_controller = nil
	self.scene = nil
end

function local_class:start_first_clear_event()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local leader = get_party_leader()
	local leader_pos = field_util.get_marker_pos('coop_expedition_narrative_manual')
	local monster_pos = field_util.get_marker_pos('coop_expedition_narrative_monster')
	local saya_pos = field_util.get_marker_pos('coop_expedition_narrative_saya')
	local move_end_key = 'move_end'

	-- 1초 간 circle fade out
	music_player_util.play_stage_music({ state = 'muted', mix = 4 })
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 리더 죽어 있는 상태라면 살림
	if leader.CharacterStatsBehaviour.IsDead then
		self:revive_character(leader)
	end

	-- 리더 세팅
	character_util.hide_weapon(leader, true)
	character_util.remove_anim_and_emotion(leader)

	character_util.set_direction(leader, 'up')
	character_util.set_position(leader, leader_pos)
	camera_util.resize_to_default(0)

	-- background_fade_controller 세팅
	local is_get = false
	local background_fade_controller = nil

	while not is_get do
		is_get, background_fade_controller = global_table_util.try_create_background_fade_controller()
	end

	local asset_path = 'ondemand/coop_expedition/effect'
	local asset_name = 'white_tint_background'
	background_fade_controller:load_async(asset_path, asset_name)

	-- fx 로드
	self.fx:create_all()
	yield_return(unity_object_pool, 'WaitAll')

	-- npc 세팅
	self.dynamic_npc:load_async()

	local monster = self.dynamic_npc:get(self.monster_key)
	local saya = self.dynamic_npc:get(self.saya_key)

	wait_for_sec(1)

	--플레이어 2초동안 walk 자세로 왼쪽으로 4.5칸 이동.
	wp_util.move_with_end_callback(leader, leader.Position + vector(-4.5, 0, 0), nil
	, 2, self, move_end_key)

	--이동을 시작한 동시에 화면 1초동안 일반 페이드 인.
	local wind_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_04', loop = true, fade_in_time = 4 })
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	wp_util.wait_move_end(self, move_end_key)

	--플레이어 이동 완료 후 0.5초 대기
	wait_for_sec(0.5)

	--플레이어 up 방향 전환. 후 0.4초 대기
	scene_util.set_direction(leader, 'up')
	wait_for_sec(0.4)

	--down 방향 전환 후 0.4초 대기
	scene_util.set_direction(leader, 'down')
	wait_for_sec(0.4)

	--플레이어 left 방향 전환.
	scene_util.set_direction(leader, 'left')

	--카메라 오른쪽 바깥에서 몬스터 (left, idle, idle) 생성
	--몬스터가 2초에 걸쳐 플레이어 기준 오른쪽 4.5칸 옆 위치로 walk 자세로 이동.
	character_util.set_position(monster, monster_pos)
	character_util.set_direction(monster, 'left')
	wp_util.move_async(monster, leader_pos, nil, 2)

	--몬스터 (left, idle, pounce_ready_loop) 자세로 전환 후 1.5초 대기
	music_player_util.play_sfx_one_shot('01_growl_wolf_01')
	scene_util.set_anim(monster, self, { name = 'pounce_ready_loop', loop = true })
	wait_for_sec(1.5)

	--몬스터가 0.8초에 걸쳐 플레이어 기준 오른쪽 1.5칸 옆 위치로 run 자세로 이동.
	music_player_util.play_sfx_one_shot('02_wolf_boss_jump_01')
	music_player_util.play_sfx_one_shot('01_slowmotion_01')
	character_util.remove_anim(monster)
	wp_util.move_with_end_callback(monster, leader.Position + vector(1.5, 0, 0)
	, nil, 0.8, self, move_end_key, { run = true })

	--동시에 0.3초에 걸쳐 Stage Camera 값 3.5로 줌인.
	camera_util.resize_by_ratio(3.5, 0.3)
	--0.1초 대기
	wait_for_sec(0.1)

	--플레이어 (right, attack, idle 자세로 jump 1회)와 동시에 머리 위에 (notice) 이모티콘 표시.
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	character_util.set_direction(leader, 'right')
	character_util.set_emotion(leader, { name = 'attack' })
	character_util.normal_jump(leader, '01_small_jump_01')
	local emoticon = character_util.show_emoticon(leader, nil, 'notice')

	--몬스터가 이동을 완료한 이후 notice 이모티콘 바로 삭제되며, 1프레임만에 화면 화이트 페이드 아웃.
	wp_util.wait_move_end(self, move_end_key)

	screen_util.fade_out_async(0, unity_class.color.white, 'linear')

	emoticon:Dispose()

	--화면 가려진 동안 세팅
	--■지점에 사야 NPC (right, idle, idle) 생성
	character_util.set_position(saya, saya_pos)
	character_util.set_direction(saya, 'right')
	--몬스터,플레이어,사야 캐릭터 까맣게 틴트 처리
	character_util.add_color(leader, leader.Name, unity_class.color.black, 1, 0)
	character_util.add_color(monster, monster.Name, unity_class.color.black, 1, 0)
	character_util.add_color(saya, saya.Name, unity_class.color.black, 1, 0)
	--배경 하얗게 틴트 처리
	background_fade_controller:set_background_color(1, 1, 1)
	background_fade_controller:set_background_active(true)
	background_fade_controller:set_background_sorting_order('Top Effects', 0)
	background_fade_controller:set_background_alpha(1)
	character_util.set_sorting_layer(leader, 'Top Effects', 1)
	character_util.set_sorting_layer(monster, 'Top Effects', 1)
	character_util.set_sorting_layer(saya, 'Top Effects', 1)

	--사야 ‘china_sword_epic’ 무기 장착한 상태로 (right, attack, katana_batto) / 몬스터 (left, idle, damaged)
	character_util.spine_set_attachment(saya, '[base]weapon1', 'gold_hilt_sword')
	character_util.set_anim(saya, { name = 'katana_batto', loop = false })
	character_util.set_anim(monster, { name = 'damaged' })
	--플레이어 (right, surprise, idle)
	scene_util.set_anim(leader, self, 'idle')
	scene_util.set_emotion(leader, self, 'surprise')
	--몬스터 중앙에 fx_co_ex_bigslash_black_white 출력
	music_player_util.fade_out_sfx(wind_sfx, 0.5)
	music_player_util.play_sfx_one_shot('02_bakeneko_rush_01')
	music_player_util.play_sfx_one_shot('01_event_vb_02')
	self.fx.big_slash():Instantiate(monster.Position)
	--0.1초간 화면 일반페이드 인
	screen_util.fade_in_async(0.1, unity_class.color.white, 'linear')

	--1.6초 대기
	wait_for_sec(1.6)

	--1초간 다음 동작 수행
	--플레이어,사야,몬스터 색 회복
	character_util.remove_color(leader, leader.Name, 1)
	character_util.remove_color(monster, monster.Name, 1)
	character_util.remove_color(saya, saya.Name, 1)
	--배경 틴트 회복
	coroutine_util.while_each_frame(1, function(progress)
		background_fade_controller:set_background_alpha(1 - progress)
	end)

	--0.2초 대기
	wait_for_sec(0.2)

	--사야 (left, sleep_deep, katana_batto_end)
	scene_util.set_emotion(saya, self, 'sleep_deep')
	scene_util.set_anim(saya, self, { name = 'katana_batto_end', loop = false })

	local animation_duration = spine_util.get_animation_duration(saya, 'katana_batto_end')
	wait_for_sec(animation_duration)

	--몬스터 airspin되며 죽음.
	wind_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_04', loop = true, fade_in_time = 4 })
	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	character_util.air_spin(monster, { offset = unity_class.vector3.right * 3 })
	--몬스터 몬스터 airspin되며 죽는게 완료될 때까지 기다린 이후, 0.5초 대기
	wait_for_sec(2)

	--사야 (left, idle, idle) 로 전환 후 1초 대기
	character_util.set_direction(saya, 'left')
	character_util.remove_anim_and_emotion(saya)
	wait_for_sec(1)

	--사야 캐릭터 1.5초에 걸쳐 왼쪽으로 4칸 walk 자세로 이동
	wp_util.move(saya, saya.Position + vector(-4, 0, 0), nil, 2)

	--0.5초가 지났을 때 1.2초에 걸쳐 화면 일반 페이드 아웃.
	wait_for_sec(0.5)

	music_player_util.fade_out_sfx(wind_sfx, 3)
	screen_util.fade_out_async(1.2, unity_class.color.black, 'linear')

	background_fade_controller:dispose_loaded()

	character_util.stop(saya)

	-- 카메라 화면 밖으로 보냄
	camera_util.move_async(vector(3000, 0, 3000), 0)
	wait_for_sec(0.5)

	-- 클리어 UI 보여야해서 fade in
	screen_util.fade_in_async(0, unity_class.color.black, 'linear')

	-- 연출 시퀀스 끝
	message_system:Publish(CS.Oak.CoopExpeditionIngameSequenceEndEvent.Create())
end

function local_class:revive_character(character)
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = character
	heal_info.target = character
	heal_info.heal = character.CharacterStatsBehaviour.MaxHP
	heal_info.skipEffect = true
	heal_info.isRevive = true

	command_util.publish_heal(heal_info)
	message_system:SendSync(character.CharacterBehaviour, CS.Oak.StateResetEvent.Instance)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
