local local_class = newclass('DefenseGame')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.game_progress = {
		none = 1,
		playing = 2,
		fail = 3,
		clear = 4
	}
	self.current_game_progress = self.game_progress.none

	-- 스테이지별 웨이브에 필요한 정보를 담고 있는 구조체
	-- Key : 스테이지 이름
	-- Value : 필요 정보들의 테이블
	-- -- hp : 디펜스 게임 HP (몬스터 몇 마리 놓치면 게임 오버) hp가 깎일때는 맨 마지막 번째 안드로이드부터 없어진다!
	-- -- -- 예를 들어, hp가 3에서 2로 깎이면 self.hp_androids[3] 이 없어진다.
	-- -- hp_androids_position : 각 HP를 나타내는 안드로이드의 위치. 플레이어 시작지점을 기준으로 벡터로 표현된다. 아이템들의 총 갯수는 self.stage_defensegame_info[stage.Name].hp 과 같다.
	-- -- -- 예를 들어, 리스트가 { unity_class.vector3.left , unity_class.vector3.back, unity_class.vector3.right } 라면 첫번째 HP 안드로이드는 플레이어 시작지점에서 왼쪽으로 1칸, 두번째는 아래로 1칸, 세번째는 오른쪽에 1칸 배치된다.
	-- -- spawn_cycle_each_stage : 몬스터들 스폰 시간 리스트. 아이템들의 총 개수는 몬스터의 총 개수와 동일한 숫자로 이뤄지고 몬스터들의 순서와 똑같이 매핑된다.
	-- -- -- 예를 들어, 리스트가 {1,2,3}이라면 1번 몬스터는 1초후에 스폰되고 2번 몬스터는 1번 몬스터가 스폰된 시점으로부터 2초 후 스폰되는 식이다.
	-- -- monster_waypoints : 몬스터들의 경로. 시작 지점에서 상대 위치로 기술이 되며, 바로 전 waypoint를 이동하고 난 후를 기준으로 다음 waypoint를 기술한다.
	-- -- -- 예를 들어, 리스트가 { unity_class.vector3.left , unity_class.vector3.back, unity_class.vector3.right }이라면 몬스터는 시작지점에서 왼쪽으로 1칸 이동, 아래쪽으로 1칸 이동, 그리고 오른쪽으로 1칸 이동한다.

	self.stage_defensegame_info = {
		tower_light_5 = {
			hp = 3,
			hp_androids_position = {
				5 * unity_class.vector3.back + 8.5 * unity_class.vector3.right,
				5 * unity_class.vector3.back + 9.5 * unity_class.vector3.right,
				5 * unity_class.vector3.back + 10.5 * unity_class.vector3.right
			},
			spawn_cycle_each_stage = {
				2, 4, 2, 3, 3,
				6, 1.5, 2, 3, 2,
				6, 1.5, 1.5, 2, 2, 2, 1.5
			},
			monster_waypoints = {
				7 * unity_class.vector3.forward,
				14 * unity_class.vector3.left,
				11 * unity_class.vector3.back,
				20 * unity_class.vector3.right
			}
		},
		tower_light_35 = {
			hp = 3,
			hp_androids_position = {
				5 * unity_class.vector3.back + 5.5 * unity_class.vector3.right,
				5 * unity_class.vector3.back + 6.5 * unity_class.vector3.right,
				5 * unity_class.vector3.back + 7.5 * unity_class.vector3.right
			},
			spawn_cycle_each_stage = {
				2, 4, 2, 3, 3, 2, 2, 0,
				6, 1.5, 2, 3, 2, 1.5, 2.5, 0,
				6, 1.5, 1.5, 2, 1, 2, 1.5, 2, 1, 0
			},
			monster_waypoints = {
				7 * unity_class.vector3.forward,
				14 * unity_class.vector3.left,
				11 * unity_class.vector3.back,
				20 * unity_class.vector3.right
			}
		},
		tower_darkness_5 = {
			hp = 3,
			hp_androids_position = {
				2.5 * unity_class.vector3.back + 12.5 * unity_class.vector3.right,
				2.5 * unity_class.vector3.back + 11.5 * unity_class.vector3.right,
				2.5 * unity_class.vector3.back + 10.5 * unity_class.vector3.right
			},
			spawn_cycle_each_stage = {
				2, 1, 1, 1.5, 2,
				4, 1, 2, 1, 0.5, 0.5, 1.5,
				4, 1, 0.5, 2, 1,
				4, 0.5, 0.5, 0.5, 1.5, 2, 0.5, 1, 0.5
			},
			monster_waypoints = {
				9 * unity_class.vector3.right,
				5 * unity_class.vector3.back,
				5 * unity_class.vector3.left,
				10 * unity_class.vector3.forward,
				16 * unity_class.vector3.right,
				5 * unity_class.vector3.back,
				5 * unity_class.vector3.left,
				5 * unity_class.vector3.back,
				18 * unity_class.vector3.right
			}
		},
		tower_darkness_35 = {
			hp = 3,
			hp_androids_position = {
				5.5 * unity_class.vector3.forward + 10.5 * unity_class.vector3.right,
				5.5 * unity_class.vector3.forward + 9.5 * unity_class.vector3.right,
				5 * unity_class.vector3.forward + 10 * unity_class.vector3.right
			},
			spawn_cycle_each_stage = {
				2, 1, 1, 1.5, 2,
				4, 1, 1.5, 1, 0.5,
				4, 1, 0.5, 1, 2, 1, 0.5,
				4, 1, 2, 1, 0.5, 0.5, 1.5,
				4, 0.5, 0.5, 0.5, 1.5, 2, 0.5, 1, 0.5
			},
			monster_waypoints = {
				12 * unity_class.vector3.right,
				4 * unity_class.vector3.forward,
				4 * unity_class.vector3.left,
				12 * unity_class.vector3.back,
				4 * unity_class.vector3.left,
				4 * unity_class.vector3.forward,
				8 * unity_class.vector3.right,
				4 * unity_class.vector3.back,
				6 * unity_class.vector3.right,
				21 * unity_class.vector3.forward
			}
		},
		tower_earth_5 = {
			hp = 3,
			hp_androids_position = {
				4 * unity_class.vector3.forward + 6.5 * unity_class.vector3.left,
				4 * unity_class.vector3.forward + 7.5 * unity_class.vector3.left,
				3 * unity_class.vector3.forward + 7 * unity_class.vector3.left
			},
			spawn_cycle_each_stage = {
				3, 2, 2, 2, 1,
				4, 2, 0.5, 2, 1, 0.5, 2,
				4, 1, 1, 2, 1,
				4, 0.5, 1, 2, 1, 2, 0.5, 1, 0.5
			},
			monster_waypoints = {
				9 * unity_class.vector3.forward,
				5 * unity_class.vector3.right,
				9 * unity_class.vector3.back,
				5 * unity_class.vector3.right,
				21 * unity_class.vector3.forward
			}
		},
		tower_earth_35 = {
			hp = 3,
			hp_androids_position = {
				7.5 * unity_class.vector3.back + 1 * unity_class.vector3.up + 12 * unity_class.vector3.right,
				7.5 * unity_class.vector3.back + 1 * unity_class.vector3.up + 11 * unity_class.vector3.right,
				7 * unity_class.vector3.back + 1 * unity_class.vector3.up + 11.5 * unity_class.vector3.right
			},
			spawn_cycle_each_stage = {
				3, 2, 3, 2,
				5, 2, 1, 3,
				5, 2, 1, 2.5, 1, 1,
				5, 2, 0.5, 1.5, 0.5, 1,
				5, 2, 0.5, 1.5, 1.5, 1, 0.5
			},
			monster_waypoints = {
				3 * unity_class.vector3.right,
				3 * unity_class.vector3.forward,
				4 * unity_class.vector3.right,
				11 * unity_class.vector3.back,
				4 * unity_class.vector3.left,
				4 * unity_class.vector3.forward,
				11 * unity_class.vector3.right,
				4 * unity_class.vector3.back,
				3 * unity_class.vector3.left,
				21 * unity_class.vector3.back
			}
		},
		tower_fire_5 = {
			hp = 3,
			hp_androids_position = {
				6 * unity_class.vector3.forward + 15.5 * unity_class.vector3.right,
				6 * unity_class.vector3.forward + 14.5 * unity_class.vector3.right,
				5.5 * unity_class.vector3.forward + 15 * unity_class.vector3.right
			},
			spawn_cycle_each_stage = {
				2, 2, 3, 1.5, 2,
				5, 2, 1.5, 2, 2,
				5, 2, 1.5, 2.5, 2, 1, 1.5,
				5, 1, 1, 2.5, 2, 2, 1,
				5, 0.5, 0.5, 2, 2, 1, 1.5
			},
			monster_waypoints = {
				12 * unity_class.vector3.forward,
				6 * unity_class.vector3.right,
				12 * unity_class.vector3.back,
				6 * unity_class.vector3.right,				
				21 * unity_class.vector3.forward
			}
		},
		tower_fire_35 = {
			hp = 3,
			hp_androids_position = {
				1 * unity_class.vector3.back + 5.5 * unity_class.vector3.right,
				1 * unity_class.vector3.back + 4.5 * unity_class.vector3.right,
				1.5 * unity_class.vector3.back + 5 * unity_class.vector3.right
			},
			spawn_cycle_each_stage = {
				3, 2, 1.5, 2.5, 2,
				5, 1, 2.5, 1, 1,
				5, 2, 1, 1, 2, 1.5, 0.5,
				5, 1, 2.5, 1.5, 1, 0.5, 2,
				5, 2, 1, 0.5, 1.5, 1, 0.5, 1.5, 0.5
			},
			monster_waypoints = {
				4 * unity_class.vector3.back,
				4 * unity_class.vector3.right,
				8 * unity_class.vector3.forward,
				8 * unity_class.vector3.left,
				7 * unity_class.vector3.back,
				9 * unity_class.vector3.left,
				10 * unity_class.vector3.back,
				10 * unity_class.vector3.right,
				21 * unity_class.vector3.forward
			}
		},
		tower_ice_5 = {
			hp = 3,
			hp_androids_position = {
				8.5 * unity_class.vector3.back + 3 * unity_class.vector3.right,
				7.5 * unity_class.vector3.back + 3.5 * unity_class.vector3.right,
				7.5 * unity_class.vector3.back + 2.5 * unity_class.vector3.right
			},
			spawn_cycle_each_stage = {
				2, 1.5, 3, 2, 3,
				5, 2, 3, 1, 2,
				5, 2, 1, 3, 2, 2, 1.5,
				5, 1, 2, 2.5, 2, 1, 2.5,
				5, 0.5, 2, 1.5, 0.5, 1.5, 1
			},
			monster_waypoints = {
				2 * unity_class.vector3.right,
				4 * unity_class.vector3.back,
				6 * unity_class.vector3.left,
				8 * unity_class.vector3.forward,
				14 * unity_class.vector3.right,
				4 * unity_class.vector3.back,
				4 * unity_class.vector3.left,							
				21 * unity_class.vector3.back
			}
		},
		tower_ice_35 = {
			hp = 3,
			hp_androids_position = {
				6 * unity_class.vector3.forward + 2.5 * unity_class.vector3.left,
				5.5 * unity_class.vector3.forward + 3.5 * unity_class.vector3.left,
				6.5 * unity_class.vector3.forward + 3.5 * unity_class.vector3.left
			},
			spawn_cycle_each_stage = {
				3, 2, 3, 2, 3,
				5, 1.5, 3, 3, 1.5,
				5, 1.5, 3, 2.5, 2.5, 1, 2.5,
				5, 2, 2.5, 2, 1, 2, 2,
				5, 1, 1.5, 2, 1, 1, 1.5, 0.5, 0.5
			},
			monster_waypoints = {
				3 * unity_class.vector3.right,
				11 * unity_class.vector3.back,
				4 * unity_class.vector3.left,
				5 * unity_class.vector3.forward,
				4 * unity_class.vector3.left,
				5 * unity_class.vector3.back,
				4 * unity_class.vector3.left,
				11 * unity_class.vector3.forward,
				21 * unity_class.vector3.right
			}
		},
		tower_none_5 = {
			hp = 3,
			hp_androids_position = {
				2.5 * unity_class.vector3.back + 19.5 * unity_class.vector3.left,
				1.5 * unity_class.vector3.back + 19.5 * unity_class.vector3.left,
				2 * unity_class.vector3.back + 18.5 * unity_class.vector3.left
			},
			spawn_cycle_each_stage = {
				3, 2, 3, 2, 2,
				5, 3, 2, 3, 1,
				5, 1.5, 2, 1, 2, 3, 2,
				5, 4, 3, 2, 1, 3, 2
			},
			monster_waypoints = {
				13 * unity_class.vector3.left,
				9 * unity_class.vector3.back,
				5 * unity_class.vector3.right,
				vector(3, 0, 2),
				5 * unity_class.vector3.right,
				8 * unity_class.vector3.back,
				vector(-2, 0, -1),
				21 * unity_class.vector3.left
			}
		},
		tower_none_35 = {
			hp = 3,
			hp_androids_position = {
				11.5 * unity_class.vector3.forward + 6.5 * unity_class.vector3.left,
				12.5 * unity_class.vector3.forward + 6.5 * unity_class.vector3.left,
				12 * unity_class.vector3.forward + 5.5 * unity_class.vector3.left
			},
			spawn_cycle_each_stage = {
				2, 2, 3, 4, 3,
				5, 2, 4, 3, 3,
				5, 3, 2.5, 3, 2.5,
				5, 4, 2.5, 2.5, 3, 2.5,
				5, 2, 2, 1, 3, 2, 2
			},
			monster_waypoints = {
				4 * unity_class.vector3.right,
				4 * unity_class.vector3.forward,
				8 * unity_class.vector3.left,
				8 * unity_class.vector3.back,
				12 * unity_class.vector3.right,
				12 * unity_class.vector3.forward,
				21 * unity_class.vector3.left
			}
		}
	}

	self.monster_spawn_type = {
		use_marker = 1,
		random_in_end_line = 2
	}
	self.spawn_type = self.monster_spawn_type.use_marker

	self.active_monsters = {}

	self.available_monsters = {}

	-- hp를 나타내는 안드로이드
	self.hp_androids = {}

	self.spawn_time_passed = 0
	self.spawn_cycle = 2

	self.game_start_area_name = 'start_game'
	self.game_area_name = 'game_area'
	self.game_over_zone_name = 'game_over'
	self.player_start_stand_name = 'default_start'
	self.player_end_stand_name = 'player_end_stand'
	self.door_clear_name = 'door_clear'
	self.monster_spawn_marker_name = 'monster_spawn'
	self.monster_group_name = 'monster_group'

	self.gamepad_label = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_started_event')

	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_monster_dead_event')
	message_system:Subscribe(self, typeof(CS.Oak.RemoveFieldObjectEvent), 'on_monster_dead_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadConnectedEvent), 'on_gamepad_connected')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadDisconnectedEvent), 'on_gamepad_disconnected')

	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')


	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('FX_reset_object')
	unity_object_pool.GetOrCreate('FX_dead')
	unity_object_pool.GetOrCreate('joypad_push_label')

	coroutine.yield(unity_object_pool.WaitAll())
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(_)
	camera_util.resize_to(8, 0.5)
	self.current_game_progress = self.game_progress.playing

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.custom_intro, self))
end

