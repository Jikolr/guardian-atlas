local local_class = newclass("ShortStoryLahn")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 7000701

	--region box 세팅
	self.box_list = nil
	self.item_list = nil

	self.first_paper = false
	self.second_paper = false
	self.third_paper = false
	self.brazier_check = false

	self.first_paper_id = 20022
	self.third_paper_id = 20167

	self.first_paper_item = nil
	self.third_paper_item = nil
	--endregion

	--region 굿즈 더미 세팅
	self.get_goods_dummy = function() return get_field_object('goods_dummy') end
	--endregion

	-- 눈공의 원래 비주얼 스케일
	self.snowball_visual_scale = nil

	-- 눈공의 원래 히트박스
	self.snowball_original_hitbox = nil

	self.snowball_original_pos = nil

	-- 리셋 이펙트 프리셋
	self.reset_effect = "FX_reset_object"

	self.get_snowball = function() return get_field_object('s13_snowball') end
	self.get_snowball_reset_switch = function() return get_field_object('s13_snowball_reset_switch') end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_item_get_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	unity_object_pool.GetOrCreate(self.reset_effect)
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	self.main_quest_id = 7000701
	self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	self.lahn = get_character('lahn')

	local nol = false
	if self.main_quest_progress == nil or self.main_quest_progress.InnerProgress < 0 then
		nol = true
		--character_util.set_position(self.lahn, field:GetMarker('pre_start').position + vector(0, 0.5, 0))
		-- 메인3 (첫 사냥) 파트 (5,6섹션)
	elseif self.main_quest_progress.InnerProgress > 4 and self.main_quest_progress.InnerProgress < 9 then
		nol = true
	elseif self.main_quest_progress.InnerProgress > 8 and self.main_quest_progress.InnerProgress < 11 then
		nol = true
	elseif self.main_quest_progress.InnerProgress >= 11 and self.main_quest_progress.InnerProgress <= 13 then
		nol = true
	elseif self.main_quest_progress.InnerProgress >= 14 and not self.main_quest_progress.IsComplete then
		nol = true
	end

	if not lua_helper.reference_equals(user_party.Leader, self.lahn) then
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		param.HidePreviousParty = true
		param.MoveCamera = false
		character_util.convert_to_manual_character(self.lahn, param)
	end

	--region box 세팅
	self.item_list = {}
	self.box_list = {}
	for i = 1, 16 do
		table.insert(self.box_list ,get_field_object('goods_box_' .. i))
	end

	local item = drop_item_util.create_item({ pos = get_field_object('goods_dummy').Position,
											  itemid = 20022,
											  notforinven = true, lootstate = 'dontfindlooter' })
	table.insert(self.item_list, item)

	item = drop_item_util.create_item({ pos = get_field_object('goods_dummy').Position
			+ vector(0.5, 0, 0), itemid = 20420,
										notforinven = true, lootstate = 'dontfindlooter' })
	table.insert(self.item_list, item)

	item = drop_item_util.create_item({ pos = get_field_object('goods_dummy').Position
			+ vector(1, 0, 0), itemid = 20421,
										notforinven = true, lootstate = 'dontfindlooter' })
	table.insert(self.item_list, item)

	item = drop_item_util.create_item({ pos = get_field_object('goods_dummy').Position
			+ vector(1.5, 0, 0), itemid = 20422,
										notforinven = true, lootstate = 'dontfindlooter' })
	table.insert(self.item_list, item)

	item = drop_item_util.create_item({ pos = get_field_object('goods_dummy').Position
			+ vector(2, 0, 0), itemid = 20423,
										notforinven = true, lootstate = 'dontfindlooter' })
	table.insert(self.item_list, item)
	unity_object_pool.GetOrCreate('FX_dead')
	--endregion

	--region 굿즈 더미 세팅
	local goods_dummy = self.get_goods_dummy()
	goods_dummy.Hitbox = CS.Oak.Hitbox(vector(1, 2, 2))
	--endregion

	return nol
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	local lahn = get_character('lahn')

	local section_10_pos = field:GetMarker('lupina_room_center').position

	if self.main_quest_progress == nil then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		return
	elseif self.main_quest_progress.InnerProgress > 8 and self.main_quest_progress.InnerProgress < 11 then
		lahn.Position = section_10_pos
		character_util.set_direction(lahn, 'left')
	elseif self.main_quest_progress.InnerProgress == 13 then
		lahn.Position = field:GetMarker('lupina_room_center').position
		character_util.set_direction(lahn, 'up')
	elseif self.main_quest_progress.InnerProgress == 14 then
		lahn.Position = field:GetMarker('lupina_s14_last_pos').position + vector(0, 0, 3)
		lahn.Direction = CS.Oak.Direction.Right
	else
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		return
	end

	camera_util.return_to_leader(0)

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')
	yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry,
		lahn.Position, lahn.Direction, game_string:GetString(stage.Name))

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded()
	elseif event_type == typeof(CS.Oak.MoveFieldObjectEvent) then
		--- 페가수스 스파이크 획득 여부와 관계 없이 빙판 기믹 작동하도록 처리
		if lua_helper.reference_equals(e.FieldObject, self.lahn) then
			--CS.UnityEngine.Debug.LogError('lahn has moved!')
			local actual_diff = vector_util.get_x0z(self.lahn.Position - e.OldPosition)
			local type = field:GetTileInfoAt(self.lahn.Position).types
			if vector_util.magnitude(actual_diff) > 0 and
					(type & CS.Tilemaps.TileTypes.Sliding) ~= CS.Tilemaps.TileTypes.None and
				lua_helper.type_compare(self.lahn.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterAnalogueState) then
				message_system:Send(self.lahn.CharacterBehaviour,
				CS.Oak.StateChangeEvent.Create(CS.Oak.SlideState.Create(self.lahn, direction_util.to_vector3(actual_diff:ToDirection()))))
				--CS.UnityEngine.Debug.LogError('slide start')
			end
		end
	end

	return false
