local local_class = newclass('TowerBlizzardCampfireController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 전체 스테이지에 대한 플레이 상태
	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- boss_name : 보스 이름
	-- blizzard_zone_name : 눈보라 효과를 적용할 이벤트 존 이름
	-- campfire_object_names : 맵에 배치된 캠프파이어 기믹 핸들네임 리스트
	-- monster_kill_heal_scale : 몬스터 처치 시 힐량 비율
	-- campfire_heal_range : 캠프파이어 힐 범위 반지름
	-- campifre_heal_scale : 캠프파이어 힐 틱당 힐량 비율
	-- campfire_heal_term : 캠프파이어 힐 틱 간격
	-- campfire_cool_time : 캠프파이어 꺼진 후 다시 켜지지 않는 시간
	-- campfire_burn_duration : 캠프파이어 켜진 후 지속 시간
	-- blizzard_damage_scale : 눈보라 틱당 데미지 비율
	-- blizzard_damage_term : 눈보라 틱 간격
	]]--
	self.stage_battle_info = {
		tower_ice_55 = {
			boss_name = 'snowman_general',
			blizzard_zone_names ={
				'blizzard_start_event',
				'boss'
			},
			always_on_campfire = {
				'campfire_0',
			},
			campfire_object_names = {
				 'campfire_1',
				 'campfire_2'
			},
			monster_kill_heal_scale = 0.1,
			campfire_heal_range = 3.5,
			campfire_heal_scale = 0.075,
			campfire_heal_term = 0.5,
			campfire_cool_time = 2,
			campfire_burn_duration = 10,
			blizzard_damage_scale = 0.18,
			blizzard_damage_term = 4,
		},
		herotower_store_angel_3 = {
			boss_name = 'battle_3_key',
			blizzard_zone_names ={
				'blizzard_battle_1',
				'blizzard_battle_2',
				'blizzard_battle_3'
			},
			always_on_campfire = {},
			campfire_object_names = {
				 'campfire_1',
				 'campfire_2',
				 'campfire_3'
			},
			monster_kill_heal_scale = 0,
			campfire_heal_range = 2.5,
			campfire_heal_scale = 0.09,
			campfire_heal_term = 0.35,
			campfire_cool_time = 2,
			campfire_burn_duration = 999999999,
			blizzard_damage_scale = 0.03,
			blizzard_damage_term = 0.5,
		},
		herotower_adela_noble_4 = {
			boss_name = 'battle_3_key',
			blizzard_zone_names ={
				'battle1',
				'battle2',
				'battle3'
			},
			always_on_campfire = {},
			campfire_object_names = {
			},
			monster_kill_heal_scale = 0,
			campfire_heal_range = 1,
			campfire_heal_scale = 0,
			campfire_heal_term = 0,
			campfire_cool_time = 10,
			campfire_burn_duration = 0,
			blizzard_damage_scale = 0.05,
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

	-- 눈보라 대미지, 캠프파이어 힐 데이터
	-- scale: 최대 체력 * scale
	-- duration: 주기

	-- 눈보라 틴트 강도
	self.blizzard_tint = 0.1

	-- 카메라 패닝 스피드
	self.panning_speed = 9

	self.blizzard_progress = {
		-- 초기 상태
		none = 0,
		-- 눈보라 이벤트 상태
		start = 1,
		-- 중지 중
		suspended = 2,
		-- 눈보라 이벤트를 클리어 했거나 실패한 상태
		clear_or_fail = 3
	}

	self.campfire_object_list = {}
	-- 항상 켜져있는 캠프파이어 리스트
	self.always_on_campfire_list = {}
	self.campfire_heal_delay = 0
	self.blizzard_current_progress = self.blizzard_progress.none
	self.current_progress = self.progress.none
	self.time_passed = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BurnEvent), 'on_burn_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	self.boss = get_character(self.current_stage_info.boss_name)

	self.preset.blizzard = unity_object_pool.GetOrCreate('FX_Blizzard')
	self.preset.blizzard_fade = unity_object_pool.GetOrCreate('FX_Screen_Blizzard_Cloud')
	self.fade.gradient = CS.UnityEngine.ParticleSystem.MinMaxGradient(unity_class.color.black)

	for _,v in pairs(self.current_stage_info.campfire_object_names) do
		local o = get_field_object(v)
		if lua_helper.type_compare(o.CombustibleBehaviour, CS.Oak.CampfireCombustibleBehaviour) then
			o.Owner = CS.Oak.Player.Local
			o.EntityGroup = CS.Oak.EntityGroups.Player0
			o.CombustibleBehaviour.BurnLifeTime = 0
			table.insert(self.campfire_object_list, { fo = o, last_extinguish_time = 0, last_burn_time = 0 })
		end
	end

	for _,v in pairs(self.current_stage_info.always_on_campfire) do
		local o = get_field_object(v)
		if lua_helper.type_compare(o.CombustibleBehaviour, CS.Oak.CampfireCombustibleBehaviour) then
			o.Owner = CS.Oak.Player.Local
			o.EntityGroup = CS.Oak.EntityGroups.Player0
			-- 처음부터 타고 있는 상태인지
			o.CombustibleBehaviour.FireOnStart = true
			-- 계속 타고 있는 상태로 설정
			o.CombustibleBehaviour.BurnLifeTime = 0
			table.insert(self.always_on_campfire_list, o)
		end
	end

	return
end

function local_class:start_blizzard()
	-- 눈보라 플레이 중에는 다시 시작 되지 않음.
	if self.blizzard_current_progress == self.blizzard_progress.start then return end
	if self.blizzard_current_progress == self.blizzard_progress.clear_or_fail then return end

	-- 블리자드 시작되지 않았다면 시작 시킴.
	self.blizzard_current_progress = self.blizzard_progress.start
	self.blizzard_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true, fade_in_time = 2 })
	-- lerp 값 초기화
	self:init_blizzard()
	--self:blizzard_update_alpha(self.blizzard_tint)
	-- 블리자드 시간 초기화
	self.blizzard_time_passed = 0
