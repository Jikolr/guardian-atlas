local local_class = newclass('LaboseWorld3Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	--region Character
	--안드로이드
	--a == 1, b == 2, ... , h == 8
	self.get_android = function(target_number)
		return get_character('android_' .. target_number)
	end

	--라보스 괴물
	self.get_labose_creature = function(target_number)
		return get_character('labose_creature_' .. target_number)
	end
	--endregion Character

	--region FieldObject
	self.get_center_warp = function()
		return get_field_object('center_warp')
	end

	self.get_cockpit_warp = function()
		return get_field_object('cockpit_warp')
	end
	--endregion FieldObject

	--region Marker
	--안드로이드 마커
	--a == 1, b == 2, ... , h == 8
	self.get_android_pos = function(target_number, number)
		return field_util.get_marker_pos('s10_android_' .. target_number .. '_pos_' .. number)
	end

	--라보스 괴물 위치
	self.get_labose_creature_pos = function(target_number, number)
		return field_util.get_marker_pos('s10_labose_creature_' .. target_number .. '_pos_' .. number)
	end

	--챔피언 소드 마커
	self.get_sword_pos = function()
		return field_util.get_marker_pos('s14_sword_pos_1')
	end
	--endregion Marker

	--region Fx
	self.fx = {
		teleport_red = function()
			return unity_object_pool.GetOrCreate('fx_lw_teleportsphere_red')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}
	--endregion Fx

	self.scene_version = scene_util.default_version

	--챔피언소드 아이디
	self.champion_sword_id = 21142

	--챔피언 소드
	self.champion_sword = nil

	-- 메인 퀘스트 id
	self.main_quest_id = 386
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	if self.champion_sword then
		self.champion_sword:ConsumeComplete()
		self.champion_sword = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.fx:load_all()

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
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
	return false
end

function local_class:on_interact_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if quest_progress.InnerProgress > 13 then
		if lua_helper.reference_equals(e.Target, self.get_cockpit_warp()) then
			local pos = self.get_center_warp().Position

			sp_util.start_scene(self.execute_warp, self, pos)
		elseif lua_helper.reference_equals(e.Target, self.get_center_warp()) then
			local pos = self.get_cockpit_warp().Position

			sp_util.start_scene(self.execute_warp, self, pos)
		end
	end
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_field_object('lightning_puzzle_brazier_holdable_1'), 'reset_zone_1') then
		local target_switch = get_field_object('lightning_puzzle_reset_1')

		start_coroutine(self.reset_brazier, self, target_switch)
	end

	if type_util.is_zone_full_leave(e, get_field_object('wind_puzzle_brazier_holdable_1'), 'reset_zone_2') then
		local target_switch = get_field_object('wind_reset_1')

		start_coroutine(self.reset_brazier, self, target_switch)
	end
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

	-- 시작 연출
	self:pre_setting(quest_progress)

	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, false)
	elseif quest_progress.InnerProgress == 10 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s11_start'),
				true, true)
	elseif quest_progress.InnerProgress == 11 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s12_start'),
				true, true)
	elseif quest_progress.InnerProgress == 12 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s13_start'),
				true, true)
	elseif quest_progress.InnerProgress == 13 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

