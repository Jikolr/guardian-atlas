local local_class = newclass('ExpeditionRescueNPCEvent')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	if stage.PlayHiddenEvent == true then
		unity_object_pool.GetOrCreate('FX_slime_buttbounce')
	end

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_stage_loaded_event(e)
	self.rock_list = {
		get_field_object('event_hidden_rock_1'),
		get_field_object('event_hidden_rock_2'),
		get_field_object('event_hidden_rock_3'),
	}

	self.cocoon_list = {}
	self.fx_list = {}
	for _, rock in ipairs(self.rock_list) do
		table.insert(self.cocoon_list, rock.Transform:Find('cocoon'))
		table.insert(self.fx_list, rock.Transform:Find('fx'))
	end

	for _, rock in ipairs(self.rock_list) do
		-- 이미 이벤트 깼다면 바위 숨김
		if stage.HiddenEventCleared == true then
			rock.ActiveState = CS.Oak.ActiveState.Disabled
		end
	end


	-- 이벤트 플레이 가능케 함
	if stage.PlayHiddenEvent == true then
		message_system:Subscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent), 'on_monster_spawned_event')
		message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
		self.current_visible = {}
		self.rock_count = 0
		for _ in ipairs(self.rock_list) do
			self.rock_count = self.rock_count+1
			table.insert(self.current_visible, 1)
		end
		local npc_names = {
			expedition_rescue_china_female = "expedition_rescue_china_female",
			expedition_rescue_china_male = "expedition_rescue_china_male",
			expedition_rescue_china_oldman = "expedition_rescue_china_oldman",
			expedition_rescue_china_merchant = "expedition_rescue_china_merchant"
		}
		self.npc_name_list = {
			"expedition_rescue_china_female",
			"expedition_rescue_china_male",
			"expedition_rescue_china_oldman",
			"expedition_rescue_china_merchant",
		}
		self.npc_count = 4
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				function()
					self.npc_list = load_util.create_dynamic_npcs_async(npc_names)
					for _, character in pairs(self.npc_list) do
						character.ActiveState = active_state('disabled')
						character.gameObject:SetActive(false)
					end
				end))


		-- 체력바 세팅
		self.hp_bar_list = {}
		for i, _ in ipairs(self.rock_list) do
			local rock = self.rock_list[i]
			local ui_dict = field_ui_manager:SetUI(rock, CS.Oak.FieldUiType.TimerBar)
			local hp_bar = ui_dict[CS.Oak.FieldUiType.TimerBar]
			hp_bar.BarSprite:SetWidth(100)
			hp_bar.BarSprite:SetMinMax(0, 1)
			hp_bar.BarSprite:SetValue(1, 0)

			hp_bar:SetPosition(rock.Position)
			hp_bar.gameObject:SetActive(false)
			hp_bar_active_checker = {}

			-- 바위를 지정된 레이저 몬스터만 때릴 수 있도록 함.
			rock.EntityGroup = CS.Oak.EntityGroups.AllyObject
			rock.DamagedBehaviour = CS.Oak.RegisterFieldObjectDamagedBehaviour()
			rock.FieldObjectStatsBehaviour.FieldObjectSpec = CS.Oak.GameDataService.GetData('FieldObjectSpecs'):GetSpec(200003)

			hp_bar_active_checker[i] = false
			table.insert(self.hp_bar_list, hp_bar)
		end
	end

	return true
end

function local_class:on_monster_spawned_event(e)
	-- 스폰 된 몬스터가 히든 관련 몬스터면 등록
	if e.Spec.AffectHiddenObject == true then
		for _, rock in ipairs(self.rock_list) do
			rock.DamagedBehaviour:RegisterObject(e.Monster)
		end
	end
end

