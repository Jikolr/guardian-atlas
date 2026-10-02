local local_class = newclass('ExpeditionDistrict3HiddenEvent')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.crevasse_state = {
		cracked = 1,
		broken = 2,
		none = 3
	}

	self.time_passed = 0
end

function local_class:load_resource()
	if stage.PlayHiddenEvent == true then
		unity_object_pool.GetOrCreate('fx_expedition_crevasse')
	end

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_stage_loaded_event(_)
	self.crevasse = get_field_object('event_hidden_crevasse')

	if not self.crevasse then
		return false
	end

	self.crevasse_transform_1 = self.crevasse.Transform:Find('1')
	self.crevasse_transform_2 = self.crevasse.Transform:Find('2')
	self.crevasse_transform_3 = self.crevasse.Transform:Find('3')

	self.use_transform_update = is_unity_null(self.crevasse_transform_1) == false and
			is_unity_null(self.crevasse_transform_2) == false and
			is_unity_null(self.crevasse_transform_3) == false

	if not self.use_transform_update then
		return false
	end

	if stage.HiddenEventCleared then
		self:change_crevasse_state(self.crevasse_state.none)
		return true
	else
		self:change_crevasse_state(self.crevasse_state.cracked)
	end

	-- 이벤트 플레이 가능케 함
	if stage.PlayHiddenEvent then
		local ui_dic = field_ui_manager:SetUI(self.crevasse, CS.Oak.FieldUiType.TimerBar)

		-- 게이지 최대
		self.gauge_total = 2000
		-- 게이지 차는 속도
		self.gauge_fill_speed = {
			one = 10,
			two = 80,
			three = 160,
			four = 320
		}
		-- 플레이어 캐릭터 감지 거리
		self.crevasse_radius = self.crevasse.Bounds.extents.x
		-- 게이지 바 높이
		local gauge_bar_height = 1
		local gauge_bar_width = 100
		-- 넉백 계수
		self.knock_back_impact_force = 14000
		self.knock_back_impact_time = 0.05
		self.knock_back_time = 0.4
		-- 카메라 흔들림 계수
		self.shake_magnitude = {
			one = 0.06,
			two = 0.08,
			three = 0.10,
			four = 0.12
		}
		-- 폭발 이펙트 후 구멍 생기는 타이밍, knock_back_time보다 작게 설정
		self.show_broken_timing = 0.25

		self.gauge_bar = ui_dic[CS.Oak.FieldUiType.TimerBar]
		self.gauge_bar.BarSprite:SetWidth(gauge_bar_width)
		self.gauge_bar.BarSprite:SetMinMax(0, self.gauge_total)
		self.gauge_bar.BarSprite:SetValue(self.gauge_total, 0)
		self.gauge_bar.BarSprite.Transform.position = self.crevasse.Bounds.center + unity_class.vector3(0,gauge_bar_height,0)
		self.gauge_bar.BarSprite.Transform.gameObject:SetActive(false)

		self.current_gauge = self.gauge_total
		self.is_shaking = false
		self.crevasse_event_active = true

		message_system:Subscribe(self, typeof(CS.Oak.ExpeditionEndEvent), 'on_expedition_end')
	end

	return true
end

function local_class:on_expedition_end(_)
	if self.is_shaking then
		self.gauge_bar.BarSprite.Transform.gameObject:SetActive(false)
		stage_camera:CancelShake('crevasse')
		self.is_shaking = false
	end
	self.crevasse_event_active = false
	return true
end

function local_class:change_crevasse_state(next_state)
	if self.current_crevasse_state == next_state then return end

	if self.current_crevasse_state == self.crevasse_state.cracked then
		if self.is_shaking then
			self.gauge_bar.BarSprite.Transform.gameObject:SetActive(false)
			stage_camera:CancelShake('crevasse')
			self.is_shaking = false
		end
	elseif self.current_crevasse_state == self.crevasse_state.broken then
		self.crevasse.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		self.crevasse.EntityGroup = CS.System.Convert.ToUInt32(self.crevasse.EntityGroup)
								& ~CS.System.Convert.ToInt32(CS.Oak.EntityGroups.Obstacle)
	end

	self.time_passed = 0
	self.current_crevasse_state = next_state

	if self.current_crevasse_state == self.crevasse_state.cracked then
		if self.use_transform_update then
			self.crevasse_transform_1.gameObject:SetActive(true)
			self.crevasse_transform_2.gameObject:SetActive(false)
			self.crevasse_transform_3.gameObject:SetActive(false)
		end
	elseif self.current_crevasse_state == self.crevasse_state.broken then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.crevasse_explosion_routine, self))
		-- 이벤트 클리어 처리
		stage:ClearHiddenEvent()
	elseif self.current_crevasse_state == self.crevasse_state.none then
		if self.use_transform_update then
			self.crevasse_transform_1.gameObject:SetActive(false)
			self.crevasse_transform_2.gameObject:SetActive(false)
			self.crevasse_transform_3.gameObject:SetActive(true)
		end
	end
