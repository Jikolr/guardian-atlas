local local_class = newclass('SnowMountain1At3Controller')

function local_class:init(cs_controller, scene)
--- 기존 서바이버 관련 코드 사용하지 않아 삭제.
-- TODO:GameGuy 관련 코드 기믹으로 옮겨야함. (나중에 송수한이 할것)
-- TODO:의외성 요소

	self.cs_controller = cs_controller
	self.scene = scene()

	--self.substage_3_3_name = 'substage_3_3'
	--self.substage_3_3_npc_name = 'innuit_elder_igloo'

	self.substage_3_4_name = 'substage_3_4'
	self.substage_3_4_npc_name = 'substage_3_4_npc'

	self.hiker_name = "accident_hiker"

	self.hiker_try_to_grab_bomb_coroutine = nil
	self.hided_cave_grid_name = "hided_cave_grid"
	self.hided_cave_rock_name = "hided_cave_rock"

	self.hiker_marker_name = "accident_hiker_pos"
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_load_resource_routine, self))
end

function local_class:on_load_resource_routine()
	quest_icon.PreLoad()

	--- load check
	while not quest_icon.IsLoaded do
		coroutine.yield(nil)
	end

	--- substage setup
	--if not user_progress:IsStageOpened(self.substage_3_3_name) then
	--	local substage_npc = get_character(self.substage_3_3_npc_name)
	--	substage_npc.Interactable:AddListener(self.cs_controller)
	--	quest_icon.SetSubstageIcon(substage_npc)
	--end

	-- 서브스테이지 3-4 관련 처리
	if not user_progress:IsStageOpened(self.substage_3_4_name) then
		local substage_3_4_npc = get_character(self.substage_3_4_npc_name)
		substage_3_4_npc.Interactable:AddListener(self.cs_controller)
		quest_icon.SetSubstageIcon(substage_3_4_npc)
	end

	yield_return_func(self.scene.setting, self.scene)

	self.scene:add_callback('HikerMoveToPlayer', { controller = self, func = self.hiker_move_to_player })
	self.scene:add_callback('HikerLeaveCave', { controller = self, func = self.hiker_leave_cave })

	return false
end

function local_class:need_on_launch()
	local snow_mountain_main_quest_id = 19

	local main_quest = user_progress:GetStartedQuest(snow_mountain_main_quest_id)
	return main_quest ~= nil and main_quest.InnerProgress == 5
end

function local_class:on_launch(start_point_name)
	--- 메세지만 보냄, 실제 진입 처리는 main quest 에서 한다.
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	--local substage_npc = get_character(self.substage_3_3_npc_name)
	--if substage_npc ~= nil and lua_helper.type_compare(substage_npc.Interactable, CS.Oak.NPCInteractable) then
	--	substage_npc.Interactable:RemoveRelatedEvent(self.cs_controller)
	--end

	local substage_3_4_npc = get_character(self.substage_3_4_npc_name)
	if substage_3_4_npc ~= nil and lua_helper.type_compare(substage_3_4_npc.Interactable, CS.Oak.NPCInteractable) then
		substage_3_4_npc.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
	self.scene = nil
end

