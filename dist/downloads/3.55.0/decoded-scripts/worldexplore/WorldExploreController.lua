--- 월드 탐험 게임 컨트롤러
local local_class = newclass("WorldExploreController")

function local_class:init(cs_controller, scene)
	self.constants = require('worldexplore/WorldExploreConstants')

	self.current_phase = self.constants.phases.none
	self.game_ended = false
	self.has_custom_ending = false

	self.refPlaneXZ = CS.UnityEngine.Plane(vector(0, 1, 0), 0)

	self.inactive_color = unity_class.color(0.3, 0.3, 0.3, 1)

	self.exit_directions = {}
	self.exit_directions[1] = CS.UnityEngine.Vector2Int(1, 0)
	self.exit_directions[2] = CS.UnityEngine.Vector2Int(0, 1)
	self.exit_directions[3] = CS.UnityEngine.Vector2Int(-1, 0)
	self.exit_directions[4] = CS.UnityEngine.Vector2Int(0, -1)

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), "on_manual_battle_group_destroyed")
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent), "on_manual_game_over")

	if self.narration_box ~= nil then
		CS.Utils.SafeDestroy(self.narration_box)
	end

	self.game_ended = true
	self.hero_units = nil
	self.boss_units = nil
	self.boss_unit_infos = nil
	self.boss_original_positions = nil
	self.boss_original_directions = nil
	self.enemy_unit_infos = nil
	self.normal_battle_popup_hero_swordmen = nil
	self.normal_battle_popup_hero_riflemen = nil
	self.normal_battle_popup_hero_shieldmen = nil
	self.normal_battle_popup_enemy_swordmen = nil
	self.normal_battle_popup_enemy_riflemen = nil
	self.normal_battle_popup_enemy_shieldmen = nil

	for i = 0, self.resource_mines.Count - 1 do
		if self.flags[self.resource_mines[i].Name] ~= nil then
			self.flags[self.resource_mines[i].Name]:Dispose()
		end
	end

	for i = 0, self.towns.Count - 1 do
		if self.flags[self.towns[i].Name] ~= nil then
			self.flags[self.towns[i].Name]:Dispose()
		end
	end
	self.flags = nil

	if self.camera_effect ~= nil then
		self.camera_effect:Dispose()
		self.camera_effect = nil
	end

	self.resource_mines:Dispose()
	self.resource_mines = nil
	self.towns:Dispose()
	self.towns = nil

	self.clear_stage_ui = nil
	self.game_over_ui = nil

	self.res_holder:Dispose()
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self.current_turn = -1
		self.turn_limit = stage.Spec.TurnLimit
		self.current_gold = 0
		self.current_wood = 0
		self.current_stone = 0
		self.gold_per_turn = 0
		self.wood_per_turn = 0
		self.stone_per_turn = 0
		self.current_enemy_gold = 0
		self.current_enemy_wood = 0
		self.current_enemy_stone = 0
		self.current_dropped_resource = 0
		self.resource_mines = field:GetFieldObjectsWithBehaviour(typeof(CS.Oak.WorldExploreResourceMineBehaviour))
		self.towns = field:GetFieldObjectsWithBehaviour(typeof(CS.Oak.WorldExploreTownBehaviour))
		self.town_trained = create_generic_list(CS.System.Int32)
		for i = 0, self.towns.Count - 1 do
			self.town_trained:Add(0)
		end

		self.flags = {}
		self.objective = stage.Spec.StageObjective
		self:load_units()
		self:initialize_ui()

		if self.objective == "world_explore_defeat_leader" and self.boss_leader_index == nil then
			CS.UnityEngine.Debug.LogError("Can't find leader in the stage")
			self.boss_leader_index = 0
		end

		stage.WorldStates:Add("controller", self)

		local camera_zone = stage.Field:GetZone("camera_bounds")
		if camera_zone ~= nil then
			local camera_bounds = camera_zone.Bounds
			local half_x = stage_camera.Camera.orthographicSize * stage_camera.Camera.aspect
			local half_z = stage_camera.Camera.orthographicSize
			self.camera_controller.ClampMax = vector(camera_bounds.max.x - half_x, camera_bounds.max.z - half_z)
			self.camera_controller.ClampMin = vector(camera_bounds.min.x + half_x, camera_bounds.min.z + half_z)
		end
	elseif event_type == typeof(CS.Oak.ItemGetEvent) then
		local updated_get_resource = false
		if e.Item.ItemId == CS.Oak.ItemSpecId.WorldExploreGold then
			self.current_gold = self.current_gold + e.Item.Amount
			updated_get_resource = true
		elseif e.Item.ItemId == CS.Oak.ItemSpecId.WorldExploreWood then
			self.current_wood = self.current_wood + e.Item.Amount
			updated_get_resource = true
		elseif e.Item.ItemId == CS.Oak.ItemSpecId.WorldExploreStone then
			self.current_stone = self.current_stone + e.Item.Amount
			updated_get_resource = true
		end

		if updated_get_resource then
			self.current_dropped_resource = self.current_dropped_resource - 1
			self:set_resources()
		end
	end
	return false
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

--- Load data here
function local_class:stage_load_resource()
	-- 오브젝트 풀
	unity_object_pool.GetOrCreate("world_explore_tile_icon")
	unity_object_pool.GetOrCreate("world_explore_army")
	unity_object_pool.GetOrCreate("world_explore_tile_cursor")
	unity_object_pool.GetOrCreate("world_explore_player_flag")
	unity_object_pool.GetOrCreate("world_explore_enemy_flag")
	unity_object_pool.GetOrCreate("world_explore_notice")
	unity_object_pool.GetOrCreate("world_explore_boss")
	unity_object_pool.GetOrCreate("fx_worldexplore_enemy_dead")
	unity_object_pool.GetOrCreate('FX_Event_InvaderBeam')
	unity_object_pool.GetOrCreate("FX_Common_CannonFire")

	-- FIXME: 월드 탐험 스펙에 스크린 이펙트를 더해야 한다
	local pool_name = nil
	if stage.Name == "worldexplore_stage_1" or stage.Name == "worldexplore_stage_3" or stage.Name == "worldexplore_stage_4" or stage.Name == "worldexplore_stage_6" or stage.Name == "worldexplore_stage_7" then
		pool_name = "fx_worldexplore_screenfx_forest_dust"
	elseif 	stage.Name == "worldexplore_stage_2" or stage.Name == "worldexplore_stage_5" or stage.Name == "worldexplore_stage_8" or stage.Name == "worldexplore_stage_9" then
		pool_name = "fx_worldexplore_screenfx_lava_spark"
	end

	self.army_hit_pool = unity_object_pool.GetOrCreate("FX_hit_small")

	if pool_name ~= nil then
		self.camera_effect_pool = unity_object_pool.GetOrCreate(pool_name)
	end

	--music_player:PreloadSfx('01_ui_grid_01')

	CS.Oak.CommonScreenplay.PreloadStageTitle()

	music_player_util.set_stage_music_clip_async({ name = "ondemand/worldexplore/audio:bgm_worldexplore_field", state = 'field' })

	-- NGUI / FieldUI 어셋 로드
	if self.res_holder == nil then
		self.res_holder = CS.Foundations.ResourceHolder()

		-- NGUI
		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreStageInfoPopUp"), function(p)
			local menuObj = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
			local overlay = menuObj:GetComponent(typeof(CS.Oak.UI.IUIOverlay))
			overlay.UISceneManager = stage.UISceneManager
			menuObj:SetActive(false)
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreBossBattlePopUp"), function(p)
			local menuObj = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
			local overlay = menuObj:GetComponent(typeof(CS.Oak.UI.IUIOverlay))
			overlay.UISceneManager = stage.UISceneManager
			menuObj:SetActive(false)
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreNormalBattlePopUp"), function(p)
			local menuObj = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
			local overlay = menuObj:GetComponent(typeof(CS.Oak.UI.IUIOverlay))
			overlay.UISceneManager = stage.UISceneManager
			menuObj:SetActive(false)

			local t = menuObj.transform
			local my_soldiers = t:Find("My Unit Info/Soldiers")
			self.normal_battle_popup_hero_swordmen = my_soldiers:Find("Swordmen").gameObject
			self.normal_battle_popup_hero_riflemen = my_soldiers:Find("Riflemen").gameObject
			self.normal_battle_popup_hero_shieldmen = my_soldiers:Find("Shieldmen").gameObject
			local enemy_soldiers = t:Find("Enemy Unit Info/Soldiers")
			self.normal_battle_popup_enemy_swordmen = enemy_soldiers:Find("Swordmen").gameObject
			self.normal_battle_popup_enemy_riflemen = enemy_soldiers:Find("Riflemen").gameObject
			self.normal_battle_popup_enemy_shieldmen = enemy_soldiers:Find("Shieldmen").gameObject
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreTownInfoPopUp"), function(p)
			local menuObj = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
			local overlay = menuObj:GetComponent(typeof(CS.Oak.UI.IUIOverlay))
			overlay.UISceneManager = stage.UISceneManager
			menuObj:SetActive(false)
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreStageCameraController"), function(p)
			local obj = CS.UnityEngine.GameObject.Instantiate(p, CS.Oak.Stage.Instance.StageTransform)
			self.camera_controller = obj:GetComponent(typeof(CS.Oak.StageTouchCamera))
			self.camera_controller:DeactivateTouch()
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreStageClear"), function(p)
			self.clear_stage_ui = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
			self.clear_stage_ui:SetActive(false)
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreStageGameOver"), function(p)
			self.game_over_ui = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
			self.game_over_ui:SetActive(false)
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreMyTurnStart"), function(p)
			self.player_turn_start_ui = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
			self.player_turn_start_ui:SetActive(false)
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/worldexplore/ui", "WorldExploreEnemyTurnStart"), function(p)
			self.enemy_turn_start_ui = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
			self.enemy_turn_start_ui:SetActive(false)
		end))

		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ui/common", "FieldUINarrationBox"), function(p)
			self.narration_box = CS.UnityEngine.GameObject.Instantiate(p):GetComponent(typeof(CS.Oak.FieldUINarrationBox))
		end))

		-- 공룡
		coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("characters/vehicle_dino", "vehicle_dino"), function(p)
			self.dinos = {}
			self.dino_ride = {}
			for i = 1, stage.Spec.PartyCount  do
				local go = CS.UnityEngine.GameObject.Instantiate(p)
				local spine = go:GetComponent(typeof(CS.Oak.SpineController))
				self.dinos[i] = spine
				self.dino_ride[i] = false
				spine:SetAnimation(0, "idle", true)
				spine.Direction = CS.Oak.Direction.Right
				spine.transform.position = vector(999, 0, 999)
				spine.transform.localScale = vector(0.7, 0.7, 0.7)
				spine.IsShadowActive = false
			end
		end))

	end
end

function local_class:load_units()
	-- 유저 파티를 읽어온다.
	self.hero_units = {}
	self.hero_unit_positions = {}
	self.hero_unit_armies = {}
	self.hero_unit_actives = {}
	self.boss_units = {}
	self.boss_unit_infos = {}
	self.boss_unit_positions = {}
	self.boss_original_positions = {}
	self.boss_original_directions = {}
	self.boss_unit_actives = {}
	self.enemy_unit_infos = {}
	self.enemy_unit_positions = {}
	self.enemy_unit_armies = {}
	self.enemy_unit_max_hps = {}
	self.max_party_index = 0
	self.boss_leader_index = nil

	local tilemap_transform = field.Tilemap.transform:Find("units")
	local hero_placeholders = tilemap_transform:GetComponentsInChildren(typeof(CS.Oak.WorldExploreHeroUnitPlaceholder))

	if hero_placeholders ~= nil and hero_placeholders.Length > 0 then
		for i = 0, hero_placeholders.Length - 1 do
			local p = hero_placeholders[i]
			local t = p.transform
			local leader = get_character(string.format("explorer_party_%d_%d", p.PartyIndex, 0))

			if p.PartyIndex < 0 or p.PartyIndex >= stage.Spec.PartyCount then
				CS.UnityEngine.Debug.LogError("Invalid party index")
			elseif leader ~= nil then
				local hero_list = create_generic_list(typeof(CS.Oak.ICharacter))
				local numMembers = CS.Oak.UserMerch.Me.Parties[p.PartyIndex].Count
				for j = 0, numMembers - 1 do
					local c = get_character(string.format("explorer_party_%d_%d", p.PartyIndex, j))
					if c == nil then
						CS.UnityEngine.Debug.LogError(string.format("Failed to load explorer_party_%d_%d", p.PartyIndex, j))
					else
						hero_list:Add(c)
					end
				end

				if self.hero_units[p.PartyIndex + 1] ~= nil then
					CS.UnityEngine.Debug.LogError(string.format("Duplicate party index %d", p.PartyIndex))
				else
					self.hero_units[p.PartyIndex + 1] = hero_list
					self.hero_unit_actives[p.PartyIndex + 1] = true
					self.hero_unit_armies[p.PartyIndex + 1] = create_generic_list(typeof(CS.Oak.PooledUnityObject))

					local unit = CS.Oak.WorldExploreStageUnit(p.PartyIndex, string.format("party_%d", p.PartyIndex), CS.Oak.WorldExploreStageFaction.Player)
					unit.X = CS.UnityEngine.Mathf.RoundToInt(t.position.x)
					unit.Z = CS.UnityEngine.Mathf.RoundToInt(t.position.z)
					unit.SizeX = 1;
					unit.SizeZ = 1;
					unit.NumSwordmen = p.InitialSwordmen
					unit.NumRiflemen = p.InitialRiflemen
					unit.NumShieldmen = p.InitialShieldmen
					unit.Direction = p.Direction
					stage.Units:Add(unit)

					if self.max_party_index < p.PartyIndex + 1 then
						self.max_party_index = p.PartyIndex + 1
					end

					self:update_army(unit)
					self:set_dino_ride(unit, true)
					self:set_unit_on_field(unit, vector(unit.X, 0, unit.Z), unit.Direction)
				end
			end
		end
	end

	local boss_placeholders = tilemap_transform:GetComponentsInChildren(typeof(CS.Oak.WorldExploreEnemyBossUnitPlaceholder))
	if boss_placeholders ~= nil and boss_placeholders.Length > 0 then
		for i = 0, boss_placeholders.Length - 1 do
			local p = boss_placeholders[i]
			local t = p.transform
			local c = get_character(p.LeaderName)
			c.FieldObjectController.DontFight = true
			self.boss_units[i + 1] = c
			self.boss_original_positions[i + 1] = c.Position
			self.boss_original_directions[i + 1] = c.Direction
			self.boss_unit_infos[i + 1] = p
			self.boss_unit_actives[i + 1] = true
			self.boss_icon = nil

			if t.name == "boss_unit_leader" then
				self.boss_leader_index = i
			end

			local unit = CS.Oak.WorldExploreStageUnit(i, t.name, CS.Oak.WorldExploreStageFaction.Enemy)
			unit.X = CS.UnityEngine.Mathf.RoundToInt(t.position.x)
			unit.Z = CS.UnityEngine.Mathf.RoundToInt(t.position.z)
			unit.SizeX = CS.UnityEngine.Mathf.RoundToInt(p.Size.x)
			unit.SizeZ = CS.UnityEngine.Mathf.RoundToInt(p.Size.y)
			unit.Direction = p.Direction
			unit.IsBoss = true
			stage.Units:Add(unit)

			self:set_unit_on_field(unit, vector(unit.X, 0, unit.Z), unit.Direction)
		end

		self:set_boss_icon()
	end

	local army_placeholders = tilemap_transform:GetComponentsInChildren(typeof(CS.Oak.WorldExploreEnemyArmyUnitPlaceholder))
	if army_placeholders ~= nil and army_placeholders.Length > 0 then
		for i = 0, army_placeholders.Length - 1 do
			local p = army_placeholders[i]
			local t = p.transform

			self.enemy_unit_infos[i + 1] = p
			self.enemy_unit_armies[i + 1] = create_generic_list(typeof(CS.Oak.PooledUnityObject))
			local hp = p.InitialSwordmen + p.InitialRiflemen + p.InitialShieldmen
			self.enemy_unit_max_hps[i + 1] = hp

			local unit = CS.Oak.WorldExploreStageUnit(i, t.name, CS.Oak.WorldExploreStageFaction.Enemy)
			unit.X = CS.UnityEngine.Mathf.RoundToInt(t.position.x)
			unit.Z = CS.UnityEngine.Mathf.RoundToInt(t.position.z)
			unit.SizeX = 1
			unit.SizeZ = 1
			unit.NumSwordmen = p.InitialSwordmen
			unit.NumRiflemen = p.InitialRiflemen
			unit.NumShieldmen = p.InitialShieldmen
			unit.Direction = p.Direction
			unit.IsBoss = false
			stage.Units:Add(unit)

			self:update_army(unit)
			self:set_unit_on_field(unit, vector(unit.X, 0, unit.Z), unit.Direction)
		end
	end
end

function local_class:initialize_ui()
	local ui = CS.Oak.UI.WorldExploreFieldUI.Instance
	self.field_ui = ui

	ui:ShowActionPanel(false)
	ui:ShowRightList(false)
	ui:ShowEndTurn(false)
	ui:HideUnitTileInfo()
	ui:ShowTurn(true)

	local actionCb = function (ok)
		if self.current_phase ~= self.constants.phases.hero_turn_unit_move_range then
			return
		end

		if ok then
			self.action_panel_ok_clicked = true
			self.action_panel_cancel_clicked = false
		else
			self.action_panel_ok_clicked = false
			self.action_panel_cancel_clicked = true
		end

		ui:ShowActionPanel(false)
	end

	local rightUnitCb = function (index)
		if self.current_phase ~= self.constants.phases.hero_turn then
			if self.current_phase == self.constants.phases.hero_turn_unit_move_range then
				local unit = self:get_hero_unit_from_stage(index)
				if unit.Destroyed or unit.MoveEnded then
					return
				end

				self.tile_tap_player_index = index
				self.tile_tap = self.constants.tap_types.change_player_with_focus
			end
			return
		end

		local unit = self:get_hero_unit_from_stage(index)
		if unit.Destroyed or unit.MoveEnded then
			return
		end
		self.current_phase = self.constants.phases.focusing_hero
		self.hero_to_focus = index
	end

	local endTurnCb = function ()
		if self.current_phase ~= self.constants.phases.hero_turn then
			return
		end

		local units = stage.Units
		for i = 0, units.Count -1 do
			if units[i].Faction == CS.Oak.WorldExploreStageFaction.Player then
				units[i].MoveEnded = true
			end
		end

		self.current_phase = self.constants.phases.hero_turn_end
	end

	ui:SetCallbacks(actionCb, endTurnCb, rightUnitCb)

	self:set_right_units()
	self:set_resources()
	self:set_turn()

	ui:SetPauseButtonIcon(true)
end

function local_class:set_resources()
	local ui = self.field_ui

	local gold_per_turn = 0
	local stone_per_turn = 0
	local wood_per_turn = 0

	for i = 0, self.resource_mines.Count - 1 do
		local m = self.resource_mines[i].FieldObjectBehaviour
		if m.Faction == CS.Oak.WorldExploreStageFaction.Player then
			if m.Resource == CS.Oak.WorldExploreStageResource.Gold then
				gold_per_turn = gold_per_turn + m.Productivity
			elseif m.Resource == CS.Oak.WorldExploreStageResource.Wood then
				wood_per_turn = wood_per_turn + m.Productivity
			elseif m.Resource == CS.Oak.WorldExploreStageResource.Stone then
				stone_per_turn = stone_per_turn + m.Productivity
			end
		end
	end

	for i = 0, self.towns.Count - 1 do
		local t = self.towns[i].FieldObjectBehaviour
		if t.Faction == CS.Oak.WorldExploreStageFaction.Player then
			gold_per_turn = gold_per_turn + self.constants.town_productions[t.Level + 1]
		end
	end

	self.gold_per_turn = gold_per_turn
	self.wood_per_turn = wood_per_turn
	self.stone_per_turn = stone_per_turn

	ui:SetGold(self.current_gold, self.gold_per_turn)
	ui:SetWood(self.current_wood, self.wood_per_turn)
	ui:SetStone(self.current_stone, self.stone_per_turn)
end

function local_class:refresh_town_info(hero_unit, town_fo)

	if hero_unit == nil or town_fo == nil then
		return
	end

	local town = town_fo.FieldObjectBehaviour
	local ui = CS.Oak.UI.WorldExploreTownInfoPopup.Instance
	local c = self.hero_units[hero_unit.Index + 1][0]
	local csb = c.FieldObjectStatsBehaviour
	local sprite_name = c.SpriteName
	local town_index = self.towns:IndexOf(town_fo)

	ui:SetTownInfo("world_explore_town_level", town.Level, self.constants.town_productions[town.Level + 1], sprite_name, csb.CharacterSpec.NameWithoutRank)
	ui:SetVisitingUnitInfo(sprite_name, csb.CharacterSpec.NameWithoutRank, csb.Level, true, hero_unit.NumSwordmen, hero_unit.NumShieldmen, hero_unit.NumRiflemen)

	local gold_cost = 0
	local wood_cost = 0
	local stone_cost = 0
	local cost_obj = nil

	if town.Level < #self.constants.town_levelup_costs then
		cost_obj = self.constants.town_levelup_costs[town.Level + 1]

		if cost_obj['gold'] ~= nil then
			gold_cost = cost_obj['gold']
		end

		if cost_obj['wood'] ~= nil then
			wood_cost = cost_obj['wood']
		end

		if cost_obj['stone'] ~= nil then
			stone_cost = cost_obj['stone']
		end
	end

	ui:SetTownLevelUp(town.Level == #self.constants.town_productions - 1, gold_cost, self.current_gold >= gold_cost,
			wood_cost, self.current_wood >= wood_cost, stone_cost, self.current_stone >= stone_cost)

	for i = 0, 2 do
		if i == 0 then
			cost_obj = self.constants.town_swordmen_costs[town.Level + 1]
		elseif i == 1 then
			cost_obj = self.constants.town_riflemen_costs[town.Level + 1]
		else
			cost_obj = self.constants.town_shieldmen_costs[town.Level + 1]
		end
		gold_cost = 0
		if cost_obj['gold'] ~= nil then
			gold_cost = cost_obj['gold']
		end
		wood_cost = 0
		if cost_obj['wood'] ~= nil then
			wood_cost = cost_obj['wood']
		end
		stone_cost = 0
		if cost_obj['stone'] ~= nil then
			stone_cost = cost_obj['stone']
		end

		if i == 0 then
			ui:SetSwordmenSlot(self.town_trained[town_index] > 0, cost_obj['amount'], gold_cost, self.current_gold >= gold_cost, wood_cost,
					self.current_wood >= wood_cost, stone_cost, self.current_stone >= stone_cost)
		elseif i == 1 then
			ui:SetRiflemenSlot(self.town_trained[town_index] > 0, cost_obj['amount'], gold_cost, self.current_gold >= gold_cost, wood_cost,
					self.current_wood >= wood_cost, stone_cost, self.current_stone >= stone_cost)
		else
			ui:SetShieldmenSlot(self.town_trained[town_index] > 0, cost_obj['amount'], gold_cost, self.current_gold >= gold_cost, wood_cost,
					self.current_wood >= wood_cost, stone_cost, self.current_stone >= stone_cost)
		end
	end

	-- FIXME: 루아에서 직접 수정하도록 해 뒀지만 나중에 씨샾으로 옮겨야 함
	if self.town_gold_label == nil then
		local contents = ui.transform:Find("TopBar")
		self.town_gold_label = contents:Find("Gold/Current"):GetComponent("UILabel")
		self.town_gold_turn_label = contents:Find("Gold/Turn"):GetComponent("UILabel")
		self.town_wood_label = contents:Find("Wood/Current"):GetComponent("UILabel")
		self.town_wood_turn_label = contents:Find("Wood/Turn"):GetComponent("UILabel")
		self.town_stone_label = contents:Find("Stone/Current"):GetComponent("UILabel")
		self.town_stone_turn_label = contents:Find("Stone/Turn"):GetComponent("UILabel")
	end

	self.town_gold_label.text = tostring(self.current_gold)
	self.town_gold_turn_label.text = CS.GameStrings.Instance:Format("world_explore_turn_income", self.gold_per_turn)
	self.town_wood_label.text = tostring(self.current_wood)
	self.town_wood_turn_label.text = CS.GameStrings.Instance:Format("world_explore_turn_income", self.wood_per_turn)
	self.town_stone_label.text = tostring(self.current_stone)
	self.town_stone_turn_label.text = CS.GameStrings.Instance:Format("world_explore_turn_income", self.stone_per_turn)
end

function local_class:use_gold(amount)
	self.current_gold = self.current_gold - amount
	if self.current_gold < 0 then
		self.current_gold = 0
	end
	self.field_ui:SetGold(self.current_gold, self.gold_per_turn)
end

function local_class:use_wood(amount)
	self.current_wood = self.current_wood - amount
	if self.current_wood < 0 then
		self.current_wood = 0
	end
	self.field_ui:SetWood(self.current_wood, self.wood_per_turn)
end

function local_class:use_stone(amount)
	self.current_stone = self.current_stone - amount
	if self.current_stone < 0 then
		self.current_stone = 0
	end
	self.field_ui:SetStone(self.current_stone, self.stone_per_turn)
end

function local_class:set_turn()
	self.field_ui:SetTurn(self.current_turn + 1, self.turn_limit)
end

function local_class:set_right_units()
	local ui = self.field_ui
	local unit = nil
	local csb = nil
	local ratio = 0
	local walker = 0

	if self.hero_units[1] ~= nil then
		unit = self:get_hero_unit_from_stage(0)
		csb = self.hero_units[1][0].FieldObjectStatsBehaviour
		ratio = csb.HP / csb.MaxHP
		ui:SetHero1(self.hero_units[1][0].SpriteName, ratio, csb.Level, unit.MoveEnded, unit.Destroyed)
		walker = walker + 1
	else
		ui:SetHero1(nil, 0, 0, false, false)
	end

	if self.hero_units[2] ~= nil then
		unit = self:get_hero_unit_from_stage(1)
		csb = self.hero_units[2][0].FieldObjectStatsBehaviour
		ratio = csb.HP / csb.MaxHP
		ui:SetHero2(self.hero_units[2][0].SpriteName, ratio, csb.Level, unit.MoveEnded, unit.Destroyed)
		walker = walker + 1
	else
		ui:SetHero2(nil, 0, 0, false, false)
	end

	if self.hero_units[3] ~= nil then
		unit = self:get_hero_unit_from_stage(2)
		csb = self.hero_units[3][0].FieldObjectStatsBehaviour
		ratio = csb.HP / csb.MaxHP
		ui:SetHero3(self.hero_units[3][0].SpriteName, ratio, csb.Level, unit.MoveEnded, unit.Destroyed)
		walker = walker + 1
	else
		ui:SetHero3(nil, 0, 0, false, false)
	end
