--- 플레이어 캐릭터들이 전투 인스턴스에 포함되있는 상태라면 회복력 저하 디버프를 부여 / 해제하는 컨트롤러
local local_class = newclass('HellForestPlayerHealIncomeDecrease')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	--- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	--- 전투 세션이 진행중인 대상인지 체크하기위한 기능
	self.battle_session_helpers = {}
	--- 사용할 디버프 명칭
	self.debuff_name = 'buff_hell_heal_income_down_persistent'
	--- 사용할 디버프의 레벨
	self.debuff_level = 10000
end

function local_class:load_resource()
	local on_session_begin_func = function(target) self:on_session_begin(target) end
	local on_session_finish_func = function(target) self:on_session_finish(target) end

	-- 지옥에선 일단 파티 수가 곧 유저의 파티수기 때문에 그냥 이대로 쓴다.
	local party_count = party_manager.Count
	for idx = 1, party_count do
		local party = party_manager[idx - 1]
		-- FIXME : 일단 그냥 래퍼를 통하지 않고 쌩 C# 콜로 진행, 나중에 stage_init에도 편입 시도를 하자..
		table.insert(self.battle_session_helpers, CS.Oak.BattleSessionOptionHelper(
			-- 주체는 각 파티의 리더
			party.Leader,
			-- StageMember도 있긴한데 일단 Party로 처리
			CS.Oak.BattleSessionOptionHelper.TargetType.Party,
			-- 세션이 시작할 때 처리할 함수
			on_session_begin_func,
			-- 세션이 종료될 때 처리할 함수
			on_session_finish_func
		))
	end
end

function local_class:on_session_begin(target)
	-- 이미 해제된 상태라면 생략함
	if not self.cs_controller then return end
	-- 받는 회복력 저하 디버프 부여
	buff_manager:AddBuff(target, CS.Oak.EquipmentSlot.None, target, self.debuff_name, self.debuff_level, false, false)
end

function local_class:on_session_finish(target)
	-- 이미 해제된 상태라면 생략함
	if not self.cs_controller then return end
	-- 받는 회복력 저하 디버프 해제
	buff_manager:RemoveBuff(target, CS.Oak.EquipmentSlot.None, target, self.debuff_name)
end

function local_class:dispose()
	self.cs_controller = nil

	-- 세션 핼퍼 순회하면서 해제한다.
	for _ = #self.battle_session_helpers, 1, -1 do
		local session_helper = table.remove(self.battle_session_helpers)
		session_helper:Dispose()
	end
end

return local_class
