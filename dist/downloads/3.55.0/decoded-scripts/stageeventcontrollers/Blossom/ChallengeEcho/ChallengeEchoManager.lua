---@class ChallengeEchoManager
local local_class = newclass('ChallengeEchoManager')

--region StageEventController

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.fx = setmetatable({
		glitch = function()
			return unity_object_pool.GetOrCreate('fx_bs_glithch_normal_effect')
		end,

		knight_trail = function()
			return unity_object_pool.GetOrCreate('fx_m_knight2_1st_trail')
		end,

		reset = function()
			return unity_object_pool.GetOrCreate('FX_reset_object')
		end,

	}, {
		__index = {
			create_all = function(this)
				for _, creator in pairs(this) do
					creator()
				end
			end
		}
	})

	self.echo_states = {
		none = 0,
		-- 해당 그리드에 들어오면 에코 루틴을 대기한다.
		--존에 들어가면 init으로 변경
		in_grid = 1,

		--존에 들어가면 에코 루틴을 위해 이펙트 설정.
		--설정 완료 후 wait_echo_npc로 변경
		init = 2,

		--UI를 설정한다.
		--설정 완료 후 wait_echo_npc로 변경
		set_ui = 3,

		-- 동적 할당 NPC 생성을 대기.
		--특정 주기마다 spawn_echo_npc로 변경.
		--제한시간을 넘어서면 wait_rewind로 변경.
		--존을 탈출하면 exit으로 변경
		wait_echo_npc = 4,

		-- 동적 할당 NPC를 생성한다.
		-- 생성 완료 시 wait_echo_npc로 변경.
		spawn_echo_npc = 5,

		--리와인드 조건이 될 때 까지 대기(Idle State로 돌아왔는지)
		--조건 충족 시 in_rewind로 변경.
		wait_rewind = 6,

		--리와인드 실행 연출 중.
		--실행시키고 in_rewind으로 변경.
		start_rewind = 7,

		--리와인드 실행 연출 중.
		--실행 완료 시 init으로 변경.
		in_rewind = 8,

		--탈출. UI및 동적 할당 NPC 제거.
		--완료 후 none으로 변경.
		exit = 9,
	}
	self.cur_echo_state = self.echo_states.none

	self.cur_tint = 0
	self.tint_request = 0

	self.cur_echo_info = {
		reset_marker = '',
		zone_name = '',
	}

	self.echo_npc_color = unity_color({ 0.1, 1, 0.85, 1 })
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self:dispose_knight_trail()
	self:dispose_fx_glitch()

	self:dispose_echo_npc()

	self:stop_sun_amb()

	self.cs_controller = nil
end

function local_class:load_resource()
	self.fx:create_all()

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	local puzzle_infos = self.constants_data.puzzle_infos
	for i = 1, #puzzle_infos do
		local zone_name = puzzle_infos[i].zone_name
		if type_util.is_zone_full_enter(e, user_party.Leader, zone_name) and
				self.cur_echo_state == self.echo_states.in_grid then

			self.cur_echo_info.reset_marker = puzzle_infos[i].reset_marker
			self.cur_echo_info.zone_name = puzzle_infos[i].zone_name
			self.cur_echo_state = self.echo_states.init

			return true
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, self.cur_echo_info.zone_name) and
			self.cur_echo_state ~= self.echo_states.in_grid then
		self.cur_echo_state = self.echo_states.exit

		return true
	end

	return false
end

function local_class:on_stage_start_event(_)
	return false
end

function local_class:on_stage_loaded_event(_)
	self:load_constants_data()
	start_coroutine(function()
		self:load_background_fade_controller()
		self:init_background_fade_controller()
		self:create_echo_npc()
		self:create_puzzle_glitch()

		self:echo_routine()
	end)
end

function local_class:load_constants_data()
	local path = 'stageeventcontrollers/Blossom/ChallengeEcho/Constants'
	local constants_data = get_or_create_global_variable(path)
	local stage_name = stage.Name
	self.constants_data = constants_data[stage_name]
end