end

function local_class:clear_range_tiles()
	if self.range_tiles == nil then
		return
	end

	for i = 0, self.range_tiles.Count - 1 do
		self.range_tiles[i]:Dispose()
	end
	self.range_tiles:Clear()
	if self.cursor ~= nil then
		self.cursor:Dispose()
		self.cursor = nil
	end
end

function local_class:touch_handler()
	self.touch_started = false
	local current_platform = CS.UnityEngine.Application.platform
	local use_touch_emulation = CS.UnityEngine.Application.isEditor
			or current_platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer
			or current_platform == CS.UnityEngine.RuntimePlatform.OSXPlayer
			or CS.Oak.InputManager.IsPC

	while not self.game_ended do

		local emulatedTouch = nil;

		if use_touch_emulation then
			if CS.UnityEngine.Input.GetMouseButtonDown(0) or CS.UnityEngine.Input.GetMouseButtonUp(0) then
				emulatedTouch = CS.UnityEngine.Touch()
				emulatedTouch.fingerId = 10;
				local p = CS.UnityEngine.Input.mousePosition
				emulatedTouch.position = vector(p.x, p.y)
				if CS.UnityEngine.Input.GetMouseButtonDown(0) then
					emulatedTouch.phase = CS.UnityEngine.TouchPhase.Began
				else
					emulatedTouch.phase = CS.UnityEngine.TouchPhase.Ended
				end
			end
		end

		local touchCount = 0
		if emulatedTouch ~= nil then
			touchCount = 1
		else
			touchCount = CS.UnityEngine.Input.touchCount
		end

		for i = 0, touchCount - 1 do
			local touch = nil

			if emulatedTouch ~= nil then
				touch = emulatedTouch
			else
				touch = CS.UnityEngine.Input.GetTouch(i)
			end

			if touch.phase == CS.UnityEngine.TouchPhase.Began then
				if not CS.UICamera.Raycast(vector(touch.position.x, touch.position.y, 0)) then
					self.touch_started = true
					self.touch_pos = touch.position
				end
			elseif touch.phase == CS.UnityEngine.TouchPhase.Ended then
				if self.touch_started then
					self:on_tap(touch.position, self.touch_pos)
				end
				self.touch_started = false
			end
		end


		coroutine.yield(nil)
	end
end

function local_class:on_tap(touch_pos, touch_start_pos)
	if self.current_phase ~= self.constants.phases.hero_turn and
			self.current_phase ~= self.constants.phases.hero_turn_unit_move_range and
			self.current_phase ~= self.constants.phases.town_visit then
		return
	end

	-- UI 버튼 등에 터치가 생길 경우 제어 안하게 막음
	if CS.UICamera.Raycast(vector(touch_pos.x, touch_pos.y, 0)) then
		return
	end

	local r = stage.StageCamera.Camera:ScreenPointToRay(vector(touch_pos.x, touch_pos.y, 0))
	local hit_pos = r.origin - r.direction * (r.origin.y / r.direction.y)

	local r_start = stage.StageCamera.Camera:ScreenPointToRay(vector(touch_start_pos.x, touch_start_pos.y, 0))
	local hit_pos_start = r_start.origin - r_start.direction * (r_start.origin.y / r_start.direction.y)

	local legit_hit = false
	if CS.UnityEngine.Mathf.RoundToInt(hit_pos.x) == CS.UnityEngine.Mathf.RoundToInt(hit_pos_start.x) and CS.UnityEngine.Mathf.RoundToInt(hit_pos.z) == CS.UnityEngine.Mathf.RoundToInt(hit_pos_start.z) then
		legit_hit = true
	end

	if not legit_hit then
		return
	end

	if self.current_phase == self.constants.phases.hero_turn then
		local unit = self:get_unit_at(hit_pos)
		if unit ~= nil then
			if unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
				if not unit.Destroyed then
					music_player:PlaySfxOneShot("01_button_07")
					self:show_unit_info(unit)
					self:preview_move_range(unit)
				end
			elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
				self:show_unit_info(unit)
			elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
				if not unit.MoveEnded and not unit.Destroyed then
					self.tile_tap_player_index = unit.Index
					self.tile_tap = self.constants.tap_types.active_player
				elseif not unit.Destroyed then
					local fo = self:get_field_object_at(hit_pos)
					if fo ~= nil and fo.FieldObjectBehaviour ~= nil and fo.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreTownBehaviour) then
						self.tile_tap = self.constants.tap_types.inactive_town_player
						self.tile_tap_player_index = unit.Index
					else
						music_player:PlaySfxOneShot("01_button_07")
						self:show_unit_info(unit)
						self:preview_move_range(unit)
					end
				end
			elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Neutral then
				self:trigger_npc_oneline(unit.Index)
				self:clear_range_tiles()
			end
		else
			CS.Oak.UI.WorldExploreFieldUI.Instance:HideUnitTileInfo()
			self:clear_range_tiles()
		end
	elseif self.current_phase == self.constants.phases.hero_turn_unit_move_range then
		local hp = CS.UnityEngine.Vector2Int()
		hp.x = CS.UnityEngine.Mathf.RoundToInt(hit_pos.x)
		hp.y = CS.UnityEngine.Mathf.RoundToInt(hit_pos.z)

		if self.range_search_result:Contains(hp) then
			-- 파란 타일 클릭
			local unit_at = self:get_unit_at(vector(hp.x, 0, hp.y))
			if unit_at == nil or unit_at.Index == self.tile_tap_player_index then
				self.tile_tap = self.constants.tap_types.range_blue_tap
				self.tile_tap_pos = hp
			elseif unit_at ~= nil and unit_at.Faction == CS.Oak.WorldExploreStageFaction.Player and not unit_at.Destroyed and not unit_at.MoveEnded then
				self.tile_tap = self.constants.tap_types.change_player
				self.tile_tap_player_index = unit_at.Index
			end
		elseif self.range_search_boundaries:Contains(hp) then
			local index = self.range_search_boundaries:IndexOf(hp)
			local interaction = self.range_search_interactables[index]

			if interaction ~= self.constants.interactions.stay then
				-- 붉은 타일 위 상호 작용 오브젝트 탭
				self.tile_tap = self.constants.tap_types.range_interactable_tap
				self.tile_tap_pos = hp
			else
				local unit_at = self:get_unit_at(vector(hp.x, 0, hp.y))
				if unit_at ~= nil and unit_at.Faction == CS.Oak.WorldExploreStageFaction.Player and not unit_at.Destroyed and not unit_at.MoveEnded then
					self.tile_tap = self.constants.tap_types.change_player
					self.tile_tap_player_index = unit_at.Index
				else
					if unit_at ~= nil and unit_at.Faction == CS.Oak.WorldExploreStageFaction.Neutral then
						self:trigger_npc_oneline(unit_at.Index)
					else
						self.tile_tap = self.constants.tap_types.empty_tap
					end
				end
			end
		else
			local unit_at = self:get_unit_at(vector(hp.x, 0, hp.y))
			if unit_at ~= nil and unit_at.Faction == CS.Oak.WorldExploreStageFaction.Player and not unit_at.Destroyed and not unit_at.MoveEnded then
				self.tile_tap = self.constants.tap_types.change_player
				self.tile_tap_player_index = unit_at.Index
			else
				self.tile_tap = self.constants.tap_types.empty_tap
			end
		end
	elseif self.current_phase == self.constants.phases.town_visit then
		if CS.Oak.UI.WorldExploreTownInfoPopup.Instance.IsViewingMap then
			local unit = self:get_unit_at(hit_pos)
			local hit = false
			if unit ~= nil then
				if unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy or unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
					if not unit.Destroyed then
						music_player:PlaySfxOneShot("01_button_07")
						self:show_unit_info(unit)
						self:preview_move_range(unit)
						hit = true
					end
				end
			end

			if not hit then
				CS.Oak.UI.WorldExploreFieldUI.Instance:HideUnitTileInfo()
				self:clear_range_tiles()
			end
		end
	end
end

function local_class:get_field_object_at(hit_pos)
	hit_pos.x = CS.UnityEngine.Mathf.RoundToInt(hit_pos.x)
	hit_pos.z = CS.UnityEngine.Mathf.RoundToInt(hit_pos.z)

	local list = field:GetFieldObjectsInRadius(hit_pos, 0.1)
	local res = nil

	for i = 0, list.Count - 1 do
		local t = list[i].FieldObjectBehaviour:GetType()
		if t == typeof(CS.Oak.TreasureBehaviour) then
			res = list[i]
			break
		elseif t == typeof(CS.Oak.WorldExploreDoorBehaviour) then
			res = list[i]
			break
		elseif t == typeof(CS.Oak.WorldExploreSwitchBehaviour) then
			res = list[i]
			break
		elseif t == typeof(CS.Oak.WorldExploreBreakableBehaviour) then
			res = list[i]
			break
		elseif t == typeof(CS.Oak.WorldExploreTownBehaviour) then
			res = list[i]
			break
		elseif t == typeof(CS.Oak.WorldExploreResourceMineBehaviour) then
			res = list[i]
			break
		elseif t == typeof(CS.Oak.WorldExploreExitBehaviour) then
			res = list[i]
			break
		else
			if list[i].CrashBehaviour:GetType() == typeof(CS.Oak.WallCrashBehaviour) then
				res = list[i]
			end
		end
	end

	list:Dispose()
	return res
end

function local_class:is_there_bridge_at(hit_pos)
	hit_pos.x = CS.UnityEngine.Mathf.RoundToInt(hit_pos.x)
	hit_pos.z = CS.UnityEngine.Mathf.RoundToInt(hit_pos.z)

	local list = field:GetFieldObjectsInRadius(hit_pos, 0.1)
	local res = false

	-- FIXME: 일단 EthrealCrashBehaviour 면 무조건 다리로 취급한다..
	for i = 0, list.Count - 1 do
		if list[i].CrashBehaviour:GetType() == typeof(CS.Oak.EtherealCrashBehaviour) then
			res = true
		end
	end

	list:Dispose()
	return res
end

function local_class:get_unit_at(hit_pos)
	local x = CS.UnityEngine.Mathf.RoundToInt(hit_pos.x)
	local z = CS.UnityEngine.Mathf.RoundToInt(hit_pos.z)

	local units = stage.Units
	local unit = nil
	for i = 0, units.Count- 1 do
		if not units[i].Destroyed then
			if units[i].X == x and units[i].Z == z then
				if not units[i].Destroyed then
					unit = units[i]
					break
				end

			end
		end
	end

	return unit
end

function local_class:show_unit_info(unit)
	local sprite_name = nil
	local unit_name = nil
	local level = 0
	local current_hp = 100
	local max_hp = 100
	local is_player = true
	local num_swordmen = unit.NumSwordmen
	local num_shieldmen = unit.NumShieldmen
	local num_riflemen = unit.NumRiflemen

	if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
		local c = self.hero_units[unit.Index + 1][0]
		local csb = c.FieldObjectStatsBehaviour

		sprite_name = csb.CharacterSpec.SpriteAssetName.assetName
		unit_name = game_string:GetString(csb.CharacterSpec.NameWithoutRank)
		level = csb.Level
		current_hp = csb.HP
		max_hp = csb.MaxHP

		CS.Oak.UI.WorldExploreFieldUI.Instance:ShowUnitInfo(c.SpriteName, unit_name, level, current_hp, max_hp, is_player, num_swordmen, num_shieldmen, num_riflemen)
		CS.Oak.UI.WorldExploreFieldUI.Instance:SetMarker(unit.Index)
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
		CS.Oak.UI.WorldExploreFieldUI.Instance:SetMarker(-1)

		if unit.IsBoss then
			local c = self.boss_units[unit.Index + 1]
			local csb = c.FieldObjectStatsBehaviour

			sprite_name = csb.CharacterSpec.SpriteAssetName.assetName
			unit_name = game_string:GetString(csb.CharacterSpec.NameWithoutRank)
			level = csb.Level
			current_hp = csb.HP
			max_hp = csb.MaxHP

			local num_swordmen, num_riflemen, num_shieldmen = get_army_count_for(unit)
			CS.Oak.UI.WorldExploreFieldUI.Instance:ShowBossInfo(sprite_name, unit_name, level, current_hp, max_hp, self:get_buff_string(num_swordmen, num_riflemen, num_shieldmen))
		else
			sprite_name = "unknown_enemy"
			unit_name = game_string:Format("world_explore_invader_army", unit.Index + 1)
			level = self.enemy_unit_infos[unit.Index + 1].Level
			current_hp = (unit.NumSwordmen + unit.NumShieldmen + unit.NumRiflemen) * self.constants.army_to_display_hp
			max_hp = self.enemy_unit_max_hps[unit.Index + 1] * self.constants.army_to_display_hp
			is_player = false

			CS.Oak.UI.WorldExploreFieldUI.Instance:ShowUnitInfo(sprite_name, unit_name, level, current_hp, max_hp, is_player, num_swordmen, num_shieldmen, num_riflemen)
		end
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Neutral then
		CS.Oak.UI.WorldExploreFieldUI.Instance:SetMarker(-1)

		local c = self.npc_units[unit.Index + 1]
		local info = self.npc_infos[unit.Index + 1]
		local sprite_override = info['sprite']
		local csb = c.FieldObjectStatsBehaviour

		if sprite_override ~= nil then
			sprite_name = sprite_override
		else
			sprite_name = csb.CharacterSpec.SpriteAssetName.assetName
		end

		unit_name = game_string:GetString(csb.CharacterSpec.NameWithoutRank)
		level = csb.Level
		current_hp = csb.HP
		max_hp = csb.MaxHP

		CS.Oak.UI.WorldExploreFieldUI.Instance:ShowUnitInfo(sprite_name, unit_name, level, current_hp, max_hp, is_player, num_swordmen, num_shieldmen, num_riflemen)
	end
end

function local_class:set_unit_on_field(unit, pos, dir)
	if unit.Destroyed then
		return
	end

	if dir ~= CS.Oak.Direction.Left and dir ~= CS.Oak.Direction.Right then
		if dir == CS.Oak.Direction.Up then
			dir = CS.Oak.Direction.Right
		else
			dir = CS.Oak.Direction.Left
		end
	end

	unit.Direction = dir
	if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
		set_army_on_field(self.hero_unit_armies[unit.Index + 1], pos, dir, false)
		local c = self.hero_units[unit.Index + 1][0]
		c.Position = pos
		c.Direction = dir
		c.SpineController.Transform.localScale = vector(0.5, 0.5, 0.5)

		if self.dino_ride[unit.Index + 1] then
			local d = self.dinos[unit.Index + 1]
			d.transform.position = pos
			d.Direction = dir
		end

		self.hero_unit_positions[unit.Index + 1] = pos
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
		if unit.IsBoss then
			local c = self.boss_units[unit.Index + 1]
			local scaleX = 1.0 / c.Hitbox.size.x
			local scaleZ = 1.0 / c.Hitbox.size.z
			c.Position = pos
			c.Direction = dir
			c.SpineController.Transform.localScale = vector(1, 1, 1) * math.min(scaleX, scaleZ, 0.7)
			c.FieldObjectController.NoReturnFlag = true

			self.boss_unit_positions[unit.Index + 1] = pos
		else
			set_army_on_field(self.enemy_unit_armies[unit.Index + 1], pos, dir, true)
			self.enemy_unit_positions[unit.Index + 1] = pos
		end

	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Neutral then
		local c = self.npc_units[unit.Index + 1]
		c.Position = pos
		c.Direction = dir
		c.SpineController.Transform.localScale = vector(0.7, 0.7, 0.7)

		self.npc_unit_positions[unit.Index + 1] = pos
	end
end

function set_army_on_field(army_list, pos, dir, is_enemy)
	local num_rows = 0
	if army_list.Count > 6 then
		num_rows = 3
	elseif army_list.Count > 3 then
		num_rows = 2
	elseif army_list.Count > 0 then
		num_rows = 1
	end

	if num_rows == 0 then
		return
	end

	local major_axis = vector(1, 0, 0)
	local other_axis = vector(0, 0, 1)
	if dir == CS.Oak.Direction.Left then
		major_axis = vector(-1, 0, 0)
	end

	local offset = 0.3

	if is_enemy then
		if army_list.Count > 0 then
			army_list[0].transform.position = pos
		end

		if army_list.Count == 2 then
			army_list[1].transform.position = pos + major_axis * offset
		elseif army_list.Count == 3 then
			army_list[1].transform.position = pos + major_axis * offset
			army_list[2].transform.position = pos + other_axis * offset
		elseif army_list.Count == 4 then
			army_list[1].transform.position = pos + major_axis * offset
			army_list[2].transform.position = pos + other_axis * offset
			army_list[3].transform.position = pos - other_axis * offset
		elseif army_list.Count == 5 then
			army_list[1].transform.position = pos + major_axis * offset
			army_list[2].transform.position = pos + other_axis * offset
			army_list[3].transform.position = pos - other_axis * offset
			army_list[4].transform.position = pos - major_axis * offset
		elseif army_list.Count >= 6 then
			army_list[1].transform.position = pos + major_axis * offset
			army_list[2].transform.position = pos + major_axis * offset + other_axis * offset
			army_list[3].transform.position = pos + major_axis * offset - other_axis * offset
			army_list[4].transform.position = pos + other_axis * offset
			army_list[5].transform.position = pos - other_axis * offset

			if army_list.Count >= 7 then
				army_list[6].transform.position = pos - major_axis * offset
			end

			if army_list.Count >= 8 then
				army_list[7].transform.position = pos - major_axis * offset + other_axis * offset
			end

			if army_list.Count >= 9 then
				army_list[8].transform.position = pos - major_axis * offset - other_axis * offset
			end
		end

	else
		if army_list.Count == 1 then
			army_list[0].transform.position = pos + major_axis * offset
		elseif army_list.Count == 2 then
			army_list[0].transform.position = pos + major_axis * offset
			army_list[1].transform.position = pos + other_axis * offset
		elseif army_list.Count == 3 then
			army_list[0].transform.position = pos + major_axis * offset
			army_list[1].transform.position = pos + other_axis * offset
			army_list[2].transform.position = pos - other_axis * offset
		elseif army_list.Count == 4 then
			army_list[0].transform.position = pos + major_axis * offset
			army_list[1].transform.position = pos + other_axis * offset
			army_list[2].transform.position = pos - other_axis * offset
			army_list[3].transform.position = pos - major_axis * offset
		elseif army_list.Count >= 5 then
			army_list[0].transform.position = pos + major_axis * offset
			army_list[1].transform.position = pos + major_axis * offset + other_axis * offset
			army_list[2].transform.position = pos + major_axis * offset - other_axis * offset
			army_list[3].transform.position = pos + other_axis * offset
			army_list[4].transform.position = pos - other_axis * offset

			if army_list.Count >= 6 then
				army_list[5].transform.position = pos - major_axis * offset
			end

			if army_list.Count >= 7 then
				army_list[6].transform.position = pos - major_axis * offset + other_axis * offset
			end

			if army_list.Count >= 8 then
				army_list[7].transform.position = pos - major_axis * offset - other_axis * offset
			end
		end
	end

	for i = 0, army_list.Count - 1 do
		if dir == CS.Oak.Direction.Left then
			army_list[i].transform.localScale = vector(-1, 1, 1)
		else
			army_list[i].transform.localScale = vector(1, 1, 1)
		end
	end
end

function local_class:move_unit_on_field(unit, move_from, move_to, target_unit)
	local move_dir = nil

	if target_unit ~= nil then
		move_dir = get_direction(target_unit:GetFieldPosition() - move_from)
	else
		move_dir = 	get_direction(move_to - move_from)
	end

	local duration = (move_from - move_to).magnitude * self.constants.move_duration_per_tile
	if duration > self.constants.max_move_duration then
		duration = self.constants.max_move_duration
	end

	self:set_unit_run_animation(unit)

	local dash_sfx = nil
	if duration > 0.1 then
		dash_sfx = music_player_util.play_sfx({ sfx_name = '01_dash_01', parent = self.fo, type_priority = CS.Oak.SfxTypePriority.Loop, player_priority = CS.Oak.SfxPlayerPriority.Player })
	end

	local time_passed = 0
	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		self:set_unit_on_field(unit, CS.UnityEngine.Vector3.Lerp(move_from, move_to, time_passed / duration), move_dir)
		coroutine.yield(nil)
	end

	self:unset_unit_run_animation(unit)

	if dash_sfx ~= nil then
		dash_sfx:FadeOut(0.1)
	end

	self:set_unit_on_field(unit, move_to, move_dir)
end

function local_class:hide_unit(unit)
	if unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy and unit.IsBoss then
		self.boss_units[unit.Index + 1].ActiveState = CS.Oak.ActiveState.Disabled
	end
end

function local_class:reinforce_unit(unit)
	if unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy and unit.IsBoss then
		unity_object_pool.GetOrCreate('FX_Event_InvaderBeam'):Instantiate(unit:GetFieldPosition())
		music_player:PlaySfxOneShot("01_invader_beam_01")
		self.boss_units[unit.Index + 1].ActiveState = CS.Oak.ActiveState.Enabled
		self:set_unit_on_field(unit, unit:GetFieldPosition(), unit.Direction)
	end
end

function local_class:set_unit_run_animation(unit)
	local c = nil
	if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
		if self.dino_ride[unit.Index + 1] then
			self.dinos[unit.Index + 1]:SetAnimation(0, "run", true)
			return
		end

		c = self.hero_units[unit.Index + 1][0]
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy and unit.IsBoss then
		c = self.boss_units[unit.Index + 1]
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Neutral then
		c = self.npc_units[unit.Index + 1]
	end

	if c ~= nil then
		character_util.set_anim(c, { name = "run", loop = true })
	end
end

function local_class:unset_unit_run_animation(unit)
	local c = nil
	if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
		if self.dino_ride[unit.Index + 1] then
			self.dinos[unit.Index + 1]:SetAnimation(0, "idle", true)
			return
		end
		c = self.hero_units[unit.Index + 1][0]
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy and unit.IsBoss then
		c = self.boss_units[unit.Index + 1]
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Neutral then
		c = self.npc_units[unit.Index + 1]
	end

	if c ~= nil then
		character_util.remove_anim(c, false)
	end
end

function local_class:update_army(unit)
	if unit.IsBoss or unit.Destroyed then
		return
	end

	local max_display_army = 30.0
	local max_instances = 8
	if unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
		max_instances = 9
	end

	local divide_factor = 3.0

	local num_swords = unit.NumSwordmen
	local num_rifles = unit.NumRiflemen
	local num_shields = unit.NumShieldmen
	local total_army = num_swords + num_rifles + num_shields

	if total_army > max_display_army + constants.epsilon then
		num_swords = num_swords * (total_army / max_display_army)
		num_rifles = num_rifles * (total_army / max_display_army)
		num_shields = num_shields * (total_army / max_display_army)
	end

	local swords = 0
	local rifles = 0
	local shields = 0

	if num_swords > 10 then
		swords = CS.UnityEngine.Mathf.FloorToInt(num_swords / divide_factor)
	elseif num_swords > 6 then
		swords = 3
	elseif num_swords > 3 then
		swords = 2
	elseif num_swords > 0 then
		swords = 1
	end

	if num_rifles > 10 then
		rifles = CS.UnityEngine.Mathf.FloorToInt(num_rifles / divide_factor)
	elseif num_rifles > 6 then
		rifles = 3
	elseif num_rifles > 3 then
		rifles = 2
	elseif num_rifles > 0 then
		rifles = 1
	end

	if num_shields > 10 then
		shields = CS.UnityEngine.Mathf.FloorToInt(num_shields / divide_factor)
	elseif num_shields > 6 then
		shields = 3
	elseif num_shields > 3 then
		shields = 2
	elseif num_shields > 0 then
		shields = 1
	end

	while swords + rifles + shields > max_instances do
		local max_num = math.max(swords, rifles, shields)
		if math.abs(swords - max_num) <= constants.epsilon then
			swords = swords - 1
		elseif math.abs(rifles - max_num) <= constants.epsilon then
			rifles = rifles - 1
		elseif math.abs(shields - max_num) <= constants.epsilon then
			shields = shields - 1
		end
	end

	local army_list = nil
	if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
		army_list = self.hero_unit_armies[unit.Index + 1]
	else
		army_list = self.enemy_unit_armies[unit.Index + 1]
	end

	local orig_swords = 0
	local orig_rifles = 0
	local orig_shields = 0

	for i = 0, army_list.Count - 1 do
		local army = army_list[i]:GetComponent(typeof(CS.Oak.WorldExploreArmy))
		if army.Type == CS.Oak.WorldExploreStageArmy.Sword then
			orig_swords = orig_swords + 1
		elseif army.Type == CS.Oak.WorldExploreStageArmy.Rifle then
			orig_rifles = orig_rifles + 1
		elseif army.Type ==	CS.Oak.WorldExploreStageArmy.Shield then
			orig_shields = orig_shields + 1
		end
	end

	if swords == orig_swords and rifles == orig_rifles and shields == orig_shields then
		return
	end

	local total_display = swords + rifles + shields
	if army_list.Count < total_display then
		for i = 1, (total_display - army_list.Count) do
			army_list:Add(unity_object_pool.GetOrCreate("world_explore_army"):Instantiate(vector(999, 0, 999)))
		end
	elseif army_list.Count > total_display then
		while army_list.Count > total_display do
			local last_index = army_list.Count - 1
			army_list[last_index]:Dispose()
			army_list:RemoveAt(last_index)
		end
	end

	local walker = 0
	local size = 0.0125
	local half_height = 0.125
	local leader_modifier = 1.5

	for i = 0, shields - 1 do
		local army = army_list[walker + i]:GetComponent(typeof(CS.Oak.WorldExploreArmy))
		local sprite = nil
		local size_modifier = 1
		if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
			sprite = "shieldmen"
		else
			sprite = "invader_shieldmen"
			if walker == 0 and i == 0 then
				size_modifier = leader_modifier
			end
		end

		army:SetArmy(sprite, CS.Oak.WorldExploreStageArmy.Shield, size * size_modifier, half_height * size_modifier, 0, false)
		if unit.MoveEnded then
			army.ArmySprite.TintColor = self.inactive_color
		else
			army.ArmySprite.TintColor = unity_class.color(1, 1, 1, 1)
		end
		army.ArmySprite:Rebuild()
	end

	walker = walker + shields

	for i = 0, swords - 1 do
		local army = army_list[walker + i]:GetComponent(typeof(CS.Oak.WorldExploreArmy))
		local sprite = nil
		local size_modifier = 1
		if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
			sprite = "swordmen"
		else
			sprite = "invader_swordmen"
			if walker == 0 and i == 0 then
				size_modifier = leader_modifier
			end
		end

		army:SetArmy(sprite, CS.Oak.WorldExploreStageArmy.Sword, size * size_modifier, half_height * size_modifier, 0, false)
		if unit.MoveEnded then
			army.ArmySprite.TintColor = self.inactive_color
		else
			army.ArmySprite.TintColor = unity_class.color(1, 1, 1, 1)
		end
		army.ArmySprite:Rebuild()
	end

	walker = walker + swords

	for i = 0, rifles - 1 do
		local army = army_list[walker + i]:GetComponent(typeof(CS.Oak.WorldExploreArmy))
		local sprite = nil
		local size_modifier = 1
		if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
			sprite = "riflemen"
		else
			sprite = "invader_riflemen"
			if walker == 0 and i == 0 then
				size_modifier = leader_modifier
			end
		end

		army:SetArmy(sprite, CS.Oak.WorldExploreStageArmy.Rifle, size * size_modifier, half_height * size_modifier, 0, false)
		if unit.MoveEnded then
			army.ArmySprite.TintColor = self.inactive_color
		else
			army.ArmySprite.TintColor = unity_class.color(1, 1, 1, 1)
		end
		army.ArmySprite:Rebuild()
	end