end

function local_class:crevasse_explosion_routine()
	local pos = self.crevasse.Bounds.center
	unity_object_pool.GetOrCreate('fx_expedition_crevasse'):Instantiate(pos)

	local crash_list = {}
	local bound = CS.UnityEngine.Bounds(pos, self.crevasse.Bounds.size)
	local push_time = self.knock_back_time
	local transform_updated = false

	stage_camera:Shake(0.25, push_time)
	music_player_util.play_sfx_one_shot('03_rock_break_03')

	while self.time_passed < push_time and self.current_crevasse_state == self.crevasse_state.broken do
		if not stage.Paused then
			-- transform 스위칭
			if self.use_transform_update and not transform_updated and self.time_passed > self.show_broken_timing then
				self.crevasse_transform_1.gameObject:SetActive(false)
				self.crevasse_transform_2.gameObject:SetActive(true)
				self.crevasse_transform_3.gameObject:SetActive(false)
			end

			-- 파티 관짝 전체 확인. 캐릭터 죽는 연출 진행중에 파티 스위치 시 관짝이 남음
			for i = 0, 2 do
				local party = CS.Oak.PartyManager.Instance[i]
				for j = 0, party.Count - 1 do
					local character = party[j]
					if character.FieldObjectStatsBehaviour.IsDead and character.Bounds:Intersects(bound)
							and not crash_list[character] then
						crash_list[character] = true

						local diff = (character.Bounds.center - pos):GetX0z()
						local dir = diff.normalized
						local knock_back_info = CS.Oak.KnockBackInfo()
						knock_back_info.type = CS.Oak.KnockBackType.Physics
						knock_back_info.stun = false
						knock_back_info.direction = dir:IsAlmostZero() and unity_class.vector3.up or dir
						knock_back_info.impactForce = self.knock_back_impact_force
						knock_back_info.impactTime = self.knock_back_impact_time
						knock_back_info.muCoefficient = CS.Oak.Constants.DefaultFrictionCoefficient
						coroutine_manager:StartCoroutine(stage.StageGameObject,
								util.cs_generator(self.coffin_knock_back_routine, self, knock_back_info, character))
					end
				end
			end

			local crash_this_frame = {}
			local collide_fos = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(pos, bound)
			for i = 0, collide_fos.Count - 1 do
				local fo = collide_fos[i]
				if CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(fo, typeof(CS.Oak.Character))
						and not crash_list[fo] and not fo.FieldObjectStatsBehaviour.IsDead then
					table.insert(crash_this_frame, fo)
					crash_list[fo] = true
					-- 일관되게 작동하기 위해서 컨트롤러 스테이트 변경함
					CS.Oak.CharacterControllerScreenplayState.Stop(fo)
					fo.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
				end
			end

			if collide_fos.Count == 0 then
				self.crevasse.CrashBehaviour = CS.Oak.HoleCrashBehaviour.Instance
				self.crevasse.EntityGroup = self.crevasse.EntityGroup | CS.Oak.EntityGroups.Obstacle
				coroutine.yield(coroutine_class.wait_for_sec(push_time - self.time_passed))
				collide_fos:Dispose()
				break
			end
			collide_fos:Dispose()

			for _,fo in pairs(crash_this_frame) do
				character_util.set_anim(fo, { name = 'embarrassed' })
				-- BoneFollower를 이용하는 이모션은 해당 Bone이 없으면 에러
				if CS.Oak.SpineControllerExtensions.GetBone(fo.SpineController, '[base]face') then
					character_util.set_emotion(fo, { name = 'surprise' })
				end

				local diff = (fo.Bounds.center - pos):GetX0z()
				local dir = diff.normalized
				local knock_back_info = CS.Oak.KnockBackInfo()
				knock_back_info.type = CS.Oak.KnockBackType.Physics
				knock_back_info.jump = true
				knock_back_info.stun = false
				knock_back_info.direction = dir:IsAlmostZero() and unity_class.vector3.up or dir
				knock_back_info.impactForce = self.knock_back_impact_force
				knock_back_info.impactTime = self.knock_back_impact_time
				knock_back_info.muCoefficient = CS.Oak.Constants.DefaultFrictionCoefficient

				-- 넉백 방어 무시 필요
				local knock_back_state = CS.Oak.CharacterKnockBackState.Create(fo, knock_back_info)

				message_system:SendSync(fo.FieldObjectBehaviour, CS.Oak.StateChangeEvent.Create(knock_back_state))
			end
		end

		coroutine.yield(nil)
	end

	for fo,_ in pairs(crash_list) do
		character_util.remove_anim_and_emotion(fo)
		message_system:SendSync(fo, CS.Oak.StateResetEvent.Instance)
		fo.OverrideCrashBehaviour = nil
	end

	self.crevasse.CrashBehaviour = CS.Oak.HoleCrashBehaviour.Instance
	self.crevasse.EntityGroup = self.crevasse.EntityGroup | CS.Oak.EntityGroups.Obstacle
