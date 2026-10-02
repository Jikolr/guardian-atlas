local local_class = newclass('CafeChallengeBugFix')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	--- 보스 배틀존
	self.boss_zone_name = 'boss'

	--- 보스 객체 이름
	self.boss_fo_name = 'boss'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.boss_fo_name = nil
	self.boss_zone_name = nil

	self.cs_controller = nil
end

--- OnEvent
function local_class:on_event(_)
	return false
end

--- ZoneLeaveEvent
function local_class:on_zone_leave_event(e)
	--- 보스 배틀존을 빠져나갔을때
	if type_util.is_zone_full_leave(e, user_party.Leader, self.boss_zone_name) then
		--- 보스 객체 가져옴
		local boss = get_character(self.boss_fo_name)

		--- 보스가 죽었는지 체크
		if boss.FieldObjectStatsBehaviour.IsDead then
			--- 전투를 강제로 종료 시킴
			stage.BattleManager:ForceEndBattles()
		end
	end

	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