end

function local_class:set_dino_ride(unit, ride)
	if unit.Faction ~= CS.Oak.WorldExploreStageFaction.Player then
		return
	end

	if unit.Destroyed then
		ride = false
	end

	if self.dino_ride[unit.Index + 1] == ride then
		return
	end

	local c = self.hero_units[unit.Index + 1][0]
	local d = self.dinos[unit.Index + 1]

	if ride then
		character_util.set_anim(c, { name = "seat", loop = true })
		d:SetAnimation(0, "idle", true)
		c.SpineController.SpineOffset = vector(0, 0.125, 0.5)
		d.transform.position = c.Position
		d.Direction = c.Direction
	else
		character_util.remove_anim(c, false)
		c.SpineController.SpineOffset = vector(0, 0, 0)
		d.transform.position = vector(999, 0, 999)
	end

	self.dino_ride[unit.Index + 1] = ride
end

function local_class:focus_camera_to(pos, fade_if_long)
	local dist = (pos - stage_camera.LookAtPosition).magnitude
	local speed = self.constants.camera_speed
	local duration = dist / speed
	if duration > self.constants.max_camera_duration then
		duration = self.constants.max_camera_duration
	end

	if fade_if_long and dist / duration > 30 then
		screen_util.fade_out_async(0.3, unity_class.color.black, "linear")
		stage_camera:Move(pos, 0, nil)
		coroutine.yield(nil)
		screen_util.fade_in_async(0.3, unity_class.color.black, "linear")
	else
		stage_camera:Move(pos, duration, nil)
		wait_for_sec(duration)
	end

	coroutine.yield(nil)
end

function local_class:set_boss_icon()
	-- FIXME: 보스 아이콘 디자인이 나올때까지 사제
	if self.boss_leader_index == nil or self.boss_leader_index < 0 or true then
		return
	end

	if self.boss_icon ~= nil then
		self.boss_icon:Dispose()
		self.boss_icon = nil
	end

	local unit = self:get_boss_unit_from_stage(self.boss_leader_index)
	if unit.Destroyed then
		return
	end

	local c = self.boss_units[unit.Index + 1]
	self.boss_icon = unity_object_pool.GetOrCreate("world_explore_boss"):Instantiate(c.Position + vector(0, 1.8, 0), unity_class.quaternion.identity, c.Transform)
end

function local_class:get_unit_position(unit)
	if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
		return self.hero_unit_positions[unit.Index + 1]
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy and unit.IsBoss then
		return self.boss_unit_positions[unit.Index + 1]
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy and not unit.IsBoss then
		return self.enemy_unit_positions[unit.Index + 1]
	end

	return vector(0, 0, 0)
end

function local_class:get_hero_unit_from_stage(hero_index)
	local units = stage.Units
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Player and units[i].Index == hero_index then
			return units[i]
		end
	end
	return nil
end

function local_class:get_enemy_unit_from_stage(enemy_index)
	local units = stage.Units
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy and not units[i].IsBoss and units[i].Index == enemy_index then
			return units[i]
		end
	end
	return nil
end

function local_class:get_boss_unit_from_stage(enemy_index)
	local units = stage.Units
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy and units[i].IsBoss and units[i].Index == enemy_index then
			return units[i]
		end
	end
	return nil
end

function local_class:change_manual_party(party_index)
	local new_leader = self.hero_units[party_index + 1][0]

	user_party:StopAndDisableControl()

	if lua_helper.reference_equals(user_party[0], new_leader) then
		return
	end

	field_ui_manager:RemoveUI(user_party, CS.Oak.FieldUiType.TopHpBarForBoss)
	field_ui_manager:RemoveUI(user_party[0], CS.Oak.FieldUiType.TopHpBar)

	user_party[0].FieldObjectController = CS.Oak.NullFieldObjectController.Instance

	if new_leader.FieldObjectController == nil or new_leader.FieldObjectController:GetType() ~= typeof(CS.Oak.ManualTouchCharacterController) then
		new_leader.FieldObjectController = CS.Oak.ManualTouchCharacterController()
		new_leader.DamagedBehaviour = CS.Oak.ManualCharacterDamagedBehaviour.Create()
		coroutine.yield(new_leader:UpdateAndBattleAndStageOptions())
	end
	local heroes = self.hero_units[party_index + 1]
	while user_party.Count > 0 do
		user_party:RemoveAt(0)
	end

	for i = 0, heroes.Count - 1 do
		user_party:Add(heroes[i])
	end

	for i = 1, heroes.Count - 1 do
		local c = heroes[i]
		if c.FieldObjectController == nil or c.FieldObjectController:GetType() ~= typeof (CS.Oak.PartyMemberCharacterController) then
			c.FieldObjectController = CS.Oak.PartyMemberCharacterController(user_party)
		end
	end

	coroutine.yield(nil)
	field_ui_manager:SetUI(user_party, CS.Oak.FieldUiType.TopHpBarForBoss)
	field_ui_manager:SetUI(user_party[0], CS.Oak.FieldUiType.TopHpBar)

	coroutine.yield(nil)
	coroutine.yield(nil)

	user_party:StopAndDisableControl()
end

function set_dont_fight_on_battle_group(battle_group_name, dont_fight)
	local monsters = stage.BattleManager:GetBattleGroup(battle_group_name):GetMonsters()
	for i = 0, monsters.Count - 1 do
		if monsters[i].FieldObjectController:GetType() == typeof(CS.Oak.MonsterCharacterController) then
			monsters[i].FieldObjectController.DontFight = dont_fight
		end
	end
	monsters:Dispose()
end

function set_death_type_on_battle_group(battle_group_name)
	local monsters = stage.BattleManager:GetBattleGroup(battle_group_name):GetMonsters()
	for i = 0, monsters.Count - 1 do
		if monsters[i].DamagedBehaviour.DeathType == CS.Oak.DeathType.BossExplosion then
			monsters[i].DamagedBehaviour.DeathType = CS.Oak.DeathType.SmallExplosion
		end
	end
	monsters:Dispose()
end

function get_survivor_in_battle_group(battle_group_name)
	local monsters = stage.BattleManager:GetBattleGroup(battle_group_name):GetMonsters()
	local survivor = nil
	for i = 0, monsters.Count - 1 do
		if not monsters[i].FieldObjectStatsBehaviour.IsDead then
			survivor = monsters[i]
			break
		end
	end
	monsters:Dispose()
	return survivor
end

function add_army_buff_to_battle_group(battle_group_name, num_swordmen, num_riflemen, num_shieldmen)
	local monsters = stage.BattleManager:GetBattleGroup(battle_group_name):GetMonsters()
	for i = 0, monsters.Count - 1 do
		if not monsters[i].FieldObjectStatsBehaviour.IsDead then
			if num_swordmen > 0 then
				stage.BuffManager:AddBuff(monsters[i], CS.Oak.EquipmentSlot.None, monsters[i], "buff_world_explore_melee", num_swordmen, false, false)
			end

			if num_riflemen > 0 then
				stage.BuffManager:AddBuff(monsters[i], CS.Oak.EquipmentSlot.None, monsters[i], "buff_world_explore_projectile", num_riflemen, false, false)
			end

			if num_shieldmen > 0 then
				stage.BuffManager:AddBuff(monsters[i], CS.Oak.EquipmentSlot.None, monsters[i], "buff_world_explore_defense", num_shieldmen, false, false)
			end
		end
	end
	monsters:Dispose()
end

function remove_army_buff_from_battle_group(battle_group_name)
	local monsters = stage.BattleManager:GetBattleGroup(battle_group_name):GetMonsters()
	for i = 0, monsters.Count - 1 do
		stage.BuffManager:RemoveBuff(monsters[i], CS.Oak.EquipmentSlot.None, monsters[i], "buff_world_explore_melee")
		stage.BuffManager:RemoveBuff(monsters[i], CS.Oak.EquipmentSlot.None, monsters[i], "buff_world_explore_projectile")
		stage.BuffManager:RemoveBuff(monsters[i], CS.Oak.EquipmentSlot.None, monsters[i], "buff_world_explore_defense")
	end
	monsters:Dispose()
end

function local_class:add_army_buff_to_party(index, num_swordmen, num_riflemen, num_shieldmen)
	local characters = self.hero_units[index + 1]
	for i = 0, characters.Count - 1 do
		if not characters[i].FieldObjectStatsBehaviour.IsDead then
			if num_swordmen > 0 then
				stage.BuffManager:AddBuff(characters[i], CS.Oak.EquipmentSlot.None, characters[i], "buff_world_explore_melee", num_swordmen, false, false)
			end

			if num_riflemen > 0 then
				stage.BuffManager:AddBuff(characters[i], CS.Oak.EquipmentSlot.None, characters[i], "buff_world_explore_projectile", num_riflemen, false, false)
			end

			if num_shieldmen > 0 then
				stage.BuffManager:AddBuff(characters[i], CS.Oak.EquipmentSlot.None, characters[i], "buff_world_explore_defense", num_shieldmen, false, false)
			end
		end
	end
end

function local_class:remove_army_buff_from_party(index)
	local characters = self.hero_units[index + 1]
	for i = 0, characters.Count - 1 do
		stage.BuffManager:RemoveBuff(characters[i], CS.Oak.EquipmentSlot.None, characters[i], "buff_world_explore_melee")
		stage.BuffManager:RemoveBuff(characters[i], CS.Oak.EquipmentSlot.None, characters[i], "buff_world_explore_projectile")
		stage.BuffManager:RemoveBuff(characters[i], CS.Oak.EquipmentSlot.None, characters[i], "buff_world_explore_defense")
	end
end

function local_class:get_movement_range(range, faction, center_x, center_z)
	if self.range_queue_dists == nil then
		self.range_queue_dists = create_generic_list(typeof(CS.System.Int32))
		self.range_queue_vertices = create_generic_list(typeof(CS.UnityEngine.Vector2Int))
		self.range_search_result = create_generic_list(typeof(CS.UnityEngine.Vector2Int))
		self.range_search_boundaries = create_generic_list(typeof(CS.UnityEngine.Vector2Int))
		self.range_search_interactables = create_generic_list(typeof(CS.System.Int32))
	end

	self:clear_range_queue()

	local result = self.range_search_result
	result:Clear()

	local boundaries = self.range_search_boundaries
	boundaries:Clear()

	local interactables = self.range_search_interactables
	interactables:Clear()

	local infinity = 200000000
	local step = 1000000

	for i = -range, range do
		for j = -range, range do
			if math.abs(i) + math.abs(j) <= range then
				local can_access = true

				local floor = field:IsThereFloorAt(vector(i + center_x, 0, j + center_z))
				if not floor then
					can_access = self:is_there_bridge_at(vector(i + center_x, 0, j + center_z))
				end

				if can_access then
					local fo = self:get_field_object_at(vector(i + center_x, 0, j + center_z))
					if fo ~= nil and fo.CrashBehaviour:GetType() ~= typeof(CS.Oak.EtherealCrashBehaviour) then
						can_access = false
					else
						local unit = self:get_unit_at(vector(i + center_x, 0, j + center_z))
						if unit ~= nil then
							if unit.Faction ~= faction then
								can_access = false
							end
						end
					end
				end

				if can_access then
					if i == 0 and j == 0 then
						self:add_to_range_queue(0, CS.UnityEngine.Vector2Int(center_x + i, center_z + j))
					else
						self:add_to_range_queue(infinity + hash_position(i, j), CS.UnityEngine.Vector2Int(center_x + i, center_z + j))
					end
				end
			end
		end
	end

	while self.range_queue_dists.Count > 0 do
		local v, vd = self:pop_range_queue()
		local actual_d = CS.UnityEngine.Mathf.FloorToInt(vd / step)

		if actual_d <= range then
			result:Add(v)
		end

		for n = 0, 3 do
			local n_offset = CS.UnityEngine.Vector2Int(0, 0)
			if n  == 0 then
				n_offset.x = 1
			elseif n == 1 then
				n_offset.y = 1
			elseif n == 2 then
				n_offset.x = -1
			else
				n_offset.y = -1
			end

			local nv = v + n_offset
			local index = self.range_queue_vertices:IndexOf(nv)
			if index >= 0 then
				local n_dist = CS.UnityEngine.Mathf.FloorToInt(vd / step) * step + step
				local n_orig_dist = self.range_queue_dists[index]

				if n_dist < n_orig_dist then
					self:update_range_queue(n_dist + hash_position(nv.x - center_x, nv.y - center_z), nv)
				end
			end
		end
	end

	if result.Count == 0 then
		result:Add(CS.UnityEngine.Vector2Int(center_x, center_z))
	end

	for i = 0, result.Count - 1 do
		local v = result[i]
		local is_center = v.x == center_x and v.y == center_z
		if is_center or self:get_unit_at(vector(v.x, 0, v.y)) == nil then
			for n = 0, 3 do
				local n_offset = CS.UnityEngine.Vector2Int(0, 0)
				if n  == 0 then
					n_offset.x = 1
				elseif n == 1 then
					n_offset.y = 1
				elseif n == 2 then
					n_offset.x = -1
				else
					n_offset.y = -1
				end

				nv = v + n_offset
				if not result:Contains(nv) then
					if not boundaries:Contains(nv) then
						local is_valid_boundary = true
						local floor = field:IsThereFloorAt(vector(nv.x, 0, nv.y))
						if not floor then
							is_valid_boundary = self:is_there_bridge_at(vector(nv.x, 0, nv.y))
						end

						if is_valid_boundary then
							boundaries:Add(nv)

							local interaction = self.constants.interactions.stay
							local target_unit = self:get_unit_at(vector(nv.x, 0, nv.y))
							if target_unit ~= nil then
								if faction == CS.Oak.WorldExploreStageFaction.Player then
									if target_unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
										interaction = self.constants.interactions.battle
									elseif target_unit.Faction == CS.Oak.WorldExploreStageFaction.Neutral then
										if self.npc_infos[target_unit.Index + 1]["interactable"] then
											interaction = self.constants.interactions.talk
										end
									end
								else
									if target_unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
										interaction = self.constants.interactions.battle
									end
								end
							elseif faction == CS.Oak.WorldExploreStageFaction.Player then
								local fo = self:get_field_object_at(vector(nv.x, 0, nv.y))
								if fo ~= nil then
									local fobt = fo.FieldObjectBehaviour:GetType()
									if fobt == typeof(CS.Oak.TreasureBehaviour) then
										if not fo.FieldObjectBehaviour.IsOpened then
											interaction = self.constants.interactions.open_treasure
										end
									elseif fobt == typeof(CS.Oak.WorldExploreBreakableBehaviour) then
										interaction = self.constants.interactions.break_object
									end
								end
							end

							interactables:Add(interaction)
						end
					end
				end
			end
		end
	end
end

function hash_position(x, y)
	modifier = 0
	if x > 0 then
		modifier = modifier + 10
	end

	if y > 0 then
		modifier = modifier + 1
	end

	modifier = modifier + math.abs(x) * 10000 + math.abs(y) * 100
	return modifier
end

function local_class:clear_range_queue()
	self.range_queue_dists:Clear()
	self.range_queue_vertices:Clear()
end

function local_class:pop_range_queue()
	local min_index = 0
	local min_dist = self.range_queue_dists[0]

	for i = 0, self.range_queue_dists.Count - 1 do
		if self.range_queue_dists[i] < min_dist then
			min_index = i
			min_dist = self.range_queue_dists[i]
		end
	end

	local min_vertex = self.range_queue_vertices[min_index]

	self.range_queue_dists:RemoveAt(min_index)
	self.range_queue_vertices:RemoveAt(min_index)

	return min_vertex, min_dist
end

function local_class:add_to_range_queue(dist, vertex)
	self.range_queue_dists:Add(dist)
	self.range_queue_vertices:Add(vertex)
end

function local_class:update_range_queue(dist, vertex)
	local index = self.range_queue_vertices:IndexOf(vertex)
	if index < 0 then
		CS.UnityEngine.Debug.LogError("trying to update non-existent vertex")
		return
	end
	self.range_queue_dists[index] = dist
end

function local_class:render_movement_range(show_interactions, is_preview, starting_scale)
	if starting_scale == nil then
		starting_scale = 1
	end

	local pool = unity_object_pool.GetOrCreate("world_explore_tile_icon")
	local q = unity_class.quaternion.AngleAxis(90, vector(1, 0, 0))
	for i = 0, self.range_search_result.Count - 1 do
		local p = self.range_search_result[i]

		local floor = field:IsThereFloorAt(vector(p.x, 0, p.y))
		local sorting_order = -1
		local y = 0.01
		if not floor then
			sorting_order = 0
			y = 0.001
		end

		local tile = pool:Instantiate(vector(p.x, y, p.y), q, nil)
		tile.transform.localScale = vector(starting_scale, starting_scale, starting_scale)
		local cs = tile:GetComponent(typeof(CS.CustomSprite))
		cs.SpriteName = "exploration_tile_base_00.png"
		if is_preview then
			cs.TintColor = unity_class.color(156.0 / 255.0, 217.0 / 255.0, 218.0 / 255.0, 1.0)
		else
			cs.TintColor = unity_class.color(21.0 / 255.0, 88.0 / 255.0, 241.0 / 255.0, 1.0)
		end
		cs.PixelToWorld = 0.015
		cs:SetSortingOrder(sorting_order)
		cs:Rebuild()
		self.range_tiles:Add(tile)
	end

	for i = 0, self.range_search_boundaries.Count - 1 do
		local p = self.range_search_boundaries[i]

		local floor = field:IsThereFloorAt(vector(p.x, 0, p.y))
		local sorting_order = -1
		local y = 0.01
		if not floor then
			sorting_order = 0
			y = 0.001
		end

		local tile = pool:Instantiate(vector(p.x, y, p.y), q, nil)
		tile.transform.localScale = vector(starting_scale, starting_scale, starting_scale)
		local cs = tile:GetComponent(typeof(CS.CustomSprite))
		cs.SpriteName = "exploration_tile_base_00.png"
		cs.TintColor = unity_class.color(255.0 / 255.0, 26.0 / 255.0, 26.0 / 255.0, 1.0)
		cs.PixelToWorld = 0.015
		cs:SetSortingOrder(sorting_order)
		cs:Rebuild()
		self.range_tiles:Add(tile)

		if show_interactions then
			local this_interaction = self.range_search_interactables[i]
			if this_interaction ~= self.constants.interactions.stay then
				tile = pool:Instantiate(vector(p.x, 0.011, p.y) + vector(0, 5, - 5 / math.sqrt(2.0)), q, nil)
				tile.transform.localScale = vector(starting_scale, starting_scale, starting_scale)
				cs = tile:GetComponent(typeof(CS.CustomSprite))
				if this_interaction == self.constants.interactions.battle then
					cs.SpriteName = "exploration_ic_atk_00.png"
				elseif this_interaction == self.constants.interactions.break_object then
					cs.SpriteName = "exploration_ic_shovel_00.png"
				else
					cs.SpriteName = "exploration_ic_ellipsis_00.png"
				end
				cs.TintColor = unity_class.color(255.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 1.0)
				cs.PixelToWorld = 0.016
				cs:SetSortingOrder(1)
				cs:Rebuild()
				self.range_tiles:Add(tile)
			end
		end
	end
end

function local_class:preview_move_range(unit)
	if self.range_tiles == nil then
		self.range_tiles = create_generic_list(typeof(CS.Oak.PooledUnityObject))
	end

	local range = self:get_unit_range(unit)
	self:clear_range_tiles()
	self:get_movement_range(range, unit.Faction, unit.X, unit.Z)
	self:render_movement_range(false, true, 1)
end

function local_class:get_unit_range(unit)
	-- FIXME: 플레리어와 군대 유닛도 어딘가에서 이동 범위를 읽어야 한다.
	local range = 3

	if unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy and unit.IsBoss then
		if self.boss_unit_infos[unit.Index + 1].AIType == CS.Oak.WorldExploreAIType.Stationary then
			range = 0
		else
			range = self.boss_unit_infos[unit.Index + 1].FieldSight
		end
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
		if self.enemy_unit_infos[unit.Index + 1].AIType == CS.Oak.WorldExploreAIType.Stationary then
			range = 0
		else
			range = self.enemy_unit_infos[unit.Index + 1].FieldSight
		end
	end

	return range
end

function local_class:get_ai(unit)
	if unit.Faction ~= CS.Oak.WorldExploreStageFaction.Enemy then
		return CS.Oak.WorldExploreAIType.Stationary
	end

	if unit.IsBoss then
		return self.boss_unit_infos[unit.Index + 1].AIType
	else
		return self.enemy_unit_infos[unit.Index + 1].AIType
	end
end

function is_faction_done(faction)
	local everyone_done = true

	local units = stage.Units
	for i = 0, units.Count - 1 do
		if units[i].Faction == faction then
			if not units[i].MoveEnded and not units[i].Destroyed then
				everyone_done = false
				break
			end
		end
	end

	return everyone_done
end

function local_class:is_victory()
	if self.objective == "world_explore_defeat_leader" then
		local units = stage.Units
		for i = 0, units.Count -1 do
			if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy and units[i].IsBoss and units[i].Index == self.boss_leader_index then
				return units[i].Destroyed
			end
		end
	else
		local units = stage.Units
		for i = 0, units.Count -1 do
			if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy then
				if not units[i].Destroyed then
					return false
				end
			end
		end
		return true
	end

	return false
end

function local_class:is_game_over()
	local units = stage.Units
	for i = 0, units.Count -1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Player then
			if not units[i].Destroyed then
				return false
			end
		end
	end
	return true
end

function local_class:drop_resource(resource, amount, drop_pos)
	local item = CS.Oak.ItemPlaceholder()
	if resource == CS.Oak.WorldExploreStageResource.Gold then
		item.ItemId = CS.Oak.ItemSpecId.WorldExploreGold
	elseif resource == CS.Oak.WorldExploreStageResource.Stone then
		item.ItemId = CS.Oak.ItemSpecId.WorldExploreStone
	else
		item.ItemId = CS.Oak.ItemSpecId.WorldExploreWood
	end

	item.Amount = amount
	item.NotForInventory = true
	item.SkipItemGetText = true

	local di = CS.Oak.DropItem.Create(drop_pos, drop_pos, item, false, false, CS.Oak.DropItem.LootState.DontFindLooter, 0.7, true)
	local looter = nil
	local min_distance = 99999
	local units = stage.Units

	-- 현재 드랍된 리소스 수
	self.current_dropped_resource = self.current_dropped_resource + 1

	for i = 0, units.Count - 1 do
		if not units[i].Destroyed and units[i].Faction == CS.Oak.WorldExploreStageFaction.Player then
			local distance = (units[i]:GetFieldPosition() - drop_pos).magnitude
			if distance < min_distance then
				min_distance = distance
				looter = self.hero_units[units[i].Index + 1][0]
			end
		end
	end

	di:MarkForLooter(looter)
end

function get_direction(v)
	if math.abs(v.x) < CS.Oak.Constants.Epsilon then
		if v.z >= 0 then
			return CS.Oak.Direction.Right
		else
			return CS.Oak.Direction.Left
		end
	else
		if v.x >= 0 then
			return CS.Oak.Direction.Right
		else
			return CS.Oak.Direction.Left
		end
	end
end

function local_class:set_unit_active(unit, active)
	if unit.Destroyed then
		return
	end

	if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
		if self.hero_unit_actives[unit.Index + 1] ~= active then
			if not active then
				self.hero_units[unit.Index + 1][0].SpineController:AddColor("active", self.inactive_color, 1, 0)
				if self.dino_ride[unit.Index + 1] then
					self.dinos[unit.Index + 1]:AddColor("active", self.inactive_color, 1, 0)
				end

				local army_list = self.hero_unit_armies[unit.Index + 1]
				for i = 0, army_list.Count -1 do
					local army = army_list[i]:GetComponent(typeof(CS.Oak.WorldExploreArmy))
					army.ArmySprite.TintColor = self.inactive_color
					army.ArmySprite:Rebuild()
				end
			else
				self.hero_units[unit.Index + 1][0].SpineController:RemoveColor("active", 0)
				if self.dino_ride[unit.Index + 1] then
					self.dinos[unit.Index + 1]:RemoveColor("active", 0)
				end

				local army_list = self.hero_unit_armies[unit.Index + 1]
				for i = 0, army_list.Count -1 do
					local army = army_list[i]:GetComponent(typeof(CS.Oak.WorldExploreArmy))
					army.ArmySprite.TintColor = unity_class.color(1, 1, 1, 1)
					army.ArmySprite:Rebuild()
				end
			end
			self.hero_unit_actives[unit.Index + 1] = active
		end
	elseif unit.Faction == CS.Oak.WorldExploreStageFaction.Enemy and unit.IsBoss then
		if self.boss_unit_actives[unit.Index + 1] ~= active then
			if not active then
				self.boss_units[unit.Index + 1].SpineController:AddColor("active", self.inactive_color, 1, 0)
			else
				self.boss_units[unit.Index + 1].SpineController:RemoveColor("active", 0)
			end
			self.boss_unit_actives[unit.Index + 1] = active
		end
	end
