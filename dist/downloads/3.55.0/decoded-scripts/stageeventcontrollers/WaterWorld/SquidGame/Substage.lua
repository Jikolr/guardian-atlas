local local_class = newclass('WaterWorldSquidGameController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 477
	self.quest_progress = nil
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:load_resource()
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
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:npc_setting(self.quest_progress)
	self:door_setting(self.quest_progress)

	stage_start_util.start_function(self.quest_progress)
end

function local_class:npc_setting(progress)
	if progress ~= nil and progress.InnerProgress >= 1 then
		local soldier_count = 2

		for i = 1, soldier_count do
			local soldier = get_character('s1_pink_soldier_' .. i)

			character_util.set_position(soldier, field_util.get_marker_pos('s1_soldier_pos_' .. i))
			character_util.set_direction(soldier, 'down')
			character_util.spine_set_attachment(soldier, '[base]weapon1', 'ak')
			character_util.set_anim(soldier, { name = 'rifle_idle' })
			soldier.Interactable.Talk = 'ww_squid_game_s1_oneline_' .. i
		end
	end

	--patrol
	if progress.InnerProgress == 3 then
		for i = 1, 15 do
			local npc = get_character('s4_patrol_npc_' .. i)

			npc.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
			npc.Hitbox = CS.Oak.Hitbox(vector(0.9, 1, 0.9))
		end
	end
end

function local_class:door_setting(progress)
	if progress ~= nil and not progress.IsComplete and progress.InnerProgress >= 3 then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('break_room_door_5'))
	end
end

return local_class
