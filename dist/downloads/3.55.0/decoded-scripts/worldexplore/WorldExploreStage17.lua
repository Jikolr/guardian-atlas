--- 월드 탐험 게임 컨트롤러
local local_class = newclass("WorldExploreStage17")

function local_class:init(cs_controller, scene)
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.WorldExploreStageEvent), 'on_event')

	self.constants = require('worldexplore/WorldExploreConstants')
end



function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.WorldExploreStageEvent), 'on_event')
	self.world_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageLoadedEvent) then

	elseif event_type == typeof(CS.Oak.StageStartEvent) then

	elseif event_type == typeof(CS.Oak.WorldExploreStageEvent) then
		if e.Type == self.constants.event_types.start_stage_event_load then
			self:load_npc()
		elseif e.Type == self.constants.event_types.npc_interaction_start then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.npc_interaction, self, e.Unit1, e.Unit2))
		elseif e.Type == self.constants.event_types.stage_launch_ready then
			--coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_event, self))
			self.world_controller:default_start_event()
		end
	end
	return false
end

function local_class:need_on_launch()
	return false

end

function local_class:on_launch(start_point_name)
end

function local_class:load_resource()
end

function local_class:load_npc()
	local has, world_controller = stage.WorldStates:TryGetValue("controller")
	self.world_controller = world_controller
	self.world_controller.current_enemy_gold = 100
	self.world_controller.current_enemy_wood = 0
	self.world_controller.current_enemy_stone = 0
	--self.world_controller:add_npc("eva", "eva", CS.UnityEngine.Vector2Int(1, 2), CS.Oak.Direction.Left, "none", false, "unknown")
	self.world_controller:finish_stage_event_load()
end

function local_class:npc_interaction(hero_unit, npc_unit)
	wait_for_sec(1.0)
	self.world_controller:finish_npc_interaction()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}