function local_class:custom_intro()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_game, self))
end

function local_class:on_zone_enter_event(e)
	if self.current_game_progress == self.game_progress.none then return true end

	if e.FullEnter and e.Zone.Name == self.game_over_zone_name and table_util.contain_key(self.active_monsters, e.FieldObject) and self.stage_defensegame_info[stage.Name].hp > 0 then
		self:reduce_hp()
		self.active_monsters[e.FieldObject] = false
		unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(e.FieldObject.Position)
		if self.stage_defensegame_info[stage.Name].hp == 0 then
			self.current_game_progress = self.game_progress.fail
			e.FieldObject.Position = unity_class.vector3(999,0,999)
		else
			e.FieldObject.ActiveState = active_state('disabled')
			e.FieldObject.SpineController.AlwaysUpdateSpine = false
		end
		return true
	end
	return false
end

function local_class:on_zone_leave_event(e)
	if self.current_game_progress ~= self.game_progress.playing then return true end

	return false
end

function local_class:on_touch_event(e)
	-- 게임 플레이 중이 아니면 터치 관련 처리 하지않음.
	if self.current_game_progress ~= self.game_progress.playing then
		return true
	end
	return false
end

function local_class:on_monster_dead_event(e)
	if lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		if table_util.contain_key(self.active_monsters, e.FieldObject) then
			self.active_monsters[e.FieldObject] = false
			if self:is_all_monster_dead() and self.stage_defensegame_info[stage.Name].hp > 0 then
				self.current_game_progress = self.game_progress.clear
			end
		end
		return true
	elseif lua_helper.type_compare(e, CS.Oak.RemoveFieldObjectEvent) then
		if table_util.contain_key(self.active_monsters, e.Target) then
			self.active_monsters[e.Target] = false
			if self:is_all_monster_dead() and self.stage_defensegame_info[stage.Name].hp > 0 then
				self.current_game_progress = self.game_progress.clear
			end
		end
		return true
	end
	return false