function local_class:load_background_fade_controller()
	self.is_get, self.background_fade_controller = global_table_util.try_create_background_fade_controller()
	--asset_path, asset_name 디폴트 값 사용
	--local asset_path = 'ondemand/blossom/effects'
	--local asset_name = 'white_tint_background'
	local background_fade_infos = self.constants_data.background_fade_infos
	local asset_path = background_fade_infos.asset_path
	local asset_name = background_fade_infos.asset_name
	self.background_fade_controller:load_async(asset_path, asset_name)
end

function local_class:init_background_fade_controller()
	self.background_fade_controller:set_background_color(0, 0, 0)
	self.background_fade_controller:set_background_active(true)
	self.background_fade_controller:set_background_alpha(0)
	self.background_fade_controller:set_background_scale(100)
end

function local_class:create_echo_npc()
	if self.dynamic_echo_npc_list ~= nil then
		return
	end

	local leader = get_party_leader()
	local skin_name = 'bs_guardian_bob'

	local npc_list = {}
	self.echo_info_list = {}

	local npc_prefix = self.constants_data.echo_infos.npc_prefix
	local max_count = self.constants_data.echo_infos.max_count

	for i = 1, max_count do
		local key = npc_prefix .. i
		local value = skin_name
		npc_list[key] = value

		local echo_info = {}
		echo_info['pos'] = vector(0, 0, 0)
		echo_info['emotion'] = 'idle'
		echo_info['anim'] = 'idle'
		echo_info['direction'] = 'down'
		table.insert(self.echo_info_list, echo_info)
	end

	self.dynamic_echo_npc_list = load_util.create_dynamic_npcs_async(npc_list)
	yield_return_func(self.setting_dynamic_npc_skin, self)

	for i = 1, max_count do
		local key = npc_prefix .. i
		local npc = self.dynamic_echo_npc_list[key]

		--rgba 값 (0.2, 0.9, 0.1, 0.5)으로 틴트해서
		--애니메이션 재생속도 0.001배로 실행시켜 배치한다.
		character_util.add_color(npc, npc.Name, self.echo_npc_color, 1, 0)
		npc.SpineController.TimeScale = 0.001
		field_ui_manager:RemoveUI(npc, CS.Oak.FieldUiType.CharacterStats)
		character_util.set_sorting_layer(npc, 'Default', -1)
	end
end

function local_class:dispose_echo_npc()
	if self.dynamic_echo_npc_list ~= nil then
		load_util.dispose_dynamic_npcs(self.dynamic_echo_npc_list)
		self.dynamic_echo_npc_list = nil
	end
end

function local_class:setting_dynamic_npc_skin()
	self.res_holder = CS.Foundations.ResourceHolder()

	local user_party_leader = get_party_leader()

	local asset_bundle_name = user_party_leader.CharacterInfo.AssetName.assetBundleName
	local asset_name = user_party_leader.CharacterInfo.AssetName.assetName
	local skin_name = user_party_leader.CharacterInfo.SkinName

	local npc_prefix = self.constants_data.echo_infos.npc_prefix
	local max_count = self.constants_data.echo_infos.max_count

	for i = 1, max_count do
		local npc_key = npc_prefix .. i
		local dynamic_npc = self.dynamic_echo_npc_list[npc_key]

		-- 코스튬이 있다면 코스튬으로 아니면 캐릭터 기본 스팩의 데이터로 SpriteAssetName 세팅
		if user_party_leader.Costume == nil then
			dynamic_npc.FieldObjectStatsBehaviour.CharacterSpec.SpriteAssetName = user_party_leader.CharacterInfo.CharacterSpec.SpriteAssetName
		else
			dynamic_npc.FieldObjectStatsBehaviour.CharacterSpec.SpriteAssetName = user_party_leader.Costume.CostumeSpec.AssetName
		end

		-- 캐릭터 일반 이름 세팅
		dynamic_npc.FieldObjectStatsBehaviour.CharacterSpec.CharacterName = user_party_leader.CharacterInfo.CharacterSpec.CharacterName

		-- 메뉴얼 조종할 때 캐릭터 걷기 속도 세팅
		dynamic_npc.FieldObjectStatsBehaviour.CharacterSpec.ManualWalkSpeed = user_party_leader.FieldObjectStatsBehaviour.CharacterSpec.ManualWalkSpeed

		-- 메뉴얼 조종할 때 캐릭터 달리기 속도
		dynamic_npc.FieldObjectStatsBehaviour.CharacterSpec.ManualDashSpeed = user_party_leader.FieldObjectStatsBehaviour.CharacterSpec.ManualDashSpeed

		-- 프리팹 불러올 때 까지 대기
		yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder,
				asset_bundle_name, asset_name, function(prefab)
					local go = CS.UnityEngine.GameObject.Instantiate(prefab)
					local spine_controller = go:GetComponent(typeof(CS.Oak.SpineController))

					if spine_controller ~= nil then
						dynamic_npc.SpineController:SwitchSpineController(spine_controller)
					else
						CS.UnityEngine.Object.Destroy(go)
					end
				end)

		-- 스킨 설정
		if skin_name then
			dynamic_npc.SpineController.SkinName = skin_name
		end

	end
