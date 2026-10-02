local local_class = newclass('NightmareQueenShip1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 메인 퀘스트 id
	self.main_quest_id = 435

	--region Character
	-- 인베이더 기사
	self.get_invader_knight = function()
		return get_party_leader()
	end
	--endregion Character


	--region FieldObject
	self.get_interact_item = function(number)
		return get_field_object('interact_item_' .. number)
	end
	--endregion FieldObject

	--region Marker
	--카메라 마커 (현재 section, scene)
	self.get_interact_item_pos = function(number)
		return field_util.get_marker_pos('interact_item_pos_' .. number)
	end
	--endregion Marker

	--region Sprite
	self.sprite = {
		sprite_info = {
			bubblegum = 21326,
			rc_training = 21327,
			water_mineral = 21328,
			empty_bottle = 21329
		},
		sprite_table = {},
		sprite_table_origin_parent = {},
		create = function(this, name, pos, item_id, scale, showoncharacter, target, drop_type, skip_text)
			scale = lua_helper.get_or_default(scale, 1)
			showoncharacter = lua_helper.get_or_default(showoncharacter, false)

			local item = quest_drop_item_util.create_item(
					{ pos = pos, item_id = item_id, show_on_character = showoncharacter,
					  loot_state = quest_drop_item_loot_state.dont_find_looter, spr_scale = scale, target = target, drop_type = drop_type, skip_text = skip_text })

			this.sprite_table[name] = item
			this.sprite_table_origin_parent[name] = item.SpriteTransform.parent

			return item
		end,
		fly = function(this, name, target)
			this.sprite_table[name].ConsumeTarget = target
			this.sprite_table[name]:Fly()
			this.sprite_table[name] = nil
			this.sprite_table_origin_parent[name] = nil
		end,
		size_set = function(this, name, to, duration, from)
			local from = lua_helper.get_or_default(from, 1)
			local time_passed = 0
			local target = this.sprite_table[name]

			-- time_passed값이 duration보다 작을 경우 반복
			while time_passed < duration do
				local progress = interpolations_constants.linear(time_passed, from, to - from, duration)
				target.SpriteTransform.localScale = unity_class.vector3.one * progress
				target.ShadowTransform.localScale = unity_class.vector3.one * progress

				time_passed = time_passed + unity_class.time.deltaTime
				coroutine.yield(nil)
			end
			target.SpriteTransform.localScale = unity_class.vector3.one * to
			target.ShadowTransform.localScale = unity_class.vector3.one * to

			-- to가 0이 아닐땐 사라지지 않도록
			if float_util.is_almost_zero(to) then
				this:dispose(name)
			end
		end,
		dispose = function(this, name)
			if this.sprite_table[name] then
				if not (this.sprite_table_origin_parent[name] == this.sprite_table[name].SpriteTransform.parent) then
					this.sprite_table[name].SpriteTransform:SetParent(this.sprite_table_origin_parent[name])
				end
				this.sprite_table[name]:ConsumeComplete()
				this.sprite_table[name] = nil
				this.sprite_table_origin_parent[name] = nil
			end
		end,
		dispose_all = function(this)
			if this.sprite_table then
				for name, value in pairs(this.sprite_table) do
					if name then
						this:dispose(name)
					end
				end
			end
			this.sprite_table = nil
			this.sprite_table_origin_parent = nil
		end
	}
	--endregion Sprite

	--region Fx
	self.fx = {
		hit = function()
			return unity_object_pool.GetOrCreate('FX_hit')
		end,
		last_hit = function()
			return unity_object_pool.GetOrCreate('FX_lasthit')
		end,
		custom_sprite = function()
			return unity_object_pool.GetOrCreate('custom_sprite')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}
	--endregion Fx

	--region Etc
	self.wait_pos = vector(999, 0, 999)
	self.save_weapon = nil
	--endregion Etc
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_exit_interact_teleport_start_event(e)
	if e.ExitHandleName == 'exit_inner_1' or
			e.ExitHandleName == 'exit_inner_4' then
		start_coroutine(self.store_oneshot_sfx, self)

	elseif e.ExitHandleName == 'exit_inner_2' or
			e.ExitHandleName == 'exit_inner_3' then
		start_coroutine(self.bar_oneshot_sfx, self)
	end

	return false
end
--endregion event

--region late_update_frame
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
--endregion

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local leader = self.get_invader_knight()

	while leader.IsChangingEquipment do
		coroutine.yield()
	end

	self:remove_equipment(leader)

	-- 시작 연출
	if self.quest_progress == nil or self.quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)

	elseif self.quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s1_start'), false, false)

	elseif self.quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s2_start'), true, true)

	elseif self.quest_progress.InnerProgress == 2 then
		music_player_util.set_stage_music_clip_async({ state = 'field', name = 'ondemand/v2_49_queenship/audio:bgm_queenship_chamber' })
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s3_start'), true, true)

	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	end
	music_player_util.start_bgm_manager()

	self:pre_setting()
end

function local_class:pre_setting()
	self:item_setting()
end

--BGM 변경
function local_class:store_oneshot_sfx()
	wait_for_sec(0.6)

	music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')
end

function local_class:bar_oneshot_sfx()
	wait_for_sec(0.6)

	music_player_util.play_sfx_one_shot('01_interact_restaurant_01')
end

-- 실제 장착 중 장비 없애줌 (무기 스킬 못쓰도록 하기 위함)
function local_class:remove_equipment(target_npc)
	self.save_weapon = {}
	self.save_weapon.weapon1 = target_npc.Weapon1

	target_npc:SetEquipment(CS.Oak.EquipmentSlot.Weapon1, nil)
end

function local_class:show_equipment(target_npc, save_weapon1, save_weapon2)
	target_npc:SetEquipment(CS.Oak.EquipmentSlot.Weapon1, save_weapon1)
end

function local_class:item_setting()
	local items = {
		item_1 = {
			target = self.get_interact_item(1),
			pos = self.get_interact_item_pos(1),
			name = 'bubblegum',
			id = self.sprite.sprite_info.bubblegum,
			scale = 1,
		},
		item_2 = {
			target = self.get_interact_item(2),
			pos = self.get_interact_item_pos(2),
			name = 'rc_training',
			id = self.sprite.sprite_info.rc_training,
			scale = 0.6,
		},
		item_3 = {
			target = self.get_interact_item(3),
			pos = self.get_interact_item_pos(3),
			name = 'empty_bottle',
			id = self.sprite.sprite_info.empty_bottle,
			wait_pos = function()
				if self.quest_progress.InnerProgress ~= 0 then
					return self.wait_pos
				else
					return self.get_interact_item_pos(3)
				end
			end,
			scale = 1,
		},
		item_4 = {
			target = self.get_interact_item(4),
			pos = self.get_interact_item_pos(4),
			name = 'water_mineral',
			id = self.sprite.sprite_info.water_mineral,
			scale = 1,
		}
	}

	for _, item in pairs(items) do
		local target = item.target
		local pos = item.pos
		local target_pos = item.wait_pos
		local item_id = item.id
		local item_name = item.name
		local item_scale = item.scale

		if target_pos then
			target.Position = target_pos()
		else
			target.Position = pos
		end

		self.sprite:create(item_name, target.Position + vector(0, 1, 0),
				item_id, item_scale, true, nil, nil, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