end

function local_class:on_stage_loaded_event(_)
	self:set_spawn_monsters()
	return false
end

function local_class:on_stage_started_event(_)
	camera_util.resize_to(8, 0.5)
	self.current_game_progress = self.game_progress.playing

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.custom_intro, self))

	return true
end

function local_class:on_gamepad_connected(_)
	if self.current_game_progress ~= self.game_progress.playing then return true end
	self:show_gamepad_label()
	return false
end

function local_class:on_gamepad_disconnected(_)
	if self.current_game_progress ~= self.game_progress.playing then return true end
	self:hide_gamepad_label()
	return false
end

function local_class:on_damage_event(e)
	local damage_info = e.Info
	local monster = damage_info.target
	local sender = damage_info.sender

	-- 파티 리더가 fat이름이 들어간 몬스터에게 down 데미지를 주었을때만 활성화
	if lua_helper.reference_equals(sender, user_party.Leader) then
		if damage_info[CS.Oak.Ailment.Down] ~= nil then
			if string.match(monster.Name, 'fat') then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.delayed_spine_update, self, monster))
			end
		end
	end
end

-- 몬스터 스테이트를 계속 폴링식으로 검사해서 down에서 down이 아닌 스테이트로 전환할때 AlwayUpdateSpine을 2프레임 켜줌
-- 이렇게 하지 않으면 fat_invader_guard가 다운이 된후 damaged표정이 side로 걸어갈때 잔류해있음
function local_class:delayed_spine_update(monster)
	while lua_helper.type_compare(monster.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterDownState) do
		coroutine.yield(nil)
	end

	monster.SpineController.AlwaysUpdateSpine = true

	coroutine.yield(nil)
	coroutine.yield(nil)

	monster.SpineController.AlwaysUpdateSpine = false