end

--region box 세팅
function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'interacting' then
		for i, box in ipairs(self.box_list) do
			if lua_helper.reference_equals(e.Sender, box) then
				self:box_interacting_end(box, i)
				return true
			end
		end
	end

	return false
end

function local_class:on_item_get_event(e)

	if e.Item.ItemId == self.first_paper_id then
		self.first_paper_item = nil
		sp_util.play_normal_screenplay(function()
			field_ui_util.show_narration_async({ key = 'shortstory_lahn_main_s11_5' })
		end)
	elseif e.Item.ItemId == self.third_paper_id then
		self.third_paper_item = nil
		sp_util.play_normal_screenplay(function()
			field_ui_util.show_narration_async({ key = 'shortstory_lahn_main_s11_7' })
		end)
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	local snowball_reset_switch = self.get_snowball_reset_switch()

	if lua_helper.reference_equals(e.SwitchObject, snowball_reset_switch) then
		if e.IsTurningOn then
			local snowball = self.get_snowball()

			music_player:PlaySfxOneShot('01_guild_warp_01')
			unity_object_pool.GetOrCreate(self.reset_effect):Instantiate(snowball.Position)

			snowball.Transform.localScale = self.snowball_visual_scale
			snowball.Hitbox = self.snowball_original_hitbox
			snowball.Position = self.snowball_original_pos

			unity_object_pool.GetOrCreate(self.reset_effect):Instantiate(snowball.Position)
			return true
		end
	end

	return false
end