end

function local_class:trigger_npc_oneline(index)
	local oneline = self.npc_infos[index + 1]["oneline"]
	if oneline ~= nil then
		self:npc_talk(index, oneline, false)
	end
end

function local_class:npc_talk(index, key, skip)
	local offset, bd = self:get_npc_talk_params(true)

	speech_bubble_util.show_speech_bubble(self.npc_units[index + 1], { key = key, skip = skip, offset = offset, bubble_direction = bd })
end

function local_class:get_npc_talk_params(force_right)
	local aspect_cut = 1.5

	if stage_camera.Camera.aspect < aspect_cut and not force_right then
		return CS.SpeechBubbleOffset.Offsets[speech_bubble.bubble_directions.rt] - vector(2.15, 0.5, 0), "ct"
	else
		return CS.SpeechBubbleOffset.Offsets[speech_bubble.bubble_directions.rt] - vector(0.1, 0.5, 0), "rt"
	end
end

function local_class:conquer_resource(unit, fo)
	if fo.FieldObjectBehaviour.Faction ~= unit.Faction then
		fo.FieldObjectBehaviour.Faction = unit.Faction
		if self.flags[fo.Name] ~= nil then
			self.flags[fo.Name]:Dispose()
		end
		local flag = unity_object_pool.GetOrCreate("world_explore_player_flag"):Instantiate(fo.Position + vector(0, 0, 0.5))
		flag.transform.localScale = vector(0.8, 0.8, 0.8)
		local skeleton = flag:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
		skeleton.state:ClearTrack(0)
		if unit.Faction == CS.Oak.WorldExploreStageFaction.Player then
			skeleton.state:SetAnimation(0, "blue_start", false)
			skeleton.state:AddAnimation(0, "blue_idle", true, 0)
			music_player:PlaySfxOneShot("03_quest_complete_a_01")
		else
			skeleton.state:SetAnimation(0, "red_start", false)
			skeleton.state:AddAnimation(0, "red_idle", true, 0)
			music_player:PlaySfxOneShot("03_quest_complete_d_01")
		end
		self.flags[fo.Name] = flag

		self:set_resources()
		wait_for_sec(0.5)
	end
end

function local_class:teleport(unit, fo, is_player)
	local wp = fo.FieldObjectBehaviour.ExitMarker
	local move_marker = field:GetMarker(wp)
	local move_point = move_marker.position
	local move_direction = move_marker.direction
	local move_index = 0

	if move_direction == CS.Oak.Direction.Up then
		move_index = 1
	elseif move_direction == CS.Oak.Direction.Left then
		move_index = 2
	elseif move_direction == CS.Oak.Direction.Down then
		move_index = 3
	end

	local move_hit_pos = nil

	if self:get_unit_at(move_point) == nil and self:get_field_object_at(move_point) == nil then
		move_hit_pos = move_point
	else
		for i = 0, 3 do
			local this_index = (move_index + i) % 4
			local this_loc = vector(move_point.x + self.exit_directions[this_index + 1].x, 0, move_point.z + self.exit_directions[this_index + 1].y)
			if self:get_unit_at(this_loc) == nil and self:get_field_object_at(this_loc) == nil then
				move_hit_pos = this_loc
				break
			end
		end
	end

	if move_hit_pos ~= nil then
		if not is_player then
			wait_for_sec(0.5)
		end

		music_player:PlaySfxOneShot("01_teleport_01")
		screen_util.fade_out_async(0.3, unity_class.color.black, "linear")
		unit.X = CS.UnityEngine.Mathf.RoundToInt(move_hit_pos.x)
		unit.Z = CS.UnityEngine.Mathf.RoundToInt(move_hit_pos.z)
		self:set_unit_on_field(unit, move_hit_pos, unit.Direction)
		stage_camera:Move(move_hit_pos, 0, nil)
		wait_for_sec(0.2)
		screen_util.fade_in_async(0.3, unity_class.color.black, "linear")
	else
		if is_player then
			local offset, bd = self:get_npc_talk_params(false)
			local extra_offset = fo.Bounds.center - fo.Position
			extra_offset.y = 0
			offset = offset + extra_offset
			speech_bubble_util.show_speech_bubble_async(fo, { key = "world_explore_exit_no_room", skip = true, offset = offset, bubble_direction = bd })
		end
	end
end

function local_class:get_buff_string(num_swordmen, num_riflemen, num_shieldmen)
	if self.string_builder == nil then
		self.string_builder = CS.System.Text.StringBuilder()
	end

	local buff_data = CS.Oak.GameDataService.GetData("BuffData")

	self.string_builder:Clear()

	local has_before = false
	if num_swordmen > 0  then
		local buff_spec = buff_data:GetBuffSpecFromName("buff_world_explore_melee")
		self.string_builder:Append(CS.Oak.MeleeAttackScaleBuff.ToString(buff_spec, num_swordmen, true))
		has_before = true
	end

	if num_riflemen > 0  then
		local buff_spec = buff_data:GetBuffSpecFromName("buff_world_explore_projectile")
		if has_before then
			self.string_builder:Append("\n")
		end
		self.string_builder:Append(CS.Oak.ProjectileAttackScaleBuff.ToString(buff_spec, num_riflemen, true))
		has_before = true
	end

	if num_shieldmen > 0  then
		local buff_spec = buff_data:GetBuffSpecFromName("buff_world_explore_defense")
		if has_before then
			self.string_builder:Append("\n")
		end
		self.string_builder:Append(CS.Oak.DefenseScaleBuff.ToString(buff_spec, num_shieldmen, true))
		has_before = true
	end

	return self.string_builder:ToString()
end

function get_army_count_for(unit)
	if unit.Faction ~= CS.Oak.WorldExploreStageFaction.Enemy or unit.Destroyed or not unit.IsBoss then
		return 0, 0, 0
	end

	local units = stage.Units
	local num_swordmen = 0
	local num_shieldmen = 0
	local num_riflemen = 0

	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy and not units[i].IsBoss then
			if math.abs(units[i].X - unit.X) < 1.1 and math.abs(units[i].Z - unit.Z) < 1.1 then
				num_swordmen = num_swordmen + units[i].NumSwordmen
				num_riflemen = num_riflemen + units[i].NumRiflemen
				num_shieldmen = num_shieldmen + units[i].NumShieldmen
			end
		end
	end

	return num_swordmen, num_riflemen, num_shieldmen
end

function local_class:show_turn_end_tutorial()
	if CS.UnityEngine.PlayerPrefs.GetInt('WorldExploreEndTurn', 0) == 1 then
		return
	end

	if self.turn_end_guide == nil then
		local ui = CS.Oak.UI.WorldExploreFieldUI.Instance
		self.turn_end_guide = ui.transform:Find("Content/EndTurn/fx_ui_guide").gameObject
	end

	self.turn_end_guide:SetActive(true)
end

function local_class:hide_turn_end_tutorial()
	if self.turn_end_guide ~= nil then
		CS.UnityEngine.PlayerPrefs.SetInt('WorldExploreEndTurn', 1)
		self.turn_end_guide:SetActive(false)
	end
end

-- 다른 Event Controller 와의 커뮤니케이션을 위한 용도 (npc, 스테이지 내 이벤트 제어 등)

function local_class:add_npc(name, character_name, pos, direction, oneline, interactable, sprite_override)
	if self.current_phase ~= self.constants.phases.stage_event_loading then
		return
	end

	local c = get_character(character_name)
	if c == nil then
		CS.UnityEngine.Debug.LogError("Can't find npc character")
		return
	end
	c:ScaleHitbox("field_scale", vector(0.1, 0.1, 0.1), 0)

	if self.npc_units == nil then
		self.npc_units = {}
		self.npc_infos = {}
		self.npc_unit_positions = {}
		self.npc_notices = {}
	end

	local index = #self.npc_units
	local data = {}
	data['oneline'] = oneline
	if sprite_override ~= nil then
		data['sprite'] = sprite_override
	end

	self.npc_units[index + 1] = c
	self.npc_infos[index + 1] = data

	local unit = CS.Oak.WorldExploreStageUnit(index, name, CS.Oak.WorldExploreStageFaction.Neutral)
	unit.X = pos.x
	unit.Z = pos.y
	unit.SizeX = 1;
	unit.SizeZ = 1;
	unit.NumSwordmen = 0
	unit.NumRiflemen = 0
	unit.NumShieldmen = 0
	unit.Direction = direction
	stage.Units:Add(unit)

	self:set_unit_on_field(unit, unit:GetFieldPosition(), unit.Direction)
	self:set_npc_interactable(unit.Name, interactable)
end

function local_class:finish_stage_event_load()
	if self.current_phase ~= self.constants.phases.stage_event_loading then
		return
	end
	self.current_phase = self.constants.phases.stage_event_loading_done
end

function local_class:finish_npc_interaction()
	if self.current_phase ~= self.constants.phases.npc_interacting then
		return
	end
	self.current_phase = self.constants.phases.npc_interacting_end
end

function local_class:set_npc_oneline(name, oneline)
	local units = stage.Units
	local index = -1
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Neutral and units[i].Name == name then
			index = units[i].Index
			break
		end
	end

	if index >= 0 then
		self.npc_infos[index + 1]["oneline"] = oneline
	end
end

function local_class:set_npc_interactable(name, interactable)
	local units = stage.Units
	local index = -1
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Neutral and units[i].Name == name then
			index = units[i].Index
			break
		end
	end

	if index >= 0 then
		if interactable and self.npc_notices[index + 1] == nil then
			local c = self.npc_units[index + 1]
			self.npc_notices[index + 1] = unity_object_pool.GetOrCreate("world_explore_notice"):Instantiate(c.Position + vector(0, 1.25, 0), unity_class.quaternion.identity, c.Transform)
		elseif not interactable and self.npc_notices[index + 1] ~= nil then
			self.npc_notices[index + 1]:Dispose()
			self.npc_notices[index + 1] = nil
		end

		self.npc_infos[index + 1]["interactable"] = interactable
	end
end

function local_class:destroy_npc(name)
	local units = stage.Units
	local unit = nil
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Neutral and units[i].Name == name then
			unit = units[i]
			break
		end
	end

	if unit == nil then
		return
	end

	unit.Destroyed = true
	self:set_npc_interactable(name, false)

	local c = self.npc_units[unit.Index + 1]
	field_ui_manager:RemoveUI(c, CS.Oak.FieldUiType.CharacterStats)
	c.SpineController:SetAlphaFade(0, 0.5)
end

function local_class:finish_start_event()
	if self.current_phase ~= self.constants.phases.start_event_running then
		return
	end
	self.current_phase = self.constants.phases.start_event_done
end

function local_class:default_start_event()
	if self.current_phase ~= self.constants.phases.start_event_running then
		return
	end
	self.current_phase = self.constants.phases.start_event_default
end

function local_class:finish_ending_event()
	if self.current_phase ~= self.constants.phases.ending_event_running then
		return
	end
	self.current_phase = self.constants.phases.ending_event_done
end

--- 메인 loop 과 state transition

function local_class:main_loop()
	local game_over_break = false
	local clear_break = false
	local is_turn_over = false

	while not self.game_ended do
		if self.current_phase == self.constants.phases.hero_turn_start then
			self.current_turn = self.current_turn + 1
			self:set_turn()
			coroutine.yield(self:to_hero_turn_start())
			self.current_phase = self.constants.phases.hero_turn
		elseif self.current_phase == self.constants.phases.hero_turn then
			-- 드랍된 리소스가 있다면 다 받은 뒤에 탭에 대해 처리를 한다.
			if self.current_dropped_resource == 0 then
				if self.tile_tap == self.constants.tap_types.active_player then
					self.tile_tap = self.constants.tap_types.none
					coroutine.yield(self:to_hero_move(self.tile_tap_player_index))
				elseif self.tile_tap == self.constants.tap_types.inactive_town_player then
					self.tile_tap = self.constants.tap_types.none
					local hero_unit = self:get_hero_unit_from_stage(self.tile_tap_player_index)
					local town = self:get_field_object_at(hero_unit:GetFieldPosition())
					coroutine.yield(self:to_town(hero_unit, town))
				end
			end
		elseif self.current_phase == self.constants.phases.hero_turn_unit_move_end then
			if self:is_victory() then
				clear_break = true
				break
			elseif self:is_game_over() then
				game_over_break = true
				break
			else
				self.current_phase = self.constants.phases.hero_turn
				if is_faction_done(CS.Oak.WorldExploreStageFaction.Player) then
					self:show_turn_end_tutorial()
				end
			end
		elseif self.current_phase == self.constants.phases.hero_turn_end then
			self:clear_range_tiles()
			CS.Oak.UI.WorldExploreFieldUI.Instance:HideUnitTileInfo()
			self:hide_turn_end_tutorial()
			self.current_phase = self.constants.phases.enemy_turn_start
		elseif self.current_phase == self.constants.phases.enemy_turn_start then
			coroutine.yield(self:to_enemy_turn_start())
			self.current_phase = self.constants.phases.enemy_turn
		elseif self.current_phase == self.constants.phases.enemy_turn then
			self.camera_controller:DeactivateTouch()
			self.camera_controller.gameObject:SetActive(false)
			local units = stage.Units
			local last_unit_index = -1
			for i = 0, units.Count - 1 do
				if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy and not units[i].Destroyed then
					if last_unit_index >= 0 then
						units[last_unit_index].MoveEnded = true
						self:set_unit_active(units[last_unit_index], false)
						coroutine.yield(nil)
					end

					coroutine.yield(self:to_enemy_move(units[i]))
					last_unit_index = i
					if self:is_victory() then
						clear_break = true
						break
					elseif self:is_game_over() then
						game_over_break = true
						break
					end
				end
			end

			if clear_break or game_over_break then
				break
			end

			self.current_phase = self.constants.phases.enemy_turn_end
			self.camera_controller.gameObject:SetActive(true)
		elseif self.current_phase == self.constants.phases.enemy_turn_end then
			if self.turn_limit >= 0 and self.current_turn + 1 >= self.turn_limit then
				game_over_break = true
				is_turn_over = true
				break
			end
			self.current_phase = self.constants.phases.hero_turn_start
		elseif self.current_phase == self.constants.phases.focusing_hero then
			coroutine.yield(self:to_focus_hero())
			self.current_phase = self.constants.phases.hero_turn
		end
		coroutine.yield(nil)
	end

	if game_over_break then
		self.current_phase = self.constants.phases.game_over
		coroutine.yield(self:game_over(is_turn_over))
	elseif clear_break	then
		self.current_phase = self.constants.phases.clear_stage
		coroutine.yield(self:clear_stage())
	end
end

function local_class:to_hero_turn_start()
	local units = stage.Units
	local start_unit = nil
	for i = 0, units.Count - 1 do
		units[i].MoveEnded = false
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Player then
			if not units[i].Destroyed then
				if start_unit == nil or units[i].Index < start_unit.Index then
					start_unit = units[i]
				end

				-- 영웅 유닛이 어디로 튀었을지 몰라 방어코드
				self:set_unit_on_field(units[i], units[i]:GetFieldPosition(), self.hero_units[units[i].Index + 1][0].Direction)
			end
		end
		self:set_unit_active(units[i], true)
	end

	-- 마을 초기화
	for i = 0, self.towns.Count - 1 do
		self.town_trained[i] = 0
	end

	local move_duration = 0

	if start_unit ~= nil then
		local dist = (start_unit:GetFieldPosition() - stage_camera.LookAtPosition).magnitude
		if dist >= self.constants.hero_turn_focus_distance then
			local speed = self.constants.camera_speed
			move_duration = dist / speed
			if move_duration > self.constants.max_camera_duration then
				move_duration = self.constants.max_camera_duration
			end
		end
	end

	if move_duration > 0 then
		self.camera_controller:DeactivateTouch()
		stage_camera:Move(start_unit:GetFieldPosition(), move_duration, nil)
	else
		self.camera_controller:ActivateTouch()
	end

	--music_player:PlaySfxOneShot("01_ui_transition_03")
	--music_player:PlaySfxOneShot("03_dialogue_ready_01")
	self.player_turn_start_ui:SetActive(true)
	local wait_time = 1.25

	if move_duration > 0 then
		wait_for_sec(move_duration)
		self.camera_controller:ActivateTouch()
		if move_duration < wait_time then
			wait_for_sec(wait_time - move_duration)
		end
	else
		wait_for_sec(wait_time)
	end

	self.player_turn_start_ui:SetActive(false)

	local dropped = false

	-- 점령한 필드 Object의 리소스 드랍
	for i = 0, self.resource_mines.Count - 1 do
		local m = self.resource_mines[i].FieldObjectBehaviour
		if m.Faction == CS.Oak.WorldExploreStageFaction.Player then
			dropped = true
			self:drop_resource(m.Resource, m.Productivity, self.resource_mines[i].Position)
		end
	end

	for i = 0, self.towns.Count - 1 do
		local t = self.towns[i].FieldObjectBehaviour
		if t.Faction == CS.Oak.WorldExploreStageFaction.Player then
			dropped = true
			self:drop_resource(CS.Oak.WorldExploreStageResource.Gold, self.constants.town_productions[t.Level + 1], self.towns[i].Position)
		end
	end

	self:set_right_units()
	self.field_ui:ShowRightList(true)
	self.field_ui:ShowEndTurn(true)
end

function local_class:to_enemy_turn_start()
	self:clear_range_tiles()
	self.field_ui:ShowRightList(false)
	self.field_ui:ShowEndTurn(false)

	local units = stage.Units
	for i = 0, units.Count - 1 do
		units[i].MoveEnded = false
		self:set_unit_active(units[i], true)
	end

	for i = 0, self.resource_mines.Count - 1 do
		local m = self.resource_mines[i].FieldObjectBehaviour
		if m.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
			if m.Resource == CS.Oak.WorldExploreStageResource.Stone then
				self.current_enemy_stone = self.current_enemy_stone + m.Productivity
			elseif m.Resource == CS.Oak.WorldExploreStageResource.Wood then
				self.current_enemy_wood = self.current_enemy_wood + m.Productivity
			end
		end
	end

	for i = 0, self.towns.Count - 1 do
		local t = self.towns[i].FieldObjectBehaviour
		if t.Faction == CS.Oak.WorldExploreStageFaction.Enemy then
			self.current_enemy_gold = self.current_enemy_gold + self.constants.town_productions[t.Level + 1]
		end
	end
	--music_player:PlaySfxOneShot("01_ui_transition_03")
	self.enemy_turn_start_ui:SetActive(true)

	wait_for_sec(1.25)

	self.enemy_turn_start_ui:SetActive(false)
end

function local_class:to_hero_move(hero_index)
	self.current_phase = self.constants.phases.hero_turn_unit_move_range_preparing

	music_player:PlaySfxOneShot("01_ui_grid_01")

	local unit = self:get_hero_unit_from_stage(hero_index)
	self:show_unit_info(unit)

	local interaction = self.constants.interactions.stay
	local interact_target = nil

	local initial_fo = self:get_field_object_at(unit:GetFieldPosition())
	if initial_fo ~= nil and initial_fo.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreTownBehaviour) then
		self.field_ui:SetActionButton("world_explore_action_enter")
	elseif initial_fo ~= nil and initial_fo.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreExitBehaviour) then
		self.field_ui:SetActionButton("world_explore_action_enter")
	else
		self.field_ui:SetActionButton("world_explore_action_stay")
	end

	self.field_ui:ShowActionPanel(true)
	self.field_ui:ShowEndTurn(false)

	if self.range_tiles == nil then
		self.range_tiles = create_generic_list(typeof(CS.Oak.PooledUnityObject))
	end

	local battled = false
	local unit_original_x = unit.X
	local unit_original_z = unit.Z
	local unit_original_dir = unit.Direction
	local range = self:get_unit_range(unit)
	self:clear_range_tiles()
	self:get_movement_range(range, unit.Faction, unit.X, unit.Z)
	self:render_movement_range(true)

	self.tile_tap = self.constants.tap_types.none

	local prepare_time_passed = 0
	local duration = 0.1

	while prepare_time_passed < duration do
		prepare_time_passed = prepare_time_passed + unity_class.time.deltaTime
		local prog = CS.UnityEngine.Mathf.Lerp(0, 1, prepare_time_passed / duration)
		for i = 0, self.range_tiles.Count - 1 do
			self.range_tiles[i].transform.localScale = vector(prog, prog, prog)
		end
		coroutine.yield(nil)
	end

	for i = 0, self.range_tiles.Count - 1 do
		self.range_tiles[i].transform.localScale = vector(1, 1, 1)
	end

	self.current_phase = self.constants.phases.hero_turn_unit_move_range

	local cancelled = false

	while true do
		while self.tile_tap == self.constants.tap_types.none and not self.action_panel_ok_clicked and not self.action_panel_cancel_clicked do
			coroutine.yield(nil)
		end

		if self.tile_tap == self.constants.tap_types.empty_tap or self.action_panel_ok_clicked or self.action_panel_cancel_clicked then
			CS.Oak.UI.WorldExploreFieldUI.Instance:HideUnitTileInfo()
			self:clear_range_tiles()

			if self.action_panel_ok_clicked then
				-- 실제 액션
				if interaction == self.constants.interactions.break_object then
					local fo = self:get_field_object_at(vector(interact_target.x, 0, interact_target.y))
					unit.Direction = get_direction(fo.Position - unit:GetFieldPosition())
					self:set_unit_on_field(unit, unit:GetFieldPosition(), unit.Direction)
					if not fo.FieldObjectBehaviour.Destroyed then
						fo.FieldObjectBehaviour:Break(self.hero_units[hero_index + 1][0])
						-- FieldObject Break를 통해 드랍된 리소스
						self.current_dropped_resource = self.current_dropped_resource + 1
					end
					wait_for_sec(1.0)
				elseif interaction == self.constants.interactions.open_treasure then
					local fo = self:get_field_object_at(vector(interact_target.x, 0, interact_target.y))
					unit.Direction = get_direction(fo.Position - unit:GetFieldPosition())
					self:set_unit_on_field(unit, unit:GetFieldPosition(), unit.Direction)
					coroutine.yield(fo.FieldObjectBehaviour:OpenInWorldExplore())
				elseif interaction == self.constants.interactions.talk then
					local npc_unit = self:get_unit_at(vector(interact_target.x, 0, interact_target.y))
					local talk_dir = npc_unit:GetFieldPosition() - unit:GetFieldPosition()
					unit.Direction = get_direction(talk_dir)
					npc_unit.Direction = get_direction(-talk_dir)
					self:set_unit_on_field(unit, unit:GetFieldPosition(), unit.Direction)
					self:set_unit_on_field(npc_unit, npc_unit:GetFieldPosition(), npc_unit.Direction)
					self:clear_range_tiles()
					self.current_phase = self.constants.phases.npc_interacting
					message_system:Publish(CS.Oak.WorldExploreStageEvent.Create(self.constants.event_types.npc_interaction_start, unit, npc_unit, 0))

					self.camera_controller:DeactivateTouch()
					while self.current_phase ~= self.constants.phases.npc_interacting_end do
						coroutine.yield(nil)
					end
					self.current_phase = self.constants.phases.hero_turn_unit_move_range
					self.camera_controller:ActivateTouch()
				end
			else
				unit.X = unit_original_x
				unit.Z = unit_original_z
				unit.Direction = unit_original_dir
				self:set_unit_on_field(unit, vector(unit.X, 0, unit.Z), unit.Direction)
				cancelled = true
			end
			break
		elseif self.tile_tap == self.constants.tap_types.change_player or self.tile_tap == self.constants.tap_types.change_player_with_focus then
			if self.tile_tap_player_index ~= hero_index then
				self:clear_range_tiles()
				unit.X = unit_original_x
				unit.Z = unit_original_z
				unit.Direction = unit_original_dir
				self:set_unit_on_field(unit, vector(unit.X, 0, unit.Z), unit.Direction)
				cancelled = true
				break
			end
		elseif self.tile_tap == self.constants.tap_types.range_blue_tap or self.tile_tap == self.constants.tap_types.range_interactable_tap then
			local target_pos = nil

			if self.tile_tap == self.constants.tap_types.range_interactable_tap then
				local red_pos = self.tile_tap_pos
				interact_target = red_pos
				local index = self.range_search_boundaries:IndexOf(red_pos)
				interaction = self.range_search_interactables[index]

				local min_dist = 99999

				for n = 0, 3 do
					local n_offset = CS.UnityEngine.Vector2Int()
					if n == 0 then
						n_offset.x = 1
						n_offset.y = 0
					elseif n == 1 then
						n_offset.x = 0
						n_offset.y = 1
					elseif n == 2 then
						n_offset.x = -1
						n_offset.y = 0
					else
						n_offset.x = 0
						n_offset.y = -1
					end

					local bv = red_pos + n_offset
					if self.range_search_result:Contains(bv) then
						if (bv.x == unit.X and bv.y == unit.Z) or self:get_unit_at(vector(bv.x, 0, bv.y)) == nil then
							local dist = (vector(bv.x, 0, bv.y) - self:get_unit_position(unit)).magnitude
							if dist < min_dist then
								target_pos = bv
								min_dist = dist
							end
						end
					end
				end

				if target_pos == nil then
					target_pos = CS.UnityEngine.Vector2Int()
					target_pos.x = unit.X
					target_pos.y = unit.Z
					interact_target = nil
					interaction = self.constants.interactions.stay
				end
			else
				target_pos = self.tile_tap_pos
				interact_target = nil
				interaction = self.constants.interactions.stay
			end

			if self.cursor == nil then
				self.cursor = unity_object_pool.GetOrCreate("world_explore_tile_cursor"):Instantiate(vector(0, 0, 0))
			end

			if interact_target ~= nil then
				self.cursor.transform.position = vector(interact_target.x, 0.02, interact_target.y)
			else
				self.cursor.transform.position = vector(target_pos.x, 0.02, target_pos.y)
			end

			if unit.X ~= target_pos.x or unit.Z ~= target_pos.y then
				self.current_phase = self.constants.phases.hero_turn_unit_moving

				unit.X = target_pos.x
				unit.Z = target_pos.y

				local move_from = self:get_unit_position(unit)
				local move_to = vector(unit.X, 0, unit.Z)
				coroutine.yield(self:move_unit_on_field(unit, move_from, move_to, nil))
				self.current_phase = self.constants.phases.hero_turn_unit_move_range
			end

			if interaction == self.constants.interactions.open_treasure then
				self.field_ui:SetActionButton("world_explore_action_open_treasure")
			elseif interaction == self.constants.interactions.break_object then
				self.field_ui:SetActionButton("world_explore_action_break_object")
			elseif interaction == self.constants.interactions.talk then
				self.field_ui:SetActionButton("world_explore_action_talk")
			elseif interaction == self.constants.interactions.stay then
				local fo_at = self:get_field_object_at(unit:GetFieldPosition())
				if fo_at ~= nil and fo_at.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreTownBehaviour) then
					self.field_ui:SetActionButton("world_explore_action_enter")
				else
					self.field_ui:SetActionButton("world_explore_action_stay")
				end
			elseif interaction == self.constants.interactions.battle then
				local fo_at = self:get_field_object_at(unit:GetFieldPosition())
				if fo_at ~= nil and fo_at.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreTownBehaviour) then
					self.field_ui:SetActionButton("world_explore_action_enter")
				else
					self.field_ui:SetActionButton("world_explore_action_stay")
				end

				-- 타겟이 전투일 경우
				local target_unit = self:get_unit_at(vector(interact_target.x, 0, interact_target.y))
				if target_unit.IsBoss then
					self.army_battle_fought = false
					self.manual_battle_fought = false
					coroutine.yield(self:to_manual_battle(hero_index, target_unit.Index, true))
				else
					self.manual_battle_fought = false
					self.army_battle_fought = false
					coroutine.yield(self:to_army_battle(hero_index, target_unit.Index, true))
				end

				if (self.army_battle_fought or self.manual_battle_fought) and target_unit.Destroyed then
					local fo = self:get_field_object_at(target_unit:GetFieldPosition())
					if fo ~= nil then
						local fobt = fo.FieldObjectBehaviour:GetType()
						if fobt == typeof(CS.Oak.WorldExploreTownBehaviour) or fobt == typeof(CS.Oak.WorldExploreResourceMineBehaviour) then
							wait_for_sec(0.5)
							unit.X = target_unit.X
							unit.Z = target_unit.Z

							local move_from = self:get_unit_position(unit)
							local move_to = vector(unit.X, 0, unit.Z)
							coroutine.yield(self:move_unit_on_field(unit, move_from, move_to, nil))
							self.current_phase = self.constants.phases.hero_turn_unit_move_range
						end
					end
				end

				if self.army_battle_fought or self.manual_battle_fought then
					battled = true
					self:set_right_units()
					break
				end
			end
		end

		self.tile_tap = self.constants.tap_types.none
	end

	self.action_panel_ok_clicked = false
	self.action_panel_cancel_clicked = false

	if cancelled then
		self.current_phase = self.constants.phases.hero_turn
		if self.tile_tap == self.constants.tap_types.change_player then
			self.tile_tap = self.constants.tap_types.active_player
		elseif self.tile_tap == self.constants.tap_types.change_player_with_focus then
			self.current_phase = self.constants.phases.focusing_hero
			self.hero_to_focus = self.tile_tap_player_index
			self.tile_tap = self.constants.tap_types.none
			self.tile_tap_player_index = -1
		else
			self.tile_tap = self.constants.tap_types.none
			self.tile_tap_player_index = -1
			self.field_ui:ShowActionPanel(false)
			self.field_ui:ShowEndTurn(true)
		end
	else
		self.tile_tap = self.constants.tap_types.none
		self.tile_tap_player_index = -1
		self.field_ui:ShowActionPanel(false)

		local moved = unit_original_x ~= unit.X or unit_original_z ~= unit.Z

		-- 이동 종료 후 해당 타일에서의 액션
		-- 유닛이 아직 살아있다면
		local town_conquered = false
		if not unit.Destroyed and moved then
			local fo = self:get_field_object_at(unit:GetFieldPosition())
			if fo ~= nil then
				local fobt = fo.FieldObjectBehaviour:GetType()
				if fobt == typeof(CS.Oak.WorldExploreSwitchBehaviour) then
					fo.FieldObjectBehaviour.IsTurnedOn = true
				elseif fobt == typeof(CS.Oak.WorldExploreResourceMineBehaviour) then
					coroutine.yield(self:conquer_resource(unit, fo))
				elseif fobt == typeof(CS.Oak.WorldExploreTownBehaviour) then
					if fo.FieldObjectBehaviour.Faction ~= unit.Faction then
						town_conquered = true
					end
					coroutine.yield(self:conquer_resource(unit, fo))
				end
			end
		end

		--  원래 있던 자리 처리
		if moved or unit.Destroyed then
			local fo = self:get_field_object_at(vector(unit_original_x, 0, unit_original_z))
			if fo ~= nil then
				if fo.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreSwitchBehaviour) then
					fo.FieldObjectBehaviour.IsTurnedOn = false
				end
			end
		end

		local fo = self:get_field_object_at(unit:GetFieldPosition())
		local is_in_town = fo ~= nil and fo.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreTownBehaviour)

		if is_in_town and not unit.Destroyed and (interaction == self.constants.interactions.stay or town_conquered) then
			coroutine.yield(self:to_town(unit, fo))
		elseif not unit.Destroyed and fo ~= nil and fo.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreExitBehaviour) then
			coroutine.yield(self:teleport(unit, fo, true))
		end

		local is_game_over = self:is_game_over()
		local is_victory = self:is_victory()
		unit.MoveEnded = true

		if not is_game_over and not is_victory then
			self:set_unit_active(unit, false)
			self:set_right_units()
			self.field_ui:ShowEndTurn(true)
		else
			if interaction == self.constants.interactions.battle then
				wait_for_sec(0.5)
			end
			field_ui_manager:Hide()
		end

		if battled then
			-- 전투 끝났을 때 무슨 문제로 캐릭터가 다른 위치로 튀어있을지 모르니 강제로 리셋해준다.
			self:set_unit_on_field(unit, unit:GetFieldPosition(), self.hero_units[unit.Index + 1][0].Direction)
		end

		self.current_phase = self.constants.phases.hero_turn_unit_move_end
	end