end

function local_class:game_loop()
	while(self.current_game_progress == self.game_progress.playing) do
		self:monster_spawn_update(unity_class.time.deltaTime)
		coroutine.yield()
	end
end

function local_class:monster_spawn_update(dt)
	-- 가용할수있는 몬스터가 없으면 스폰 업데이트 하지않음.
	if #self.available_monsters == 0 then return end

	self.spawn_time_passed = self.spawn_time_passed + dt
	if self.spawn_time_passed > self.spawn_cycle then
		self.spawn_time_passed = 0
		self:spawn_monster()
	end
end

function local_class:get_waypoints(start_pos)
	local wps = { start_pos }

	local prev = wps[1]
	for i,v in ipairs(self.stage_defensegame_info[stage.Name].monster_waypoints) do
		table.insert(wps, prev + v)
		prev = prev + v
	end

	return wps
end

function local_class:enable_monster()
	if #self.available_monster < 5 then return end

	self.available_monster[5].ActiveState = active_state('enabled')
end

function local_class:spawn_monster()
	local monster = table.remove(self.available_monsters, 1)

	local spawn_point = field:GetMarker(self.monster_spawn_marker_name).position

	local move_point = self:get_waypoints(spawn_point)
	local mcc = CS.Oak.MonsterCharacterController('battle1', CS.Oak.PatrolAI.Waypoints, move_point)
	monster.FieldObjectController = mcc

	monster.FieldObjectController.DontFight = true
	monster.Position = spawn_point
	monster.FieldObjectController.PatrolSight = 0
	monster.FieldObjectController.PatrolAngle = 0

	monster.ActiveState = active_state('enabled')
	-- monster.SpineController.AlwaysUpdateSpine = true

	-- character_util.set_emotion(monster, { name = 'attack' })

	-- 몬스터가 생성된 곳에 등장 이펙트 생성
	music_player:PlaySfxOneShot('01_guild_warp_01')
	command_util.execute_monster_notice(monster, user_party_leader, "battle")

	unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(spawn_point)

	self.active_monsters[monster] = true

	-- 다음 몬스터 스폰사이클 세팅
	self:set_spawn_cycle(table_util.get_size(self.active_monsters) + 1)