end

function local_class:coffin_knock_back_routine(info, character)
	local friction = CS.CalculatorFrictionPush(0, character.FieldObjectStatsBehaviour.FieldObjectSpec.Mass,
			info.muCoefficient, info.impactForce, info.impactTime)
	local start_pos = character.Position

	while not friction:IsDone() do
		friction:Proceed(unity_class.time.deltaTime)
		local pos = start_pos + info.direction * friction:GetDistance()
		character_util.set_position(character, pos)

		coroutine.yield(nil)
	end
end

function local_class:use_late_update_frame()
	return stage.PlayHiddenEvent
end

function local_class:late_update_frame(dt)
	if not self.crevasse_event_active then
		return
	end

	self.time_passed = self.time_passed + dt

	if self.current_crevasse_state == self.crevasse_state.cracked then
		local count = 0
		-- 현재 사용중인 파티가 항상 0번에 옴
		local party = CS.Oak.PartyManager.Instance[0]
		for i = 0, party.Count - 1 do
			local character = party[i]
			local dist = (self.crevasse.Bounds.center - character.Bounds.center):GetX0z().magnitude

			if dist < self.crevasse_radius and not character.FieldObjectStatsBehaviour.IsDead
					and character.ActiveState == CS.Oak.ActiveState.Enabled then
				count = count + 1
			end
		end

		if count == 0 then
			if self.is_shaking then
				self.gauge_bar.BarSprite.Transform.gameObject:SetActive(false)
				stage_camera:CancelShake('crevasse')
				self.is_shaking = false
			end
		else
			local shake_magnitude = self.shake_magnitude.one
			if count == 1 then
				self.current_gauge = self.current_gauge - self.gauge_fill_speed.one * dt
			elseif count == 2 then
				shake_magnitude = self.shake_magnitude.two
				self.current_gauge = self.current_gauge - self.gauge_fill_speed.two * dt
			elseif count == 3 then
				shake_magnitude = self.shake_magnitude.three
				self.current_gauge = self.current_gauge - self.gauge_fill_speed.three * dt
			elseif count >= 4 then
				shake_magnitude = self.shake_magnitude.four
				self.current_gauge = self.current_gauge - self.gauge_fill_speed.four * dt
			end

			if not self.is_shaking then
				self.gauge_bar.BarSprite.Transform.gameObject:SetActive(true)
				self.is_shaking = true
				local shake_info = CS.Oak.ShakeInfo()
				shake_info.name = 'crevasse'
				shake_info.magnitude = shake_magnitude
				shake_info.duration = CS.System.Single.MaxValue
				shake_info.useUnscaledTime = false
				stage_camera:Shake(shake_info)
				music_player_util.play_sfx_one_shot('01_earthquake_02')
			end
		end
		self.gauge_bar.BarSprite:SetValue(self.current_gauge, 0)

		if self.current_gauge <= 0 then
			self:change_crevasse_state(self.crevasse_state.broken)
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionEndEvent))

	self.cs_controller = nil
	self.scene = nil
	self.crevasse = nil
	self.current_crevasse_state = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
