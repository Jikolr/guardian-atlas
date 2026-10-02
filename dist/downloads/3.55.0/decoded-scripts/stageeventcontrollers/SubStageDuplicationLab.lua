local local_class = newclass('SubStageDuplicationLabController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 맨손 기사 가져오기
	self.get_knight_fist = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_fist')
		else
			return get_character('knight_female_fist')
		end
	end

	-- 공주 가져오기
	self.get_princess = function()
		return get_character('princess')
	end
end

function local_class:load_resource()
	local clff = get_field_object('cliff_wall')

	self.cliff_sfx = music_player_util.play_sfx({
		sfx_name = '01_blizzard_03', loop = true,
		play_pos = clff.Position + vector(0, 0, 2.5),
		type_priority = 'event', player_priority = 'default'
	})

	-- CCTV HitBox 크기 줄임
	local cctvs = {}
	table.insert(cctvs, get_character('cctv_1'))
	table.insert(cctvs, get_character('cctv_2'))
	table.insert(cctvs, get_character('cctv_3'))
	table.insert(cctvs, get_character('cctv_4'))

	for i = 1, #cctvs do
		local cctv = cctvs[i]
		if cctv ~= nil then
			cctv.Hitbox = CS.Oak.Hitbox(vector(0.7, cctv.Hitbox.size.y, 0.7))
		end
	end
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:dispose()
	if self.cliff_sfx ~= nil then
		self.cliff_sfx:Stop()
		self.cliff_sfx = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:pre_setting()
	local change_leader = function(character, add_princess_to_party)
		local param = CS.Oak.CharacterConvertParam:ManualDefault()

		character_util.set_active_state(character, 'enabled')
		character_util.convert_to_manual_character(character, param, true)

		if add_princess_to_party == true then
			local princess = self.get_princess()
			character_util.set_active_state(princess, 'enabled')
			character_util.convert_to_party_member(princess, user_party, true)
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		local leader = user_party.Leader

		-- 리더를 시작 좌표로 이동
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
					leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	local qs_duplication_lab = user_progress:GetStartedQuest(317)

	if qs_duplication_lab ~= nil then
		local qs_duplication_lab_progress = qs_duplication_lab.InnerProgress

		if qs_duplication_lab.Grade == 0 then
			change_leader(self.get_knight_fist())
			start_stage_event('right', field:GetMarker('s2_leader_pos').position,
					false, false)
		elseif qs_duplication_lab_progress == 0 then
			change_leader(self.get_knight(), true)
			start_stage_event('up', field:GetMarker('default_start').position,
					true, true)
		elseif qs_duplication_lab_progress == 1 then
			change_leader(self.get_knight_fist())
			start_stage_event('right', field:GetMarker('s2_leader_pos').position,
					false, false)
		elseif qs_duplication_lab_progress == 2 then
			change_leader(self.get_knight_fist())
			start_stage_event('right', field:GetMarker('s2_leader_pos').position,
					false, false)
		else
			change_leader(self.get_knight_fist())
			start_stage_event('right', field:GetMarker('s2_leader_pos').position,
					true, true)
		end
	else
		change_leader(self.get_knight_fist())
		start_stage_event('right', field:GetMarker('s2_leader_pos').position,
				true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