end

function local_class:sort_available_monsters()
	local hierarchy_orders = {}
	-- local npcs = stage.StageGameObject.transform:Find(stage.Name .. '/npcs')
	local monsters = stage.StageGameObject.transform:Find(stage.Name .. '/monsters')

	-- monsters 루트 없으면 그냥 소팅 안하고 리턴
	-- if is_unity_null(npcs) then return end
	if is_unity_null(monsters) then return end

	for i = 0, monsters.childCount - 1 do
		local name = monsters:GetChild(i).gameObject.name
		hierarchy_orders[name] = i
	end

	local poped = {}
	for _, monster in ipairs(self.available_monsters) do
		table.insert(poped, { monster })
	end

	-- 이름순 정렬
	table.sort(poped, function (left, right)
		return hierarchy_orders[left[1].Name] < hierarchy_orders[right[1].Name]
	end)

	self.available_monsters = {}
	for _, t in pairs(poped) do
		local monster = t[1]
		table.insert(self.available_monsters, monster)
	end
end

function local_class:set_spawn_monsters()
	local npcs = stage.CharacterManager:GetAllNpcs()
	local monsters = stage.CharacterManager:GetAllMonsters()
	
	for i = 0, monsters.Count - 1 do
		local monster = monsters[i]
		if string.match(monster.Name, 'defense_game_monster') then
			monster.Position = unity_class.vector3.one * 999
			monster.CrashBehaviour = CS.Oak.PassCharacterCrashBehaviour.Instance
			monster.ActiveState = active_state('disabled')
			-- 죽어있던 몬스터들에겐 힐을 준다.
			if monster.FieldObjectStatsBehaviour.HP ~= monster.FieldObjectStatsBehaviour.MaxHP then
				local heal_info = CS.Oak.HealInfo()
				heal_info.sender = monster
				heal_info.target = monster
				heal_info.isRevive = true
				heal_info.heal = monster.FieldObjectStatsBehaviour.MaxHP
				command_util.execute_heal(heal_info)
			end

			table.insert(self.available_monsters, monster)
		end
	end

	local j = 1
	for i = 0, npcs.Count - 1 do
		local npc = npcs[i]
		if string.match(npc.Name, 'android') then
			table.insert(self.hp_androids, npc)
			npc.Position = self.stage_defensegame_info[stage.Name].hp_androids_position[j] + field:GetMarker(self.player_start_stand_name).position
			npc.ActiveState = active_state('enabled')
			j = j + 1
		end
	end

	self:sort_available_monsters()
