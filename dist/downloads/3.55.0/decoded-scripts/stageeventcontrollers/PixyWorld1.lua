local local_class = newclass('PixyWorld1Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 412

	---@generic T
	---@field create_all fun(self:self)
	---@param fx_spec_names T
	---@return T | table<string, UnityObjectPool>
	local function create_fx_manager(fx_spec_names)
		local create_all = function()
			for _, spec_name in pairs(fx_spec_names) do
				unity_object_pool.GetOrCreate(spec_name)
			end
		end

		return setmetatable({}, {
			__index = function(this, key)
				if key == 'create_all' then
					return create_all
				else
					return unity_object_pool.GetOrCreate(fx_spec_names[key])
				end
			end
		})
	end

	self.fx = create_fx_manager({
		gimmick_reset = 'FX_reset_object',
	})
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	self.fx.create_all()

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 파티멤버 전투 시에만 등장 로직 / 전투 팔로우 배틀 로직
	custom_stage_option_util.register_option({
		break_in_party_member = {},
		follow_npc_battle_logic = { quest_id = 412 },
	})
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return true
end

function local_class:on_switch_on_off_event(e)
	if e.IsTurningOn and
			lua_helper.reference_equals(e.SwitchObject, get_field_object('puz_star1_reset_switch_1')) then
		self:reset_rock()

		return true
	end

	return false
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
	local boomerang_controller = get_stage_event_controller('PixyWorldBoomerangController')

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('main_s4_restart_pos'), true, true)
	elseif quest_progress.InnerProgress == 0 then
		boomerang_controller:boomerang_active_setting(false)

		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), false, false)
	elseif quest_progress.InnerProgress == 1 then
		boomerang_controller:boomerang_active_setting(false)

		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 2 then
		boomerang_controller:boomerang_active_setting(false)

		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('main_s3_restart_pos'), true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('main_s4_restart_pos'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('main_s4_restart_pos'), true, true)
	end
end

function local_class:reset_rock()
	for idx = 1, 6 do
		local rock = get_field_object('reset_rock_' .. idx)

		if rock.ActiveState == active_state('disabled') then
			-- 부숴진 바위가 있다면 다시 활성화
			local heal_info = CS.Oak.HealInfo()
			heal_info.isRevive = true
			heal_info.sender = rock
			heal_info.target = rock
			heal_info.skipEffect = true

			command_util.publish_heal(heal_info)
		end

		self.fx.gimmick_reset:Instantiate(rock.Bounds.center)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
