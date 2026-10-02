local local_class = newclass('CivilWar1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	-- 메인 퀘스트 id
	self.main_quest_id = 357

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 소히
	self.get_ghost_buster = function() return get_character('ghost_buster') end

	-- 리리스
	self.get_demon_queen = function() return get_character('demon_queen') end

	-- 에리나
	self.get_legendary_hero_old = function() return get_character('legendary_hero_old') end

	-- 마빈
	self.get_desert_slave = function() return get_character('desert_slave') end

	-- 마리안
	self.get_teatan_hero = function() return get_character('teatan_hero') end

	-- 크레이그
	self.get_tanker = function() return get_character('tanker') end

	-- 코코
	self.get_innuit = function() return get_character('innuit') end

	-- 페이 메이
	self.get_china_hero = function()
		return user_util.get_china_hero_character('china_hero_boy', 'china_hero_girl')
	end

	-- 콘웰
	self.get_neo_federation_governor = function() return get_character('neo_federation_governor') end

	-- 쌍둥이 안드로이드
	self.get_neo_federation_twins = function(index) return get_character('cw_neo_federation_twins_' .. index) end

	-- 회의장 내 모리안 측 병사 2명
	self.get_summit_saul_soldier = function(index) return get_character('summit_saul_soldier_' .. index) end

	-- 프리실라
	self.get_half_vampire = function() return get_character('half_vampire') end

	-- 발렌시아
	self.get_vampire_captain = function() return get_character('vampire_captain') end

	-- 리리스 일기
	self.get_demon_queen_diary = function() return get_field_object('demon_queen_diary') end

	-- 리셋 이팩트
	self.get_fx_reset = function() return unity_object_pool.GetOrCreate('FX_reset_object') end

	-- 사울 군인 원라인 샤우트 관련
	self.get_saul_soldier = function(index) return get_character('s3_saul_soldier_' .. index) end
	self.is_active_solider_shout = false
	self.start_saul_solider_count = 4
	self.end_saul_solider_count = 7

	-- 일기 아이템 스프라이트
	self.diary_sprite = nil

	-- 일기 아이템 이름
	self.diary_sprite_id = 21022

	-- 콘웰 케이크 관련 아이템
	self.cheesecake_item = nil
	self.cheesecake_item_id = 21023
	self.dish_item = nil
	self.dish_item_id = 21055
	self.is_enter_neo_federation_tent = false

	-- 플레이어 무기
	self.player_weapon = {
		right = nil,
		left = nil
	}

	-- 유틸
	self.cw_util = nil

	-- 네오 페데레이션 구역 존 바운스
	self.neo_federation_tent_zone_bounds = nil
end

function local_class:load_resource()
	self.cw_util = get_or_create_global_table('Quest/Main/CivilWar/Common/Util')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

--region event
function local_class:on_event(e)
	if type_util.is_interacted_target(e, self.get_demon_queen_diary()) then
		sp_util.play_normal_screenplay(self.interact_demon_queen_diary, self)
		return true
	end

	-- 사울 병사 활성화되었다면 체크해서 샤우트 말풍선 출력
	if self.is_active_solider_shout then
		for i = self.start_saul_solider_count, self.end_saul_solider_count do
			local soldier = self.get_saul_soldier(i)
			if type_util.is_interacted_target(e, soldier) then
				speech_bubble_util.show_speech_bubble(soldier, { key = 'cw_main_s3_interact_3_4'
				, skip = false, bubble_type = 'shout', world_pos = vector(111.5, 0, -28.5), scale = 1.25 })
				return true
			end
		end
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'set_governor' then
		-- 3 ~ 4섹션 진행 중 주지사 세팅
		self:set_governor(99)
		return true
	elseif e:GetParamAt(0) == 'remove_governor' then
		self:remove_governor()
		return true
	elseif e:GetParamAt(0) == 'remove_player_weapon' then
		self:remove_player_weapon()
		return true
	elseif e:GetParamAt(0) == 'restore_player_weapon' then
		self:reset_player_weapon()
		return true
	elseif e:GetParamAt(0) == 'active_solider_shout' then
		self:set_solider_shout()
		return true
	elseif e:GetParamAt(0) == 'set_sfx_eating_cake' then
		self:set_sfx_eating_cake()
		return true
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	local camera_grid_name = e.CameraGrid.name

	-- TODO: 여러개로 늘어나면 테이블로 정리할 것
	if camera_grid_name == 'summit_area' then
		camera_util.resize_by_ratio(5, 0.5)
	elseif self.cheesecake_item ~= nil and
			type_util.is_player_enter_to_cam_grid(e, 'neo_federation_tent_grid') then
		self:set_sfx_eating_cake()
		return true
	end
end

function local_class:on_camera_grid_leave_event(e)
	local camera_grid_name = e.CameraGrid.name

	-- TODO: 여러개로 늘어나면 테이블로 정리할 것
	if camera_grid_name == 'summit_area' then
		camera_util.resize_by_ratio(4, 0.5)
		return true
	elseif type_util.is_player_leave_to_cam_grid(e, 'neo_federation_grid') then
		self:reset_wind_pot()
		return true
	elseif type_util.is_player_leave_to_cam_grid(e, 'neo_federation_tent_grid') then
		self:stop_sfx_eating_cake()
		return true
	elseif type_util.is_player_leave_to_cam_grid(e, 'brazier_puzzle_grid') then
		self:reset_brazier_puzzle()
		return true
	end

	return false
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
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	self.neo_federation_tent_zone_bounds = nil

	if self.diary_sprite ~= nil then
		self.diary_sprite:ConsumeComplete()
		self.diary_sprite = nil
	end

	self:stop_sfx_eating_cake()

	-- 콘웰 케이크 제거
	if self.cheesecake_item ~= nil then
		self.cheesecake_item:ConsumeComplete()
		self.cheesecake_item = nil
	end

	if self.dish_item ~= nil then
		self.dish_item:ConsumeComplete()
		self.dish_item = nil
	end

	-- 샤우트 병사들 활성화 상태라면 add_listener 구독해제
	if self.is_active_solider_shout then
		for i = self.start_saul_solider_count, self.end_saul_solider_count do
			local soldier = self.get_saul_soldier(i)
			character_util.remove_relate_event(soldier, self)
		end
	end

	self.cw_util = nil
	self.cs_controller = nil
	self.scene = nil
end

function local_class:launch_routine()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	self.cw_util:activate_control_directional_light(
			{
				main_field = 'default_light',
				demonworld_field = 'demonworld_light',
				tent_field = 'tent_light',
			}
	)

	self.neo_federation_tent_zone_bounds = field:GetZone('neo_federation_area_zone').Bounds

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 다이어리 세팅
	local diary = self.get_demon_queen_diary()
	self.diary_sprite = drop_item_util.create_item(
			{ itemid = self.diary_sprite_id, notforinven = true, lootstate = 'dontfindlooter',
			  pos = vector_util.get_x0z(diary.Position, 0.75), skip_text = true })

	-- 원라인 npc 무기 세팅
	self:set_one_line_npc(quest_progress)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s2_leader_pos_1')
				+ vector(0, 0.5, 0), false, false)
	elseif quest_progress.InnerProgress == 2 then
		local save_state = quest_util.get_custom_state(quest_progress, 's3_state_save_key')
		local marker = self:get_s3_start_marker(save_state)

		self:set_governor(save_state)
		self:custom_play_launch_stage(quest_progress, marker.direction, marker.position, true)
	elseif quest_progress.InnerProgress == 3 then
		local init_pos = field_util.get_marker_pos('s4_start_pos_1')
		local init_dir = field_util.get_marker_dir('s4_start_pos_1')
		stage_launch_util.play_launch_stage(init_dir, init_pos, true, true)
	elseif quest_progress.InnerProgress == 4 then
		camera_util.resize_by_ratio(5, 0)

		self:set_npcs_in_summit_room()
		self:remove_player_weapon()

		local init_pos = field_util.get_marker_pos('summit_knight_pos')
		local init_dir = field_util.get_marker_dir('summit_knight_pos')
		stage_launch_util.play_launch_stage(init_dir, init_pos, false, true)
	elseif quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('s6_start_pos'),
				false, false)
	elseif quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('s6_start_pos'),
				false, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