-- 세팅
function local_class:pre_setting(quest_progress)
	-- 클리어하지 않은 경우에만 세팅
	if not quest_progress.IsComplete then
		-- 섹션10 이후  15섹션 이전 전용 연출
		if quest_progress.InnerProgress > 9 and
				quest_progress.InnerProgress < 14 then
			local androids = {
				a = {
					target = self.get_android(1),
					pos = self.get_android_pos(1, 6),
					dir = 'right',
					emo = 'scared',
					talk = 'lw_main_s10_oneline_1'
				},
				b = {
					target = self.get_android(2),
					pos = self.get_android_pos(2, 4),
					dir = 'left',
					talk = 'lw_main_s10_oneline_2'
				},
				c = {
					target = self.get_android(3),
					pos = self.get_android_pos(3, 4),
					dir = 'left',
					talk = 'lw_main_s10_oneline_3'
				},
				d = {
					target = self.get_android(4),
					pos = self.get_android_pos(4, 4),
					dir = 'left',
					emo = 'scared',
					talk = 'lw_main_s10_oneline_4'
				},
				e = {
					target = self.get_android(5),
					pos = self.get_android_pos(5, 4),
					dir = 'right',
					talk = 'lw_main_s10_oneline_5'
				},
				f = {
					target = self.get_android(6),
					pos = self.get_android_pos(6, 4),
					dir = 'right',
					emo = 'sleep_deep',
					talk = 'lw_main_s10_oneline_6'
				},
				g = {
					target = self.get_android(7),
					pos = self.get_android_pos(7, 4),
					dir = 'right',
					emo = 'scared',
					talk = 'lw_main_s10_oneline_7'
				},
				h = {
					target = self.get_android(8),
					pos = self.get_android_pos(8, 5),
					dir = 'right',
					talk = 'lw_main_s10_oneline_8'
				},
			}

			for _, android in pairs(androids) do
				android.target.CustomIdleAnimationName = 'idle'

				character_util.set_active_state(android.target, 'enabled')
				character_util.set_position(android.target, android.pos)
				character_util.remove_anim_and_emotion(android.target)
				scene_util.hide_weapon(android.target)
				scene_util.set_direction(android.target, android.dir, false)
				android.target.Interactable.Talk = android.talk

				if android.emo then
					scene_util.set_emotion(android.target, self, android.emo)
				end

				if android.anim then
					scene_util.set_anim(android.target, self, android.anim)
				end
			end

			if quest_progress.InnerProgress > 11 then
				--12섹션 1번째방 원라인 npc 설정
				local android_a = get_character('s12_android_2')
				local android_b = get_character('s12_android_3')

				scene_util.hide_weapon(android_a)
				scene_util.set_anim(android_a, self, 'bomb_idle')
				scene_util.set_anim(android_b, self, { name = 'cross_arm', one_shot_sfx = false })
			end
		end

		-- 12 섹션 이후
		if quest_progress.InnerProgress > 11 then
			local android = get_character('s12_android_1')
			local android_pos = field_util.get_marker_pos('s12_reminisce_pos_1') + vector(1.5, 0, 0.5)

			--가 NPC (up, dualgun_attack2): 작업에 방해되니 말 걸지 말아주십시오.
			scene_util.set_direction(android, 'right', false)
			character_util.set_active_state(android, 'enabled')
			character_util.set_position(android, android_pos)
			character_util.remove_anim_and_emotion(android)

			scene_util.set_emotion(android, self, 'tired')
			scene_util.set_anim(android, self, 'sleep')
			android.Interactable.Talk = 'lw_main_s12_oneline_1'
		end
	end

	--상시 세팅

	--3스테이지 완료 후 재진입 시
	if quest_progress.InnerProgress > 13 then
		--워프 인터렉트 설정
		local center_warp = self.get_center_warp()
		local cockpit_warp = self.get_cockpit_warp()

		center_warp.Interactable = CS.Oak.PublishInteractable.Create()
		cockpit_warp.Interactable = CS.Oak.PublishInteractable.Create()

		--챔피언 소드 세팅
		self.champion_sword = self:create_champion_sword_on_floor(self.get_sword_pos())
		self.champion_sword:SetSortingLayer('Top Effects', 0)
	end

end

