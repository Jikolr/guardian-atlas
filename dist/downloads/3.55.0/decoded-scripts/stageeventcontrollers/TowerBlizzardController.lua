local local_class = newclass('TowerBlizzardController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- boss_name : 무적 버프를 받는 보스 이름
	-- hp_list : 보스 무적버프 부여할 hp구간
	-- last_wave_index : 웨이브 수
	]]--
	self.stage_battle_info = {
		tower_earth_43 = {
			blizzard_zone_name = 'blizzard_start_event',
			campfire_object_names = {'campfire_1',
									'campfire_4',
									'campfire_5'},
			monster_kill_heal_scale = 0.1,
			campfire_heal_range = 3,
			campfire_heal_scale = 0.1,
			campfire_heal_term = 0.5,
			blizzard_damage_scale = 0.03,
			blizzard_damage_term = 1,
		}
	}

	-- 사용할 프리셋
	self.preset = { blizzard = nil, blizzard_fade = nil }

	-- 생성된 눈보라 이펙트
	self.blizzard = {
		-- 풀링된 이펙트
		obj = nil,
		-- 이펙트 material
		material = nil,
		-- material color
		color = nil
	}

	-- 생성된 페이드 이펙트
	self.fade = {
		-- 풀링된 이펙트
		obj = nil,
		-- particle system main module
		main_module = nil,
		--
		color = nil,
		--
		gradient = nil
	}

	-- preset property name
	self.property_name = '_TintColor'

	self.is_blizzard_active = false

	-- 눈보라 대미지, 캠프파이어 힐 데이터
	-- scale: 최대 체력 * scale
	-- duration: 주기

	-- 눈보라 틴트 강도
	self.blizzard_tint = 0.1

	-- 카메라 패닝 스피드
	self.panning_speed = 9

	self.blizzard_progress_enum = {
		-- 초기 상태
		none = 0,
		-- 눈보라 이벤트 상태
		start_blizzard = 1,
		-- 눈보라 이벤트를 클리어 했거나 실패한 상태
		clear_or_fail = 2
	}

	-- 플레이어가 캠프파이어 주변(힐 존)에 있는지
	self.in_heal_zone = false
	self.heal_object_pos_list = {}
	self.campfire_heal_delay = 0
	self.blizzard_current_progress = self.blizzard_progress_enum.none
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	self.preset.blizzard = unity_object_pool.GetOrCreate('FX_Blizzard')
	self.preset.blizzard_fade = unity_object_pool.GetOrCreate('FX_Screen_Blizzard_Cloud')
	self.fade.gradient = CS.UnityEngine.ParticleSystem.MinMaxGradient(unity_class.color.black)

	for _,v in pairs(self.current_stage_info.campfire_object_names) do
		local o = get_field_object(v)
		table.insert(self.heal_object_pos_list, o.Position)
	end
	return
end

function local_class:start_blizzard()
	if self.blizzard_current_progress ~= self.blizzard_progress_enum.start_blizzard then
		self.blizzard_current_progress = self.blizzard_progress_enum.start_blizzard
	else
		return
	end

	self.blizzard_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true, fade_in_time = 2 })
	self:blizzard_lerp(0, self.blizzard_tint, 0)

	-- 대미지 정보
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.DotDamage | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Passive
	damage_info.sender = user_party_leader
	damage_info.target = user_party_leader
	damage_info.direction = unity_class.vector3.zero
	damage_info.noCritical = true
	damage_info.damage = unity_class.mathf.Floor(user_party_leader.FieldObjectStatsBehaviour.MaxHP
			* self.current_stage_info.blizzard_damage_scale)

	local time_passed = 0

	while self.blizzard_current_progress == self.blizzard_progress_enum.start_blizzard do
		if time_passed > self.current_stage_info.blizzard_damage_term and not self.in_heal_zone then
			command_util.execute_damage(damage_info)
			time_passed = 0
		else
			time_passed = time_passed + unity_class.time.deltaTime
		end

		coroutine.yield(nil)
	end
end

function local_class:end_blizzard()
	self.blizzard_sfx:FadeOut(2)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.blizzard_lerp, self, self.blizzard_tint, 0, 0.5))
	self.blizzard_current_progress = self.blizzard_progress_enum.clear_or_fail
	--self:blizzard_dispose()
end

function local_class:excute_monster_kill_heal()
	-- 힐 정보
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = user_party_leader
	heal_info.target = user_party_leader
	heal_info.heal = math.floor(user_party_leader.CharacterStatsBehaviour.MaxHP
			* self.current_stage_info.monster_kill_heal_scale)

	music_player:PlaySfxOneShot('02_magic_heal_01')
	command_util.execute_heal(heal_info)
end