-- 섹션3 마커 구하기
function local_class:get_s3_start_marker(save_state)
	if save_state == 1 then
		return field:GetMarker('s3_start_pos_2')
	elseif save_state == 2 then
		return field:GetMarker('s3_start_pos_3')
	end

	return field:GetMarker('s3_start_pos_1')
end

-- 원라인 npc 세팅
function local_class:set_one_line_npc(quest_progress)
	local function set_weapon(first_name, count)
		for i = 1, count do
			local swat = get_character(first_name .. i)
			character_util.spine_set_attachment(swat, '[base]weapon1', 'ak')
			scene_util.set_anim(swat, self, 'rifle_idle')
		end
	end

	local is_quest_progressing = quest_progress ~= nil and not quest_progress.IsComplete

	-- 3 ~ 5 섹션으로 입장 시 부유성 친구들 세팅
	if is_quest_progressing
			and quest_progress.InnerProgress >= 1 and quest_progress.InnerProgress <= 4 then
		-- 크레이그
		local tanker = self.get_tanker()
		local pos = field_util.get_marker_pos('s2_tanker_pos_1')

		scene_util.set_direction(tanker, 'right', false)
		character_util.set_anim(tanker, { name = 'sleep' })
		scene_util.set_emotion(tanker, self, 'tired')
		character_util.set_position(tanker, vector_util.get_x0z(pos, 0.75))
		character_util.set_active_state(tanker, 'enabled')
		tanker.Interactable.Talk = 'cw_main_s2_33'

		-- 마빈
		local desert_slave = self.get_desert_slave()
		pos = field_util.get_marker_pos('s2_desert_slave_pos_1')

		scene_util.set_direction(desert_slave, 'right', false)
		character_util.set_anim(desert_slave, { name = 'sleep' })
		scene_util.set_emotion(desert_slave, self, 'tired')
		character_util.set_position(desert_slave, vector_util.get_x0z(pos, 0.75))
		character_util.set_active_state(desert_slave, 'enabled')
		desert_slave.Interactable.Talk = 'cw_main_s2_34'

		-- 마리안
		local teatan_hero = self.get_teatan_hero()
		pos = field_util.get_marker_pos('s2_teatan_hero_pos_1')

		scene_util.set_direction(teatan_hero, 'right', false)
		character_util.set_anim(teatan_hero, { name = 'sleep' })
		scene_util.set_emotion(teatan_hero, self, 'damaged')
		character_util.set_position(teatan_hero, vector_util.get_x0z(pos, 0.75))
		character_util.set_active_state(teatan_hero, 'enabled')
		teatan_hero.Interactable.Talk = 'cw_main_s2_35'

		-- 2섹션 이후라면 소히, 메이, 코코도 세팅
		if quest_progress.InnerProgress > 1 then
			local ghost_buster = self.get_ghost_buster()
			character_util.hide_weapon(ghost_buster, false)
			character_util.remove_anim_and_emotion(ghost_buster)
			scene_util.set_emotion(ghost_buster, self, 'tired')
			scene_util.set_anim(ghost_buster, self, 'eat')
			scene_util.set_direction(ghost_buster, 'right', false)
			character_util.set_position(ghost_buster, field_util.get_marker_pos('s2_ghost_buster_pos_2')
					+ vector(0, 0, 0.5))
			character_util.set_active_state(ghost_buster, 'enabled')
			ghost_buster.Interactable.Talk = 'cw_main_s2_36'

			-- 페이,메이
			local china_hero = self.get_china_hero()
			character_util.hide_weapon(china_hero, false)
			character_util.remove_anim_and_emotion(china_hero)
			scene_util.set_emotion(china_hero, self, 'tired')
			scene_util.set_anim(china_hero, self, 'cast')
			scene_util.set_direction(china_hero, 'left', false)
			character_util.set_position(china_hero, field_util.get_marker_pos('s2_china_hero_pos_2')
					- vector(0, 0, 0.5))
			character_util.set_active_state(china_hero, 'enabled')
			china_hero.Interactable.Talk = user_util.has_fei() and 'cw_main_s2_37' or 'cw_main_s2_38'

			-- 코코
			local innuit = self.get_innuit()
			scene_util.set_emotion(innuit, self, 'tired')
			scene_util.set_anim(innuit, self, 'cast')
			scene_util.set_direction(innuit, 'right', false)
			character_util.set_position(innuit, field_util.get_marker_pos('s2_ghost_buster_pos_2')
					+ vector(2, 0, -1.5))
			character_util.set_active_state(innuit, 'enabled')
			innuit.Interactable.Talk = 'cw_main_s2_38_1'

			pos = field_util.get_marker_pos('s2_legendary_hero_pos_1')

			if quest_progress.InnerProgress < 4 then
				-- 리리스
				local demon_queen = self.get_demon_queen()
				character_util.set_direction(demon_queen, 'right')
				character_util.set_position(demon_queen, pos - vector(1, 0, 0))
				character_util.set_active_state(demon_queen, 'enabled')
				character_util.hide_weapon(demon_queen, true)
				demon_queen.Interactable.Talk = 'cw_main_s2_109'

				--에리나
				local legendary_hero_old = self.get_legendary_hero_old()
				character_util.set_direction(legendary_hero_old, 'left')
				character_util.set_position(legendary_hero_old, pos)
				scene_util.set_anim(legendary_hero_old, self, { name = 'cross_arm', one_shot_sfx = false })
				character_util.set_active_state(legendary_hero_old, 'enabled')
				legendary_hero_old.Interactable.Talk = 'cw_main_s2_110'
			end
		end
	end

	--텐트 부분 왼쪽 막고 있는 군인들
	if quest_progress.InnerProgress < 6 then
		set_weapon('blocking_demon_swat_1_', 4)
	end