end

function local_class:update_blizzard(dt)
	-- 시작되지 않았다면 리턴
	if self.blizzard_current_progress ~= self.blizzard_progress.start then return end
	if self:check_campfire() then return end
	if self:check_always_on_campfire() then return end
	self.blizzard_time_passed = self.blizzard_time_passed + dt

	if self.blizzard_time_passed > self.current_stage_info.blizzard_damage_term then
		self:damage_user_party()
	end
end

function local_class:end_blizzard()
	-- 중복 종료되지 않음.
	self.blizzard_sfx:FadeOut(2)
	-- 컬러 변경 시간 체크
	self.blizzard_fade_out_time_passed = 0
	self.blizzard_fade_out_duration = 0.5
	self.blizzard_fade_out_target_value = 0

	-- 동작중 들어온거라면 suspended 처리
	if self.blizzard_current_progress == self.blizzard_progress.start then
		-- 존에서 나가면 suspended 시킴.
		self.blizzard_current_progress = self.blizzard_progress.suspended
	end
end

function local_class:damage_user_party()
	for i = 0, user_party.Count - 1 do
		local character = user_party[i]

		-- 대미지 정보
		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.DotDamage | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Passive
		damage_info.sender = character
		damage_info.target = character
		damage_info.direction = unity_class.vector3.zero
		damage_info.noCritical = true
		damage_info.damage = unity_class.mathf.Floor(character.FieldObjectStatsBehaviour.MaxHP
				* self.current_stage_info.blizzard_damage_scale)
		command_util.execute_damage(damage_info)
	end
	-- 데미지 주었다면 시간 초기화
	self.blizzard_time_passed = 0
end

function local_class:execute_campfire_heal()
	for i = 0, user_party.Count - 1 do
		local character = user_party[i]

		-- 힐 정보
		local heal_info = CS.Oak.HealInfo()
		heal_info.sender = character
		heal_info.target = character
		heal_info.heal = math.floor(character.CharacterStatsBehaviour.MaxHP
				* self.current_stage_info.campfire_heal_scale)

		music_player:PlaySfxOneShot('02_magic_heal_01')
		command_util.execute_heal(heal_info)
	end
end