function local_class:box_interacting_end(box, index)
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(box.Position)
	box.ActiveState = active_state('disabled')
	music_player_util.play_sfx_one_shot('01_pet_trap_activate_01')

	if index <= 3 then
		get_field_object('goods_present_'..index).Position = box.Position

		local item_id = 20424

		local item = drop_item_util.create_item(
				{ pos = box.Position, itemid = item_id, bounce = true,
				  notforinven = true, lootstate = 'dontfindlooter' })
		table.insert(self.item_list, item)
	elseif index <= 6 then
		if not self.first_paper then
			self.first_paper = true
			local block = get_field_object('present_thorn_block')
			block.Position = box.Position

			self.first_paper_item = drop_item_util.create_item({ pos = box.Position, itemid = self.first_paper_id,
														   target = box.Position - vector(1,0,0),
														   notforinven = true, skip_text = true, lootstate = 'findlooter' })
			self.first_paper_item.PickFlyDistance = 0.5

			-- 플레이어 데미지
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Trap
			damage_info.sender = user_party.Leader
			damage_info.target = user_party.Leader
			damage_info.damage = math.floor(user_party.Leader.FieldObjectStatsBehaviour.MaxHP * 0.1)
			command_util.execute_damage(damage_info)

			-- 플레이어 넉백 방향
			local player_knock_back_dir =
			direction_util.to_vector3(vector_util.to_direction(user_party.Leader.Position - block.Position))

			-- 플레이어 넉백
			local knock_back_info = character_util.knockback_info(
					'linear', true, player_knock_back_dir, nil, nil,
					nil, true, nil, CS.Oak.Constants.WallBounceTime,
					CS.Oak.Constants.WallBounceDistance)

			command_util.publish_knock_back(user_party.Leader.Owner,
					user_party.Leader, knock_back_info, user_party.Leader.Position)
		end
	elseif index <= 8 then
		if not self.brazier_check then
			self.brazier_check = true
			get_field_object('present_brazier').Position = box.Position
		end
	elseif index <= 10 then
		get_field_object('goods_present_'..index - 5).Position = box.Position

		local mall_brick_id = 20426
		item = drop_item_util.create_item({ pos = box.Position, itemid = mall_brick_id,
											notforinven = true, lootstate = 'dontfindlooter' })
		table.insert(self.item_list, item)
	elseif index <= 13 then
		get_field_object('goods_present_'..index - 5).Position = box.Position

		local goods_id = 20427
		item = drop_item_util.create_item({ pos = box.Position, itemid = goods_id,
											notforinven = true, lootstate = 'dontfindlooter' })
		table.insert(self.item_list, item)
	elseif index <= 16 then
		if not self.third_paper then
			self.third_paper = true
			local barrel = get_field_object('present_barrel')
			barrel.Position = box.Position
			message_system:Send(barrel.FieldObjectBehaviour, CS.Oak.BombProvokeEvent.Create(barrel, CS.Oak.BombProvokeType.Fire))

			self.third_paper_item = drop_item_util.create_item({ pos = box.Position, itemid = self.third_paper_id,
														   target = box.Position + vector(1,0,0),
														   notforinven = true, skip_text = true, lootstate = 'findlooter' })
			self.third_paper_item.PickFlyDistance = 0.5
		end
	end
end
--endregion

function local_class:on_stage_loaded()
	local hole = get_field_object('ice_break_hole')
	hole.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	hole.Hitbox = CS.Oak.Hitbox(vector(0.25, 0, 0.75), vector(2, 1, 2))

	local snowball = self.get_snowball()
	self.snowball_visual_scale = snowball.Transform.localScale
	self.snowball_original_hitbox = snowball.Hitbox
	self.snowball_original_pos = snowball.Position
end

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	--region box 세팅
	self.box_list = nil

	for i, item in ipairs(self.item_list) do
		item:ConsumeComplete()
	end
	self.item_list = nil

	if self.first_paper_item ~= nil then
		self.first_paper_item:ConsumeComplete()
		self.first_paper_item = nil
	end
	if self.second_paper_item ~= nil then
		self.second_paper_item:ConsumeComplete()
		self.second_paper_item = nil
	end
	if self.third_paper_item ~= nil then
		self.third_paper_item:ConsumeComplete()
		self.third_paper_item = nil
	end
	--endregion

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