end

-- 주지사 세팅
function local_class:set_governor(setting_number)
	if setting_number < 0 then
		return
	end

	-- 네오 페데레이션 주지사 세팅
	if setting_number >= 1 then
		local nf_governor = self.get_neo_federation_governor()
		local pos = field_util.get_marker_pos('s3_neo_federation_governor_pos_1') - vector(0.5, 0, 0)

		character_util.set_direction(nf_governor, 'left')
		character_util.remove_anim_and_emotion(nf_governor)
		scene_util.set_anim(nf_governor, self, 'eat')
		character_util.set_position(nf_governor, pos)
		character_util.set_active_state(nf_governor, 'enabled')
		nf_governor.Interactable.Talk = 'cw_main_s3_interact_1'

		-- 안드로이드 쌍둥이 세팅
		for i = 1, 2 do
			local android = self.get_neo_federation_twins(i)
			pos = field_util.get_marker_pos('s3_neo_federation_twins_pos_' .. i)
			character_util.set_direction(android, 'left')
			character_util.set_position(android, pos)
			character_util.set_active_state(android, 'enabled')
			android.Interactable.Talk = 'cw_main_s3_interact_' .. (1 + i)
		end

		self.dish_item = drop_item_util.create_item({
			pos = nf_governor.Position + vector(-1, 0.7, 0),
			itemid = self.dish_item_id,
			notforinven = true,
			lootstate = 'dontfindlooter',
			skip_text = true,
			spr_scale = 0.6,
		})

		self.cheesecake_item = drop_item_util.create_item({
			pos = nf_governor.Position + vector(-1, 0.8, 0),
			itemid = self.cheesecake_item_id,
			notforinven = true,
			lootstate = 'dontfindlooter',
			skip_text = true,
			spr_scale = 0.6,
		})
	end

	-- 데몬샤이어 주지사 세팅
	if setting_number >= 2 then
		local half_vampire = self.get_half_vampire()
		local vampire_captain = self.get_vampire_captain()

		scene_util.set_anim(half_vampire, self, 'cast')

		character_util.set_direction(half_vampire, 'right')
		character_util.set_position(half_vampire, field_util.get_marker_pos('s3_demon_shire_governor_pos_1'))
		character_util.set_active_state(half_vampire, 'enabled')
		half_vampire.Interactable.Talk = 'cw_main_s3_interact_4'

		-- 발렌시아 (left, smile, idle) : 걱정마세요! 프리실라님이라면 잘 해낼 수 있을겁니다!
		scene_util.set_emotion(vampire_captain, self, 'smile')

		character_util.set_direction(vampire_captain, 'left')
		character_util.set_position(vampire_captain, field_util.get_marker_pos('s3_vampire_captain_pos_1'))
		character_util.set_active_state(vampire_captain, 'enabled')
		vampire_captain.Interactable.Talk = 'cw_main_s3_interact_5'
	end
