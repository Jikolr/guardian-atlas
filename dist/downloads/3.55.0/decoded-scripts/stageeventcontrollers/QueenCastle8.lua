local local_class = newclass('QueenCastle8Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	self.main_quest_id = 330
	self.get_fx_princess_barrier = function()
		return unity_object_pool.GetOrCreate('fx_qc_altar_barrier')
	end
end

function local_class:dispose()
	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.get_fx_princess_barrier()

	yield_return(unity_object_pool, 'WaitAll')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	--TODO: 여기서 각 섹션별 시작 연출
	start_coroutine(self.pre_setting, self)
end
--endregion

--region event
function local_class:on_event(e)
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

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local inner_progress = main_quest_progress.InnerProgress

	if inner_progress > 10 then
		-- 공주 손수건 배치 함수
		self:handkerchief_setting()
	end

	do
		get_field_object('directional_light').ActiveState = active_state('enabled')
		get_field_object('directional_light_1').ActiveState = active_state('disabled')
		get_field_object('directional_light_3').ActiveState = active_state('disabled')
	end

	if main_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start_2'),
				true, true)
		self:crash_floor_setting()
	elseif inner_progress == 10 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, true)
	elseif inner_progress == 11 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'),
				true, true)
		self:princess_barrier_setting()
	elseif inner_progress == 12 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, true)
		self:princess_barrier_setting()
	elseif inner_progress == 13 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, true)
	elseif inner_progress == 14 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, true)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start_2'),
				true, true)
	end
end

-- 꼬마공주 손수건 세팅
function local_class:handkerchief_setting()
	drop_item_util.create_item({
		pos = field_util.get_marker_pos('main_s11_princess_pos_1') + vector(0, 0, -1.5),
		itemid = 20900,
		notforinven = true,
		lootstate = 'dontfindlooter',
		skip_text = true
	})
end

-- 바닥 붕괴 유지 세팅
function local_class:crash_floor_setting()
	local crash_floor = get_field_object('crash_floor')
	crash_floor.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	crash_floor.Hitbox = CS.Oak.Hitbox(vector(0.05, 0, 0.05), vector(10, 1, 10))
	local crash_floor_anim = crash_floor:GetComponent(typeof(CS.UnityEngine.Animator))
	crash_floor_anim:Play('off')
end

-- 꼬마공주 가두는 베리어 이펙트 세팅
function local_class:princess_barrier_setting()
	self.get_fx_princess_barrier():Instantiate(vector(-0.5, 2, 48.5))
	self.get_fx_princess_barrier():Instantiate(vector(-52.5, 2, 48.5))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
