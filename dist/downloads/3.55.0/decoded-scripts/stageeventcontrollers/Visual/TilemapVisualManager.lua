local local_class = newclass('TilemapVisualManager')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.camera_grid_to_visual_name = {}

	self.transition_modes = {
		none = 1,
		fixed = 2,
		grid = 3,
	}

	self.current_transition_mode = self.transition_modes.none

	self.constants = require('stageeventcontrollers/Visual/TilemapVisualConstants.lua')[stage.Name]
end

function local_class:load_resource()
	if self.constants == nil then
		logger_util.warning('Has no TilemapVisualConstants for this stage.')

		return
	end

	if self.constants.target_grids ~= nil then
		self.current_transition_mode = self.transition_modes.grid

		for visual_name, grid_names in pairs(self.constants.target_grids) do
			for _, grid_name in pairs(grid_names) do
				if self.camera_grid_to_visual_name[grid_name] == nil then
					self.camera_grid_to_visual_name[grid_name] = visual_name
				else
					logger_util.error('Duplicated visual data at [Camera Grid : ' .. grid_name .. ']')
				end
			end
		end

		message_system:Subscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent), 'on_watching_camera_grid_changed_event')

	elseif self.constants.fixed_visual ~= nil then
		self.current_transition_mode = self.transition_modes.fixed

		message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.constants = nil
	self.cs_controller = nil
	self.camera_grid_to_visual_name = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	-- fixed로 입장하는 게 보장되지만 해당 이벤트는 추후 모드가 추가되었을 때도 사용할 가능성이 있으므로, 미리 조건을 넣어둠
	if self.current_transition_mode == self.transition_modes.fixed then
		-- TilemapVisualController의 OnStageLoaded와 같은 문맥에서 동작하기에,
		-- PublishSync가 아닌 Publish를 해서 TilemapVisualController 스테이트 변경보다 나중에 불리는 것이 보장됨
		self:change_visual(self.constants.fixed_visual)

		return true
	end

	return false
end

function local_class:on_watching_camera_grid_changed_event(e)
	if e.CameraGrid == nil then
		return false
	end

	local visual_name = self.camera_grid_to_visual_name[e.CameraGrid.name]

	if visual_name == nil then
		return false
	end

	self:change_visual(visual_name)

	return true
end

function local_class:change_visual(visual_name)
	message_system:Publish(CS.Oak.ChangeTilemapVisualEvent.Create(visual_name))
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