end

function local_class:to_manual_battle(hero_index, enemy_index, is_hero_move)
	if is_hero_move and self.current_phase ~= self.constants.phases.hero_turn_unit_move_range then
		return
	end

	if is_hero_move then
		self.current_phase = self.constants.phases.manual_battle
	end

	-- 보스 배틀 팝업을 띄운다
	local menu_state = CS.Oak.UI.WorldExploreBossBattlePopupState()
	local csb = self.boss_units[enemy_index + 1].FieldObjectStatsBehaviour
	local waiting_for_popup = true
	local start_battle = false

	local hero_unit = self:get_hero_unit_from_stage(hero_index)
	local boss_unit = self:get_boss_unit_from_stage(enemy_index)

	menu_state.BossSpecId = csb.CharacterSpec.Id
	menu_state.BossLevel = csb.Level
	menu_state.BossRemainHp = csb.HP
	menu_state.BossMaxHp = csb.MaxHP
	menu_state.PartyMembers = self.hero_units[hero_index + 1]
	menu_state.AllowCancel = is_hero_move
	menu_state.HeroIndex = hero_index

	if hero_unit.NumShieldmen == 0 and hero_unit.NumSwordmen == 0 and hero_unit.NumRiflemen == 0 then
		menu_state.HeroBuff = game_string:GetString("world_explore_no_buff")
	else
		menu_state.HeroBuff = self:get_buff_string(hero_unit.NumSwordmen, hero_unit.NumRiflemen, hero_unit.NumShieldmen)
	end

	local boss_swordmen, boss_riflemen, boss_shieldmen = get_army_count_for(boss_unit)
	if boss_swordmen == 0 and boss_riflemen == 0 and boss_shieldmen == 0 then
		menu_state.EnemyBuff = game_string:GetString("world_explore_no_buff")
	else
		menu_state.EnemyBuff = self:get_buff_string(boss_swordmen, boss_riflemen, boss_shieldmen)
	end

	menu_state.ClickCallback = function (ok)
		if not is_hero_move and not ok then
			return
		end
		start_battle = ok
		if not start_battle then
			CS.Oak.UI.UISceneManager.Instance:PopOverlay()
			CS.Oak.UI.NavigationBar.Instance.CanUseNavigationBarButtons = true
		end
		waiting_for_popup = false
	end

	music_player:PlaySfxOneShot('03_dialogue_ready_01')
	CS.Oak.UI.WorldExploreFieldUI.Instance:HideFieldUI()

	-- 나가기 팝업이 떠있을 경우를 대비해 막아둔다..
	while ui_scene_manager.CurrentOverlay ~= nil do
		coroutine.yield(nil)
	end

	CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.WorldExploreBossBattlePopup.Instance, menu_state, typeof(CS.Oak.UI.WorldExploreBossBattlePopup))

	CS.Oak.UI.NavigationBar.Instance.CanUseNavigationBarButtons = false
	while waiting_for_popup do
		coroutine.yield(nil)
	end

	if start_battle then
		music_player_util.play_stage_music({ state = 'muted', mix = 2 })
		music_player:PlaySfxOneShot("01_no_del_stage_entry_01")

		message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), "on_manual_battle_group_destroyed")
		message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), "on_manual_game_over")
		screen_util.fade_out_async(0.15, unity_class.color.black, "linear")

		wait_for_sec(0.9)
		CS.Oak.UI.UISceneManager.Instance:PopOverlay()
		CS.Oak.UI.NavigationBar.Instance.CanUseNavigationBarButtons = true

		self.camera_controller:DeactivateTouch()
		self.camera_controller.gameObject:SetActive(false)
		if self.camera_effect ~= nil then
			self.camera_effect.gameObject:SetActive(false)
		end

		coroutine.yield(self:change_manual_party(hero_index))

		local boss_info = self.boss_unit_infos[enemy_index + 1]
		local battle_group = boss_info.BattleGroupName
		local battle_marker = field:GetMarker(boss_info.BattleMarker)

		if self.boss_icon ~= nil then
			self.boss_icon:Dispose()
			self.boss_icon = nil
		end

		-- 버프 적용
		self:add_army_buff_to_party(hero_index, hero_unit.NumSwordmen, hero_unit.NumRiflemen, hero_unit.NumShieldmen)
		add_army_buff_to_battle_group(battle_group, boss_swordmen, boss_riflemen, boss_shieldmen)

		set_dont_fight_on_battle_group(battle_group, true)
		set_death_type_on_battle_group(battle_group)

		CS.Oak.UI.WorldExploreFieldUI.Instance:ShowFieldUI()
		local ui = CS.Oak.UI.WorldExploreFieldUI.Instance
		ui:ShowActionPanel(false)
		ui:ShowEndTurn(false)
		ui:ShowTurn(false)
		ui:ShowRightList(false)
		ui:HideUnitTileInfo()
		ui:ShowTopResourceUI(false)
		field_ui_manager:SetUI(user_party, CS.Oak.FieldUiType.PartyState)
		stage.IsInBattle = true
		ui:SetPauseButtonIcon(false)

		local boss = self.boss_units[enemy_index + 1]
		local boss_field_position = boss.Position
		local boss_field_direction = boss.Direction
		boss.SpineController.Transform.localScale = vector(1,1,1)
		boss.Position = self.boss_original_positions[enemy_index + 1]
		boss.Direction = self.boss_original_directions[enemy_index + 1]

		stage_camera:Move(user_party[0].Position, 0, user_party[0])
		stage_camera:ResizeToDefault(0)
		user_party:PositionParty(battle_marker.position, battle_marker.direction, 0, CS.Oak.Party.AlignType.Arc)
		coroutine.yield(nil)

		self.manual_battle_fought = true
		self.manual_battle_ended = false
		self.manual_battle_player_won = false
		self.manual_battle_group_name = battle_group

		self:set_dino_ride(hero_unit, false)

		for i = 0, user_party.Count -1 do
			user_party[i].SpineController.Transform.localScale = vector(1,1,1)
		end

		screen_util.fade_in_async(0.15, unity_class.color.black, "linear")

		-- FadeIn 된 후에 세계탐험 메뉴얼 전투 시작 이벤트를 배포한다.
		message_system:Publish(CS.Oak.WorldExploreStageEvent.Create(self.constants.event_types.manual_battle_start, nil, nil, 0))

		if self.boss_leader_index ~= nil and self.boss_leader_index == enemy_index then
			music_player_util.play_stage_music({ name = 'bgm_battle_boss', state = 'combat' })
		else
			music_player_util.play_stage_music({ name = 'bgm_battle_normal', state = 'combat' })
		end

		user_party:ResetControllers()
		set_dont_fight_on_battle_group(battle_group, false)

		while not self.manual_battle_ended do
			coroutine.yield(nil)
		end

		if self.manual_battle_player_won then
			wait_for_sec(3.0)

			if boss.CharacterBehaviour.CurrentState:GetType() == typeof(CS.Oak.CharacterBossExplosionState) then
				local boss_cb = boss.CharacterBehaviour
				while boss_cb.CurrentState:GetType() == typeof(CS.Oak.CharacterBossExplosionState) and boss.ActiveState ~= CS.Oak.ActiveState.Disabled do
					coroutine.yield(nil)
				end
				wait_for_sec(1.0)
			end

			music_player:PlaySfxOneShot("01_stage_clear_01")

			screen_util.fade_out_circular_async(0.7, "linear", false)

			user_party:StopAndDisableControl()

			-- 어떤 이유로든 유저가 날고 있다면 그게 끝날때까지 기다린다
			while user_party[0].CharacterBehaviour.CurrentAction == CS.Oak.FieldObjectAction.Flying or user_party[0].CharacterBehaviour.CurrentAction == CS.Oak.FieldObjectAction.KnockedBack or user_party[0].CharacterBehaviour.CurrentAction == CS.Oak.FieldObjectAction.Stunned do
				coroutine.yield(nil)
			end

			-- FadeOut 되면 세계탐험 메뉴얼 전투 종료 이벤트를 배포한다.
			message_system:Publish(CS.Oak.WorldExploreStageEvent.Create(self.constants.event_types.manual_battle_ended, nil, nil, 0))

			local hero_pos = hero_unit:GetFieldPosition()
			self.hero_units[hero_unit.Index + 1][0].CharacterBehaviour:CancelAllBattleActions(true)
			self:set_dino_ride(hero_unit, true)
			self:set_unit_on_field(hero_unit, hero_pos, hero_unit.Direction)

			CS.Oak.CharacterControllerScreenplayState.Stop(boss)
			coroutine.yield(nil)
			coroutine.yield(nil)
			boss.ActiveState = CS.Oak.ActiveState.Visible
			boss.SpineController.SpineOffset = vector(0, 0, 0)
			character_util.set_anim(boss, { name = "damaged", loop = false, mix_duration = 0, scale = 100 })
			self:set_unit_on_field(boss_unit, boss_field_position, get_direction(hero_pos - boss_field_position))

			self:remove_army_buff_from_party(hero_index)
			remove_army_buff_from_battle_group(battle_group)

			boss_unit.Destroyed = true

			if is_hero_move then
				stage_camera:Move(hero_pos, 0, nil)
				ui:ShowRightList(true)
			else
				stage_camera:Move(boss_field_position, 0, nil)
			end
			stage_camera:ResizeTo(self.constants.field_camera_size, 0)

			stage.IsInBattle = false
			ui:ShowTurn(true)
			ui:SetPauseButtonIcon(true)
			ui:ShowTopResourceUI(true)
			self:clear_range_tiles()
			field_ui_manager:RemoveUI(user_party, CS.Oak.FieldUiType.PartyState)
			stage.BattleManager:ClearPendingBattles()

			if self.camera_effect ~= nil then
				self.camera_effect.gameObject:SetActive(true)
			end

			screen_util.fade_out(0, unity_class.color.black)
			screen_util.fade_in_circular(0, "linear")

			wait_for_sec(0.5)

			music_player_util.play_stage_music({ state = 'field', mix = 2 })

			boss:Shake(0.04, 999)
			screen_util.fade_in_async(0.3, unity_class.color.black, "linear")

			local center = boss.Bounds.center
			center.y = center.y * boss.Transform.localScale.y
			local pool = unity_object_pool.GetOrCreate("FX_explosion_small")

			local death_sfx = music_player_util.play_sfx({ sfx_name = '02_hit_loop_01', parent = boss, type_priority = CS.Oak.SfxTypePriority.Loop, player_priority = CS.Oak.SfxPlayerPriority.SmallMonster })

			for k = 0, 3 do
				local xWidth = boss.Hitbox.size.x
				local zDepth = boss.Hitbox.size.z;
				local radiusRand = 0.5 + CS.UnityEngine.Random.value * 0.5
				xWidth = xWidth * radiusRand * boss.Transform.localScale.x
				zDepth = zDepth * radiusRand * boss.Transform.localScale.z

				local rand = CS.UnityEngine.Random.value * CS.UnityEngine.Mathf.PI * 2
				local pos = center + vector(CS.UnityEngine.Mathf.Cos(rand) * xWidth, 0, CS.UnityEngine.Mathf.Sin(rand) * zDepth)

				local e1 = pool:Instantiate(pos)
				e1.transform.localScale = vector(0.3, 0.3, 0.3)
				wait_for_sec(0.125)
			end
			death_sfx:FadeOut(0.1)

			boss.ActiveState = CS.Oak.ActiveState.Disabled
			boss:CancelShake()
			if self.boss_leader_index ~= nil and self.boss_leader_index == boss_unit.Index then
				music_player:PlaySfxOneShot("02_die_boss_invader_01")
				unity_object_pool.GetOrCreate("fx_worldexplore_enemy_dead"):Instantiate(boss.Position)
			else
				music_player:PlaySfxOneShot("02_die_goblin_01")
				unity_object_pool.GetOrCreate("FX_dead"):Instantiate(boss.Position)
			end
			music_player:PlaySfxOneShot("02_explosion_01")

			if is_hero_move then
				hero_unit.MoveEnded = true
				local is_final_move = false
				hero_unit.MoveEnded = false

				if not is_final_move then
					wait_for_sec(0.25)
				end
				self.camera_controller:ActivateTouch()
				self.camera_controller.gameObject:SetActive(true)
			end
		else
			user_party:StopAndDisableControl()
			wait_for_sec(3.0)

			music_player_util.play_stage_music({ state = 'muted', mix = 1 })
			music_player:PlaySfxOneShot("01_drown_01")
			screen_util.fade_out_circular_async(0.7, "linear", false)

			-- FadeOut 되면 세계탐험 메뉴얼 전투 종료 이벤트를 배포한다.
			message_system:Publish(CS.Oak.WorldExploreStageEvent.Create(self.constants.event_types.manual_battle_ended, nil, nil, 0))

			boss.FieldObjectController:OnEvent(CS.Oak.StateResetEvent.Instance)

			if boss.FieldObjectStatsBehaviour.IsDead then
				local new_leader = get_survivor_in_battle_group(battle_group)
				boss = new_leader
				self.boss_units[enemy_index + 1] = boss
			end

			boss.CharacterBehaviour:CancelAllBattleActions()
			self:set_unit_on_field(boss_unit, boss_field_position, boss_field_direction)
			self:set_boss_icon()
			set_dont_fight_on_battle_group(battle_group, true)

			self:remove_army_buff_from_party(hero_index)
			remove_army_buff_from_battle_group(battle_group)

			if user_party.Count > 1 then
				for i = 0, user_party.Count - 1 do
					user_party[i].Position = vector(999, 0, 999)
					user_party[i].ActiveState = CS.Oak.ActiveState.Disabled
				end
			end

			local hero_pos = hero_unit:GetFieldPosition()

			CS.Oak.CharacterControllerScreenplayState.Stop(user_party[0])
			user_party[0].ActiveState = CS.Oak.ActiveState.Visible
			user_party[0].SpineController.SpineOffset = vector(0, 0, 0)
			user_party[0].LockedDirection = CS.Oak.Direction.None
			character_util.set_anim(user_party[0], { name = "embarrassed", loop = true, mix_duration = 0 })

			hero_unit.NumSwordmen = 0
			hero_unit.NumShieldmen = 0
			hero_unit.NumRiflemen = 0
			self:update_army(hero_unit)
			self:set_unit_on_field(hero_unit, hero_pos, get_direction(boss_field_position - hero_pos))

			hero_unit.Destroyed = true

			if is_hero_move then
				stage_camera:Move(hero_pos, 0, nil)
				ui:ShowRightList(true)
			else
				stage_camera:Move(boss_field_position, 0, nil)
			end
			stage_camera:ResizeTo(self.constants.field_camera_size, 0)

			stage.IsInBattle = false
			ui:SetPauseButtonIcon(true)
			ui:ShowTurn(true)
			ui:ShowTopResourceUI(true)
			self:clear_range_tiles()
			field_ui_manager:RemoveUI(user_party, CS.Oak.FieldUiType.PartyState)
			stage.BattleManager:ClearPendingBattles()

			if self.camera_effect ~= nil then
				self.camera_effect.gameObject:SetActive(true)
			end

			screen_util.fade_out(0, unity_class.color.black)
			screen_util.fade_in_circular(0, "linear")

			wait_for_sec(0.5)
			music_player_util.play_stage_music({ state = 'field', mix = 0.5 })

			user_party[0]:Shake(0.04, 999)
			screen_util.fade_in_async(0.3, unity_class.color.black, "linear")

			wait_for_sec(0.4)

			user_party[0].ActiveState = CS.Oak.ActiveState.Disabled
			user_party[0]:CancelShake()

			music_player:PlaySfxOneShot("01_linda_scream_01")
			music_player:PlaySfxOneShot("02_explosion_01")

			unity_object_pool.GetOrCreate("FX_dead"):Instantiate(user_party[0].Position)
			user_party[0].Position = vector(999, 0, 999)

			if is_hero_move then
				self.camera_controller:ActivateTouch()
				self.camera_controller.gameObject:SetActive(true)
			end
		end

		message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), "on_manual_battle_group_destroyed")
		message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent), "on_manual_game_over")
	else
		CS.Oak.UI.WorldExploreFieldUI.Instance:ShowFieldUI()
	end

	if is_hero_move then
		-- 기다려서 TapEvent 가 필드 타일 클릭을 트리거하는 것을 막는다
		wait_for_sec(0.1)
		self.current_phase = self.constants.phases.hero_turn_unit_move_range
	else

	end
end

function local_class:on_manual_battle_group_destroyed(e)
	self.manual_battle_ended = true
	self.manual_battle_player_won = true
	return false
end

function local_class:on_manual_game_over(e)
	self.manual_battle_ended = true
	self.manual_battle_player_won = false
	return false
end