---[[ on event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		return self:on_camera_grid_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		return self:on_camera_grid_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		return self:on_field_object_destroyed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local target = e.Target

	--if lua_helper.reference_equals(target, get_character(self.substage_3_3_npc_name)) and
	--		not user_progress:IsStageOpened(self.substage_3_3_name) then
	--
	--	sp_util.play_normal_screenplay(self.substage_open_routine, self, target)
	--else
	if lua_helper.reference_equals(target, get_character(self.substage_3_4_npc_name)) and
			not user_progress:IsStageOpened(self.substage_3_4_name) then

		sp_util.play_normal_screenplay(self.sub_stage_open, self)
	end
end

function local_class:on_camera_grid_enter_event(e)
	if not self:seen_old_hoot_shot_stake_event() and e.CameraGrid.name == self.hided_cave_grid_name
			and self.hiker_try_to_grab_bomb_coroutine == nil then
		self.hiker_try_to_grab_bomb_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.hiker_try_to_grab_bomb, self))
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if not self:seen_old_hoot_shot_stake_event() and e.CameraGrid.name == self.hided_cave_grid_name
			and self.hiker_try_to_grab_bomb_coroutine ~= nil then
		local hiker = get_character(self.hiker_name)
		stop_coroutine(self.hiker_try_to_grab_bomb_coroutine)

		hiker.SpineController:CancelShake()
		CS.SpeechBubble.Return(hiker)
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	if e.FieldObject.Name == self.hided_cave_rock_name then
		local hiker = get_character(self.hiker_name)
		stop_coroutine(self.hiker_try_to_grab_bomb_coroutine)

		hiker.SpineController:CancelShake()
		CS.SpeechBubble.Return(hiker)

		local blocker = get_character("hookshot_blocker")
		character_util.set_active_state(blocker, "disabled")

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.scene.DestroyCaveRock, self.scene))
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	if self:seen_old_hoot_shot_stake_event() then
		local blocker = get_character("hookshot_blocker")
		local hiker = get_character(self.hiker_name)

		character_util.set_active_state(blocker, "disabled")
		character_util.set_active_state(hiker, "disabled")

		local stake = get_field_object("breakable_stake")
		if stake.FieldObjectBehaviour:GetType() == typeof(CS.Oak.HookShotStakeBehaviour) then
			stake.FieldObjectBehaviour:SetBrokenState()
		end

	end

	return false
end

---]]

--function local_class:substage_open_routine(target)
--	quest_icon.RemoveIcon(target)
--	target.Interactable:RemoveRelatedEvent(self.cs_controller)
--
--	character_util.set_direction(target, "down")
--
--	character_util.align_party(target, target.Direction, 1, "arc")
--
--	wait_for_sec(0.5)
--
--	character_util.set_emotion(target, { name = 'tried' })
--	character_util.set_anim(target, { name = 'question', loop = false })
--
--	speech_bubble_util.show_speech_bubble_async(target, { key = 'substage_secretgarden_1', skip = true })
--
--	speech_bubble_util.show_speech_bubble_async(target, { key = 'substage_secretgarden_2', skip = true })
--
--	speech_bubble_util.show_speech_bubble_async(target, { key = 'substage_secretgarden_3', skip = true })
--
--	speech_bubble_util.show_speech_bubble_async(target, { key = 'substage_secretgarden_4', skip = true })
--
--	local substage_map = get_field_object(self.substage_3_3_name).FieldObjectBehaviour
--	-- quest와 연관이 없기때문에 이런식으로 열어도 무방
--	coroutine.yield(substage_map:OpenStage())
--end

function local_class:sub_stage_open()
	local substage_3_4_npc = get_character(self.substage_3_4_npc_name)

	quest_icon.RemoveIcon(substage_3_4_npc)
	substage_3_4_npc.Interactable:RemoveRelatedEvent(self.cs_controller)

	character_util.set_direction(substage_3_4_npc, "left")

	character_util.align_party(substage_3_4_npc, substage_3_4_npc.Direction, 1, "arc")

	wait_for_sec(0.5)

	character_util.set_emotion(substage_3_4_npc, { name = 'scared' })

	local shake_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.substage_npc_shake, self))
	music_player:PlaySfxOneShot('01_rustle_01')
	speech_bubble_util.show_speech_bubble_async(substage_3_4_npc, { key = 'substage_snowdragon_open_1', skip = true })

	stop_coroutine(shake_coroutine)

	character_util.set_emotion(substage_3_4_npc, { name = 'surprise' })
	character_util.set_anim(substage_3_4_npc, { name = 'embarrassed' })

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble_async(substage_3_4_npc, { key = 'substage_snowdragon_open_2', skip = true })

	character_util.set_emotion(substage_3_4_npc, { name = 'scared' })
	character_util.set_anim(substage_3_4_npc, { name = 'release' })

	music_player:PlaySfxOneShot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(substage_3_4_npc, { key = 'substage_snowdragon_open_3', skip = true })

	character_util.remove_anim(substage_3_4_npc)

	speech_bubble_util.show_speech_bubble_async(substage_3_4_npc, { key = 'substage_snowdragon_open_4', skip = true })

	local substage_map = get_field_object(self.substage_3_4_name).FieldObjectBehaviour

	yield_return(substage_map, 'OpenStage')

	substage_3_4_npc.Interactable.Talk = 'substage_snowdragon_open_1'
