local local_class = newclass('SubStageDemonGod')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	---@type LaboseWorldDemonGodLaboseCreatureManager
	self.creature_manager = nil

	self.demon_god_quest = nil

	---@type LaboseWorldScreenplayManager
	self.sp_manager = get_or_create_global_table('Quest/Main/LaboseWorld/Common/LaboseWorldScreenplayManager')

	---@type LaboseWorldDemonGodGimmickController
	self.gimmick_controller = nil

	---@type LaboseWorldDemonGodGimmickResetManager
	self.gimmick_reset_manager = nil

	self.get_star_piece_truck = function()
		return get_field_object('star_piece_truck')
	end
end

function local_class:load_resource()
	self.creature_manager = get_or_create_global_table('Quest/Main/LaboseWorld/DemonGod/Gimmick/LaboseCreatureManager')

	self.gimmick_reset_manager = get_or_create_global_table('Quest/Main/LaboseWorld/DemonGod/Gimmick/GimmickResetManager')

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.creature_manager = nil
	self.sp_manager = nil
	self.gimmick_controller = nil
	self.gimmick_reset_manager = nil
	self.cs_controller = nil
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	self.gimmick_controller = get_stage_event_controller('LaboseWorldDemonGodGimmickController')

	self:set_creature()

	do
		local star_piece_truck = self.get_star_piece_truck()

		self.gimmick_controller:add_interact_ignore_truck(star_piece_truck)

		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_star_piece_truck_interact_event')
	end

	return true
end

function local_class:on_star_piece_truck_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_star_piece_truck()) then
		self.sp_manager:try_start_scene(self.interact_star_piece_truck_routine, self, e.Target)

		return true
	end

	return false
end

function local_class:launch_routine()
	local demon_god_quest_id = 394
	local demon_god_quest = quest_util.get_started_quest(demon_god_quest_id)

	if demon_god_quest == nil then
		-- 이런 상황은 발생해선 안됨
	elseif demon_god_quest.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)

	elseif demon_god_quest.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)

	elseif demon_god_quest.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s1_encounter_fog_align_center'),
				true, true)

	elseif demon_god_quest.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s3_start'),
				true, true)

	elseif demon_god_quest.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('s4_start'),
				true, true)

	elseif demon_god_quest.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s5_start'),
				true, true)

	elseif demon_god_quest.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s6_start'),
				true, true)
	end
end

function local_class:set_creature()
	-- 누워있는 애들
	do
		local creature_names = {
			's1_opening_creature',
			'lying_creature_1',
		}

		for _, name in pairs(creature_names) do
			local creature = get_character(name)

			-- 안드라스 기믹에 등록
			self.gimmick_controller:add_creature_interactable(creature)
		end
	end

	-- 얼어있는 애들
	do
		local creature_names = {
			'frozen_creature_1',
			'frozen_creature_2',
		}

		for _, name in pairs(creature_names) do
			local creature = get_character(name)

			-- 얼려놓은 상태로 전환
			self.gimmick_controller:convert_creature_to_holdable_immediately(creature)
		end
	end

	-- 감시 중인 애들
	do
		local creature_names = {
			'star_piece_truck_labose_creature_1',
			'star_piece_truck_labose_creature_2',
		}

		for _, name in pairs(creature_names) do
			local creature = get_character(name)

			-- 얼려놓은 상태로 전환
			self.creature_manager:set_creature_with_marker(creature, nil,
					'star_piece_truck_detected_reset', nil, {
						sight_dist = 5,
						sight_angle = 45
					})
		end
	end

	do
		local creature = get_character('s5_blocking_truck_labose_creature')

		self.creature_manager:set_creature_with_marker(creature,
				nil,  's5_blocking_truck_detected_reset')
	end

	do
		local creature_names = {
			's6_top_puzzle_labose_creature_1',
			's6_top_puzzle_labose_creature_2',
			's6_top_puzzle_labose_creature_3',
		}

		for _, name in pairs(creature_names) do
			local creature = get_character(name)

			-- 얼려놓은 상태로 전환
			self.creature_manager:set_creature_with_marker(creature, nil,
					's6_top_puzzle_detected_reset', {
						type = 'fly_fall',
						fall_offset = unity_class.vector3.back * 3.5,
						speed = 5,
						fly_height = 1.5,
						spin_clockwise = true
					})
		end
	end

	do
		local creature = get_character('s6_left_puzzle_labose_creature')

		-- 얼려놓은 상태로 전환
		self.creature_manager:set_creature_with_marker(creature, nil,
				's6_left_puzzle_detected_reset', nil, {
					sight_dist = 5,
					sight_angle = 45,
				})
	end

	do
		local creature_names = {
			's6_bottom_puzzle_labose_creature_1',
			's6_bottom_puzzle_labose_creature_2',
		}

		for _, name in pairs(creature_names) do
			local creature = get_character(name)

			-- 얼려놓은 상태로 전환
			self.creature_manager:set_creature_with_marker(creature, nil,
					's6_bottom_puzzle_detected_reset', {
						type = 'fly_fall',
						fall_offset = unity_class.vector3.right * 3,
						speed = 5,
						fly_height = 1.5,
						spin_clockwise = true
					}, {
						sight_dist = 5,
						sight_angle = 45,
					})
		end
	end
end

function local_class:interact_star_piece_truck_routine(truck)
	-- 플레이어가 오른쪽에서 인터랙트 했을 때에만 이벤트 연출 발동
	if truck.Bounds.center.x < get_party_leader().Position.x then
		message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_star_piece_truck_interact_event')

		self:move_star_piece_truck(truck)

		-- 바로 Remove를 때려버리면 파이몬 기믹쪽의 이벤트 구독 순서가 낮을 때 move_object 루틴이 두 번 도는 케이스가 발생할 수 있음
		self.gimmick_controller:remove_interact_ignore_truck(truck)
	else
		self.gimmick_controller:move_truck_routine(truck)
	end
end

function local_class:move_star_piece_truck(truck)
	wait_all_lua(
			function()
				self.gimmick_controller:move_truck_routine(truck)
			end,
			function()
				--기믹작동
				--트럭 이동과 동시에
				wait_for_sec(0.3)

				--카메라가 1.5초간 괴물이 있는 지점까지 이동 후
				local get_creature = function(number)
					return get_character('star_piece_truck_labose_creature_' .. number)
				end

				local camera_panning_pos = (get_creature(1).Position + get_creature(2).Position) / 2

				camera_util.move_async(camera_panning_pos, 1.5)

				--1.5초 대기
				wait_for_sec(1.5)

				--1초동안 카메라 다시 플레이어에게 복귀
				camera_util.return_to_leader(1)
			end
	)
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
