local local_class = newclass('LilithTowerPassage13At3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.vent_mini_game = nil
	self.game_name = 'VentMiniGame'
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	-- 미니게임 로드
	self.vent_mini_game = mini_game_manager:GetOrCreate(self.game_name)

	local is_mini_game_load_complete = false
	mini_game_manager:LoadResource(self.game_name, 'vent_mini_game_passage_3', function()
		is_mini_game_load_complete = true
	end)

	while not is_mini_game_load_complete do
		coroutine.yield()
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	self.vent_mini_game = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
