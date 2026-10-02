local local_class = newclass("EasyForest1At1Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	return
end

function local_class:need_on_launch()
	local q = user_progress:GetStartedQuest(27)
	return q == nil or q.InnerProgress <= 8
end

function local_class:on_launch(start_point_name)
	local q = user_progress:GetStartedQuest(27)

	if q == nil or q.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif q.InnerProgress >= 4 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(get_maiden, self))
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, stage:DefaultStageLaunch())
	end
end

function local_class:get_maiden()
	local maiden = get_character("maiden")
	maiden.Position = stage.Field:GetMarker("default_start").position + vector(1, 0, 0)
	maiden.Direction = CS.Oak.Direction.Left
	maiden.ActiveState = CS.Oak.ActiveState.Enabled

	coroutine.yield(stage:DefaultStageLaunch())
	character_util.convert_to_party_member(maiden, user_party)
end

function local_class:dispose()
	self.scene = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}