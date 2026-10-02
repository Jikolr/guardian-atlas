return {
	--[[
		@ boss_name : 보스의 이름
		@ buff_spec_name : 걸어줄 버프의 스펙 이름
		@ buff_level : 걸어줄 버프 레벨, heal시에는
		@ show_effect : 버프 이펙트를 보여줄 것인지 (default = false)
		@ show_text : 버프 텍스트를 보여줄 것인지 (default = false)
		@ only_party_leader : 버프를 파티 리더에게만 걸어줄 지 (default = false)
		@ slot : 버프를 거는 주체의 장비에 의해 버프가 걸린 경우 slot 값을 지정 / default = CS.Oak.EquipmentSlot.None
		@ buff_cooltime : 주기적으로 버프를 재생성할 시, 쿨타임 (default = 5)
		@ effect = {
				--걸어주는 버프의 이펙트 정보 구조체
				name = 이펙트 이름,
				height_offset = 높이 오프셋
				init_dir = 이펙트가 생성될 시 위치할 초기 방향 (x, y, z)
				scale = 이펙트의 크기 (x, y, z)
			}
	]]
	-- heal : 1회성 힐
	-- periodical_heal : n초에 한번씩 힐.
	-- scale_up : 캐릭터 스케일 조정
	tower_earth_20 = {
		{
			boss_name = 'boss_battle1',
			slot = CS.Oak.EquipmentSlot.None,
			buff_spec_name = 'periodical_heal',
			buff_level = 0.1,
			heal_cooltime = 5,
			only_party_leader = false,
			show_effect = true,
			show_text = true,
			effect = {
				name = 'FX_heal_a',
				rotated = false,
				height_offset = 0.4,
				init_dir = { x = 0, y = 0, z = 0},
				scale = { x = 1, y = 1, z = 1 }
			}
		},
		{
			boss_name = 'boss_battle2',
			slot = CS.Oak.EquipmentSlot.None,
			buff_spec_name = 'attack_up_permill_persistent',
			buff_level = 200,
			only_party_leader = false,
			show_effect = false,
			show_text =  true,
		},
		{
			boss_name = 'boss_battle2',
			slot = CS.Oak.EquipmentSlot.None,
			buff_spec_name = 'defense_up_permill_persistent',
			buff_level = 200,
			only_party_leader = false,
			show_effect = false,
			show_text =  true,
			effect = {
				name = 'FX_levelup_new',
				rotated = false,
				height_offset = 0,
				init_dir = { x = 0, y = 0, z = 0},
				scale = { x = 1, y = 1, z = 1 }
			}
		},
		{
			boss_name = 'boss_battle2',
			slot = CS.Oak.EquipmentSlot.None,
			buff_spec_name = 'hp_up_permill_persistent',
			buff_level = 200,
			only_party_leader = false,
			show_effect = false,
			show_text =  false,
			effect = {
				name = 'scale_up',
				scale = { x = 1.3, y = 1.3, z = 1.3},
			}
		},
		{
			boss_name = 'boss_battle3',
			slot = CS.Oak.EquipmentSlot.None,
			buff_spec_name = 'elite_melee_damage_immune', -- melee_defense_up_permill_persistent
			buff_level = 1,
			only_party_leader = false,
			show_effect = false,
			show_text =  false,
			effect = {
				name = 'FX_Abnormal_Immune_Physic',
				height_offset = 0.4,
				rotated = false,
				init_dir = { x = 0, y = 0, z = 0},
				scale = { x = 1, y = 1, z = 1 }
			}
		},
		{
			boss_name = 'boss_battle4',
			slot = CS.Oak.EquipmentSlot.None,
			buff_spec_name = 'elite_projectile_damage_immune', -- projectile_defense_up_permill_persistent
			buff_level = 1,
			only_party_leader = false,
			show_effect = false,
			show_text =  false,
			effect = {
				name = 'FX_Abnormal_Immune_Physic_yellow',
				height_offset = 0.4,
				rotated = false,
				init_dir = { x = 0, y = 0, z = 0},
				scale = { x = 1, y = 1, z = 1 }
			}
		}
	}
}
