local local_class = newclass("ExpeditionHiddenBossFix")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	-- 보스 몬스터 죽었을 때 컨트롤러 정지, 연출 끝났을 때 컨트롤러 복귀
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed')
	message_system:Subscribe(self, typeof(CS.Oak.DyingEndEvent), 'on_dying_end')
end

function local_class:on_field_object_destroyed(e)
	if e.FieldObject.Name == 'expedition_salamandra_fire_fury_hidden' then
		user_party:StopAndDisableControl()
	end
end

function local_class:on_dying_end(e)
	if e.character.Name == 'expedition_salamandra_fire_fury_hidden' then
		user_party:ResetControllers()
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DyingEndEvent))

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