function local_class:to_army_battle(hero_index, enemy_index, is_hero_move)
	if is_hero_move and self.current_phase ~= self.constants.phases.hero_turn_unit_move_range then
		return
	end

	if is_hero_move then
		self.current_phase = self.constants.phases.army_battle
	end

	local units = stage.Units
	local hero_unit = self:get_hero_unit_from_stage(hero_index)
	local enemy_unit = self:get_enemy_unit_from_stage(enemy_index)
	local enemy_info = self.enemy_unit_infos[enemy_index + 1]
	local ui = CS.Oak.UI.WorldExploreFieldUI.Instance

	-- 보스 배틀 팝업을 띄운다
	CS.Oak.UI.NavigationBar.Instance.CanUseNavigationBarButtons = false

	local menu_state = CS.Oak.UI.WorldExploreNormalBattlePopupState()
	local hero = self.hero_units[hero_index + 1][0]
	local csb = hero.FieldObjectStatsBehaviour

	coroutine.yield(self:run_army_battle(hero_unit, enemy_unit, true))

	menu_state.IsReadyMode = true
	menu_state.AllowCancel = is_hero_move
	menu_state.HeroUnitSpriteName = hero.SpriteName
	menu_state.HeroUnitName = game_string:GetString(csb.CharacterSpec.NameWithoutRank)
	menu_state.HeroUnitLevel = csb.Level
	menu_state.HeroUnitCurrentHp = csb.HP
	menu_state.HeroUnitExpectedHp = csb.HP - self.hero_damage
	menu_state.HeroUnitMaxHp = csb.MaxHP
	menu_state.HeroUnitNumSwordmen = hero_unit.NumSwordmen
	menu_state.HeroUnitSwordmenLoss = self.hero_swordmen_damage
	menu_state.HeroUnitNumShieldmen = hero_unit.NumShieldmen
	menu_state.HeroUnitShieldmenLoss = self.hero_shieldmen_damage
	menu_state.HeroUnitNumRiflemen = hero_unit.NumRiflemen
	menu_state.HeroUnitRiflemenLoss = self.hero_riflemen_damage

	self.normal_battle_popup_hero_swordmen:SetActive(hero_unit.NumSwordmen > 0)
	self.normal_battle_popup_hero_riflemen:SetActive(hero_unit.NumRiflemen > 0)
	self.normal_battle_popup_hero_shieldmen:SetActive(hero_unit.NumShieldmen > 0)

	menu_state.EnemyUnitSpriteName = "unknown_enemy"
	menu_state.EnemyUnitName = game_string:Format("world_explore_invader_army", enemy_index + 1)
	menu_state.EnemyUnitLevel = self.enemy_unit_infos[enemy_index + 1].Level
	menu_state.EnemyUnitCurrentHp = (enemy_unit.NumSwordmen + enemy_unit.NumRiflemen + enemy_unit.NumShieldmen) * self.constants.army_to_display_hp
	menu_state.EnemyUnitExpectedHp = (enemy_unit.NumSwordmen + enemy_unit.NumRiflemen + enemy_unit.NumShieldmen - self.enemy_swordmen_damage - self.enemy_riflemen_damage - self.enemy_shieldmen_damage) * self.constants.army_to_display_hp
	menu_state.EnemyUnitMaxHp = self.enemy_unit_max_hps[enemy_index + 1] * self.constants.army_to_display_hp
	menu_state.EnemyUnitNumSwordmen = enemy_unit.NumSwordmen
	menu_state.EnemyUnitSwordmenLoss = self.enemy_swordmen_damage
	menu_state.EnemyUnitNumShieldmen = enemy_unit.NumShieldmen
	menu_state.EnemyUnitShieldmenLoss = self.enemy_shieldmen_damage
	menu_state.EnemyUnitNumRiflemen = enemy_unit.NumRiflemen
	menu_state.EnemyUnitRiflemenLoss = self.enemy_riflemen_damage

	self.normal_battle_popup_enemy_swordmen:SetActive(enemy_unit.NumSwordmen > 0)
	self.normal_battle_popup_enemy_riflemen:SetActive(enemy_unit.NumRiflemen > 0)
	self.normal_battle_popup_enemy_shieldmen:SetActive(enemy_unit.NumShieldmen > 0)

	local waiting_for_popup = true
	local cancelled = false
	menu_state.ClickCallback = function (ok)
		if not waiting_for_popup then
			return
		end
		if not is_hero_move and not ok then
			return
		end
		if not ok then
			CS.Oak.UI.UISceneManager.Instance:PopOverlay()
		end
		waiting_for_popup = false
		if not ok then
			cancelled = true
		end
	end

	CS.Oak.UI.WorldExploreFieldUI.Instance:HideFieldUI()
	music_player:PlaySfxOneShot('03_dialogue_ready_01')

	-- 나가기 팝업이 떠있을 경우를 대비해 막아둔다..
	while ui_scene_manager.CurrentOverlay ~= nil do
		coroutine.yield(nil)
	end

	CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.WorldExploreNormalBattlePopup.Instance, menu_state, typeof(CS.Oak.UI.WorldExploreNormalBattlePopup))

	-- UISceneManager에서의 설정을 씹고 강제로 채팅창보다 낮게 맞춰 준다.
	if self.normal_battle_popup_panel == nil then
		self.normal_battle_popup_panel = CS.Oak.UI.WorldExploreNormalBattlePopup.Instance:GetComponent("UIPanel")
	end

	self.normal_battle_popup_panel.depth = 99
	self.normal_battle_popup_panel.useSortingOrder = false

	while waiting_for_popup do
		coroutine.yield(nil)
	end

	if not cancelled then
		music_player:PlaySfxOneShot("01_no_del_stage_entry_01")
		music_player_util.play_stage_music({ state = 'muted', mix = 2 })

		screen_util.fade_out_async(0.15, unity_class.color.black, "linear")

		self.camera_controller:DeactivateTouch()
		self.camera_controller.gameObject:SetActive(false)

		CS.Oak.UI.WorldExploreFieldUI.Instance:ShowFieldUI()
		ui:ShowActionPanel(false)
		ui:ShowEndTurn(false)
		--ui:ShowTurn(false)
		ui:ShowRightList(false)
		ui:HideUnitTileInfo()
		--ui:ShowTopResourceUI(false)

		self:set_dino_ride(hero_unit, false)
		CS.Oak.UI.UISceneManager.Instance:PopOverlay()

		-- 실제 전투
		coroutine.yield(self:run_army_battle(hero_unit, enemy_unit, false))

		self.army_battle_fought = true

		local hero_pos = hero_unit:GetFieldPosition()
		local enemy_pos = enemy_unit:GetFieldPosition()

		-- 아군 적용
		local hero_dead = csb.HP - self.hero_damage <= 0
		if hero_dead then
			hero_unit.NumSwordmen = 0
			hero_unit.NumRiflemen = 0
			hero_unit.NumShieldmen = 0
		else
			hero_unit.NumSwordmen = hero_unit.NumSwordmen - self.hero_swordmen_damage
			hero_unit.NumRiflemen = hero_unit.NumRiflemen - self.hero_riflemen_damage
			hero_unit.NumShieldmen = hero_unit.NumShieldmen - self.hero_shieldmen_damage
			csb:ChangeHpToFixedValue(csb.HP - self.hero_damage)
		end

		self:set_dino_ride(hero_unit, not hero_dead)
		self:update_army(hero_unit)
		self:set_unit_on_field(hero_unit, hero_unit:GetFieldPosition(), get_direction(enemy_pos - hero_pos))

		if hero_dead then
			hero_unit.Destroyed = true
		end

		enemy_unit.NumSwordmen = enemy_unit.NumSwordmen - self.enemy_swordmen_damage
		enemy_unit.NumRiflemen = enemy_unit.NumRiflemen - self.enemy_riflemen_damage
		enemy_unit.NumShieldmen = enemy_unit.NumShieldmen - self.enemy_shieldmen_damage

		local enemy_dead = enemy_unit.NumSwordmen == 0 and enemy_unit.NumRiflemen == 0 and enemy_unit.NumShieldmen == 0
		if not enemy_dead then
			self:update_army(enemy_unit)
		end
		self:set_unit_on_field(enemy_unit, enemy_unit:GetFieldPosition(), get_direction(hero_pos - enemy_pos))

		if hero_dead then
			local hero = self.hero_units[hero_unit.Index + 1][0]
			character_util.set_anim(hero, { name = "embarrassed", loop = true, mix_duration = 0 })

			hero_unit.Destroyed = true

			if is_hero_move then
				stage_camera:Move(hero_pos, 0, nil)
				ui:ShowRightList(true)
			else
				stage_camera:Move(enemy_pos, 0, nil)
			end
			stage_camera:ResizeTo(self.constants.field_camera_size, 0)

			ui:ShowTurn(true)
			ui:ShowTopResourceUI(true)
			self:clear_range_tiles()

			hero:Shake(0.04, 999)
			music_player_util.play_stage_music({ state = 'field', mix = 0.5 })

			screen_util.fade_out(0, unity_class.color.black)
			screen_util.fade_in_circular(0, "linear")
			wait_for_sec(0.5)
			screen_util.fade_in_async(0.3, unity_class.color.black, "linear")

			wait_for_sec(0.4)

			hero.ActiveState = CS.Oak.ActiveState.Disabled
			hero:CancelShake()

			music_player:PlaySfxOneShot("01_linda_scream_01")
			music_player:PlaySfxOneShot("02_explosion_01")

			unity_object_pool.GetOrCreate("FX_dead"):Instantiate(hero.Position)
			hero.Position = vector(999, 0, 999)
		elseif enemy_dead then
			if is_hero_move then
				stage_camera:Move(hero_pos, 0, nil)
				ui:ShowRightList(true)
			else
				stage_camera:Move(enemy_pos, 0, nil)
			end
			stage_camera:ResizeTo(self.constants.field_camera_size, 0)

			ui:ShowTurn(true)
			ui:ShowTopResourceUI(true)
			self:clear_range_tiles()

			music_player_util.play_stage_music({ state = 'field', mix = 0.5 })

			screen_util.fade_out(0, unity_class.color.black)
			screen_util.fade_in_circular(0, "linear")
			wait_for_sec(0.5)
			screen_util.fade_in_async(0.3, unity_class.color.black, "linear")

			self:update_army(enemy_unit)
			enemy_unit.Destroyed = true
			unity_object_pool.GetOrCreate("FX_dead"):Instantiate(enemy_pos)
			music_player:PlaySfxOneShot("02_die_villain_01")
			music_player:PlaySfxOneShot("02_explosion_01")
		else
			if is_hero_move then
				stage_camera:Move(hero_pos, 0, nil)
				ui:ShowRightList(true)
			else
				stage_camera:Move(enemy_pos, 0, nil)
			end
			stage_camera:ResizeTo(self.constants.field_camera_size, 0)

			ui:ShowTurn(true)
			ui:ShowTopResourceUI(true)
			self:clear_range_tiles()

			music_player_util.play_stage_music({ state = 'field', mix = 0.5 })

			screen_util.fade_out(0, unity_class.color.black)
			screen_util.fade_in_circular(0, "linear")
			wait_for_sec(0.5)
			screen_util.fade_in_async(0.15, unity_class.color.black, "linear")
		end
	end

	CS.Oak.UI.WorldExploreFieldUI.Instance:ShowFieldUI()

	if is_hero_move then
		-- 기다려서 TapEvent 가 필드 타일 클릭을 트리거하는 것을 막는다
		wait_for_sec(0.1)
		self.current_phase = self.constants.phases.hero_turn_unit_move_range
		self.camera_controller:ActivateTouch()
		self.camera_controller.gameObject:SetActive(true)
	end
	CS.Oak.UI.NavigationBar.Instance.CanUseNavigationBarButtons = true
end

function local_class:run_army_battle(hero_unit, enemy_unit, predict)
	local hero_army = 0
	local hero_army_damage = 0
	local hero_leader_damage = 0
	local hero_army_type = nil
	local hero_is_melee = false
	local hero_is_projectile = false
	if hero_unit.NumSwordmen > 0 then
		hero_army = hero_unit.NumSwordmen
		hero_army_type = CS.Oak.WorldExploreStageArmy.Sword
		hero_is_melee = true
		hero_is_projectile = false
	elseif hero_unit.NumRiflemen > 0 then
		hero_army = hero_unit.NumRiflemen
		hero_army_type = CS.Oak.WorldExploreStageArmy.Rifle
		hero_is_melee = false
		hero_is_projectile = true
	elseif hero_unit.NumShieldmen > 0 then
		hero_army = hero_unit.NumShieldmen
		hero_army_type = CS.Oak.WorldExploreStageArmy.Shield
		hero_is_melee = true
		hero_is_projectile = false
	end

	local hero = self.hero_units[hero_unit.Index + 1][0]
	local csb = hero.CharacterStatsBehaviour
	local hero_max_hp =  CS.UnityEngine.Mathf.FloorToInt(csb.Level * self.constants.level_to_army)
	if hero_max_hp <= 0 then
		hero_max_hp = 1
	end

	local enemy_army = 0
	local enemy_army_damage = 0
	local enemy_army_type = nil
	local enemy_is_melee = false
	local enemy_is_projectile = false
	if enemy_unit.NumSwordmen > 0 then
		enemy_army = enemy_unit.NumSwordmen
		enemy_army_type = CS.Oak.WorldExploreStageArmy.Sword
		enemy_is_melee = true
		enemy_is_projectile = false
	elseif enemy_unit.NumRiflemen > 0 then
		enemy_army = enemy_unit.NumRiflemen
		enemy_army_type = CS.Oak.WorldExploreStageArmy.Rifle
		enemy_is_melee = false
		enemy_is_projectile = true
	elseif enemy_unit.NumShieldmen > 0 then
		enemy_army = enemy_unit.NumShieldmen
		enemy_army_type = CS.Oak.WorldExploreStageArmy.Shield
		enemy_is_melee = true
		enemy_is_projectile = false
	end

	-- 실제 카메라 이동 및 병력 배치
	if not predict then
		self.army_state = self.constants.army_states.stopped
		field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.CharacterStats, self.hero_units[hero_unit.Index + 1][0])
		self:battlefield_initialize(hero_unit.NumSwordmen, hero_unit.NumRiflemen, hero_unit.NumShieldmen, enemy_unit.NumSwordmen, enemy_unit.NumRiflemen, enemy_unit.NumShieldmen, hero_unit, enemy_unit)
		coroutine.yield(nil)
	end

	-- Phase 0 : 각 라이플 병이 적 공격
	if not predict then
		if hero_is_projectile or enemy_is_projectile then
			self.army_state = self.constants.army_states.riflemen_blink
			while self.army_state == self.constants.army_states.riflemen_blink do
				coroutine.yield(nil)
			end
		end
	end

	local rifle_kill = false
	local hero_kill = false
	if hero_is_projectile then
		if enemy_army > 0 then
			if enemy_army_type == CS.Oak.WorldExploreStageArmy.Rifle then
				enemy_army_damage = rifle_to_rifle_attack(hero_army)
			elseif enemy_army_type == CS.Oak.WorldExploreStageArmy.Sword then
				enemy_army_damage = rifle_to_sword_attack(hero_army)
			else
				enemy_army_damage = rifle_to_shield_attack(hero_army)
			end
		end

		if enemy_army <= enemy_army_damage then
			rifle_kill = true
		end
	end

	if enemy_is_projectile then
		if hero_army > 0 then
			if hero_army_type == CS.Oak.WorldExploreStageArmy.Rifle then
				hero_army_damage = rifle_to_rifle_attack(enemy_army)
			elseif hero_army_type == CS.Oak.WorldExploreStageArmy.Sword then
				hero_army_damage = rifle_to_sword_attack(enemy_army)
			else
				hero_army_damage = rifle_to_shield_attack(enemy_army)
			end
		else
			hero_leader_damage = rifle_to_leader_attack(enemy_army)

			if (hero_leader_damage / hero_max_hp) * csb.MaxHP >= csb.HP then
				rifle_kill = true
				hero_kill = true
			end
		end
	end

	if not predict then
		if hero_is_projectile or enemy_is_projectile then
			local pool = unity_object_pool.GetOrCreate("FX_Common_CannonFire")
			local center = field:GetZone("army_battleground").Bounds.center

			-- 라이플 사격
			wait_for_sec(0.1)

			if hero_is_projectile then
				local num_rifles = CS.UnityEngine.Mathf.FloorToInt(hero_army / self.constants.battlefield_army_divider)
				if num_rifles == 0 then
					num_rifles = 1
				end

				for i = 0, num_rifles -1 do
					if i >= 5 then
						break
					end

					local offset_index = i
					if i + 5 < num_rifles then
						offset_index = i + 5
					end

					local pos = center + vector(self.constants.battlefield_army_offset + 0.25, 0.15, 0) + self.battlefield_offsets[offset_index]
					local effect = pool:Instantiate(pos)
					effect.transform.localScale = vector(0.5, 0.5, 0.5)
				end
			end

			if enemy_is_projectile then
				local num_rifles = CS.UnityEngine.Mathf.FloorToInt(enemy_army / self.constants.battlefield_army_divider)
				if num_rifles == 0 then
					num_rifles = 1
				end

				for i = 0, num_rifles -1 do
					if i >= 5 then
						break
					end

					local offset_index = i
					if i + 5 < num_rifles then
						offset_index = i + 5
					end

					local offset = self.battlefield_offsets[offset_index]
					offset.x = -offset.x

					local pos = center - vector(self.constants.battlefield_army_offset + 0.25, -0.15, 0) + offset
					local effect = pool:Instantiate(pos)
					effect.transform.localScale = vector(-0.5, 0.5, 0.5)
				end
			end

			music_player:PlaySfxOneShot("02_gun_shoot_01")

			wait_for_sec(0.1)

			battlefield_impact(rifle_kill)

			if hero_is_projectile then
				self:battlefield_update_army(false, enemy_army_type, enemy_army - enemy_army_damage)
				if rifle_kill and not hero_kill then
					coroutine.yield(battle_end_slow())
				end
			end

			if enemy_is_projectile and hero_army > 0 then
				self:battlefield_update_army(true, hero_army_type, hero_army - hero_army_damage)
			elseif hero_leader_damage > 0 then
				coroutine.yield(self:battlefield_damage_leader(hero_unit, csb.HP, csb.MaxHP, (hero_leader_damage / hero_max_hp) * csb.MaxHP))
			end

			wait_for_sec(0.5)
		end
	end

	local hero_army_left = hero_army - hero_army_damage
	local enemy_army_left = enemy_army - enemy_army_damage

	if ((hero_is_melee and hero_army_left > 0) or (enemy_is_melee and enemy_army_left > 0)) and not rifle_kill then
		-- Phase  1 : 밀리 돌격 & 중앙까지.
		if not predict then
			self.army_state = self.constants.army_states.melee_blink
			while self.army_state == self.constants.army_states.melee_blink do
				coroutine.yield(nil)
			end

			music_player:PlaySfxOneShot("01_crowd_shout_06")

			self.army_state = self.constants.army_states.marching
			-- 양측 보병 전쟁터까지 진군
			while self.battlefield_state ~= self.constants.battlefield_states.centerfight do
				coroutine.yield(nil)
			end
		end

		-- 중앙 씨움이 일어났을 경우
		if hero_is_melee and enemy_is_melee then
			if hero_army_type == CS.Oak.WorldExploreStageArmy.Sword and enemy_army_type == CS.Oak.WorldExploreStageArmy.Sword then
				hero_army_damage = sword_to_sword_attack(enemy_army)
				enemy_army_damage = sword_to_sword_attack(hero_army)
			elseif hero_army_type == CS.Oak.WorldExploreStageArmy.Sword and enemy_army_type == CS.Oak.WorldExploreStageArmy.Shield then
				hero_army_damage = shield_to_sword_attack(enemy_army)
				enemy_army_damage = sword_to_shield_attack(hero_army)
			elseif hero_army_type == CS.Oak.WorldExploreStageArmy.Shield and enemy_army_type == CS.Oak.WorldExploreStageArmy.Sword then
				hero_army_damage = sword_to_shield_attack(enemy_army)
				enemy_army_damage = shield_to_sword_attack(hero_army)
			else
				hero_army_damage = shield_to_shield_attack(enemy_army)
				enemy_army_damage = shield_to_shield_attack(hero_army)
			end

			if not predict then
				-- 결과 처리
				battlefield_impact(((hero_army - hero_army_damage > 0) and (enemy_army - enemy_army_damage <= 0))  or ((hero_army - hero_army_damage <= 0) and (enemy_army - enemy_army_damage > 0)))
				music_player:PlaySfxOneShot("02_imperial_explosion_01")
				self:battlefield_update_army(true, hero_army_type, hero_army - hero_army_damage)
				self:battlefield_update_army(false, enemy_army_type, enemy_army - enemy_army_damage)
			end

			hero_army_left = hero_army - hero_army_damage
			enemy_army_left = enemy_army - enemy_army_damage
		elseif hero_is_melee then
			-- 반대쪽 진지까지 진행
			if not predict then
				while self.battlefield_state ~= self.constants.battlefield_states.othersidefight do
					coroutine.yield(nil)
				end
			end

			if hero_army_type == CS.Oak.WorldExploreStageArmy.Sword then
				enemy_army_damage = sword_to_rifle_attack(hero_army_left)
			else
				enemy_army_damage = shield_to_rifle_attack(hero_army_left)
			end

			if not predict then
				music_player:PlaySfxOneShot("02_imperial_explosion_01")
				battlefield_impact(enemy_army - enemy_army_damage <= 0)
				self:battlefield_update_army(false, enemy_army_type, enemy_army - enemy_army_damage)
			end

			hero_army_left = hero_army - hero_army_damage
			enemy_army_left = enemy_army - enemy_army_damage
		elseif enemy_is_melee then
			-- 반대쪽 진지까지 진행
			if not predict then
				while self.battlefield_state ~= self.constants.battlefield_states.othersidefight do
					coroutine.yield(nil)
				end
			end

			if hero_is_projectile then
				if enemy_army_type == CS.Oak.WorldExploreStageArmy.Sword then
					hero_army_damage = sword_to_rifle_attack(enemy_army_left)
				else
					hero_army_damage = shield_to_rifle_attack(enemy_army_left)
				end

				if not predict then
					music_player:PlaySfxOneShot("02_imperial_explosion_01")
					battlefield_impact(hero_army - hero_army_damage <= 0)
					self:battlefield_update_army(true, hero_army_type, hero_army - hero_army_damage)
				end
			end

			hero_army_left = hero_army - hero_army_damage
			enemy_army_left = enemy_army - enemy_army_damage
		end

		-- 이 시점에서 두 부대 격돌까지는 진행이 되었다.

		if hero_army_left > 0 and enemy_army_left > 0 then
			-- 두 부대가 둘다 살아있을 경우다. 바운스 한다.
			if not predict then
				self.army_state = self.constants.army_states.bouncing
			end
		elseif hero_army_left > 0 and enemy_army_left <= 0 then
			if not predict then
				coroutine.yield(battle_end_slow())

				-- 아군 부대가 벅 부대를 쓰러뜨린 경우.
				while self.battlefield_state ~= self.constants.battlefield_states.leaderfight do
					coroutine.yield(nil)
				end

				self.army_state = self.constants.army_states.stopped
			end
		elseif enemy_army_left > 0 and hero_army_left <= 0 then
			-- 적 부대가 영웅 리더를 노리는 케이스
			if not predict then
				while self.battlefield_state ~= self.constants.battlefield_states.leaderfight do
					coroutine.yield(nil)
				end
			end

			if enemy_is_melee then
				local this_damage = 0
				if enemy_army_type == CS.Oak.WorldExploreStageArmy.Sword then
					this_damage = sword_to_leader_attack(enemy_army_left)
				else
					this_damage = shield_to_leader_attack(enemy_army_left)
				end

				local hp_before = csb.HP - (hero_leader_damage / hero_max_hp) * csb.MaxHP
				hero_leader_damage = hero_leader_damage + this_damage

				if not predict then
					if this_damage > 0 then
						self.army_state = self.constants.army_states.bouncing
						coroutine.yield(self:battlefield_damage_leader(hero_unit, hp_before, csb.MaxHP, (this_damage / hero_max_hp * csb.MaxHP)))
					end
				end
			end

			if not predict then
				if self.army_state == self.constants.army_states.marching then
					self.army_state = self.constants.army_states.stopped
				end
			end
		else
			-- 양쪽 다 죽은 경우. 아무것도 안한다.

		end
	end

	if hero_army_damage > hero_army then
		hero_army_damage = hero_army
	end

	if enemy_army_damage > enemy_army then
		enemy_army_damage = enemy_army
	end

	local hero_dead = false
	local hero_damage = 0
	if hero_leader_damage > 0 then
		-- FIXME : 유닛 혼합 배치가 가능하게 되어 원, 근거리 시퀀스 모두 피해를 입을 수 있게 된다면 전투 대미지 처리/연출 구조 자체의 변경이 필요
		hero_damage = CS.UnityEngine.Mathf.FloorToInt(csb.MaxHP * hero_leader_damage / hero_max_hp)

		if hero_damage >= csb.HP then
			hero_damage = csb.HP
			hero_dead = true
		end

		if hero_damage >= csb.HP and enemy_army - enemy_army_damage == 0 then
			hero_damage = csb.HP - 10
			hero_dead = false
		end
	end

	if hero_army_type == CS.Oak.WorldExploreStageArmy.Sword then
		self.hero_swordmen_damage = hero_army_damage
	else
		self.hero_swordmen_damage = 0
	end

	if hero_army_type == CS.Oak.WorldExploreStageArmy.Rifle then
		self.hero_riflemen_damage = hero_army_damage
	else
		self.hero_riflemen_damage = 0
	end

	if hero_army_type == CS.Oak.WorldExploreStageArmy.Shield then
		self.hero_shieldmen_damage = hero_army_damage
	else
		self.hero_shieldmen_damage = 0
	end

	self.hero_damage = hero_damage

	if enemy_army_type == CS.Oak.WorldExploreStageArmy.Sword then
		self.enemy_swordmen_damage = enemy_army_damage
	else
		self.enemy_swordmen_damage = 0
	end

	if enemy_army_type == CS.Oak.WorldExploreStageArmy.Rifle then
		self.enemy_riflemen_damage = enemy_army_damage
	else
		self.enemy_riflemen_damage = 0
	end

	if enemy_army_type == CS.Oak.WorldExploreStageArmy.Shield then
		self.enemy_shieldmen_damage = enemy_army_damage
	else
		self.enemy_shieldmen_damage = 0
	end


	if not predict then
		wait_for_sec(1.25)

		if hero_dead then
			music_player:PlaySfxOneShot("01_drown_01")
		else
			music_player:PlaySfxOneShot("01_stage_clear_01")
		end
		screen_util.fade_out_circular_async(0.5, "linear", false)

		self.battlefield_state = self.constants.battlefield_states.done
		while self.battlefield_state ~= self.constants.battlefield_states.finished do
			coroutine.yield(nil)
		end

		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CharacterStats, self.hero_units[hero_unit.Index + 1][0])
		self:battlefield_clear()
	end
end

function sword_to_sword_attack(num_swordmen)
	if num_swordmen < 0 then
		num_swordmen = 0
	end

	return num_swordmen
end

function sword_to_shield_attack(num_swordmen)
	if num_swordmen < 0 then
		num_swordmen = 0
	end

	return num_swordmen * 2
end

function sword_to_rifle_attack(num_swordmen)
	if num_swordmen < 0 then
		num_swordmen = 0
	end

	return num_swordmen * 2
end

function sword_to_leader_attack(num_swordmen)
	if num_swordmen < 0 then
		num_swordmen = 0
	end

	return num_swordmen
end

function shield_to_sword_attack(num_shieldmen)
	if num_shieldmen < 0 then
		num_shieldmen = 0
	end

	return CS.UnityEngine.Mathf.FloorToInt(num_shieldmen * 0.1)
end

function shield_to_shield_attack(num_shieldmen)
	if num_shieldmen < 0 then
		num_shieldmen = 0
	end

	return num_shieldmen
end

function shield_to_rifle_attack(num_shieldmen)
	if num_shieldmen < 0 then
		num_shieldmen = 0
	end

	return num_shieldmen * 2
end

function shield_to_leader_attack(num_shieldmen)
	return num_shieldmen
end

function rifle_to_sword_attack(num_riflemen)
	if num_riflemen < 0 then
		num_riflemen = 0
	end

	return num_riflemen * 2
end

function rifle_to_shield_attack(num_riflemen)
	if num_riflemen < 0 then
		num_riflemen = 0
	end

	return CS.UnityEngine.Mathf.FloorToInt(num_riflemen * 0.1)
end

function rifle_to_rifle_attack(num_riflemen)
	if num_riflemen < 0 then
		num_riflemen = 0
	end

	return num_riflemen
end

function rifle_to_leader_attack(num_riflemen)
	if num_riflemen < 0 then
		num_riflemen = 0
	end

	return num_riflemen
end

function battlefield_impact(through)
	stage_camera:Shake(0.05, 0.15)
end

function battle_end_slow()
	CS.GlobalTimeManager.Instance:Mod(0.1, 'battle_end')
	wait_for_sec(0.05)
	CS.GlobalTimeManager.Instance:Unmod('battle_end')
end

