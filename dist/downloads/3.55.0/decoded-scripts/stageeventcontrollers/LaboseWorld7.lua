local local_class = newclass('LaboseWorld7Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 386

	--챔피언 소드 위치
	self.get_champion_sword_pos = function()
		return field_util.get_marker_pos('s33_staff_roll_pos_2')
	end

	self.champion_sword = nil
	self.champion_sword_id = 21142

	self.amb_ship_sfx = nil
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	if self.champion_sword ~= nil then
		self.champion_sword:ConsumeComplete()
		self.champion_sword = nil
	end

	if self.amb_ship_sfx ~= nil then
		self.amb_ship_sfx:Stop()
		self.amb_ship_sfx = nil
	end
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	do
		local background_attacher = get_or_create_global_table(
				'Quest/Main/LaboseWorld/Common/OtherSideBackgroundAttacher'
		)

		background_attacher:load_async()
	end
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return true
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

	--챔피언 소드 세팅
	if quest_progress ~= nil and
			not quest_progress.IsComplete then
		local champion_sword_pos = self.get_champion_sword_pos()
		self.champion_sword = self:create_champion_sword_on_floor(champion_sword_pos + vector(0, 0.25, 0))
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		-- 에필로그 이벤트 마커에서 시작
		self:play_epilogue_bgm()
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('epilogue_start_pos'),
				true, false)
	elseif quest_progress.InnerProgress == 25 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 26 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 27 then
		self:play_amb_ship_sfx()
		--bgm muted로 재생하기 위함!
		self:custom_stage_entry('left', field_util.get_marker_pos('default_start') + vector(0,1,0),
				true, false)
	elseif quest_progress.InnerProgress == 28 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 29 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 30 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 31 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 32 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('s33_knight_pos')
		, false, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:play_amb_ship_sfx()
	if self.amb_ship_sfx == nil then
		self.amb_ship_sfx = music_player_util.play_sfx({
			sfx_name = '01_amb_ship_03', volume = 0.8, mix = 4, loop = true
		})
	end
end

function local_class:fade_out_amb_ship_sfx(mix)
	mix = lua_helper.get_or_default(mix, 10)
	if self.amb_ship_sfx ~= nil then
		music_player_util.fade_out_sfx(self.amb_ship_sfx, mix)
	end

end

--- 땅에 꽂혀있는 챔피언 소드 세팅용 유틸
---@param position any 세팅될 위치
function local_class:create_champion_sword_on_floor(position)
	local sword_id = self.champion_sword_id
	local champion_sword = drop_item_util.create_item({
		pos = position,
		itemid = sword_id,
		notforinven = true,
		lootstate = 'dontfindlooter'
	})

	-- SpriteTransform.position 을 움직여 놓으면 shake 할때 기준점이 틀어져서 기본 Position 값에 offset 적용으로 변경
	--champion_sword.SpriteTransform.position = position + vector(-0.06, 0.1, 0.1)
	champion_sword.Position = position + vector(-0.06, 0.1, 0.1)
	champion_sword.SpriteTransform.localRotation = unity_class.quaternion.Euler(-35, 180, -134)
	champion_sword.SpriteTransform.localScale = vector(0.75, 0.75, 0.75)
	champion_sword.ShadowTransform.gameObject:SetActive(false)

	return champion_sword
end

function local_class:custom_stage_entry(dir, pos, directional_stage_entry, play_stage_music)
	local knight = get_party_leader()

	music_player:PlayStageIntroMusic()

	--muted로 재생하기 위함!
	if play_stage_music then
		music_player_util.play_stage_music({ state = 'field' })
	else
		music_player_util.play_stage_music({ state = 'muted' })
	end


	-- 리더를 시작 좌표로 이동
	local leader = get_party_leader()
	character_util.set_position(leader, pos)
	character_util.set_direction(leader, dir)

	if directional_stage_entry then

		CS.Oak.CommonScreenplay.ShowStageTitle(game_string:GetString(stage.Name), 1)
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

		music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
		character_util.set_anim(knight, { name = 'victory_get', loop = false })

		wait_for_sec(1.5)

		character_util.remove_anim(knight)
		character_util.set_direction(knight, dir)
	end

	music_player_util.change_stage_music_volume('field', 1)

	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	user_party:ResetControllers()
end

function local_class:play_epilogue_bgm()
	music_player_util.play_stage_music({
		state = 'field',
		name = 'ondemand/v2_86_laboseworld/audio:bgm_laboseworld_pn',
	})
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
