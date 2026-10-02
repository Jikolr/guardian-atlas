local local_class = newclass('TowerLaserGimmickController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 레이저 chest_box 가져오는 함수
	self.get_chest_box = function(index) return get_field_object('tower_laser_' .. index) end

	-- 레이저 기믹 존
	self.get_laser_loop_zone = function(index) return field:GetZone('laser_zone_' .. index) end

	-- 레이저 기믹의 상태
	-- none : 시작 전 / start : 시작 / game_over : 게임오버 됬을 때 / finish : 전투가 끝났을 때
	self.gimmick_state = { none = 1, start = 2, game_over = 3, finish = 4 }

	-- 현재 기믹 상태 초기화
	self.current_gimmick_state = self.gimmick_state.none

	-- 현재 레이저 루틴이 돌아가고 있는가?
	self.is_running_laser_gimmick = false

	-- 기믹 루틴 겹치지 않기 위한 방지용
	self.is_active_gimmick_routine = false

	-- 레이저 기믹이 시작되는 존 이름
	self.gimmick_start_zone_names = nil

	-- 체스트 박스 터지는 이팩트 이름
	self.explosion_effect_name = 'FX_explosion_small'

	-- 현재 작동 중인 레이저 인덱스
	self.current_laser_index = -1

	-- 스테이지별 레이저 기믹의 정보를 담고 있는 구조체
	-- Key : 스테이지 이름
	-- speed : 레이저 기믹이 돌아가는 속도 (높을수록 빨라짐)
	-- change_directing_time : 레이저 기믹의 돌아가는 방향이 변경되는 시간(초) 0이면 변경되지 않는다.
	-- gimmick_count : 해당 스테이지에 레이저 기믹의 갯수 gimmick_start_zone_names 와 battle_end_group_names는
	-- 해당 count와 같은 숫자의 배열을 가지고 있어야 한다.
	-- gimmick_start_zone_names : 레이저 기믹이 시작하는 존의 이름
	-- battle_end_group_names : 이 이름의 배틀그룹의 BattleGroupEliminatedEvent를 받으면 레이저가 사라진다.
	self.stage_battle_info = {
		tower_fire_30 = {
			speed = 0.1,
			change_directing_time = 45,
			gimmick_count = 1,
			gimmick_start_zone_names = { 'boss' },
			battle_end_group_names = { 'boss' }
		},
		tower_ice_25 = {
			speed = 0.1,
			change_directing_time = 0,
			gimmick_count = 1,
			gimmick_start_zone_names = { 'boss' },
			battle_end_group_names = { 'boss' }
		},
		tower_none_15 = {
			speed = 0.1,
			change_directing_time = 0,
			gimmick_count = 2,
			gimmick_start_zone_names = { 'battle_1', 'battle_2' },
			battle_end_group_names = { 'battle_1', 'battle_2' }
		},
		tower_110 = {
			speed = 0.1,
			change_directing_time = 0,
			gimmick_count = 1,
			gimmick_start_zone_names = { 'boss' },
			battle_end_group_names = { 'boss' }
		}
	}

	self.current_stage_info = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.HealEvent), 'on_heal_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]
	self.gimmick_start_zone_names = self.current_stage_info.gimmick_start_zone_names

	unity_object_pool.GetOrCreate(self.explosion_effect_name)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	-- 리더가 존에 들어갔을 때만
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

	local zone_name = e.Zone.Name
	for i = 1, #self.gimmick_start_zone_names do
		-- 레이저 기믹 존에 도착했으면서 current_gimmick_state가 none(시작 안했을 때)
		if zone_name == self.gimmick_start_zone_names[i] and self.current_gimmick_state == self.gimmick_state.none
				and self.current_laser_index < i - 1 then
			self.current_gimmick_state = self.gimmick_state.start
			self.is_running_laser_gimmick = true
			self.current_laser_index = i - 1

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gimmick_routine, self))
			return true
		end
	end

	return false
end

-- 게임오버 됬을 때 기믹 루프를 꺼준다.
function local_class:on_game_over_event(e)
	-- 레이저 기믹을 더이상 돌지 않게 하고
	-- current_gimmick_state를 game_over로 변경한다.
	self.is_running_laser_gimmick = false
	self.current_gimmick_state = self.gimmick_state.game_over
	return true
end

-- 전투가 끝났을 때 레이저 기믹꺼지도록
function local_class:on_battle_group_eliminated_event(e)
	-- 보스와의 전투가 끝날 때 레이저 기믹을 disabled 해준다.
	-- FIXME: 터지는 연출이라면 이팩트 재생 후 사라지게 해야할 것
	for i = 1, #self.current_stage_info.battle_end_group_names do
		if e.BattleGroupName == self.current_stage_info.battle_end_group_names[i] then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_chest_box, self, i - 1))
		end
	end

	return true