end

function local_class:remove_governor()
	-- 콘웰 케이크 제거
	if self.cheesecake_item ~= nil then
		self.cheesecake_item:ConsumeComplete()
		self.cheesecake_item = nil
	end

	if self.dish_item ~= nil then
		self.dish_item:ConsumeComplete()
		self.dish_item = nil
	end

	local nf_governor = self.get_neo_federation_governor()
	nf_governor.Interactable.Talk = nil
	character_util.set_active_state(nf_governor, 'disabled')

	local half_vampire = self.get_half_vampire()
	half_vampire.Interactable.Talk = nil
	character_util.set_active_state(half_vampire, 'disabled')

	local vampire_captain = self.get_vampire_captain()
	vampire_captain.Interactable.Talk = nil
	character_util.set_active_state(vampire_captain, 'disabled')

	for i = 1, 2 do
		local android = self.get_neo_federation_twins(i)
		android.Interactable.Talk = nil
		character_util.set_active_state(android, 'disabled')
	end

end

-- 회의장 NPC 설정
function local_class:set_npcs_in_summit_room()
	local npc_settings = {
		{
			fo = 'demon_queen',
			marker = 'summit_demon_queen_pos'
		},
		{
			fo = 'legendary_hero_old',
			marker = 'summit_legendary_hero_pos'
		},
		{
			fo = 'demon_governor',
			marker = 'summit_demon_governor_pos'
		},
		{
			fo = 'summit_saul_soldier_1',
			marker = 'summit_saul_guard_pos_1'
		},
		{
			fo = 'summit_saul_soldier_2',
			marker = 'summit_saul_guard_pos_2'
		},
		{
			fo = 'half_vampire',
			marker = 'summit_half_vampire_pos'
		},
		{
			fo = 'vampire_captain',
			marker = 'summit_vampire_captain_pos'
		},
		{
			fo = 'neo_federation_governor',
			marker = 'summit_neo_federation_governor_pos'
		},
		{
			fo = 'cw_neo_federation_twins_1',
			marker = 'summit_neo_federation_twins_pos_1'
		},
		{
			fo = 'cw_neo_federation_twins_2',
			marker = 'summit_neo_federation_twins_pos_2'
		}
	}

	for i = 1, #npc_settings do
		local setting = npc_settings[i]
		local npc = get_character(setting.fo)

		character_util.set_active_state(npc, 'enabled')
		character_util.hide_weapon(npc, true)
		character_util.set_position(npc, field_util.get_marker_pos(setting.marker))
		character_util.set_direction(npc, field_util.get_marker_dir(setting.marker))
	end