end

function local_class:substage_npc_shake()
	local substage_3_4_npc = get_character(self.substage_3_4_npc_name)

	while true do
		character_util.shake(substage_3_4_npc, 0.05, 2)

		wait_for_sec(3)
	end
end

---[[ 의외성
function local_class:hiker_try_to_grab_bomb()
	local hiker = get_character(self.hiker_name)
	character_util.shake(hiker, 0.05, 9999)
	while true do
		speech_bubble_util.show_speech_bubble_async(hiker, { key = 'accident_hiker_talk_1', skip = false })
		wait_for_sec(4)
	end
end

function local_class:seen_old_hoot_shot_stake_event()
	return stage_progress:GetNamedData(self.hided_cave_rock_name)
end

function local_class:hiker_move_to_player()
	local hiker = get_character(self.hiker_name)

	local check_dir_list = {
		unity_class.vector3.left,
		unity_class.vector3.right,
		unity_class.vector3.back,
		unity_class.vector3.forward,
	}

	local target_pos = nil
	local check_count = 1

	while check_count <= 100 do
		for i = 1, #check_dir_list do
			local check_pos = user_party_leader.Position + check_dir_list[i] * check_count
			if field:IsThereFloorAt(check_pos) then
				target_pos = check_pos
				break
			end
		end

		if target_pos ~= nil then
			break
		end

		check_count = check_count + 1
	end

	target_pos = target_pos == nil and user_party_leader.Position + unity_class.vector3.forward or target_pos

	local plan_path_done = false
	local plan_path = nil
	field.PathFinder:FindNormalPath(hiker, target_pos, 100, hiker, 0,
			nil,
			function(path, req_key)
				if req_key == 0 then
					plan_path_done = true
					plan_path = path
				end
			end)

	while not plan_path_done do
		coroutine.yield(nil)
	end

	if plan_path.Count == 1 then
		wp_util.move_way_points_async(hiker, {waypoints = target_pos, speed = 4.5, run = true, play_sfx = true})
	else
		local wp = {}

		for i = 0, plan_path.Count - 1 do
			wp[i+1] = plan_path[i]
		end
		wp_util.move_way_points_async(hiker, {waypoints = wp, speed = 4.5, run = true, play_sfx = true})
	end

	character_util.look_at(hiker, user_party_leader)

	user_party:PositionParty(user_party_leader.Position, direction_util.get_opposite(hiker.Direction), 1, CS.Oak.Party.AlignType.Arc)
	wait_for_sec(1)

	party_util.look_at(hiker)
end

function local_class:hiker_leave_cave()
	local hiker = get_character(self.hiker_name)
	local target_pos = vector(5, 0, -130)

	local plan_path_done = false
	local plan_path = nil
	field.PathFinder:FindNormalPath(hiker, target_pos, 100, hiker, 0,
			nil,
			function(path, req_key)
				if req_key == 0 then
					plan_path_done = true
					plan_path = path
				end
			end)
	while not plan_path_done do
		coroutine.yield(nil)
	end

	local wp = {}
	for i = 0, plan_path.Count - 1 do
		wp[i+1] = plan_path[i]
	end

	hiker:RemoveAnimation()
	wp_util.move_way_points_async(hiker, {waypoints = wp, speed = 4.5, run = true, play_sfx = true})

	character_util.set_active_state(hiker, "disabled")
end
---]]

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}