--region custom_function
function local_class:execute_warp(pos)
	local leader = get_party_leader()
	local offset = vector(0.5, 0.3, 0.5)
	local leader_start_pos = pos + offset
	local leader_move_pos = leader_start_pos + vector(0, 0, -2)

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	camera_util.move_async(leader_start_pos, 0)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	scene_util.set_direction(leader, 'down', false)

	local leader_fx = self.fx.teleport_red():Instantiate(leader.Position + vector(0, 0.5, 0),
			unity_class.quaternion.identity, leader.Transform)

	local warp_y_offset = 0.3

	local levitation_move = function(target, cur_y)
		target.Position = vector_util.get_x0z(target.Position, cur_y)
		target.SpineController.ShadowOffsetY = warp_y_offset - cur_y
	end

	self:hero_landing_copy_not_emo_anim(
			leader,
			nil,
			leader_start_pos,
			9.9,
			1,
			3,
			{ shadow_offset_y = 0.3 })

	local levitation = true

	local from = leader.Position.y
	local to = leader.Position.y - 0.2

	start_coroutine(function()
		while levitation do
			coroutine_util.while_from_to_each_frame(0.7, from, to, function(_, cur_value)
				levitation_move(leader, cur_value)

				if not levitation then
					return false
				end
			end)

			local prev_from = from
			from = to
			to = prev_from
		end
	end)

	wait_for_sec(1)

	levitation = false

	coroutine.yield(nil)

	self:hero_landing_copy_not_emo_anim(
			leader,
			nil,
			leader_start_pos,
			leader.Position.y - 0.3,
			2,
			0.3,
			{ shadow_offset_y = 0.3 })

	wait_for_sec(1)

	leader_fx:Dispose()

	yield_return(nil)

	leader_fx = self.fx.teleport_red():Instantiate(leader.Position + vector(0, 0.5, 0),
			unity_class.quaternion.identity, leader.Transform)

	wait_for_sec(0.5)

	leader_fx:Dispose()

	camera_util.return_to_leader(0)

	wait_for_sec(0.5)

	local jump_move_duration = (leader_move_pos - leader.Position).magnitude / 4

	scene_util.set_anim(leader, self, 'jump')
	character_util.jump(leader, 0.4, jump_move_duration)
	wp_util.move_async(leader,
			leader_move_pos,
			nil,
			jump_move_duration)

	character_util.remove_anim_and_emotion(leader)

	wait_for_sec(0.5)
end

function local_class:hero_landing_copy_not_emo_anim(fo, dir, pos, jump_height, fall_duration, finish_y_pos, data)
	dir = lua_helper.get_or_default(dir, fo.Direction)
	pos = lua_helper.get_or_default(pos, fo.Position)
	finish_y_pos = lua_helper.get_or_default(finish_y_pos, 0)
	jump_height = lua_helper.get_or_default(jump_height, 10)
	fall_duration = lua_helper.get_or_default(fall_duration, 0.4)

	local info = {}

	info.is_hit = lua_helper.get_value(data, 'is_hit', false)
	info.shadow_offset_y = lua_helper.get_value(data, 'shadow_offset_y', 0)
	info.is_active = lua_helper.get_value(data, 'is_active', true)

	-- 캐릭터를 히어로 랜딩 할 위치로 배치
	if info.is_active then
		character_util.set_active_state(fo, 'enabled')
	end
	character_util.set_position(fo, pos + vector(0, jump_height, 0), true)
	character_util.set_direction(fo, dir)

	local cur_time = unity_class.time.time
	local start_pos = fo.Position
	local free_fall = CS.CalculatorFreeFall(fall_duration, fo.Position.y, 0)

	while unity_class.time.time - cur_time < fall_duration do
		free_fall:Proceed(unity_class.time.deltaTime)
		local dist_y = free_fall:GetDistance()

		if start_pos.y + dist_y > finish_y_pos then
			character_util.set_position(fo, start_pos + vector(0, dist_y, 0))
		else
			character_util.set_position(fo, vector(start_pos.x, finish_y_pos, start_pos.z))
		end

		fo.SpineController.ShadowOffsetY = info.shadow_offset_y - fo.Position.y

		coroutine.yield(nil)
	end

	--TODO: 착지 될 때 효과음이 고정이라면 여기서 랜딩 끝날 때의 사운드 재생 하는 것도 좋을 듯함
	character_util.set_position(fo, vector(start_pos.x, finish_y_pos, start_pos.z))

	if info.is_hit then
		self.fx.hit():Instantiate(vector(start_pos.x, finish_y_pos, start_pos.z))
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
		lootstate = 'dontfindlooter',
	})

	champion_sword.Position = position
	champion_sword.SpriteTransform.position = position + vector(-0.06, 0.1, 0.1)
	champion_sword.SpriteTransform.localRotation = unity_class.quaternion.Euler(-35, 180, -134)
	champion_sword.ShadowTransform.gameObject:SetActive(false)

	return champion_sword
end

function local_class:reset_brazier(reset_target)
	message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(reset_target))
end
--endregion custom_function

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