end

-- 리리스 일기장 상호작용
function local_class:interact_demon_queen_diary()
	music_player_util.play_sfx_one_shot('01_turn_page_01')
	wait_for_sec(0.2)

	-- 『마계 통일 6대 조약』
	field_ui_util.show_narration_async({ key = 'cw_main_s2_42' })

	-- 1. 영토 분쟁 발생 시 마왕의 중재에 복종 할 것.
	-- 2. 마계 3주 주지사의 자치권 유지 할 것.
	field_ui_util.show_narration_async({ key = 'cw_main_s2_43' })

	-- 3. 마계에 위기가 있을 때 군사 통수권을 마왕에게 양도 할 것.
	-- 4. 인간계와의 교류를 전면 중단 할 것.
	field_ui_util.show_narration_async({ key = 'cw_main_s2_44' })

	-- 5. 고대 유적에 대한 모든 연구는 마왕의 허가를 득 할 것.
	-- 6. 헤븐 홀드와 관련 기술을 유출한 위험 분자를 영구 유폐 할 것.
	field_ui_util.show_narration_async({ key = 'cw_main_s2_45' })
end

-- 3 섹션 네오-페데레이션 주지사로부터 중력건을 받았는지 확인
function local_class:has_acquired_gravity_gun(quest_progress)
	local custom_state_key = 's3_state_save_key'
	return quest_util.get_custom_state(quest_progress, custom_state_key) >= 1
end

