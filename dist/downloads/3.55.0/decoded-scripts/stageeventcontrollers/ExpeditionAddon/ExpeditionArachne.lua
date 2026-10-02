local local_class = newclass('ExpeditionArachneController')


function local_class:on_load_resource_routine(param_table)

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.global_key = 'conquest_screenplay'

	-- 타겟될 몬스터 찾아서 세트 해야 함.
	local bosses = stage:GetBossCharacters()
	for i = 0, bosses.Count - 1 do
		if bosses[i].CharacterStatsBehaviour.FieldObjectSpec.Id == param_table.boss_id then
			self.boss = get_character(bosses[i].Name)
			break
		end
	end

	-- 보스 정보 없으면 찾아진 보스중 첫번째를 타겟으로 지정함
	if self.boss == nil then
		self.boss = bosses[0]
	end

	self.fall_angle = param_table.fall_angle
	self.fall_distance = param_table.fall_distance
	self.fall_speed = param_table.fall_speed
	self.howl_offset = unity_class.vector3(0, param_table.howl_y_offset, 0)
	-- 연출에 사용할 이펙트
	--self.fx_dash_pool = unity_object_pool.GetOrCreate('fx_balock_prison_dash')
	self.fx_land_pool = unity_object_pool.GetOrCreate('fx_boss_arachne_stomp_dust')
	self.fx_howling_pool = unity_object_pool.GetOrCreate('fx_boss_arachne_phaseshift_howling')

	-- 사운드 미리 로드
	self.sfx_pre_howling = '01_creature_13'
	music_player:PreloadSfx(self.sfx_pre_howling)

	self.sfx_jump = '02_boss_rush_01'
	music_player:PreloadSfx(self.sfx_jump)

	self.sfx_smash = '02_druid_stomp_03'
	music_player:PreloadSfx(self.sfx_smash)

	self.sfx_post_howling = '01_creature_14'
	music_player:PreloadSfx(self.sfx_post_howling)
end

-- fade in 전 연출 시작
function local_class:pre_launch_routine()
	self.boss.Position = unity_class.vector3(999, 0, 999)
end

-- 연출
function local_class:on_launch_routine()
	-- spawn_1 field:GetMarker 위치로 대각선 낙하 0.8초
	-- 낙하시 근처의 적에게 넉백
	-- 낙하시점 바닥깨지는 이펙트

	-- 보스 위치 세팅
	local land_marker = field:GetMarker('spawn_1')
	character_util.set_locked_dir(self.boss, 'left')
	local rot = unity_class.quaternion.AngleAxis(self.fall_angle, unity_class.vector3.back).normalized
	local s_dir = rot * unity_class.vector3.up
	--s_dir = vector_util.get_x0z(s_dir, 0)
	self.fall_start_pos = land_marker.position + self.fall_distance * s_dir
	self.fall_direction = (land_marker.position - self.fall_start_pos).normalized
	-- 돌진 이펙트
	self.boss.Position = self.fall_start_pos

	self.boss.ActiveState = CS.Oak.ActiveState.Visible

	character_util.set_anim(self.boss, {name = "appear", loop = true})
	-- 카메라 쉐이크 0.8초
	camera_util.shake(0.25, 0.8)
	-- 소리지르는 사운드
	music_player_util.play_sfx({ sfx_name = self.sfx_pre_howling })
	-- 카메라 쉐이크 대기
	wait_for_sec(0.8)

	local move_end = false
	local is_atk_anim = false

	local mid_pos = vector_util.lerp(land_marker.position, self.boss.Position, 0.5)
	local waypoint_count = 2
	local end_cb = function (waypoint_index)
		--if not is_atk_anim then
		--	-- 중간쯤 부터 공격 모션으로 전환
		--	character_util.set_anim(self.boss, {name = "meteo_attack", loop = false, scale = 1})
		--	is_atk_anim = true
		--end
		if waypoint_index == waypoint_count -1 then
			move_end = waypoint_count == waypoint_index + 1
		end
	end
	local sfx_jump = music_player_util.play_sfx({ sfx_name = self.sfx_jump })
	-- 오는길에 대한 웨이포인트를 두군데로 설정 하여 첫번째 웨이포인트에 갔을때 애니메이션 변경..
	character_util.move_waypoint(self.boss, { mid_pos, land_marker.position }, self.fall_speed,
			true, 'stop', 'flying', 'left', false, 0, end_cb)

	while (not move_end and self.boss.FieldObjectBehaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped) do
		coroutine.yield(nil)
	end

	sfx_jump:FadeOut()
	-- 일정시간 이후 랜드 포지션에..
	self.boss.Position = land_marker.position


	-- 착지 이펙트 실행
	object_pool_extensions.Instantiate(self.fx_land_pool, self.boss.Position)
	music_player_util.play_sfx({ sfx_name = self.sfx_smash, position = self.boss.Position })
	-- 내려와서 진동
	camera_util.shake(0.25, 0.5)
	self:knockback()
	wait_for_sec(0.6)

	character_util.remove_anim(self.boss)

	wait_for_sec(0.2)

	-- 위치 바꾸고 고함
	character_util.set_locked_dir(self.boss, 'down')
	character_util.set_anim(self.boss, {name = "howling", loop = false, scale = 1})
	object_pool_extensions.Instantiate(self.fx_howling_pool, self.boss.Bounds.center + vector(0, -1.25, 0))
	music_player_util.play_sfx({ sfx_name = self.sfx_post_howling, position = self.boss.Position })

	camera_util.shake(0.3, 1.5)
	-- 고함치는 모션 대기
	wait_for_sec(2)
	-- 뒷정리
	character_util.set_anim(self.boss, {name = "idle", loop = true, scale = 1})

	wait_for_sec(0.2)