end

function local_class:create_puzzle_glitch()
	if self.puzzle_glitch_list ~= nil then
		return
	end

	local glitch_marker_infos = self.constants_data.glitch_marker_infos
	for idx = 1, #glitch_marker_infos do
		local marker_name = glitch_marker_infos[idx]
		local puzzle_glitch_pos = field_util.get_marker_pos(marker_name)
		local puzzle_glitch = self.fx:glitch():Instantiate(puzzle_glitch_pos)
	end

end

function local_class:dispose_puzzle_glitch()
	if self.puzzle_glitch_list == nil then
		return
	end

	for i = 1, #self.puzzle_glitch_list do
		self.puzzle_glitch_list[i]:Dispose()
		self.puzzle_glitch_list[i] = nil
	end
	self.puzzle_glitch_list = nil
end

--region echo_routine

function local_class:echo_routine()
	local leader = get_party_leader()

	self.cur_echo_state = self.echo_states.in_grid
	local cur_echo_count = 0
	local max_echo_count = self.constants_data.echo_infos.max_count
	local echo_cycle_duration = self.constants_data.echo_infos.cycle_duration
	local time_passed = 0

	local echo_total_duration = echo_cycle_duration * (max_echo_count + 1)

	local in_rewind = false

	local change_states = function(state)
		self.cur_echo_state = state
	end

	self.in_echo_routine = true

	local cached_position = leader.Position

	while self.in_echo_routine do
		time_passed = time_passed + unity_class.time.deltaTime
		if self.cur_echo_state == self.echo_states.in_grid then

		elseif self.cur_echo_state == self.echo_states.init then
			--플레이어에 이펙트를 적용
			self:set_effect_on_leader()
			change_states(self.echo_states.set_ui)

		elseif self.cur_echo_state == self.echo_states.set_ui then
			--플레이어 캐스팅 UI 및 공격/스킬/롤액션 UI 제거 설정
			self:set_casting_ui(true, echo_total_duration)
			self:disable_skills()

			change_states(self.echo_states.wait_echo_npc)

			time_passed = 0
		elseif self.cur_echo_state == self.echo_states.wait_echo_npc then
			if time_passed > echo_total_duration then
				cur_echo_count = 0
				time_passed = 0
				change_states(self.echo_states.wait_rewind)
			elseif time_passed > echo_cycle_duration * (cur_echo_count + 1) then
				change_states(self.echo_states.spawn_echo_npc)
				cur_echo_count = cur_echo_count + 1
			end
		elseif self.cur_echo_state == self.echo_states.spawn_echo_npc then
			if cur_echo_count == 1 then
				cached_position = lua_helper.get_conditional_value(cur_echo_count == 1, leader.Position, cached_position)
			end
			self:spawn_echo_npc(cur_echo_count)
			change_states(self.echo_states.wait_echo_npc)

		elseif self.cur_echo_state == self.echo_states.wait_rewind then
			if self:check_rewind_ready() then
				in_rewind = true
				change_states(self.echo_states.start_rewind)
			end

		elseif self.cur_echo_state == self.echo_states.start_rewind then
			self:custom_start_scene(self.rewind_scene, self, cached_position):Then(function()
				in_rewind = false
			end)
			change_states(self.echo_states.in_rewind)

		elseif self.cur_echo_state == self.echo_states.in_rewind then
			if in_rewind == false then
				change_states(self.echo_states.set_ui)
			end

		elseif self.cur_echo_state == self.echo_states.exit then
			--n초가 지나기 전에 존에서 완전히 빠져나갈 시 처리
			--연출 진행
			cur_echo_count = 0
			self:echo_out_by_zone_exit()
			self:enable_skills()
			change_states(self.echo_states.in_grid)
		end
		coroutine.yield(nil)
	end
