local local_class = newclass('MouseBombManagerController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	if scene ~= nil then
		self.scene = scene()
	end

	self.mouse_bombs = {}

	-- 유저가 쥐 폭탄을 조종 중인가
	self.is_manipulating = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_fo_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')

	return
end

function local_class:on_event(_)
	return true
end

function local_class:on_move_fo_event(e)
	if not stage.StageLoaded  then return false end

	if table_util.contain_value(self.mouse_bombs, e.FieldObject) and not self.is_manipulating then
		self.is_manipulating = true
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.on_mouse_bomb_moving, self, e.FieldObject))
	end

	return false
end

function local_class:on_stage_loaded(_)
	local gimmick_layer = stage.StageGameObject.transform:Find(stage.Name .. '/gimmick/')
	for i = 0, gimmick_layer.childCount - 1 do
		local gimmick = gimmick_layer:GetChild(i):GetComponent(typeof(CS.Oak.FieldObject))
		if lua_helper.type_compare(gimmick.FieldObjectBehaviour, CS.Oak.MouseBombFieldObjectBehaviour) then
			table.insert(self.mouse_bombs, gimmick)
		end
	end

	return false
end

--- 쥐폭탄이 움직이기 시작하면 불리는 루틴
function local_class:on_mouse_bomb_moving(mouse_bomb)
	user_party.Leader:SetEmotion('smile', true)

	-- 쥐 폭탄이 터질떄까지 대기
	local behaviour = mouse_bomb.FieldObjectBehaviour
	cast(behaviour, typeof(CS.Oak.IFieldObjectBehaviour))
	while behaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped do coroutine.yield() end

	-- 화면 밖에 있어도 애니메이션 / 이모션 제거해줄수있게 강제 업데이트
	character_util.remove_anim_and_emotion(user_party.Leader)
	user_party.Leader.SpineController:ForceUpdateSpines(unity_class.time.deltaTime)

	self.is_manipulating = false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.mouse_bombs = nil
	self.scene = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
