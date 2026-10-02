local local_class = newclass('ExpeditionIceDragon')

function local_class:on_load_resource_routine(params)
	self.global_key = 'conquest_screenplay'

	-- 타겟될 몬스터 찾아서 세트 해야 함.
	local bosses = stage:GetBossCharacters()
	for i = 0, bosses.Count - 1 do
		if bosses[i].CharacterStatsBehaviour.FieldObjectSpec.Id == params.boss_id then
			self.boss = get_character(bosses[i].Name)
			break
		end
	end

	-- 보스 정보 없으면 찾아진 보스중 첫번째를 타겟으로 지정함
	if self.boss == nil then
		self.boss = bosses[0]
	end

	self.howl_offset = unity_class.vector3(params.howl_x_offset, 0, params.howl_z_offset)
	self.breath_opffset = unity_class.vector3(params.breath_x_offset, 0, params.breath_z_offset)

	self.fx_howl_pool = unity_object_pool.GetOrCreate('fx_boss_icedragon_howl_start')
	self.fx_breath_pool = unity_object_pool.GetOrCreate('fx_boss_icedragon_breath')
	self.fx_wave_pool = unity_object_pool.GetOrCreate('fx_boss_icedragon_wave')

	self.stomp_camera_magnitude = params.stomp_camera_magnitude
	self.stomp_camera_duration = params.stomp_camera_duration

	self.howl_camera_magnitude = params.howl_camera_magnitude
	self.howl_camera_duration = params.howl_camera_duration

	self.knockback_force = params.knockback_force

	-- 사운드 미리 로드
	self.sfx_stomp = '02_atomic_stomp_01'
	music_player:PreloadSfx(self.sfx_stomp)

	self.sfx_howl = '01_creature_12'
	music_player:PreloadSfx(self.sfx_howl)
end

-- fade in 전 연출 시작
function local_class:pre_launch_routine()
	local spawn_marker = field:GetMarker('spawn_1')
	self.boss.Position = spawn_marker.position
	self.boss.Direction = CS.Oak.Direction.Left
	self.boss.ActiveState = CS.Oak.ActiveState.Visible
	character_util.set_locked_dir(self.boss, 'left')
	user_party:StopAndDisableControl()
end

-- 연출(총 2.833초)
function local_class:on_launch_routine()
	-- 보스 위치 세팅
	character_util.set_anim(self.boss, {name = "appear", loop = false, scale = 1})

	-- bone follower 생성
	local spine_controller = self.boss.SpineController
	self.follower = CS.UnityEngine.GameObject('IcedragonTongueFollower')
	self.bone_follower = self.follower:AddComponent(typeof(CS.Spine.Unity.BoneFollower))
	self.bone_follower.followBoneRotation = false
	self.bone_follower.SkeletonRenderer = spine_controller.SkeletonAnimation
	self.bone_follower:SetBone('tongue')

	-- 땅짚
	wait_for_sec(0.45)
	-- 땅짚 카메라 쉐이크
	camera_util.shake(self.stomp_camera_magnitude, self.stomp_camera_duration)
	music_player_util.play_sfx({ sfx_name = self.sfx_stomp })

	local wave_pos1 = self.boss.Position + unity_class.vector3(-0.76, 0, 3.2)
	local wave_pos2 = self.boss.Position + unity_class.vector3(-0.45, 0, -3.84)
	object_pool_extensions.Instantiate(self.fx_wave_pool, wave_pos1)
	object_pool_extensions.Instantiate(self.fx_wave_pool, wave_pos2)

	self:publish_knockback()

	-- 브레스, 하울
	wait_for_sec(0.95)
	-- 하울 이펙트 재생
	music_player_util.play_sfx({ sfx_name = self.sfx_howl })
	object_pool_extensions.Instantiate(self.fx_howl_pool, self.follower.transform.position, unity_class.vector3.zero, self.follower.transform)
	object_pool_extensions.Instantiate(self.fx_breath_pool, self.follower.transform.position, unity_class.vector3.zero, self.follower.transform)
	--self.fx_breath = object_pool_extensions.Instantiate(self.fx_breath_pool, self.follower.transform.position, unity_class.vector3.zero, self.follower.transform)

	-- 하울 카메라 쉐이크
	camera_util.shake(self.howl_camera_magnitude, self.howl_camera_duration)

	-- 브레스 종료
	wait_for_sec(1.25)

	-- appear 종료
	wait_for_sec(0.48)

	character_util.set_anim(self.boss, {name = "idle", loop = true, scale = 1})

	-- 서비스 시간(3초 채움)
	wait_for_sec(0.2)

	-- 본 팔로워 넘겨주자
	local breath_action = CS.Oak.LuaBattleExtensions.GetBattleActionByName(self.boss, 'BossIceDragonIceBreath')
	if breath_action ~= nil then
		breath_action.MetaTable:set_bone_follwer(self.follower)
	end
end

-- 전투 시작 전 정리
function local_class:post_launch_routine()
	-- 보스 나머지 사항 복구
	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CharacterStats, self.boss)
	message_system:SendSync(self.boss, CS.Oak.StateResetEvent.Instance)

	character_util.remove_anim(self.boss)
	character_util.set_locked_dir(self.boss, 'left')

	user_party:ResetControllers()
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

function local_class:on_stage_end()

end

function local_class:publish_knockback()
	--party_manager.UserParty
	--
	--for _, v in pairs(user_party) do
	--	if not character_util.is_dead(v) then
	--		local damage_info = CS.Oak.DamageInfo()
	--		damage_info.sender = self.character
	--		damage_info.target = v
	--		damage_info.knockBackFactor = CS.Oak.DamageKnockBackConstants.FactorStrong
	--		damage_info.knockBackDirection = direction_util.to_vector3(self.character.Direction)
	--		local force = self.shield_count > 0 and self.knockback_force2 or self.knockback_force
	--		damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce * force
	--		command_util.publish_damage(damage_info)
	--	end
	--end
end

-- 호출 시점, 이펙트 붙인것 등을 제거해준다.
function local_class:on_dispose()
	self.boss = nil
	--self.fx_dash_pool = nil
	--self.fx_land_pool = nil
end

return {
	create = function()
		return local_class()
	end
}