end

function local_class:rewind_scene()
	local leader = get_party_leader()

	local rewind_infos = self.constants_data.rewind_infos

	leader.SpineController.TimeScale = 0.001

	character_util.add_color(leader, leader.Name, self.echo_npc_color, 1, 0)
	local cached_leader_direction = character_util.get_direction(leader)

	self.fx_knight_trail = self.fx:knight_trail():Instantiate(leader.Position + vector(0, 0.5, 0),
			unity_class.quaternion.identity, leader.Transform)

	--플레이어 몸에 fx_knight2_arrow_proj_contrail 이펙트 배치
	local get_xz_angle = function(target_vector)
		local x = target_vector.x
		--잔상 y위치 루트 2 만큼 곱해준 보정값만큼 다시 나눠주고, 그 값을 z값에 더함.
		local z = target_vector.z + target_vector.y * 0.7071
		local angle_rad = math.atan(z, x)  -- atan2(z, x) 사용
		local angle_deg = math.deg(angle_rad)  -- 라디안을 도(degree)로 변환

		if angle_deg < 0 then
			angle_deg = angle_deg + 360  -- 음수일 경우 보정
		end

		return angle_deg
	end

	for i = #self.echo_info_list, 1, -1 do
		local rewind_info = lua_helper.get_or_default(rewind_infos[i], rewind_infos[#rewind_infos])
		local echo_info = self.echo_info_list[i]

		local pos = echo_info['pos']
		local emotion = echo_info['emotion']
		local anim = echo_info['anim']
		local direction = echo_info['direction']

		local diff_vector = leader.Position - pos

		--플레이어에게 이펙트 출력 시 효과음 재생 /01_object_warp_01 / fx_knight2_arrow_proj_contrail
		--정확히는 출력은 아니지만…
		music_player_util.play_sfx_one_shot('01_object_warp_01')

		--해당 이펙트는 플레이어 이동이 z축에서 이루어질 경우 y로테이션 90도 적용. 플레이어 이동이 x축에서 이루어질 경우 y로테이션 0도 적용.
		self.fx_knight_trail.transform.rotation = unity_class.quaternion.Euler(0, -get_xz_angle(diff_vector), 0)

		--복귀 : k
		--존에 진입하고 n*k초 지난 후의 플레이어 파티리더의 애니메이션, 표정, 방향을 동일하게 설정하여 재생속도 0.001배로 실행.
		scene_util.set_anim(leader, self, anim)
		scene_util.set_emotion(leader, self, emotion)
		scene_util.set_direction(leader, direction, false)

		--존에 진입하고 n*k초 지난 후의 플레이어 파티리더의 좌표 지점으로 move_time초만에 이동한다. 처음엔 빠르게 움직였다 서서히 느려지면서 이동.
		local time_passed = 0
		local move_time = rewind_info.move_time

		local start_pos = leader.Position
		local target_pos = pos

		while time_passed < move_time do
			local progress = interpolations_constants.ease_in_quad(time_passed, 0, 1, move_time)

			leader.Position = start_pos * (1 - progress) + target_pos * progress

			coroutine.yield()

			time_passed = time_passed + unity_class.time.deltaTime

		end

		leader.Position = pos

		local npc_prefix = 'echo_dynamic_'
		local npc_key = npc_prefix .. i
		local npc = self.dynamic_echo_npc_list[npc_key]

		npc.Position = vector(999, 0, 999)

		character_util.remove_anim_and_emotion(npc)
		scene_util.set_direction(npc, 'right', false)

		--wait_time 대기
		local wait_time = rewind_info.wait_time
		wait_for_sec(wait_time)
	end

	--위치 세팅
	--플레이어 up 방향이면 right로 전환, 아니라면 방향 그대로 유지한 채로 damaged, damaged 실행.
	--0.1초만에 이상현상 존 별로 지정된 리셋 지점 마커로 이동.

	music_player_util.play_sfx_one_shot('01_teleport_02')
	scene_util.set_anim(leader, self, 'damaged')
	scene_util.set_emotion(leader, self, 'damaged')

	local reset_pos = field_util.get_marker_pos(self.cur_echo_info.reset_marker)

	do
		local diff_vector = leader.Position - reset_pos

		--해당 이펙트는 플레이어 이동이 z축에서 이루어질 경우 y로테이션 90도 적용. 플레이어 이동이 x축에서 이루어질 경우 y로테이션 0도 적용.
		self.fx_knight_trail.transform.rotation = unity_class.quaternion.Euler(0, -get_xz_angle(diff_vector), 0)

		--0.1초만에 이상현상 존 별로 지정된 리셋 지점 마커로 이동.
		--처음엔 빠르게 움직였다 서서히 느려지면서 이동.
		local time_passed = 0
		local move_time = 0.1
		local start_pos = leader.Position
		local target_pos = reset_pos
		while time_passed < move_time do
			local progress = interpolations_constants.ease_in_quad(time_passed, 0, 1, move_time)

			leader.Position = start_pos * (1 - progress) + target_pos * progress

			coroutine.yield()

			time_passed = time_passed + unity_class.time.deltaTime
		end

	end
	leader.Position = reset_pos

	leader.SpineController.TimeScale = 1

	--스파인 틴트 0.5초간 제거.
	character_util.remove_color(leader, leader.Name, 0.5)

	--0.5초 대기.
	wait_for_sec(0.5)

	--trail 제거
	self:dispose_knight_trail()

	--기사 idle, idle로 전환.
	character_util.remove_anim_and_emotion(leader)

	--컨트롤 돌려준다.
end

function local_class:spawn_echo_npc(cur_echo_count)
	--플레이어가 존에 진입하고 n*0.25초 지난 후
	--진입 당시의 플레이어 파티리더의 좌표 지점에
	local leader = get_party_leader()
	local cur_pos = leader.Position

	local direction = leader.Direction
	local direction_string = direction_util.to_str(direction)

	local base_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Base)
	local anim_name_ext = leader.SpineController.SkeletonAnimation.state:GetCurrent(base_track).Animation.Name
	--_side, _front, _back 등 제거
	local anim_name = anim_name_ext:match("(.+)_[^_]+$")

	local emotion_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Emotion)
	local emotion_name_ext

	if leader.Direction == character_util.get_direction('up') then
		emotion_name_ext = 'idle_side'
	elseif leader.SpineController.SkeletonAnimation.state:GetCurrent(emotion_track) == nil then
		emotion_name_ext = 'idle_side'
	else
		emotion_name_ext = leader.SpineController.SkeletonAnimation.state:GetCurrent(emotion_track).Animation.Name
	end

	local emotion_name = emotion_name_ext:match("(.+)_[^_]+$")

	if emotion_name == nil then
		emotion_name = 'idle'
	end

	local npc_prefix = 'echo_dynamic_'

	local npc = self.dynamic_echo_npc_list[npc_prefix .. cur_echo_count]
	if npc ~= nil then

		character_util.set_direction(npc, leader.Direction)

		scene_util.set_anim(npc, self, anim_name)

		scene_util.set_emotion(npc, self, emotion_name)

		--애니메이션, 표정, 방향을 동일하게 설정하여
		npc.Position = cur_pos

		--그리고 이 당시의 플레이어 파티리더의 애니메이션 이름과 표정, 좌표, 방향을 받아놓는다.
		self.echo_info_list[cur_echo_count]['pos'] = cur_pos
		self.echo_info_list[cur_echo_count]['emotion'] = emotion_name
		self.echo_info_list[cur_echo_count]['anim'] = anim_name
		self.echo_info_list[cur_echo_count]['direction'] = direction_string
	end