-- 중력건 UI 세팅하는 부분이랑 타이밍 이슈로 안꺼져서 커스텀하게 시작 연출 해주는 함수
function local_class:custom_play_launch_stage(quest_progress, dir, pos, play_stage_music)
	field_ui_manager:Hide()

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')

	stage_launch_util.directional_stage_entry(pos, dir, game_string:GetString(stage.Name),
			false, play_stage_music)

	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	message_system:PublishSync(CS.Oak.StageStartEvent.Instance)
	coroutine.yield(nil)

	if not self:has_acquired_gravity_gun(quest_progress) then
		CS.Oak.WindPotManager.SetActive(false)
	end

	user_party:ResetControllers()
	field_ui_manager:Show()
end

-- 플레이어 무기 제거
function local_class:remove_player_weapon()
	if self.player_weapon_right == nil then
		self.player_weapon_right = user_party_leader.Weapon1
	end

	if self.player_weapon_left == nil then
		self.player_weapon_left = user_party_leader.Weapon2
	end

	user_party.Leader:SetEquipment(CS.Oak.EquipmentSlot.Weapon1, nil)
	user_party.Leader:SetEquipment(CS.Oak.EquipmentSlot.Weapon2, nil)
	user_party.Leader.SpineController:SetAttachment('[base]weapon1', 'empty')
	user_party.Leader.SpineController:SetAttachment('[base]weapon2', 'empty')
end

-- 플레이어 무기 복구
function local_class:reset_player_weapon()
	user_party.Leader:SetEquipment(CS.Oak.EquipmentSlot.Weapon1, self.player_weapon_right)
	user_party.Leader:SetEquipment(CS.Oak.EquipmentSlot.Weapon2, self.player_weapon_left)
end

function local_class:set_solider_shout()
	if self.is_active_solider_shout then
		return
	end

	for i = self.start_saul_solider_count, self.end_saul_solider_count do
		local soldier = self.get_saul_soldier(i)
		soldier.Interactable = CS.Oak.NPCInteractable()
		character_util.add_listener(soldier, self)
	end

	self.is_active_solider_shout = true
end

function local_class:set_sfx_eating_cake()
	self:stop_sfx_eating_cake()
	self.eating_cake_sfx = music_player_util.play_sfx({ sfx_name = '01_eat_01'
	, parent = self.get_neo_federation_governor(), loop = true })
end

function local_class:stop_sfx_eating_cake()
	if self.eating_cake_sfx ~= nil then
		self.eating_cake_sfx:Stop()
		self.eating_cake_sfx = nil
	end
end

function local_class:reset_wind_pot()
	-- 중력건 기믹 리셋
	local wind_pot_manager = CS.Oak.WindPotManager

	-- 리더 오브젝트 빨아드린 상태라면 리셋
	local leader = get_party_leader()
	if not lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterWindPotPushState) then
		message_system:SendSync(leader, CS.Oak.WindPotPushEndEvent.Instance)
	end

	-- 네오 페데레이션 구역 존 밖에 존재하는 활성화된 오브젝트들을 리셋 시킨다.
	for i = 1, 8 do
		local fo = get_field_object('neo_federation_fo_' .. i)
		if wind_pot_manager.IsPulledObject(fo) then
			CS.Oak.WindPotManager.ForceInterrupt(CS.Oak.WindPotPullInterruptEvent.InterruptType.Reset)
		end

		if fo.ActiveState == active_state('enabled') and
				not self.neo_federation_tent_zone_bounds:Contains(fo.Position) then
			message_system:SendSync(fo, CS.Oak.WindPotPushEndEvent.Instance)
			message_system:Send(fo, CS.Oak.GimmickResetEvent.Instance)
		end
	end
end

function local_class:reset_brazier_puzzle()
	local brazier_count = 2
	local wind_pot_manager = CS.Oak.WindPotManager

	for i = 1, brazier_count do
		local brazier = get_field_object('brazier_puzzle_' .. i)
		if wind_pot_manager.IsPulledObject(brazier) then
			CS.Oak.WindPotManager.ForceInterrupt(CS.Oak.WindPotPullInterruptEvent.InterruptType.Reset)
		end

		message_system:SendSync(brazier, CS.Oak.WindPotPushEndEvent.Instance)
		self.get_fx_reset():Instantiate(vector_util.get_x0z(brazier.Position, 0.1))
		brazier.Position = field_util.get_marker_pos('brazier_puzzle_reset_pos_' .. i)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