function local_class:on_damage_event(e)
	for i, rock in ipairs(self.rock_list) do
		if lua_helper.reference_equals(e.Info.target, rock) then
			local hp_bar = self.hp_bar_list[i]
			-- 타이머 체력바 갱신
			local ratio = rock.FieldObjectStatsBehaviour.HpRatio
			if ratio < 1 then
				hp_bar.BarSprite:SetValue(ratio, 0)
				if not hp_bar_active_checker[i] then
					hp_bar_active_checker[i] = true
					hp_bar.gameObject:SetActive(true)
				end

				-- 체력 상태에 따라 모습 변경
				if rock.FieldObjectStatsBehaviour.IsDead == true then
					self:update_rock_visible(3, i)
				elseif ratio <= 0.5 then
					self:update_rock_visible(2, i)
				else
					self:update_rock_visible(1, i)
				end

				return true
			end
			break
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	for i, rock in ipairs(self.rock_list) do
		if lua_helper.reference_equals(e.FieldObject, rock) then
			rock.ActiveState = active_state('visible')
			self:update_rock_visible(3, i)
			field_ui_manager:RemoveUI(rock, CS.Oak.FieldUiType.TimerBar)
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rescue_npc, self, i))
			self.rock_count = self.rock_count-1
			if self.rock_count == 0 then
				stage:ClearHiddenEvent()
			end

			return true
		end
	end

	return false
end

function local_class:update_rock_visible(show_target, rock_index)
	if self.current_visible == show_target then
	elseif show_target == 1 then
		self.cocoon_list[rock_index].gameObject:SetActive(true)
	elseif show_target == 2 then
		-- 반파 이펙트
		unity_object_pool.GetOrCreate('FX_slime_buttbounce'):Instantiate(self.rock_list[rock_index].Position)
	elseif show_target == 3 then
		self.cocoon_list[rock_index].gameObject:SetActive(false)
		self.fx_list[rock_index].gameObject:SetActive(true)
	end

	self.current_visible[rock_index] = show_target
end

function local_class:rescue_npc(rock_index)
	local rand = random_util.get_random_int(1, self.npc_count)
	local name = table.remove(self.npc_name_list, rand)
	local npc = self.npc_list[name]
	self.npc_count = self.npc_count - 1

	npc.ActiveState = active_state('enabled')
	npc.Position = self.rock_list[rock_index].Position
	npc:SetEmotion('surprise', true)
	character_util.set_direction(npc, "down")
	character_util.normal_jump_async(npc, true)
	character_util.normal_jump_async(npc, true)
	coroutine.yield(CS.Foundations.WaitForSeconds(1))
	self:run_npc(npc)
	npc.ActiveState = active_state('disabled')
end

function local_class:run_npc(npc)
	local zone = CS.Oak.LuaBattleExtensions.GetBattleZoneBounds(npc)
	local bound = zone.Bounds
	local target_pos_candidate = {
		up = CS.UnityEngine.Vector3(npc.Position.x, 0, bound.center.z + bound.extents.z),
		right = CS.UnityEngine.Vector3(bound.center.x + bound.extents.x, 0, npc.Position.z),
		down = CS.UnityEngine.Vector3(npc.Position.x, 0, bound.center.z - bound.extents.z),
		left = CS.UnityEngine.Vector3(bound.center.x - bound.extents.x, 0, npc.Position.z),
	}
	local closest_pos = nil
	local closest_dir = nil

	local target_pos = nil
	local target_dir = nil

	local closest_dist = 0xfffffff
	local second_dist = 0xfffffff

	for direction, pos in pairs(target_pos_candidate) do
		local new_dist = vector_util.distance(npc.Position, pos)
		if closest_dist > new_dist then
			second_dist = closest_dist
			target_pos = closest_pos
			target_dir = closest_dir

			closest_dist = new_dist
			closest_pos = pos
			closest_dir = direction
		elseif second_dist > new_dist then
			second_dist = new_dist
			target_pos = pos
			target_dir = direction
		end
	end

	npc:SetAnimation("run", true)
	character_util.set_direction(npc, target_dir)
	self:npc_movement(npc, target_pos)
end

function local_class:npc_movement(npc, target_pos)
	local move_vector = vector_util.normalized(target_pos - npc.Position)
	local in_fade = false

	while true do
		if npc == nil then
			return
		end
		npc.Position =  npc.Position + move_vector * unity_class.time.deltaTime * 5
		local cur_move_vector = target_pos - npc.Position
		if cur_move_vector.x* move_vector.x + cur_move_vector.z * move_vector.z <= 0 then
			break
		end
		if not in_fade and vector_util.distance(npc.Position, target_pos) <= 2 then
			in_fade = true
			character_util.spine_set_alpha_fade(npc, 0, 0.4)
		end
		coroutine.yield(nil)
	end
	npc.Position = target_pos
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	if(self.npc_list ~= nil) then
		load_util.dispose_dynamic_npcs(self.npc_list)
	end


	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
