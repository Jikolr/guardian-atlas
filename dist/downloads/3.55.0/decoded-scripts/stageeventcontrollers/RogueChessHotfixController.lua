local local_class = newclass("RogueChessHotfixController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_action_changed')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
end

function local_class:need_on_launch()
	return false
end

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

function local_class:on_battle_action_changed(e)
	--- 이벤트 타입 검증
	if not lua_helper.type_compare(e, typeof(CS.Oak.BattleActionsChangedEvent)) then
		return false
	end

	--- 타겟 캐시
	local target = e.Target

	--- 파괴된 객체에 대한 것이면 처리하지 않는다.
	if is_unity_null(target) then
		return false
	end

	--- enemy가 아니면 처리하지 않는다.
	if not CS.Oak.EntityGroupsExtensions.IsEnemy(target.EntityGroup) then
		return false
	end

	--- 로그체스 시스템
	local rc_sub_system = CS.Oak.Game:GetCurrentSubSystem()
	--- 이번 웨이브의 몬스터 레벨
	local monster_level = rc_sub_system.Wave:GetCurrentStepMonsterLevel()
	--- 경험치 데이터
	local exp_data = game_data_service.GetData('ExpsData')
	--- 필요 경험치값
	local target_exp = CS.Oak.ExpsDataLevelExpExtensions.GetTotalExpForLevel(exp_data, monster_level)
	--- 몬스터 레벨 재설정
	target.FieldObjectStatsBehaviour:SetExp(target_exp)

	--- 장비 경험치 데이터
	local weapon_enhance_data = game_data_service.GetData('WeaponEnhanceData')
	--- 스테이지 레벨
	local stage_level = stage.Spec.StageStandardLevel
	--- 아이템 레벨
	local item_exp = weapon_enhance_data:WeaponLevelToExp(stage_level)

	if target.Weapon1 then
		target.Weapon1.Experience = item_exp
	end

	if target.Weapon2 then
		target.Weapon2.Experience = item_exp
	end

	if target.Accessory1 then
		target.Accessory1.Experience = item_exp
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