end

function local_class:set_spawn_cycle(order)
	-- 첫 몬스터 생성 스폰사이클을 세팅해준다. 값을 찾을 수 없으면 기본값 2로 세팅해줌
	if self.stage_defensegame_info[stage.Name].spawn_cycle_each_stage == nil then
		self.spawn_cycle = 2
	else
		local monster1_spawn_cycle = self.stage_defensegame_info[stage.Name].spawn_cycle_each_stage[order]
		self.spawn_cycle = monster1_spawn_cycle == nil and 2 or monster1_spawn_cycle
	end
end

function local_class:game_init()
	self.spawn_time_passed = 0
	self.available_monsters = {}
	self.active_monsters = {}

	self:set_spawn_cycle(1)
	self:set_spawn_monsters()
end

function local_class:is_all_monster_dead()
	if #self.available_monsters > 0 then return false end

	for _, alive in  pairs(self.active_monsters) do
		if alive then
			return false
		end
	end

	return true
end

-- 몬스터가 존에 들어가 HP 감소
function local_class:reduce_hp()
	self.stage_defensegame_info[stage.Name].hp = self.stage_defensegame_info[stage.Name].hp - 1
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(self.hp_androids[self.stage_defensegame_info[stage.Name].hp+1].Position)
	music_player:PlaySfxOneShot('02_explosion_01')
	self.hp_androids[self.stage_defensegame_info[stage.Name].hp+1].ActiveState = active_state('disabled')