end

-- 전투 시작 전 정리
function local_class:post_launch_routine()
	-- 보스 나머지 사항 복구
	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CharacterStats, self.boss)
	message_system:SendSync(self.boss, CS.Oak.StateResetEvent.Instance)

	character_util.remove_anim(self.boss)
	character_util.set_locked_dir(self.boss, 'none')
end

-- 보스 착지시 주변 플레이어에 넉백
function local_class:knockback()
	-- 주변 플레이어에게 넉백을 주되, 데미지는 없는것으로
	local objects = field:GetFieldObjectsInCylinder(self.boss.Bounds.center, 4, 3.5)
	for index = 0, objects.Count - 1 do
		local fo = objects.Values[index]
		-- 타격 가능한 대상 인지 확인
		if self:is_hittable_to(self.boss, fo) then
			local direction = vector_util.get_x0z(fo.Position - self.boss.Bounds.center).normalized
			local knock_direction = direction
			if direction:IsAlmostZero() then
				knock_direction = -direction_util.to_vector3(character_util.get_look_direction(fo))
			end
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Melee
			damage_info.sender = self.boss
			damage_info.target = fo
			damage_info.direction = direction
			damage_info.stunFactor = CS.Oak.DamageStunConstants.FactorStrong
			damage_info.stunDuration = 0.2
			damage_info.knockBackFactor = CS.Oak.DamageKnockBackConstants.FactorStrong
			damage_info.knockBackDirection = knock_direction
			damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce * 1.2
			local cmd = CS.Oak.DamageCommand.Create(damage_info)
			command_util.publish_cmd(damage_info.Owner, cmd)
		end
	end
	objects:Dispose()
end

function local_class:is_hittable_to(attacker, target)
	if is_unity_null(target) then
		return false
	end

	if target.FieldObjectStatsBehaviour.IsDead then
		return false
	end

	if lua_helper.reference_equals(attacker, target) then
		return false
	end

	return CS.Oak.EntityGroupsExtensions.IsHittableTo(attacker.EntityGroup, target.EntityGroup)
end

function local_class:on_custom_stage_event(e)
	if not lua_helper.reference_equals(e.Sender, self.boss) then
		return false
	end


	return false
end

--
function local_class:on_stage_end()

end

-- 호출 시점, 이펙트 붙인것 등을 제거해준다.
function local_class:on_dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.boss = nil

	self.fx_dash_pool = nil
	self.fx_land_pool = nil

end

return {
	create = function()
		return local_class()
	end
}