function local_class:battlefield_initialize(hero_swordmen, hero_riflemen, hero_shieldmen, enemy_swordmen, enemy_riflemen, enemy_shieldmen, hero_unit, enemy_unit)
	self.battlefield_state = self.constants.battlefield_states.start

	local zone = field:GetZone("army_battleground")
	stage_camera:Move(zone.Bounds.center + vector(0, 0, 0), 0, nil)

	if self.battlefield_armies == nil then
		self.battlefield_armies = create_generic_list(typeof(CS.Oak.PooledUnityObject))
		self.battlefield_army_indices = create_generic_list(typeof(CS.System.Int32))
		self.battlefield_army_states = create_generic_list(typeof(CS.System.Int32))
		self.battlefield_army_time_passed = create_generic_list(typeof(CS.System.Single))

		self.battlefield_fall_calculator = CS.CalculatorFreeFall(10, CS.Oak.Constants.DefaultGravity, 0, 0)

		local z_offset = 0.95
		local x_offset = 0.35
		self.battlefield_offsets = create_generic_list(typeof(CS.UnityEngine.Vector3))
		self.battlefield_offsets:Add(vector(0, 0, 0))
		self.battlefield_offsets:Add(vector(0, 0, z_offset))
		self.battlefield_offsets:Add(vector(0, 0, -z_offset))
		self.battlefield_offsets:Add(vector(0, 0, z_offset * 2))
		self.battlefield_offsets:Add(vector(0, 0, -z_offset * 2))
		self.battlefield_offsets:Add(vector(x_offset, 0, 0))
		self.battlefield_offsets:Add(vector(x_offset, 0, z_offset))
		self.battlefield_offsets:Add(vector(x_offset, 0, -z_offset))
		self.battlefield_offsets:Add(vector(x_offset, 0, z_offset * 2))
		self.battlefield_offsets:Add(vector(x_offset, 0, -z_offset * 2))
	end

	self.battlefield_armies:Clear()
	self.battlefield_army_indices:Clear()
	self.battlefield_army_states:Clear()
	self.battlefield_army_time_passed:Clear()

	local army_offset = self.constants.battlefield_army_offset

	local pool = unity_object_pool.GetOrCreate("world_explore_army")
	local size = self.constants.battlefield_army_size
	local half_height = self.constants.battlefield_army_half_height

	local center = zone.Bounds.center
	local init_pos = center

	init_pos = center + vector(army_offset, 0, 0)
	if hero_swordmen > 0 then
		local num_hero_swordmen = CS.UnityEngine.Mathf.FloorToInt(hero_swordmen / self.constants.battlefield_army_divider)
		if num_hero_swordmen == 0 then
			num_hero_swordmen = 1
		elseif num_hero_swordmen > self.battlefield_offsets.Count then
			num_hero_swordmen = self.battlefield_offsets.Count
		end
		for i = 1, num_hero_swordmen do
			local offset = self.battlefield_offsets[i - 1]
			local army = pool:Instantiate(init_pos + offset)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)):SetArmy("swordmen_walk_1", CS.Oak.WorldExploreStageArmy.Sword, size, half_height)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)).Army.localRotation = unity_class.quaternion.AngleAxis(self.constants.battlefield_camera_angle, vector(1, 0, 0))


			self.battlefield_armies:Add(army)
			self.battlefield_army_indices:Add(i)
			self.battlefield_army_states:Add(0)
			self.battlefield_army_time_passed:Add(0)
		end
	elseif hero_riflemen > 0 then
		local num_hero_riflemen = CS.UnityEngine.Mathf.FloorToInt(hero_riflemen / self.constants.battlefield_army_divider)
		if num_hero_riflemen == 0 then
			num_hero_riflemen = 1
		elseif num_hero_riflemen > self.battlefield_offsets.Count then
			num_hero_riflemen = self.battlefield_offsets.Count
		end
		for i = 1, num_hero_riflemen do
			local offset = self.battlefield_offsets[i - 1]
			local army = pool:Instantiate(init_pos + offset)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)):SetArmy("riflemen_walk_1", CS.Oak.WorldExploreStageArmy.Rifle, size, half_height)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)).Army.localRotation = unity_class.quaternion.AngleAxis(self.constants.battlefield_camera_angle, vector(1, 0, 0))

			self.battlefield_armies:Add(army)
			self.battlefield_army_indices:Add(i)
			self.battlefield_army_states:Add(0)
			self.battlefield_army_time_passed:Add(0)
		end
	elseif hero_shieldmen > 0 then
		local num_hero_shieldmen = CS.UnityEngine.Mathf.FloorToInt(hero_shieldmen / self.constants.battlefield_army_divider)
		if num_hero_shieldmen == 0 then
			num_hero_shieldmen = 1
		elseif num_hero_shieldmen > self.battlefield_offsets.Count then
			num_hero_shieldmen = self.battlefield_offsets.Count
		end
		for i = 1, num_hero_shieldmen do
			local offset = self.battlefield_offsets[i - 1]
			local army = pool:Instantiate(init_pos + offset)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)):SetArmy("shieldmen_walk_1", CS.Oak.WorldExploreStageArmy.Shield, size, half_height)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)).Army.localRotation = unity_class.quaternion.AngleAxis(self.constants.battlefield_camera_angle, vector(1, 0, 0))

			self.battlefield_armies:Add(army)
			self.battlefield_army_indices:Add(i)
			self.battlefield_army_states:Add(0)
			self.battlefield_army_time_passed:Add(0)
		end
	end

	init_pos = center - vector(army_offset, 0, 0)
	if enemy_swordmen > 0 then
		local num_enemy_swordmen = CS.UnityEngine.Mathf.FloorToInt(enemy_swordmen / self.constants.battlefield_army_divider)
		if num_enemy_swordmen == 0 then
			num_enemy_swordmen = 1
		elseif num_enemy_swordmen > self.battlefield_offsets.Count then
			num_enemy_swordmen = self.battlefield_offsets.Count
		end
		for i = 1, num_enemy_swordmen do
			local offset = self.battlefield_offsets[i - 1]
			offset.x = -offset.x
			local army = pool:Instantiate(init_pos + offset)
			army.transform.localScale = vector(-1, 1, 1)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)):SetArmy("invader_swordmen_walk_1", CS.Oak.WorldExploreStageArmy.Sword, size, half_height)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)).Army.localRotation = unity_class.quaternion.AngleAxis(self.constants.battlefield_camera_angle, vector(1, 0, 0))

			self.battlefield_armies:Add(army)
			self.battlefield_army_indices:Add(-i)
			self.battlefield_army_states:Add(0)
			self.battlefield_army_time_passed:Add(0)
		end
	elseif enemy_riflemen > 0 then
		local num_enemy_riflemen = CS.UnityEngine.Mathf.FloorToInt(enemy_riflemen / self.constants.battlefield_army_divider)
		if num_enemy_riflemen == 0 then
			num_enemy_riflemen = 1
		elseif num_enemy_riflemen > self.battlefield_offsets.Count then
			num_enemy_riflemen = self.battlefield_offsets.Count
		end
		for i = 1, num_enemy_riflemen do
			local offset = self.battlefield_offsets[i - 1]
			offset.x = -offset.x
			local army = pool:Instantiate(init_pos + offset)
			army.transform.localScale = vector(-1, 1, 1)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)):SetArmy("invader_riflemen_walk_1", CS.Oak.WorldExploreStageArmy.Rifle, size, half_height)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)).Army.localRotation = unity_class.quaternion.AngleAxis(self.constants.battlefield_camera_angle, vector(1, 0, 0))

			self.battlefield_armies:Add(army)
			self.battlefield_army_indices:Add(-i)
			self.battlefield_army_states:Add(0)
			self.battlefield_army_time_passed:Add(0)
		end
	elseif enemy_shieldmen > 0 then
		local num_enemy_shieldmen = CS.UnityEngine.Mathf.FloorToInt(enemy_shieldmen / self.constants.battlefield_army_divider)
		if num_enemy_shieldmen == 0 then
			num_enemy_shieldmen = 1
		elseif num_enemy_shieldmen > self.battlefield_offsets.Count then
			num_enemy_shieldmen = self.battlefield_offsets.Count
		end
		for i = 1, num_enemy_shieldmen do
			local offset = self.battlefield_offsets[i - 1]
			offset.x = -offset.x
			local army = pool:Instantiate(init_pos + offset)
			army.transform.localScale = vector(-1, 1, 1)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)):SetArmy("invader_shieldmen_walk_1", CS.Oak.WorldExploreStageArmy.Shield, size, half_height)
			army:GetComponent(typeof(CS.Oak.WorldExploreArmy)).Army.localRotation = unity_class.quaternion.AngleAxis(self.constants.battlefield_camera_angle, vector(1, 0, 0))

			self.battlefield_armies:Add(army)
			self.battlefield_army_indices:Add(-i)
			self.battlefield_army_states:Add(0)
			self.battlefield_army_time_passed:Add(0)
		end
	end

	local hero_c = self.hero_units[hero_unit.Index + 1][0]
	hero_c.Position = center + vector(self.constants.battlefield_leader_offset, 0, 0)
	hero_c.Direction = CS.Oak.Direction.Right

	-- 카메라 퍼스펙티브로
	local pivot = stage_camera.Transform.parent
	pivot.localRotation = CS.UnityEngine.Quaternion.AngleAxis(self.constants.battlefield_camera_angle, vector(1, 0, 0))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.battlefield_loop, self)):SuppressCoroutineTerminatedException()

	local end_ratio = 2.75

	if stage_camera.Camera.aspect < 1.5 then
		end_ratio = 3.35
	end

	stage_camera:ResizeTo(end_ratio, 1.0)

	screen_util.fade_in_async(0.15, unity_class.color.black, "linear")
	music_player_util.play_stage_music({ name = 'bgm_run', state = 'combat' })
	wait_for_sec(0.75)
end

function local_class:battlefield_update_army(is_hero, army_type, num_army)
	if num_army < 0 then
		num_army = 0
	end

	local at_least_one = num_army > 0
	num_army = CS.UnityEngine.Mathf.FloorToInt(num_army / self.constants.battlefield_army_divider)
	if at_least_one and num_army <= 0 then
		num_army = 1
	end

	local airspin = false
	for i = 0, self.battlefield_armies.Count - 1 do
		local comp = self.battlefield_armies[i]:GetComponent(typeof(CS.Oak.WorldExploreArmy))
		if self.battlefield_army_states[i] == 0 and comp.Type == army_type then
			if (self.battlefield_army_indices[i] < 0 and not is_hero) or (self.battlefield_army_indices[i] > 0 and is_hero) then
				self.army_hit_pool:Instantiate(comp.Army.position, unity_class.quaternion.identity, comp.Army)
				if math.abs(self.battlefield_army_indices[i]) > num_army then
					self.battlefield_army_states[i] = 1
					self.battlefield_army_time_passed[i] = 0
					airspin = true
				end
			end
		end
	end

	if airspin then
		if not is_hero then
			music_player:PlaySfxOneShot("02_die_villain_01")
		else
			music_player:PlaySfxOneShot("01_villain_scream_04")
		end

		music_player:PlaySfxOneShot("01_air_spin_03")
	end


end

function local_class:battlefield_loop()
	local bounce_time_passed = 0
	local zone = field:GetZone("army_battleground")
	local center = zone.Bounds.center
	local impact_offset = 0.5

	local blink_time_passed = 0
	local blink_duration = 0.5
	local blink_frequency = 2

	local time_passed = 0
	local tick = 0.2

	while true do
		local work_left = false
		local dt = unity_class.time.deltaTime
		local old_tick = CS.UnityEngine.Mathf.FloorToInt(time_passed / tick)
		time_passed = time_passed + dt
		local new_tick = CS.UnityEngine.Mathf.FloorToInt(time_passed / tick)

		local bounce_dist = 0
		if self.army_state == self.constants.army_states.bouncing then
			local old_bounce_time_passed = bounce_time_passed
			bounce_time_passed = bounce_time_passed + dt

			local duration = 0.5
			local bounce_full_dist = 1.0
			local old_prog = CS.UnityEngine.Mathf.Lerp(0, 1, old_bounce_time_passed / duration) * math.pi / 2.0
			local new_prog = CS.UnityEngine.Mathf.Lerp(0, 1, bounce_time_passed / duration) * math.pi / 2.0
			local old_dist = math.sin(old_prog) * bounce_full_dist
			local new_dist = math.sin(new_prog) * bounce_full_dist
			bounce_dist = new_dist - old_dist
		end

		local blink_color = unity_class.color(1, 1, 1, 1)
		if self.army_state == self.constants.army_states.riflemen_blink or self.army_state == self.constants.army_states.melee_blink then
			blink_time_passed = blink_time_passed + dt
			local prog = CS.UnityEngine.Mathf.Lerp(0, 1, blink_time_passed / blink_duration) * math.pi * blink_frequency
			local gray = math.abs(math.cos(prog))
			blink_color = unity_class.color(gray, gray, gray, 1)
		end

		for i = 0, self.battlefield_armies.Count -1 do
			local army = self.battlefield_armies[i]
			local army_comp = army:GetComponent(typeof(CS.Oak.WorldExploreArmy))
			local rebuilt = false

			if new_tick ~= old_tick then
				if self.battlefield_army_indices[i] > 0 then
					if army_comp.Type == CS.Oak.WorldExploreStageArmy.Sword then
						if new_tick % 2 == 0 then
							army_comp.ArmySprite.SpriteName = "swordmen_walk_1"
						else
							army_comp.ArmySprite.SpriteName = "swordmen_walk_2"
						end
					elseif army_comp.Type == CS.Oak.WorldExploreStageArmy.Rifle then
						if new_tick % 2 == 0 then
							army_comp.ArmySprite.SpriteName = "riflemen_walk_1"
						else
							army_comp.ArmySprite.SpriteName = "riflemen_walk_2"
						end
					else
						if new_tick % 2 == 0 then
							army_comp.ArmySprite.SpriteName = "shieldmen_walk_1"
						else
							army_comp.ArmySprite.SpriteName = "shieldmen_walk_2"
						end
					end
				else
					if army_comp.Type == CS.Oak.WorldExploreStageArmy.Sword then
						if new_tick % 2 == 0 then
							army_comp.ArmySprite.SpriteName = "invader_swordmen_walk_1"
						else
							army_comp.ArmySprite.SpriteName = "invader_swordmen_walk_2"
						end
					elseif 	army_comp.Type == CS.Oak.WorldExploreStageArmy.Rifle then
						if new_tick % 2 == 0 then
							army_comp.ArmySprite.SpriteName = "invader_riflemen_walk_1"
						else
							army_comp.ArmySprite.SpriteName = "invader_riflemen_walk_2"
						end
					else
						if new_tick % 2 == 0 then
							army_comp.ArmySprite.SpriteName = "invader_shieldmen_walk_1"
						else
							army_comp.ArmySprite.SpriteName = "invader_shieldmen_walk_2"
						end
					end
				end
			end

			if self.battlefield_army_states[i] == 0 then
				local is_melee = army_comp.Type == CS.Oak.WorldExploreStageArmy.Sword or army_comp.Type == CS.Oak.WorldExploreStageArmy.Shield
				local is_main = math.abs(self.battlefield_army_indices[i]) == 1
				local is_hero = self.battlefield_army_indices[i] > 0

				if self.army_state == self.constants.army_states.marching and is_melee then
					if is_hero then
						army.transform.position = army.transform.position + vector(dt * self.constants.battlefield_march_speed, 0, 0)
						if is_main then
							if self.battlefield_state == self.constants.battlefield_states.start then
								if army.transform.position.x >= center.x - impact_offset then
									self.battlefield_state = self.constants.battlefield_states.centerfight
								end
							elseif self.battlefield_state == self.constants.battlefield_states.centerfight then
								if army.transform.position.x >= center.x - self.constants.battlefield_army_offset - impact_offset then
									self.battlefield_state = self.constants.battlefield_states.othersidefight
								end
							elseif self.battlefield_state == self.constants.battlefield_states.othersidefight then
								if army.transform.position.x >= center.x - self.constants.battlefield_leader_offset - impact_offset then
									self.battlefield_state = self.constants.battlefield_states.leaderfight
								end
							end
						end
					else
						army.transform.position = army.transform.position - vector(dt * self.constants.battlefield_march_speed, 0, 0)
						if is_main then
							if self.battlefield_state == self.constants.battlefield_states.start then
								if army.transform.position.x <= center.x + impact_offset then
									self.battlefield_state = self.constants.battlefield_states.centerfight
								end
							elseif self.battlefield_state == self.constants.battlefield_states.centerfight then
								if army.transform.position.x <= center.x + self.constants.battlefield_army_offset + impact_offset then
									self.battlefield_state = self.constants.battlefield_states.othersidefight
								end
							elseif self.battlefield_state == self.constants.battlefield_states.othersidefight then
								if army.transform.position.x <= center.x + self.constants.battlefield_leader_offset + impact_offset then
									self.battlefield_state = self.constants.battlefield_states.leaderfight
								end
							end
						end
					end

				elseif self.army_state == self.constants.army_states.bouncing and is_melee then
					if is_hero then
						army.transform.position = army.transform.position - vector(bounce_dist, 0, 0)
					else
						army.transform.position = army.transform.position + vector(bounce_dist, 0, 0)
					end
				elseif self.army_state == self.constants.army_states.riflemen_blink and army_comp.Type == CS.Oak.WorldExploreStageArmy.Rifle then
					army_comp.ArmySprite.TintColor = blink_color
					army_comp.ArmySprite:Rebuild()
					rebuilt = true
				elseif self.army_state == self.constants.army_states.melee_blink and is_melee then
					army_comp.ArmySprite.TintColor = blink_color
					army_comp.ArmySprite:Rebuild()
					rebuilt = true
				end

			elseif self.battlefield_army_states[i] == 1 then
				local time_passed = self.battlefield_army_time_passed[i]
				time_passed = time_passed + dt

				local duration = 0.75
				local prog = CS.UnityEngine.Mathf.Lerp(0, 1, time_passed / duration)

				self.battlefield_fall_calculator:SetTime(time_passed)

				army_comp.Army.localPosition = vector(0, 0.01 + self.constants.battlefield_army_half_height + self.battlefield_fall_calculator:GetDistance(), 0)
				army_comp.Army.localRotation = unity_class.quaternion.AngleAxis(self.constants.battlefield_camera_angle, vector(1, 0, 0)) * unity_class.quaternion.AngleAxis(720 * time_passed, vector(0, 0, 1))
				army_comp.ArmySprite.TintColor = unity_class.color(1, 1, 1, 1 - prog)
				army_comp.ArmySprite:Rebuild()
				rebuilt = true
				army_comp.Shadow.localScale = vector(1 - prog, 1 - prog, 1 - prog)

				local is_hero = self.battlefield_army_indices[i] > 0
				local airspin_speed = 3.0
				if is_hero then
					local airspin_dir = self.battlefield_offsets[self.battlefield_army_indices[i] - 1]
					airspin_dir.x = -airspin_dir.x
					airspin_dir:Normalize()
					self.battlefield_armies[i].transform.position = self.battlefield_armies[i].transform.position + airspin_dir * airspin_speed * dt
				else
					local airspin_dir = self.battlefield_offsets[-self.battlefield_army_indices[i] - 1]
					airspin_dir:Normalize()
					self.battlefield_armies[i].transform.position = self.battlefield_armies[i].transform.position + airspin_dir * airspin_speed * dt
				end

				if prog >= 1 then
					self.battlefield_army_states[i] = 2
				else
					work_left = true
					self.battlefield_army_time_passed[i] = time_passed
				end
			end

			if new_tick ~= old_tick and not rebuilt then
				army_comp.ArmySprite:Rebuild()
			end
		end

		if self.army_state == self.constants.army_states.riflemen_blink or self.army_state == self.constants.army_states.melee_blink then
			if blink_time_passed >= blink_duration then
				self.army_state = self.constants.army_states.stopped
				blink_time_passed = 0
			end
		end

		if not work_left and self.battlefield_state == self.constants.battlefield_states.done then
			break
		end
		coroutine.yield(nil)
	end

	self.battlefield_state = self.constants.battlefield_states.finished
end

function local_class:battlefield_clear()
	for i = 0, self.battlefield_armies.Count - 1 do
		self.battlefield_armies[i]:GetComponent(typeof(CS.Oak.WorldExploreArmy)):ResetTransforms()
		self.battlefield_armies[i]:Dispose()
	end

	self.battlefield_armies:Clear()
	self.battlefield_army_indices:Clear()
	self.battlefield_army_states:Clear()
	self.battlefield_army_time_passed:Clear()

	stage_camera:ResizeTo(self.constants.field_camera_size, 0)
	local pivot = stage_camera.Transform.parent
	pivot.localRotation = CS.UnityEngine.Quaternion.AngleAxis(45, vector(1, 0, 0))
end

function local_class:battlefield_damage_leader(unit, hp, max_hp, damage)

	local c = self.hero_units[unit.Index + 1][0]
	self.army_hit_pool:Instantiate(c.Bounds.center)
	local dmg = CS.DamageNumber.ShowDamageNumber(c, CS.UnityEngine.Mathf.FloorToInt(damage), unity_class.color.red, c.Position)
	dmg.customRotation = unity_class.quaternion.identity
	c.SpineController:DamageSquish(1)
	c.SpineController:DamageRedPulse()
	if hp > damage then
		music_player:PlaySfxOneShot("02_hit_big_01")
		character_util.set_emotion(c, { name = "damaged", loop = false })
		wait_for_sec(0.25)
		character_util.remove_emotion(c)
	else
		music_player:PlaySfxOneShot("02_hit_critical_01")
		character_util.set_anim(c, { name = "dead", loop = false })
		character_util.set_emotion(c, { name = "damaged", loop = false })
		wait_for_sec(1.5)
	end

	coroutine.yield(nil)
end

function local_class:to_town(hero_unit, town_fo)
	local town = town_fo.FieldObjectBehaviour
	if self.current_phase ~= self.constants.phases.hero_turn_unit_move_range and self.current_phase == self.constants.phases.inactive_town_visit then
		return
	end

	if self.current_phase == self.constants.phases.hero_turn_unit_move_range and hero_unit.MoveEnded then
		return
	end

	if self.current_phase == self.constants.phases.inactive_town_visit and not hero_unit.MoveEnded then
		return
	end

	CS.Oak.UI.NavigationBar.Instance.CanUseNavigationBarButtons = false
	self.current_phase = self.constants.phases.town_visit

	local ui = CS.Oak.UI.WorldExploreTownInfoPopup.Instance
	local waiting_for_popup = true

	local cancel_cb = function ()
		CS.Oak.UI.UISceneManager.Instance:PopOverlay()
		waiting_for_popup = false
	end

	local action_performed = false
	local army_trained = false

	local level_up_cb = function ()
		if town.Level >= #self.constants.town_levelup_costs then
			local state = CS.Oak.UI.PopUpState()
			state.Title = game_string:GetString("world_explore_town_popup_title")
			state.Text = game_string:GetString("world_explore_town_max_level")
			CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.PopUp.Instance, state, typeof(CS.Oak.UI.PopUp))
			return
		end

		local cost_obj = self.constants.town_levelup_costs[town.Level + 1]
		local gold_cost = 0
		if cost_obj["gold"] ~= nil then
			gold_cost = cost_obj["gold"]
		end
		local wood_cost = 0
		if cost_obj["wood"] ~= nil then
			wood_cost = cost_obj["wood"]
		end
		local stone_cost = 0
		if cost_obj["stone"] ~= nil then
			stone_cost = cost_obj["stone"]
		end

		if self.current_gold < gold_cost or self.current_wood < wood_cost or self.current_stone < stone_cost then
			local state = CS.Oak.UI.PopUpState()
			state.Title = game_string:GetString("world_explore_town_popup_title")
			state.Text = game_string:GetString("world_explore_not_enough_resources")
			CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.PopUp.Instance, state, typeof(CS.Oak.UI.PopUp))
			return
		end

		self.current_gold = self.current_gold - gold_cost
		self.current_wood = self.current_wood - wood_cost
		self.current_stone = self.current_stone - stone_cost

		town.Level = town.Level + 1
		action_performed = true

		local gold_per_turn = 0
		for i = 0, self.towns.Count - 1 do
			local t = self.towns[i].FieldObjectBehaviour
			if t.Faction == CS.Oak.WorldExploreStageFaction.Player then
				gold_per_turn = gold_per_turn + self.constants.town_productions[t.Level + 1]
			end
		end
		self.gold_per_turn = gold_per_turn
		self:refresh_town_info(hero_unit, town_fo)

		local state = CS.Oak.UI.PopUpState()
		state.Title = game_string:GetString("world_explore_town_popup_title")
		state.Text = game_string:GetString("world_explore_town_level_up")
		state.IsShowFanfareEffect = true
		CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.PopUp.Instance, state, typeof(CS.Oak.UI.PopUp))
	end

	local produce_army = function (army, gold_cost, wood_cost, stone_cost, amount, from_yesno)
		local town_index = self.towns:IndexOf(town_fo)
		self.current_gold = self.current_gold - gold_cost
		self.current_wood = self.current_wood - wood_cost
		self.current_stone = self.current_stone - stone_cost

		local popup_text = nil
		if army == 0 then
			popup_text = game_string:GetString("world_explore_town_trained_swordmen")
			hero_unit.NumSwordmen = hero_unit.NumSwordmen + CS.UnityEngine.Mathf.RoundToInt(amount)
			hero_unit.NumRiflemen = 0
			hero_unit.NumShieldmen = 0
			self.town_trained[town_index] = 1
		elseif army == 1 then
			popup_text = game_string:GetString("world_explore_town_trained_riflemen")
			hero_unit.NumRiflemen = hero_unit.NumRiflemen + CS.UnityEngine.Mathf.RoundToInt(amount)
			hero_unit.NumSwordmen = 0
			hero_unit.NumShieldmen = 0
			self.town_trained[town_index] = 1
		else
			popup_text = game_string:GetString("world_explore_town_trained_shieldmen")
			hero_unit.NumShieldmen = hero_unit.NumShieldmen + CS.UnityEngine.Mathf.RoundToInt(amount)
			hero_unit.NumSwordmen = 0
			hero_unit.NumRiflemen = 0
			self.town_trained[town_index] = 1
		end

		self:refresh_town_info(hero_unit, town_fo)

		action_performed = true
		army_trained = true

		local state = CS.Oak.UI.PopUpState()
		state.Title = game_string:GetString("world_explore_town_popup_title")
		state.Text = popup_text
		state.IsShowFanfareEffect = true

		if not from_yesno then
			CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.PopUp.Instance, state, typeof(CS.Oak.UI.PopUp))
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(wait_and_launch_popup, state)):SuppressCoroutineTerminatedException()
		end
	end

	local army_cb = function (army)
		local town_index = self.towns:IndexOf(town_fo)
		local already_trained = self.town_trained[town_index] > 0

		-- 이미 훈련했는지 체크
		if already_trained then
			local state = CS.Oak.UI.PopUpState()
			state.Title = game_string:GetString("world_explore_town_popup_title")
			state.Text = game_string:GetString("world_explore_town_already_trained")
			CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.PopUp.Instance, state, typeof(CS.Oak.UI.PopUp))
			return
		end

		-- 재화가 충분한지 체크
		local cost_obj = nil
		if army == 0 then
			cost_obj = self.constants.town_swordmen_costs[town.Level + 1]
		elseif army == 1 then
			cost_obj = self.constants.town_riflemen_costs[town.Level + 1]
		else
			cost_obj = self.constants.town_shieldmen_costs[town.Level + 1]
		end

		local gold_cost = 0
		if cost_obj["gold"] ~= nil then
			gold_cost = cost_obj["gold"]
		end
		local wood_cost = 0
		if cost_obj["wood"] ~= nil then
			wood_cost = cost_obj["wood"]
		end
		local stone_cost = 0
		if cost_obj["stone"] ~= nil then
			stone_cost = cost_obj["stone"]
		end
		local amount = cost_obj["amount"]

		if self.current_gold < gold_cost or self.current_wood < wood_cost or self.current_stone < stone_cost then
			local state = CS.Oak.UI.PopUpState()
			state.Title = game_string:GetString("world_explore_town_popup_title")
			state.Text = game_string:GetString("world_explore_not_enough_resources")
			CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.PopUp.Instance, state, typeof(CS.Oak.UI.PopUp))
			return
		end

		-- 혼성 조합인지 체크
		local mixed = false
		if army == 0 and (hero_unit.NumShieldmen > 0 or hero_unit.NumRiflemen > 0) then
			mixed = true
		elseif army == 1 and (hero_unit.NumShieldmen > 0 or hero_unit.NumSwordmen > 0) then
			mixed = true
		elseif army == 2 and (hero_unit.NumSwordmen > 0 or hero_unit.NumRiflemen > 0) then
			mixed = true
		end

		if mixed then
			local mixed_yesno = function (ok)
				if ok then
					produce_army(army, gold_cost, wood_cost, stone_cost, amount, true)
				end
			end

			local state = CS.Oak.UI.PopUpState()
			state.Title = game_string:GetString("world_explore_town_popup_title")
			state.Text = game_string:GetString("world_explore_town_mixed_train")
			state.NoticePopUp = false
			state.DontPopOverlay = true
			state.OnYesOrNoClicked = mixed_yesno

			CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.PopUp.Instance, state, typeof(CS.Oak.UI.PopUp))
			return
		end

		produce_army(army, gold_cost, wood_cost, stone_cost, amount, false)
	end

	local to_view_map = function ()
		CS.Oak.UI.NavigationBar.Instance:Hide()
	end

	local return_to_town = function ()
		CS.Oak.UI.WorldExploreFieldUI.Instance:HideUnitTileInfo()
		self:clear_range_tiles()
		CS.Oak.UI.NavigationBar.Instance:Show()
	end

	ui:SetCallbacks(cancel_cb, level_up_cb, army_cb, to_view_map, return_to_town)
	self:refresh_town_info(hero_unit, town_fo)

	-- 다른 팝업이 떠있을 경우를 대비해 막아둔다..
	while ui_scene_manager.CurrentOverlay ~= nil do
		coroutine.yield(nil)
	end

	music_player:PlaySfxOneShot('01_interact_cakeshop_01')
	local field_ui = CS.Oak.UI.WorldExploreFieldUI.Instance
	field_ui:ShowTopBar(false)
	field_ui:ShowEndTurn(false)
	field_ui:ShowRightList(false)
	CS.Oak.UI.UISceneManager.Instance:PushOverlay(ui, nil, typeof(CS.Oak.UI.WorldExploreTownInfoPopup))

	while waiting_for_popup do
		coroutine.yield(nil)
	end

	if action_performed then
		self:set_resources()
	end

	if army_trained then
		self:update_army(hero_unit)
		self:set_unit_on_field(hero_unit, hero_unit:GetFieldPosition(), hero_unit.Direction)
	end

	field_ui:ShowTopBar(true)
	field_ui:ShowEndTurn(true)
	field_ui:ShowRightList(true)

	-- 기다려서 TapEvent 가 필드 타일 클릭을 트리거하는 것을 막는다
	wait_for_sec(0.1)

	if hero_unit.MoveEnded then
		self.current_phase = self.constants.phases.hero_turn
	else
		self.current_phase = self.constants.phases.hero_turn_unit_move_range
	end

	CS.Oak.UI.NavigationBar.Instance.CanUseNavigationBarButtons = true
