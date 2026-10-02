return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- boss_buff_name : 보스에게 부여할 버프 이름
	-- boss_buff_vfx : 보스에게 버프가 부여된 동안 붙일 이펙트
	-- boss_name : 무적 버프를 받는 보스 이름
	-- boss_group_name : 보스 그룹 이름
	-- battle_group_name : 웨이브 배틀 그룹 이름
	-- share_area_radius : 다른 몬스터에게 버프를 부여할 최대 거리
	-- share_buff_name : 다른 몬스터에게 부여할 버프 이름
	-- share_buff_vfx : 이 스테이지 컨트롤러에서 부여한 버프가 유지 되는 동안 붙일 이펙트
	-- share_range_vfx : 보스에게 버프가 부여된 동안 붙일 범위표시용 이펙트
	-- share_range_end_vfx : 보스에게 부여된 버프가 해제된 순간 표시할 이펙트
	-- wave_interval : 웨이브 생성 간격
	-- wave_start_delay : 첫 웨이브 딜레이 이후 활성화 여부
	]] --
	tower_ice_50 = {
		boss_buff_name = 'persistent_no_damage',
		boss_buff_vfx = 'fx_abnormal_immune_all',
		boss_name = 'boss_invader_terrorist_tower.ice',
		boss_group_name = 'boss',
		battle_group_name = 'wave',
		share_area_radius = 3.5,
		share_buff_name = 'persistent_no_damage',
		share_buff_vfx = 'fx_abnormal_immune_all',
		share_range_vfx = 'fx_abnormal_immune_generator_range',
		share_range_end_vfx = 'fx_abnormal_immune_generator_range_end',
		wave_interval = 9,
		wave_start_immediate = false
	}
}