function local_class:on_zone_enter_event(e) -- 벽에 대고 달릴 때도 나갔다가 들어오게 됨
	-- 현재 스테이지 진행도가 cleared 이면 존에 다시 들어와도 동작하지 않음.
	for i = 1, #self.current_stage_info.blizzard_zone_names do
		if type_util.is_zone_full_enter(e, user_party.Leader, self.current_stage_info.blizzard_zone_names[i]) and
				self.blizzard_current_progress ~= self.blizzard_progress.start and
				self.current_progress ~= self.progress.cleared then -- 스테이지 클리어되지 않음.

			-- 플레이 시작됨 : 재시작 때는 변경하지 않음.
			if self.current_progress == self.progress.none then
				self.current_progress = self.progress.playing
				self.time_passed = 0
			end

			-- 블리자드 시작
			self:start_blizzard()
		end
	end
end

function local_class:on_zone_leave_event(e)
	for i = 1, #self.current_stage_info.blizzard_zone_names do
		if type_util.is_zone_full_leave(e, user_party.Leader, self.current_stage_info.blizzard_zone_names[i]) and
				self.blizzard_current_progress == self.blizzard_progress.start then -- 블리자드가 동작중인 경우에만 중지루틴 탐
			-- 현재 스테이지의 플레이 상태는 변경 하지 않음.
			self:end_blizzard()
		end
	end
	--눈보라가 끝나는 존이 있다면 눈보라를 꺼준다
end

function local_class:on_damage_event(e)
	if lua_helper.reference_equals(e.Info.sender, self.boss) then
		for _,v in pairs(self.campfire_object_list) do
			if lua_helper.reference_equals(e.Info.target, v.fo) and v.fo.CombustibleBehaviour.IsBurning then
				self:extinguish_fire(v)
				return true
			end
		end
	end
	return false
end

function local_class:on_burn_event(e)
	for _,v in pairs(self.campfire_object_list) do
		if lua_helper.reference_equals(e.Target, v.fo) then
			v.last_burn_time = self.time_passed
			return true
		end
	end
	return false
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_progress == self.progress.playing then
		-- 보스의 사망 시
		if lua_helper.reference_equals(e.FieldObject, self.boss) then
			self.current_progress = self.progress.cleared
			return true
		end
	end
end

-- 게임 종료시 블리자드 취소되도록
function local_class:on_game_over_event(e)
	self:end_blizzard()
	self.current_progress = self.progress.cleared
end

function local_class:extinguish_fire(v)
	-- HACK: 불 끄는 함수 강제로 함수 접근해서 호출
	lua_helper.call_interface(v.fo.CombustibleBehaviour,
			'Oak.ICombustibleBehaviour', 'GetExtinguishedBy', nil)
	v.fo.CombustibleBehaviour.IsAffectedBurn = false
	v.last_extinguish_time = self.time_passed
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)

	self.time_passed = self.time_passed + dt
	-- 항상 켜져있는 캠프파이어에 대한 업데이트
	self:update_always_on_campfire(dt)
	self:update_campfire()
	if self.current_progress < self.progress.playing then return end

	--반경 안에 캠프파이어가 있는지 체크
	if self:check_campfire() then
		--캠프파이어 반경 안에있을 경우 회복
		if self.campfire_heal_delay <= 0 then
			self:execute_campfire_heal()
			self.campfire_heal_delay = self.current_stage_info.campfire_heal_term
		else
			self.campfire_heal_delay = self.campfire_heal_delay - dt
		end
	end

	if self.blizzard_current_progress == self.blizzard_progress.suspended or
		self.blizzard_current_progress == self.blizzard_progress.clear_or_fail then
		self:blizzard_fade_out(dt)
	elseif self.blizzard_current_progress == self.blizzard_progress.start then
		self:update_blizzard(dt)
	end
end

function local_class:update_always_on_campfire(dt)

	--반경 안에 캠프파이어가 있는지 체크
	if self:check_always_on_campfire() then
		--캠프파이어 반경 안에있을 경우 회복
		if self.campfire_heal_delay <= 0 then
			self:execute_campfire_heal()
			self.campfire_heal_delay = self.current_stage_info.campfire_heal_term
		else
			self.campfire_heal_delay = self.campfire_heal_delay - dt
		end
	end