end

function local_class:check_rewind_ready()
	local leader = get_party_leader()

	--n초가 지난 시점에 플레이어가 특수한 연출 상태일 때는 해당 연출이 끝날 때 까지 대기합니다.
	--ex) 벽에 충돌해서 밀려나는 연출, 기타 기믹 오브젝트를 사용하고 있는 연출(청홍벽, 레버 등) 중일 경우
	local current_state = leader.CharacterBehaviour.CurrentState
	if current_state and lua_helper.type_compare(current_state, CS.Oak.CharacterAnalogueState) then
		return true
	else
		return false
	end
end

function local_class:set_effect_on_leader()
	local leader = get_party_leader()
	--이상현상 존에 완전히 진입 시

	--필드 어두워지는 동안 BGM 볼륨 0.4로 변경 / bgm_portal_dungeon
	music_player_util.change_stage_music_volume('field', 0.4)

	--필드 어두워지는 동안 환경음 루프 재생 / 01_amb_sun_01 / 볼륨 0.8
	self:play_sun_amb(0.8,0)

	--필드 틴트 0.3초만에 0.5 수준으로 검게.
	start_coroutine(self.field_tint_routine, self, 0.3, 0.5)

	--플레이어 몸에 fx_cw_glitch_effect 이펙트 배치
	music_player_util.play_sfx_one_shot('01_glitch_08')
	self.fx_glitch = self.fx.glitch():Instantiate(leader.Bounds.center,
			unity_class.quaternion.identity, leader.Transform)

	--진입 당시의 플레이어 파티리더의 애니메이션 이름과 표정, 좌표, 방향을 받아놓는다.
