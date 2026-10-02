return {
	-- 스테이지명 기반으로 돌아갑니다

	-- DayDuration : 낮 지속시간
	-- NightDuration : 밤 지속시간
	-- OnHitTimePenalty : 낮 지속 중 리더 캐릭터 피격시 더해질 시간 페널티

	-- HealInterval : BOSS_A 에게 들어갈 힐 인터벌
	-- HealRatio : 힐이 최대체력기반 몇 % 인지

	-- AtkBuffId : BOSS_B 에게 들어갈 공격력 버프 ID
	-- AtkBuffLv : BOSS_B 에게 들어갈 공격력 버프 Level (Level * 0.001)
	-- DefBuffId : BOSS_B 에게 들어갈 방어력 버프 ID
	-- DefBuffId : BOSS_B 에게 들어갈 방어력 버프 Level (Level * 0.001)

	-- TintColor : 레버를 당겼을때 스테이지 틴트 색상(다시 누르면 원복)
	-- TintColor 초기값 : 0, 255, 0, 255

	tower_darkness_55 = {
		NarrationKey = 'tower_darkness_boss_7_narration',

		DayDuration = 12,
		NightDuration = 7,
		OnHitTimePenalty = 2,

		HealInterval = 4,
		HealRatio_A = 0.07,
		HealRatio_B = 0.035,

		AtkBuffId_A = 'attack_up_permill_persistent',
		AtkBuffLv_A = 850,
		DefBuffId_A = 'defense_up_permill_persistent',
		DefBuffLv_A = 450,
		AtkBuffId_B = 'attack_up_permill_persistent',
		AtkBuffLv_B = 400,
		DefBuffId_B = 'defense_up_permill_persistent',
		DefBuffLv_B = 900,

		TintColor = { 0, 182, 0, 182 },
	},
}