end

function local_class:update_campfire()
	for _,v in pairs(self.campfire_object_list) do
		if self.time_passed - v.last_burn_time > self.current_stage_info.campfire_burn_duration and v.fo.CombustibleBehaviour.IsBurning then
			self:extinguish_fire(v)
		end
		if self.time_passed - v.last_extinguish_time > self.current_stage_info.campfire_cool_time and not v.fo.CombustibleBehaviour.IsAffectedBurn then
			v.fo.CombustibleBehaviour.IsAffectedBurn = true
		end
	end
end

-- 상시 동작하고 있는 캠프파이어 체크
function local_class:check_always_on_campfire()
	for _, v in pairs(self.always_on_campfire_list) do
		if v.CombustibleBehaviour.IsBurning then
			local distance = math.abs(vector_util.get_x0z(user_party.Leader.Position - v.Position).magnitude)
			if distance < self.current_stage_info.campfire_heal_range then
				return true
			end
		end
	end
	return false
end

function local_class:check_campfire()
	for _,v in pairs(self.campfire_object_list) do
		if v.fo.CombustibleBehaviour.IsBurning then
			local distance = math.abs(vector_util.get_x0z(user_party.Leader.Position - v.fo.Position).magnitude)
			if distance < self.current_stage_info.campfire_heal_range then
				return true
			end
		end
	end

	return false
end

-- 블리자드 색상값 초기화
function local_class:init_blizzard()
	-- 이펙트 설정
	self:blizzard_set_up()
	-- 컬러값 재설정
	self:blizzard_color_refresh()
end

--- 눈보라 강도 조절
function local_class:blizzard_fade_out(dt)
	--- blizzard fade out
	if  self.blizzard_fade_out_time_passed < self.blizzard_fade_out_duration then
		self.blizzard_fade_out_time_passed = self.blizzard_fade_out_time_passed + dt
		local progress = unity_class.mathf.Max(self.blizzard_fade_out_time_passed / self.blizzard_fade_out_duration, 0)
		local cur_tint = unity_class.mathf.Lerp(self.blizzard_tint, self.blizzard_fade_out_target_value, progress)
		self:blizzard_update_alpha(cur_tint)
	end
end

--- blizzard 이펙트 셋업
function local_class:blizzard_set_up(args)
	if self.blizzard == nil or self.fade == nil then return end
	if self.blizzard.obj ~= nil or self.fade.obj ~= nil then
		-- 지우고 다시 만들어
		self:blizzard_dispose()
	end

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
	self.blizzard.color.a = 1
	local target_alpha = custom_alpha and alpha or self.blizzard.color.a * 0.2

	self.blizzard.material:SetColor(self.property_name, unity_color(
			{ self.blizzard.color.r, self.blizzard.color.g, self.blizzard.color.b, target_alpha }))

	if with_fade then
		self.fade.obj = self.preset.blizzard_fade:Instantiate(
				camera.Transform.position, unity_class.quaternion.identity, camera.Transform)
		self.fade.main_module = self.fade.obj.transform:GetComponentInChildren(
				typeof(CS.UnityEngine.ParticleSystem)).main

		-- 초기 설정값 세팅
		self.fade.color = self.fade.main_module.startColor.color
		self.fade.color.a = 1

		target_alpha = custom_alpha and alpha or self.fade.color.a * 0.2

		-- 초기 설정
		self.fade.gradient.color = unity_color(
				{ self.fade.color.r, self.fade.color.g, self.fade.color.b, target_alpha })

		self.fade.main_module.startColor = self.fade.gradient
		self.fade.color = self.fade.main_module.startColor.color
	end
end

function local_class:blizzard_update_alpha(alpha)

	self.blizzard.material:SetColor(self.property_name, unity_color(
			{ self.blizzard.color.r, self.blizzard.color.g, self.blizzard.color.b, alpha }))

	if self.fade.obj ~= nil then
		self.fade.gradient.color = unity_color(
				{ self.fade.color.r, self.fade.color.g, self.fade.color.b, alpha })
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
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BurnEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))

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