end

-- 게임 시작
function local_class:start_game()
	-- 게임 초기화
	self:game_init()

	--메인 게임 루프
	self:game_loop()

	-- 게임 종료:
	self:hide_gamepad_label()

	camera_util.resize_to_default(0.5)
	camera_util.return_to_leader(0.5)

	user_party_leader.CharacterBehaviour:CancelAllBattleActions()

	party_util.stop_and_disable_control()

	self.leader_battle = stage.BattleManager:GetBattleFor(user_party_leader)

	stage.BattleManager:ForceEndBattles()

	if self.current_game_progress == self.game_progress.clear then
		self.current_game_progress = self.game_progress.none

		self:clear_reaction()

		local towerSubSystem = CS.Oak.Game:GetCurrentSubSystem()
		if not is_unity_null(towerSubSystem) then
			yield_return(towerSubSystem, 'RequestClearStage')
		end
		screen_util.play_stage_clear()
		music_player_util.play_sfx_one_shot('01_stage_clear_01')
		screen_util.fade_out_circular_async(0.6, CS.Oak.Interpolations.EaseInOutSine, 'normal')
		CS.Oak.Game.Instance:StageToTower(nil, true, false)
	else
		self.current_game_progress = self.game_progress.none
		stage.FieldUIManager:Hide()
		message_system:Publish(CS.Oak.GameOverEvent.Instance)

		character_util.set_direction(user_party_leader, CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction))
		character_util.set_emotion(user_party_leader, {name = 'damaged'})
		character_util.set_anim(user_party_leader, {name = 'frustration', loop = false, scale = 0.4})

		-- 퀘스트 마커 재표시
		--ui_quest_marker:AddQuestMarkerToPoint('game_start', -1, false, vector(5.5, 0, -0.5))
	end
end

---[[
function local_class:hide_gamepad_label()
	if self.gamepad_label ~= nil then
		self.gamepad_label:Dispose()
		self.gamepad_label = nil
	end
end
--]]

function local_class:clear_reaction()

	camera_util.resize_to_default(0.5)
	camera_util.return_to_leader(0.5)

	character_util.set_direction(user_party.Leader, 'down')

	user_party.Leader:SetEmotion('awesome', true)
	user_party.Leader:SetAnimation('success', true)
end

function local_class:fail_reaction()
	music_player_util.play_sfx({sfx_name = '03_runaway_01', type_priority = 'event', player_priority = 'npc'})

	wait_for_sec(1)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.RemoveFieldObjectEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadConnectedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadDisconnectedEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	self:hide_gamepad_label()

	self.game_progress = nil
	self.monster_spawn_type = nil
	self.active_monsters = nil
	self.hp_androids = nil
	self.available_monsters = nil
	self.spawn_cycle_each_stage = nil
	self.custom_event_listener = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
