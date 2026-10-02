local local_class = newclass("FoxHoleFollowersController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.battle_2_event_open = false
	self.tint_loop_stat = false

	self.npc_followers = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.FallInHoleStartEvent), 'on_hole_in_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_hole_in_event(e)
	if lua_helper.reference_equals(e.Target, user_party.Leader) then
		for _, follower in ipairs(self.npc_followers) do
			-- 트래킹 하고있는 NPC들이 리더를 팔로잉 하고있는 상태라면 같이 구멍으로 떨궈줌.
			if lua_helper.type_compare(follower.FieldObjectController.CurrentState, CS.Oak.CharacterControllerPartyFollowerNPCState) then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hole_in, self, follower))
			end
		end
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	if stage.Name == 'fox_1_1' then
		table.insert(self.npc_followers, get_character('old_man'))
	elseif stage.Name == 'fox_1_4' then
		table.insert(self.npc_followers, get_character('fairy_basic3'))
	end

	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FallInHoleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

-- 구멍에 들어가서 떨어지는 연출
function local_class:hole_in(target)
	local full_fall_wait_time = 1.3 + 0.05
	local idx = array_util.index_of(self.npc_followers,target) - 1
	local party_idx = user_party.Count + idx
	local jump_duration = 0.5
	local party_move_delay = 0.2

	character_util.stop(target)

	-- 앞에 파티원들이 떨어질때까지 순서를 기다려줌
	local fall_wait_time = party_idx * party_move_delay
	wait_for_sec(fall_wait_time)

	local offset = fall_wait_time >= 0.5 and unity_class.vector3.zero or direction_util.to_vector3(user_party.Leader.Direction)
	local fall_in = user_party.Leader.Position + offset
	local speed = vector_util.get_x0z(fall_in - target.Position).magnitude / jump_duration
	target.Direction = direction_util.to_side_dir(target.Direction)
	target:SetAnimation('get', true)
	wp_util.move_way_points(target, { waypoints = fall_in, speed = speed })
	character_util.jump(target, 1, jump_duration)
	target.SpineController:Scale(unity_class.vector3.zero, jump_duration)
	wait_for_sec(jump_duration)

	-- 파티가 구멍에서 떨어지는 연출을 하기 전 까지 대기
	wait_for_sec(full_fall_wait_time - fall_wait_time - jump_duration)

	local bounce_cb = function(count)
		if count ~= 1 then return end

		music_player_util.play_sfx({ sfx_name = '01_land_01', type_priority = 'gimmick', player_priority = 'player' })
	end

	local fall_calc = CS.CalculatorFreeFall.Create(12, 12, 12, 1, bounce_cb)
	fall_calc:SetElasticity(0.3)
	fall_calc:ScaleTime(1.8)

	target.Position = vector_util.get_x0z(user_party.Leader.Position, fall_calc:GetDistance())
	target.Direction = character_util.get_direction('down')
	target:SetEmotion('damaged', true)
	target:SetAnimation('embarrassed', true)
	target.SpineController:Scale(unity_class.vector3.one, 0)

	while not fall_calc:IsDone() do
		fall_calc:Proceed(unity_class.time.deltaTime);

		target.Position = vector_util.get_x0z(target.Position, fall_calc:GetDistance())

		coroutine.yield()
	end

	target:RemoveEmotion()
	target:RemoveAnimation()
	local clms = CS.Oak.CharacterControllerPartyFollowerNPCState.Create(target, user_party, array_util.index_of(self.npc_followers,target) - 1, 0, false)
	message_system:SendSync(target, CS.Oak.StateChangeEvent.Create(clms))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}