end

function local_class:set_casting_ui(is_on, duration)
	duration = lua_helper.get_or_default(duration, 1)
	local leader = get_party_leader()

	if is_on then
		CS.Oak.MessageSystem.Instance:Publish(CS.Oak.AttackQueueStartEvent.Create(leader, duration))
	else
		CS.Oak.MessageSystem.Instance:Publish(CS.Oak.AttackQueueEndEvent.Create(leader))
	end


end

function local_class:echo_out_by_zone_exit()
	--컨트롤은 뺏지 않고 아래 연출 진행.

	--플레이어 발 밑의 캐스팅 UI 제거
	self:set_casting_ui(false)

	--화면 어두운 틴트 끝나는 순간에 환경음 루프 종료 / 01_amb_sun_01 → mute / 페이드 아웃, 믹스 0.5초
	self:fade_out_sun_amb(0.5)

	--화면 어두운 틴트 끝나는 순간에 BGM 볼륨 1로 변경	bgm_portal_dungeon
	music_player_util.change_stage_music_volume('field', 1)

	--필드 틴트 0.3초만에 원상복귀.
	start_coroutine(self.field_tint_routine, self, 0.3, 0)

	--플레이어 몸에 fx_cw_glitch_effect 이펙트 제거.
	self:dispose_fx_glitch()

	--배치된 분신체들이 있을 경우


	for i = #self.echo_info_list, 1, -1 do
		local npc_prefix = 'echo_dynamic_'
		local npc_key = npc_prefix .. i
		local npc = self.dynamic_echo_npc_list[npc_key]

		--FX_reset_object를 분신체들 위치에 배치.
		self.fx:reset():Instantiate(npc.Position)

		--분신체들 전원 제거.
		npc.Position = vector(999, 0, 999)
	end

	--0.8초 뒤, FX_reset_object 제거.
end

--루틴 하나에 통합하면 좋겠지만...그러면 틴트 때문에 루틴 계속 돌아야 하니 그것도 좀...
function local_class:field_tint_routine(duration, target_tint)
	self.tint_request = self.tint_request + 1
	local cur_tint_request = self.tint_request
	local time_passed = 0

	local tint_key = 'echo_field_tint'

	--시작 틴트 값 캐싱
	local start_tint = self.cur_tint

	if target_tint == start_tint then
		return
	end

	local look_at_position = stage_camera.LookAtPosition
	local y_offset = 10
	local background_position = vector(look_at_position.x, y_offset, look_at_position.z - y_offset)
	self.background_fade_controller:set_background_position(background_position)

	while self.tint_request == cur_tint_request and
			time_passed < duration do

		local progress = unity_class.mathf.Clamp01(time_passed / duration)
		local current_tint = start_tint * (1 - progress) + target_tint * progress


		--현재 틴트값을 저장해, 중간에 끊기더라도 문제 없도록.
		self.cur_tint = current_tint

		time_passed = time_passed + unity_class.time.deltaTime

		-- field_util.tint(tint_key, unity_color({ current_tint, current_tint, current_tint, current_tint }), 0)
		self.background_fade_controller:set_background_alpha(current_tint)

		coroutine.yield(nil)
	end

	if target_tint == 0 then
		self.cur_tint = 0
		self.background_fade_controller:set_background_alpha(0)
	end