function local_class:excute_campfire_heal()
	-- 힐 정보
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = user_party_leader
	heal_info.target = user_party_leader
	heal_info.heal = math.floor(user_party_leader.CharacterStatsBehaviour.MaxHP
			* self.current_stage_info.campfire_heal_scale)

	music_player:PlaySfxOneShot('02_magic_heal_01')
	command_util.execute_heal(heal_info)
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.current_stage_info.blizzard_zone_name) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_blizzard, self))
		self.current_progress = self.progress.playing
	end
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party_leader, self.current_stage_info.blizzard_zone_name) then
		self:end_blizzard()
		self.current_progress = self.progress.current_progress
	end
	--눈보라가 끝나는 존이 있다면 눈보라를 꺼준다
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_progress ~= self.progress.playing then return end

	--아군일 경우 패스
	if not CS.Oak.EntityGroupsExtensions.IsHittableTo(user_party_leader.EntityGroup, e.FieldObject.EntityGroup) then
		return false
	end

	--적을 처치했을 경우 힐
	self:excute_monster_kill_heal()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_battle_group_wave_clear_event(e)
	return true
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return end

	--반경 안에 캠프파이어가 있는지 체크
	if self:check_campfire() then
		self.in_heal_zone = true
	else
		self.in_heal_zone = false
	end

	--캠프파이어 반경 안에있을 경우 회복
	if self.in_heal_zone then
		if self.campfire_heal_delay <= 0 then
			self:excute_campfire_heal()
			self.campfire_heal_delay = self.current_stage_info.campfire_heal_term
		else
			self.campfire_heal_delay = self.campfire_heal_delay - dt
		end
	end
end

function local_class:check_campfire()
	for _,v in pairs(self.heal_object_pos_list) do
		local distance = math.abs(vector_util.get_x0z(user_party_leader.Position - v).magnitude)
		if distance < self.current_stage_info.campfire_heal_range then
			return true
		end
	end

	return false
end

--- 눈보라 강도 조절
function local_class:blizzard_lerp(from, to, duration)
	if not self.is_blizzard_active then
		--- flag set
		self.is_blizzard_active = true

		--- blizzard set up
		self:blizzard_set_up()
	end

	--- blizzard inner param refresh
	self:blizzard_color_refresh()

	local time_passed = 0

	--- blizzard update
	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = unity_class.mathf.Max(time_passed / duration, 0)
		local cur_tint = unity_class.mathf.Lerp(from, to, progress)

		self:blizzard_update(cur_tint)

		coroutine.yield(nil)
	end
end

--- blizzard 이펙트 셋업
function local_class:blizzard_set_up(args)
	if self.blizzard == nil or self.fade == nil then return end
	if self.blizzard.obj ~= nil or self.fade.obj ~= nil then return end

	local with_fade = lua_helper.get_value(args, 'with_fade', true)
	local alpha = lua_helper.get_value(args, 'alpha', -1)
	local custom_alpha = false

	if not float_util.almost_close_to(alpha, -1) then
		custom_alpha = true
	end

	local camera = stage_camera

	self.blizzard.obj = self.preset.blizzard:Instantiate(
			camera.Transform.position + vector(0, 5, 10), unity_class.quaternion.identity, camera.Transform)
	self.blizzard.material = self.blizzard.obj.transform:GetComponentInChildren(
			typeof(CS.UnityEngine.Renderer)).material

	self.blizzard.color = self.blizzard.material:GetColor(self.property_name)

	local target_alpha = custom_alpha and alpha or self.blizzard.color.a * 0.2

	self.blizzard.material:SetColor(self.property_name, unity_color(
			{ self.blizzard.color.r, self.blizzard.color.g, self.blizzard.color.b, target_alpha }))

	if with_fade then
		self.fade.obj = self.preset.blizzard_fade:Instantiate(
				camera.Transform.position, unity_class.quaternion.identity, camera.Transform)
		self.fade.main_module = self.fade.obj.transform:GetComponentInChildren(
				typeof(CS.UnityEngine.ParticleSystem)).main
		self.fade.color = self.fade.main_module.startColor.color

		target_alpha = custom_alpha and alpha or self.fade.color.a * 0.2

		self.fade.gradient.color = unity_color(
				{ self.fade.color.r, self.fade.color.g, self.fade.color.b, target_alpha })

		self.fade.main_module.startColor = self.fade.gradient
		self.fade.color = self.fade.main_module.startColor.color
	end
end

function local_class:blizzard_update(alpha, fade_alpha)
	if fade_alpha == nil then
		fade_alpha = alpha
	end

	self.blizzard.material:SetColor(self.property_name, unity_color(
			{ self.blizzard.color.r, self.blizzard.color.g, self.blizzard.color.b, alpha }))

	if self.fade.obj ~= nil then
		self.fade.gradient.color = unity_color(
				{ self.fade.color.r, self.fade.color.g, self.fade.color.b, fade_alpha })

		self.fade.main_module.startColor = self.fade.gradient
	end
end

function local_class:blizzard_color_refresh()
	self.blizzard.color = self.blizzard.material:GetColor(self.property_name)

	if self.fade.obj ~= nil then
		self.fade.color = self.fade.main_module.startColor.color
	end
end

--- 눈보라 관련 이펙트 dispose
function local_class:blizzard_dispose()
	if self.blizzard.obj ~= nil then
		self.blizzard.material = nil
		self.blizzard.color = nil
		self.blizzard.obj:Dispose()
		self.blizzard.obj = nil
	end

	if self.fade.obj ~= nil then
		self.fade.main_module = nil
		self.fade.color = nil
		self.fade.obj:Dispose()
		self.fade.obj = nil
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	if not is_unity_null(self.blizzard_sfx) then
		self.blizzard_sfx:FadeOut(2)
		self.blizzard_sfx = nil
	end

	self:blizzard_dispose()

	self.current_stage_info = nil
	self.cs_controller = nil
	self.blizzard_current_progress = nil
	self.current_progress = nil
	self.progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