end

function wait_and_launch_popup(state)
	coroutine.yield(nil)
	local popup = CS.Oak.UI.PopUp.Instance
	CS.Oak.UI.UISceneManager.Instance:PopOverlay()

	while lua_helper.reference_equals(popup, CS.Oak.UI.UISceneManager.Instance.CurrentOverlay) do
		coroutine.yield(nil)
	end

	CS.Oak.UI.UISceneManager.Instance:PushOverlay(popup, state, typeof(CS.Oak.UI.PopUp))
end

function local_class:to_focus_hero()
	local unit = self:get_hero_unit_from_stage(self.hero_to_focus)
	self:show_unit_info(unit)
	self.camera_controller:DeactivateTouch()
	self.camera_controller.gameObject:SetActive(false)

	local unit_pos = self:get_unit_position(unit)
	coroutine.yield(self:focus_camera_to(unit_pos, true))

	self.camera_controller:ActivateTouch()
	self.camera_controller.gameObject:SetActive(true)

	if not unit.MoveEnded then
		self.tile_tap_player_index = unit.Index
		self.tile_tap = self.constants.tap_types.active_player
	end
end

function local_class:to_enemy_move(unit)
	if self.range_tiles == nil then
		self.range_tiles = create_generic_list(typeof(CS.Oak.PooledUnityObject))
	end

	local original_pos = CS.UnityEngine.Vector2Int(unit.X, unit.Z)

	local unit_pos = self:get_unit_position(unit)
	coroutine.yield(self:focus_camera_to(unit_pos, true))

	local range = self:get_unit_range(unit)

	self:clear_range_tiles()
	self:get_movement_range(range, unit.Faction, unit.X, unit.Z)
	self:render_movement_range(false)

	local prepare_time_passed = 0
	local duration = 0.1

	while prepare_time_passed < duration do
		prepare_time_passed = prepare_time_passed + unity_class.time.deltaTime
		local prog = CS.UnityEngine.Mathf.Lerp(0, 1, prepare_time_passed / duration)
		for i = 0, self.range_tiles.Count - 1 do
			self.range_tiles[i].transform.localScale = vector(prog, prog, prog)
		end
		coroutine.yield(nil)
	end

	for i = 0, self.range_tiles.Count - 1 do
		self.range_tiles[i].transform.localScale = vector(1, 1, 1)
	end

	local ai = self:get_ai(unit)
	local is_stationary_ai = ai == CS.Oak.WorldExploreAIType.Stationary

	-- 공격 범위내에 타겟이 있는지 서치
	local min_dist = 99999
	local min_index = -1

	-- FIXME: 타이브레이커로 영웅 유닛의 약함을 고려해야 한다.
	for i = 0, self.range_search_interactables.Count - 1 do
		if self.range_search_interactables[i] == self.constants.interactions.battle then
			local dist = math.abs(self.range_search_boundaries[i].x - unit.X) + math.abs(self.range_search_boundaries[i].y - unit.Z)
			if dist < min_dist then
				if not is_stationary_ai or dist == 1 then
					min_dist = dist
					min_index = i
				end
			end
		end
	end

	if min_index >= 0 then
		if self.cursor == nil then
			self.cursor = unity_object_pool.GetOrCreate("world_explore_tile_cursor"):Instantiate(vector(0, 0, 0))
		end
		self.cursor.transform.position = vector(self.range_search_boundaries[min_index].x, 0.02, self.range_search_boundaries[min_index].y)
		wait_for_sec(0.5)
	end

	local target_pos = CS.UnityEngine.Vector2Int(unit.X, unit.Z)
	local target_unit = nil

	-- 이동 처리 (stationary 가 아닐 경우에만)
	if min_index >= 0 and not is_stationary_ai then
		local red_pos = self.range_search_boundaries[min_index]
		min_dist = 99999
		target_unit = self:get_unit_at(vector(red_pos.x, 0, red_pos.y))

		for n = 0, 3 do
			local n_offset = CS.UnityEngine.Vector2Int()
			if n == 0 then
				n_offset.x = 1
				n_offset.y = 0
			elseif n == 1 then
				n_offset.x = 0
				n_offset.y = 1
			elseif n == 2 then
				n_offset.x = -1
				n_offset.y = 0
			else
				n_offset.x = 0
				n_offset.y = -1
			end

			local bv = red_pos + n_offset
			if self.range_search_result:Contains(bv) then
				if (bv.x == unit.X and bv.y == unit.Z) or self:get_unit_at(vector(bv.x, 0, bv.y)) == nil then
					local dist = (vector(bv.x, 0, bv.y) - self:get_unit_position(unit)).magnitude
					if dist < min_dist then
						target_pos = bv
						min_dist = dist
					end
				end
			end
		end

	elseif ai == CS.Oak.WorldExploreAIType.Custom then
		-- 미친개 AI. 공격 범위 안에 아무도 없어도 가장 가까운 적을 향해 달려간다.
		local closest_player_unit = nil
		local closest_dist = -1
		local units = stage.Units
		for i = 0, units.Count - 1 do
			if not units[i].Destroyed and units[i].Faction == CS.Oak.WorldExploreStageFaction.Player then
				local this_dist = (unit:GetFieldPosition() - units[i]:GetFieldPosition()).magnitude
				if closest_player_unit == nil or this_dist < closest_dist then
					closest_player_unit = units[i]
					closest_dist = this_dist
				end
			end
		end

		if closest_player_unit ~= nil then
			target_unit = closest_player_unit
			local player_pos = closest_player_unit:GetFieldPosition()
			local min_range_dist = 99999
			for i = 0, self.range_search_result.Count -1 do
				local this_p = vector(self.range_search_result[i].x, 0, self.range_search_result[i].y)
				if self:get_unit_at(this_p) == nil then
					local this_dist = (this_p - player_pos).magnitude
					if this_dist < min_range_dist then
						min_range_dist = this_dist
						target_pos = self.range_search_result[i]
					end
				end
			end
		end
	end

	local moved = false

	if target_pos.x ~= unit.X or target_pos.y ~= unit.Z then
		unit.X = target_pos.x
		unit.Z = target_pos.y

		local move_from = self:get_unit_position(unit)
		local move_to = vector(unit.X, 0, unit.Z)
		coroutine.yield(self:move_unit_on_field(unit, move_from, move_to, target_unit))
		moved = true
	elseif target_unit ~= nil then
		local new_dir = get_direction(target_unit:GetFieldPosition() - unit:GetFieldPosition())
		self:set_unit_on_field(unit, unit:GetFieldPosition(), new_dir)
	end

	if min_index >= 0 then
		-- 공격 대상이 있을 때 공격을 시작한다.
		local attack_pos = self.range_search_boundaries[min_index]
		local unit_at = self:get_unit_at(vector(attack_pos.x, 0, attack_pos.y))

		if unit.IsBoss then
			coroutine.yield(self:to_manual_battle(unit_at.Index, unit.Index, false))
		else
			coroutine.yield(self:to_army_battle(unit_at.Index, unit.Index, false))
		end

		-- 쓰러뜨린 적 자리에 마을이나 재화 생산소가 있다면 점령한다.
		if unit_at.Destroyed then
			local fo = self:get_field_object_at(vector(attack_pos.x, 0, attack_pos.y))
			if fo ~= nil then
				local fobt = fo.FieldObjectBehaviour:GetType()
				if fobt == typeof(CS.Oak.WorldExploreTownBehaviour) or fobt == typeof(CS.Oak.WorldExploreResourceMineBehaviour) then
					unit.X = attack_pos.x
					unit.Z = attack_pos.y

					wait_for_sec(0.75)
					local move_from = self:get_unit_position(unit)
					local move_to = vector(unit.X, 0, unit.Z)
					coroutine.yield(self:move_unit_on_field(unit, move_from, move_to, nil))
					moved = true
				end
			end
		end
	end

	local already_cleared = false
	-- 새로 도착한 곳에서 이벤트 처리
	if not unit.Destroyed then
		local fo = self:get_field_object_at(unit:GetFieldPosition())
		if fo ~= nil then
			local fobt = fo.FieldObjectBehaviour:GetType()
			if fobt == typeof(CS.Oak.WorldExploreSwitchBehaviour) then
				fo.FieldObjectBehaviour.IsTurnedOn = true
			elseif fobt == typeof(CS.Oak.WorldExploreResourceMineBehaviour) then
				if not moved then
					already_cleared = true
					wait_for_sec(0.5)
					self:clear_range_tiles()
				end
				coroutine.yield(self:conquer_resource(unit, fo))
			elseif fobt == typeof(CS.Oak.WorldExploreTownBehaviour) then
				if not moved then
					already_cleared = true
					wait_for_sec(0.5)
					self:clear_range_tiles()
				end
				coroutine.yield(self:conquer_resource(unit, fo))
			end
		end
	end

	-- 원래 있던 자리에서 이벤트 처리
	if moved or unit.Destroyed then
		local fo = self:get_field_object_at(vector(original_pos.x, 0, original_pos.y))
		if fo ~= nil then
			local fobt = fo.FieldObjectBehaviour:GetType()
			if fobt == typeof(CS.Oak.WorldExploreSwitchBehaviour) then
				fo.FieldObjectBehaviour.IsTurnedOn = false
			end
		end
	end

	-- 현재 위치가 마을이고 AI 가 군대 증설형이라면
	local fo = self:get_field_object_at(unit:GetFieldPosition())
	if not unit.IsBoss and self.enemy_unit_infos[unit.Index + 1].CustomAIType == self.constants.enemy_ai_types.army_adding then
		if fo ~= nil and fo.FieldObjectBehaviour ~= nil and fo.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreTownBehaviour) then
			local town = fo.FieldObjectBehaviour

			-- 마을 레벨업

			local cost_obj = nil
			local gold_cost = 0
			local wood_cost = 0
			local stone_cost = 0

			if town.Level < #self.constants.town_levelup_costs then
				cost_obj = self.constants.town_levelup_costs[town.Level + 1]
			end

			if cost_obj ~= nil then
				if cost_obj["gold"] ~= nil then
					gold_cost = cost_obj["gold"]
				end
				if cost_obj["wood"] ~= nil then
					wood_cost = cost_obj["wood"]
				end
				if cost_obj["stone"] ~= nil then
					stone_cost = cost_obj["stone"]
				end
			end

			if cost_obj ~= nil and self.current_enemy_gold >= gold_cost and self.current_enemy_wood >= wood_cost and self.current_enemy_stone >= stone_cost then
				town.Level = town.Level + 1
				self.current_enemy_gold = self.current_enemy_gold - gold_cost
				self.current_enemy_wood = self.current_enemy_wood - wood_cost
				self.current_enemy_stone = self.current_enemy_stone - stone_cost
				music_player:PlaySfxOneShot("01_heavenhold_build_complete_01")
				CS.Oak.FieldUIFloatingText.Get(fo):ActivateForText(
						game_string:GetString('world_explore_enemy_town_level_up'), 0,
						unity_class.color.red, unity_color({ 0, 0, 0, 0 }))
				wait_for_sec(0.75)
			end

			-- 병사 훈련 시퀀스

			cost_obj = nil
			gold_cost = 0
			wood_cost = 0
			stone_cost = 0
			local upgrade_army = 0
			if unit.NumSwordmen > 0 then
				cost_obj = self.constants.town_swordmen_costs[town.Level + 1]
			elseif unit.NumRiflemen > 0 then
				cost_obj = self.constants.town_riflemen_costs[town.Level + 1]
			elseif unit.NumShieldmen > 0 then
				cost_obj = self.constants.town_shieldmen_costs[town.Level + 1]
			end

			if cost_obj ~= nil then
				if cost_obj["gold"] ~= nil then
					gold_cost = cost_obj["gold"]
				end
				if cost_obj["wood"] ~= nil then
					wood_cost = cost_obj["wood"]
				end
				if cost_obj["stone"] ~= nil then
					stone_cost = cost_obj["stone"]
				end
				upgrade_army = cost_obj["amount"]
			end

			if cost_obj ~= nil and self.current_enemy_gold >= gold_cost and self.current_enemy_wood >= wood_cost and self.current_enemy_stone >= stone_cost then
				self.current_enemy_gold = self.current_enemy_gold - gold_cost
				self.current_enemy_wood = self.current_enemy_wood - wood_cost
				self.current_enemy_stone = self.current_enemy_stone - stone_cost

				if unit.NumSwordmen > 0 then
					unit.NumSwordmen = unit.NumSwordmen + upgrade_army
				elseif unit.NumShieldmen > 0  then
					unit.NumShieldmen = unit.NumShieldmen + upgrade_army
				elseif unit.NumRiflemen > 0 then
					unit.NumRiflemen = unit.NumRiflemen + upgrade_army
				end

				self:update_army(unit)
				self:set_unit_on_field(unit, unit:GetFieldPosition(), unit.Direction)

				local dmg = CS.DamageNumber.ShowDamageNumber(nil, upgrade_army, unity_class.color.green, unit:GetFieldPosition())
				dmg.customRotation = unity_class.quaternion.identity
				music_player:PlaySfxOneShot("01_equip_weapon_01")
				wait_for_sec(0.75)
			end
		end
	end

	if not unit.Destroyed and fo ~= nil and fo.FieldObjectBehaviour:GetType() == typeof(CS.Oak.WorldExploreExitBehaviour) then
		coroutine.yield(self:teleport(unit, fo, false))
	end

	if not already_cleared then
		wait_for_sec(0.5)
		self:clear_range_tiles()
	end
end

-- 연출 함수
function local_class:opening_routine()
	-- NPC 로딩을 위헤 이벤트 컨트롤러에 전달한다.
	self.current_phase = self.constants.phases.stage_event_loading
	message_system:Publish(CS.Oak.WorldExploreStageEvent.Create(self.constants.event_types.start_stage_event_load, nil, nil, 0))

	while self.current_phase ~= self.constants.phases.stage_event_loading_done do
		coroutine.yield(nil)
	end

	coroutine.yield(nil)

	if self.camera_effect_pool ~= nil then
		local camera_t = stage_camera.Camera.transform
		self.camera_effect = self.camera_effect_pool:Instantiate(camera_t.position, camera_t.rotation, camera_t)
	end

	-- 처음 로딩에 시간이 걸리는 sfx 를 미리 한번씩 튼다
	music_player:PlaySfxOneShot("01_ui_grid_01", 0)
	coroutine.yield(nil)

	self.current_phase = self.constants.phases.start_event_running
	message_system:Publish(CS.Oak.WorldExploreStageEvent.Create(self.constants.event_types.stage_launch_ready, nil, nil, 0))

	while self.current_phase ~= self.constants.phases.start_event_done and self.current_phase ~= self.constants.phases.start_event_default do
		coroutine.yield(nil)
	end

	if self.current_phase == self.constants.phases.start_event_default then
		coroutine.yield(self:intro_zoom_and_fade_in(nil))
		field_ui_manager:Show()
		coroutine.yield(self:show_stage_info())
	end

	coroutine.yield(nil)
	coroutine.yield(nil)

	-- 게임 시작
	self.camera_controller:ActivateTouch()
	music_player_util.play_stage_music({ state = 'field', mix = 0 })
	self.current_phase = self.constants.phases.hero_turn_start
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.main_loop, self)):SuppressCoroutineTerminatedException()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.touch_handler, self)):SuppressCoroutineTerminatedException()
end

function local_class:intro_zoom_and_fade_in(start_pos)
	if start_pos == nil then
		local default_marker = field:GetMarker("default_start")
		if default_marker ~= nil then
			start_pos = default_marker.position
		else
			start_pos = vector(0, 0, 0)
		end
	end

	local start_angle = 44.0
	local end_angle = 45.0
	local pivot = stage_camera.Transform.parent
	pivot.localRotation = CS.UnityEngine.Quaternion.AngleAxis(start_angle, vector(1, 0, 0))
	stage_camera:ResizeTo(5.0, 0)
	stage_camera:Move(start_pos, 0, nil)

	coroutine.yield(nil)

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	wait_for_sec(0.3)

	stage_camera:ResizeTo(self.constants.field_camera_size, 2.0)

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')

	local duration = 1.8
	local time_passed = 0
	local title_played = false
	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		local angle = CS.UnityEngine.Mathf.Lerp(start_angle, end_angle, time_passed / duration)
		pivot.localRotation = CS.UnityEngine.Quaternion.AngleAxis(angle, vector(1, 0, 0))

		if not title_played and time_passed > 0.75 then
			title_played = true
			music_player:PlaySfxOneShot("01_stage_intro_jump_01")
			CS.Oak.CommonScreenplay.ShowStageTitle(game_string:GetString(stage.Name), 2.0)
		end

		coroutine.yield(nil)
	end

	pivot.localRotation = CS.UnityEngine.Quaternion.AngleAxis(end_angle, vector(1, 0, 0))

	--wait_for_sec(0.75)
	wait_for_sec(0.35)
end

function local_class:show_stage_info()
	music_player:PlaySfxOneShot("01_coop_matching_start_01")
	ui_scene_manager:PushOverlay(CS.Oak.UI.WorldExploreStageInfoPopup.Instance, nil)

	while CS.Oak.UI.WorldExploreStageInfoPopup.Instance.gameObject.activeSelf do
		coroutine.yield(nil)
	end
end

function local_class:clear_stage()
	self.game_ended = true
	field_ui_manager:Hide()

	music_player:PlaySfxOneShot("01_stage_intro_jump_01")

	local units = stage.Units
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Player then
			if not units[i].Destroyed then
				if start_unit == nil or units[i].Index < start_unit.Index then
					start_unit = units[i]
				end

				local c = self.hero_units[units[i].Index + 1][0]
				character_util.set_emotion(c, { name = "smile", loop = false })
				character_util.set_anim(c, { name = "victory_get", loop = false })
			end
		end
	end

	wait_for_sec(1.25)

	music_player:PlaySfxOneShot("01_crowd_clap_02")
	music_player:PlaySfxOneShot("01_coop_victory_01")
	self.clear_stage_ui:SetActive(true)
	wait_for_sec(4.0)

	if self.has_custom_ending then
		coroutine.yield(CS.Oak.FadeScreenTransition.Instance:FadeOutAsync(0.3, unity_class.color.black, CS.Oak.Interpolations.EaseInOutSine))
		self.clear_stage_ui:SetActive(false)

		self.current_phase = self.constants.phases.ending_event_running
		message_system:Publish(CS.Oak.WorldExploreStageEvent.Create(self.constants.event_types.ending_ready, nil, nil, 0))

		while self.current_phase ~= self.constants.phases.ending_event_done do
			coroutine.yield(nil)
		end
	end

	local failed = false
	coroutine.yield(CS.Oak.NetworkManager.ApiConnection:SendEndWorldExplore(stage.StageId, stage.IsExplore, true, self.current_turn + 1)
					  :Then(function (res) CS.Oak.MerchClient.Instance:ClearStage(res) end)
					  :Catch(function (e)	failed = true end)
					  :SuppressDefaultErrorHandler())

	if failed then
		-- 에러 팝업을 보여준다
		local waitingForPopUp = true
		local state = CS.Oak.UI.PopUpState()
		state.Title = game_string:GetString("ERROR_INTERNAL_SERVER_ERROR")
		state.Text = game_string:GetString("ERROR_INTERNAL_SERVER_ERROR")
		state.DontPopOverlay = true
		state.OnYesOrNoClicked = function (yes)
			waitingForPopUp = false
		end
		CS.Oak.UI.UISceneManager.Instance:PushOverlay(CS.Oak.UI.PopUp.Instance, state, typeof(CS.Oak.UI.PopUp))

		while waitingForPopUp do
			coroutine.yield(nil)
		end
	end

	-- 페이드 아웃
	coroutine.yield(CS.Oak.FadeScreenTransition.Instance:FadeOutAsync(
			0.3, unity_class.color.black, CS.Oak.Interpolations.EaseInOutSine, CS.Oak.LoadingScreen.LoadingMode.Simple))

	CS.Oak.Game.Instance:ExitWorldExploreStage(true and not failed, true)
end

function local_class:game_over(is_turn_over)
	self.game_ended = true

	if is_turn_over then
		local units = stage.Units
		local start_unit = nil
		for i = 0, units.Count - 1 do
			if units[i].Faction == CS.Oak.WorldExploreStageFaction.Player then
				if not units[i].Destroyed then
					if start_unit == nil or units[i].Index < start_unit.Index then
						start_unit = units[i]
					end

					character_util.set_emotion(self.hero_units[units[i].Index + 1][0], { name = "damaged", loop = false})
				end
			end
		end

		if start_unit ~= nil then
			local dist = (start_unit:GetFieldPosition() - stage_camera.LookAtPosition).magnitude
			if dist >= self.constants.hero_turn_focus_distance then
				coroutine.yield(self:focus_camera_to(start_unit:GetFieldPosition(), true))
			end
		end

		self.narration_box:Show()
		coroutine.yield(self.narration_box:SetNarration(game_string:GetString("world_explore_turn_over"), 0, 1, false))
		self.narration_box:Hide()
		music_player:PlaySfxOneShot("01_drown_01")

		for i = 0, units.Count - 1 do
			if units[i].Faction == CS.Oak.WorldExploreStageFaction.Player then
				if not units[i].Destroyed then
					if start_unit == nil or units[i].Index < start_unit.Index then
						start_unit = units[i]
					end
					character_util.set_anim(self.hero_units[units[i].Index + 1][0], { name = "seat", loop = true})
				end
			end
		end
	end

	music_player_util.play_stage_music({ state = 'muted', mix = 1.0 })
	wait_for_sec(0.6)
	field_ui_manager:Hide()

	music_player:PlaySfxOneShot("01_coop_defeat_01")
	self.game_over_ui:SetActive(true)
	wait_for_sec(4.0)

	screen_util.fade_out_async(0.3, unity_class.color.black, CS.Oak.Interpolations.EaseInOutSine, CS.Oak.LoadingScreen.LoadingMode.Simple)

	CS.Oak.Game.Instance:ExitWorldExploreStage()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