end

function local_class:disable_skills()
	local leader = get_party_leader()
	local manual_touch_state = leader.FieldObjectController.CurrentState
	local controls_to_disable = (CS.Oak.DisabledControls.Attack | CS.Oak.DisabledControls.Super)
	manual_touch_state:RequestDisableControl(leader, controls_to_disable)

	--local state_change_event = CS.Oak.StateChangeEvent.Create(manual_touch_state)
	--message_system:SendSync(leader.FieldObjectController, state_change_event)

	coroutine.yield(nil)

	field_ui_manager:RemoveUI(leader, CS.Oak.FieldUiType.SkillButton | CS.Oak.FieldUiType.ClassButton |
			CS.Oak.FieldUiType.RoleButton | CS.Oak.FieldUiType.MythSkillButton)
end

function local_class:enable_skills()
	local leader = get_party_leader()
	local manual_touch_state = leader.FieldObjectController.CurrentState
	if manual_touch_state ~= nil and
			lua_helper.type_compare(manual_touch_state, CS.Oak.CharacterControllerManualTouchState) then
		manual_touch_state:RemoveDisableControl(leader)
	end

	coroutine.yield(nil)

	field_ui_manager:SetUI(leader, CS.Oak.FieldUiType.SkillButton | CS.Oak.FieldUiType.ClassButton |
			CS.Oak.FieldUiType.RoleButton | CS.Oak.FieldUiType.MythSkillButton)

end

function local_class:dispose_knight_trail()
	if self.fx_knight_trail ~= nil then
		self.fx_knight_trail:Dispose()
		self.fx_knight_trail = nil
	end
end

function local_class:dispose_fx_glitch()
	if self.fx_glitch ~= nil then
		self.fx_glitch:Dispose()
		self.fx_glitch = nil
	end
end

function local_class:play_sun_amb(volume, fade_in_time)
	volume = lua_helper.get_or_default(volume, 0.8)
	fade_in_time = lua_helper.get_or_default(fade_in_time, 0)

	if self.amb_sun_sfx == nil then
		self.amb_sun_sfx = music_player_util.play_sfx({
			sfx_name = '01_amb_sun_01', volume = volume, fade_in_time = fade_in_time, loop = true
		})
	end
end

function local_class:change_sun_amb(volume,fade_in_time)
	volume = lua_helper.get_or_default(volume, 0.2)
	fade_in_time = lua_helper.get_or_default(fade_in_time, 1)

	if self.amb_sun_sfx ~= nil then
		music_player_util.change_sfx_volume(self.amb_sun_sfx,volume,fade_in_time)
	end
end

function local_class:fade_out_sun_amb(fade_out_time)
	fade_out_time = lua_helper.get_or_default(fade_out_time, 1)

	if self.amb_sun_sfx ~= nil then
		music_player_util.fade_out_sfx(self.amb_sun_sfx, fade_out_time)
		self.amb_sun_sfx = nil
	end
end

function local_class:stop_sun_amb()
	if self.amb_sun_sfx ~= nil then
		music_player_util.stop_sfx(self.amb_sun_sfx)
		self.amb_sun_sfx = nil
	end
end

--타이머바 출력과 hide_ui가 동시에 일어나지 않도록 방지,
function local_class:custom_start_scene(func, ...)
	local args = { ... }
	local routine = function()
		-- 이전 리더에 대한 정보를 미리 캐싱해둬야 해제가 가능함
		local cached_leader = get_party_leader()

		self:set_casting_ui(false)

		--먼저 조작을 못하게 막음. 캐릭터가 새로운 버튼을 누르지 못하도록 함.
		party_util.stop_and_disable_control()

		--타이머바가 나올 정도로 충분히 대기 한 후,
		wait_for_sec(0.1)

		--enter_scene에 진입해 UI를 가림.
		sp_util.enter_scene({ hide_ui = true, stop_party = false})

		yield_return_func(func, table.unpack(args))

		sp_util.exit_scene({ show_ui = true,  }, cached_leader)

	end

	return start_coroutine(routine)
end


--endregion echo_routine

--endregion StageEventController

return local_class