end

function local_class:disabled_chest_box(index)
	self.is_running_laser_gimmick = false
	self.current_gimmick_state = index == self.current_stage_info.gimmick_count - 1 and self.gimmick_state.finish or self.gimmick_state.none

	local add_index = 2 * index
	local chest_1 = self.get_chest_box(1 + add_index)
	local chest_2 = self.get_chest_box(2 + add_index)

	-- chest 1에서 레이저롤 쏘고 있으니 1에서 이팩트 Deactive
	chest_1.FieldObjectBehaviour:DeactiveLaserEffect()

	music_player_util.play_sfx_one_shot('02_explosion_water_01')
	-- 각 박스 좌표에서 폭발 이팩트 재생
	for i = 1, 2 do
		unity_object_pool.GetOrCreate(self.explosion_effect_name):Instantiate(i == 1 and chest_1.Position or chest_2.Position)
	end

	-- 0.25초 딜레이 후
	wait_for_sec(0.25)

	-- 체스트 박스들 Disabled
	chest_1.ActiveState = active_state('disabled')
	chest_2.ActiveState = active_state('disabled')
end

function local_class:on_heal_event(e)
	-- 힐 되는 타겟이 리더면서
	if lua_helper.reference_equals(e.Info.target, user_party_leader) then
		return false
	end

	-- 기믹 상태가 게임 오버이며 리더가 부활 한 경우 기믹루틴을 다시 돌려준다.
	if self.current_gimmick_state == self.gimmick_state.game_over and e.Info.isRevive then
		self.is_running_laser_gimmick = true
		self.current_gimmick_state = self.gimmick_state.start
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gimmick_routine, self))
	end
end

-- 레이저 기믹 루틴
function local_class:gimmick_routine()
	while self.is_active_gimmick_routine do
		if not self.is_running_laser_gimmick then
			return
		end
		coroutine.yield(nil)
	end

	self.is_active_gimmick_routine = true

	local zone = self.get_laser_loop_zone(self.current_laser_index + 1)

	local lasers = {}
	local room = zone.Bounds
	local room_center = room.center

	local start_index = 1 + 2 * self.current_laser_index
	for i = start_index, start_index + 1 do
		local laser = self.get_chest_box(i)
		if i == start_index then room_center.y = laser.Position.y end
		laser.Position = (room_center + vector(room.extents.x, laser.Position.y, 0))
		laser.ActiveState = active_state('enabled')
		table.insert(lasers, laser)
	end

	local change_time = 0
	local time_passed = 0
	local direction_value = 1

	lasers[1].FieldObjectBehaviour.IsActiveLaserIntersectCheck = true

	local sfx_loop = music_player_util.play_sfx({ sfx_name = '02_light_laser_loop_01', loop = true, type_priority = 'gimmick', player_priority = 'player', fade_in_time = 2 })
	while self.is_running_laser_gimmick do
		-- 레이저 기믹 박스 위치 세팅
		local dt = unity_class.time.deltaTime
		time_passed = time_passed + dt * direction_value

		local rad = time_passed * CS.UnityEngine.Mathf.PI * self.current_stage_info.speed
		local dir = vector(CS.UnityEngine.Mathf.Cos(rad), 0, CS.UnityEngine.Mathf.Sin(rad))

		local r1 = CS.UnityEngine.Ray(room.center, dir)
		local r2 = CS.UnityEngine.Ray(room.center, -dir)

		local dist1 = CS.BoundsExtensions.RayIntersectDistance(room, r1)
		local dist2 = CS.BoundsExtensions.RayIntersectDistance(room, r2)

		-- 레이저 기믹 위치 이동
		lasers[1].Position = room_center + dir * dist1
		lasers[2].Position = room_center - dir * dist2

		-- change_directing_time때 마다 레이저 기믹의 방향이 변경된다.
		change_time = change_time + unity_class.time.deltaTime
		if change_time > self.current_stage_info.change_directing_time
				and self.current_stage_info.change_directing_time ~= 0 then
			direction_value = direction_value * -1
			change_time = 0
		end
		coroutine.yield(nil)
	end
	sfx_loop:Stop()

	-- 레이저 체크 활성화 해제
	lasers[1].FieldObjectBehaviour.IsActiveLaserIntersectCheck = false

	self.is_active_gimmick_routine = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.HealEvent))

	self.current_stage_info = nil
	self.stage_battle_info = nil
	self.is_running_laser_gimmick = false

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
