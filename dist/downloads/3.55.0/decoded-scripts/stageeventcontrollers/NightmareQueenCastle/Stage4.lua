local local_class = newclass('NightmareQueenCastle4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.sector_tanker_quest_id = 459

	self.area_detection_reset_info = {
		detection_reset_pos_1 = {
			dir = direction_constants.left,
		},
		detection_reset_pos_2 = {
			dir = direction_constants.down,
		},
		detection_reset_pos_3 = {
			dir = direction_constants.up,
		},
		detection_reset_pos_4 = {
			dir = direction_constants.right,
		},
		detection_reset_pos_5 = {
			dir = direction_constants.up,
		},

	}

	-- marker
	self.marker = {
		detection_reset_pos = function(pos_idx)
			return field_util.get_marker_pos('detection_reset_pos_' .. pos_idx)
		end,
	}

	-- 발각 되었는지?
	self.is_detected = false

	self.is_blacked = false

	self.black_color_key = 'android_black_color'

	---@type CharacterPlaceController 캐릭터 배치 컨트롤러
	self.place_controller = nil

	--- 후일담 이벤트 컨트롤러
	self.post_script_controller = nil

	self.script = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.post_script_controller:dispose()

	self.script:dispose()

	self.script = nil

	self.place_controller = nil

	self.cs_controller = nil
end

function local_class:load_resource()
	local is_create, place_controller = global_table_util.try_create('Quest/Etc/CharacterPlaceController/CharacterPlaceController')

	self.post_script_controller = get_or_create_global_table('Quest/Nightmare/QueenCastle/PostScript/PostScript')

	self.place_controller = place_controller

	self.place_controller:initialize()

	self.post_script_controller:initialize()

	local script_path = 'Quest/Nightmare/QueenCastle/Common/WeaponNpcBattleLogic'

	self.script = CS.Oak.StageLuaScript.Create(script_path)
end

function local_class:on_event(e)
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
	local quest_progress = user_progress:GetStartedQuest(self.sector_tanker_quest_id)

	self.script:load()

	stage_start_util.start_function(quest_progress)

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
end

function local_class:on_custom_stage_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.sector_tanker_quest_id)

	-- 섹터 크레이그 퀘스트 섹션3 혹은 클리어 상태일 경우 발각 이벤트 진행되지 않음
	if quest_progress ~= nil and (quest_progress.InnerProgress >= 2 or quest_progress.IsComplete) then
		return false
	end

	if not self.is_detected and not self.is_blacked and string.find(e.Params[0], 'detected_by_character_in_') then
		self.is_detected = true
		sp_util.start_scene(self.on_party_detected_by_npc, self, e.Sender)

		return true
	elseif string.find(e.Params[0], self.black_color_key) then
		self.is_blacked = not self.is_blacked
	end

	return false
end

function local_class:on_party_detected_by_npc(detecting_character)
	music_player_util.change_stage_music_volume('field', 0.6, 1)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')

	party_util.look_at(detecting_character)
	party_util.set_emotion({ name = 'attack' })
	party_util.jump(0.5, 0.3)

	scene_util.set_anim(detecting_character, self, { name = 'release' })
	scene_util.set_emotion(detecting_character, self, 'mad')

	music_player_util.play_sfx_one_shot('03_dialogue_worker_03')

	speech_bubble_util.show_speech_bubble_async(detecting_character, { key = 'nm_qc_sector_tk_detecting_1',
																	   bubble_type = 'shout', type_speed = 0, skip = true })

	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.8, 'linear')
	wait_for_sec(0.5)

	--리셋 위치 설정
	do
		local reset_marker_name = detecting_character.FieldObjectController.ResetMarkerName
		local reset_marker = field_util.get_marker_pos(reset_marker_name)

		local reset_dir = self.area_detection_reset_info[reset_marker_name].dir
		party_util.position_party(reset_marker, reset_dir, 'linear')
	end

	camera_util.return_to_leader(0)
	character_util.remove_anim_and_emotion(detecting_character)
	party_util.remove_emotion()
	party_util.remove_animation()

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.8, 'linear')

	self.is_detected = false

	music_player_util.change_stage_music_volume('field', 1, 1)
end

return local_class
