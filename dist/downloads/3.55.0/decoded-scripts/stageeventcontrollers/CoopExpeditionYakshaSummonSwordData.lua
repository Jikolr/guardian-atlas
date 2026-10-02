return {
	co_exp_stage_2_4 = {
		not_destroyed_park_groggy = '10', --검이 파괴되지 않고 파킹될 때 그로기 수치
		destroyed_park_groggy = '35', --검을 파괴했을 때 그로기 수치
		summon_sword_shield = 2500000, --검 소환 시 쉴드량
		coop_class_priority = { -- 검 소환 우선순위 ( 위에서부터 높은 순서대로 )
			CS.Oak.CoopExpeditionClass.Dealer,
			CS.Oak.CoopExpeditionClass.Healer,
			CS.Oak.CoopExpeditionClass.Tanker,
		}
	},
	co_exp_stage_2_4_hard = {
		not_destroyed_park_groggy = '10', --검이 파괴되지 않고 파킹될 때 그로기 수치
		destroyed_park_groggy = '20', --검을 파괴했을 때 그로기 수치
		summon_sword_shield = 6500000,
		coop_class_priority = {
			CS.Oak.CoopExpeditionClass.Dealer,
			CS.Oak.CoopExpeditionClass.Healer,
			CS.Oak.CoopExpeditionClass.Tanker,
		}
	},
	co_exp_stage_2_4_super_hard = {
		not_destroyed_park_groggy = '10', --검이 파괴되지 않고 파킹될 때 그로기 수치
		destroyed_park_groggy = '20', --검을 파괴했을 때 그로기 수치
		summon_sword_shield = 8840000, -- 6500000(hard 난이도 쉴드 양) * 1.36배(항마력 0과 4의 데미지 감소율 기반으로 계산된 값)
		coop_class_priority = {
			CS.Oak.CoopExpeditionClass.Dealer,
			CS.Oak.CoopExpeditionClass.Healer,
			CS.Oak.CoopExpeditionClass.Tanker,
		}
	}	
}
