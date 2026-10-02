local local_class = newclass('NightmareQueenCastle3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	--region Character
	self.get_character = {
		--android_npc (hold_up 용)
		s1_scrap_metal_android_npc = function(number)
			return get_character('s1_scrap_metal_android_npc_' .. number)
		end,
	}
	--endregion Character

	--region Interact Narration Item

	self.interact_narration_item = {
		---@type fun(this:self)
		load = function(this)
			if this.is_load then
				return
			else
				this.is_load = true
			end

			local center_pos = field_util.get_marker_pos(this.marker_pos_name)
			local count = 1

			for key, info in pairs(this.data) do
				local fo = get_field_object(this.fo_prefix .. count)
				local target_pos = center_pos + info.offset

				--item
				local item = quest_drop_item_util.create_item({
					pos = unity_class.vector3.zero,
					item_id = info.id,
					spr_scale = info.scale,
					loot_state = quest_drop_item_loot_state.dont_find_looter,
					show_on_character = false,
					skip_text = true,
				})

				item.Position = target_pos
				item.ShadowTransform.localPosition = vector(0, target_pos.y + 0.01, 0)

				--fo
				fo.Position = vector_util.get_x0z(target_pos, 0)
				fo.Interactable = CS.Oak.PublishInteractable.Create()

				this.data[key].fo = fo
				this.data[key].item = item

				count = count + 1
			end
		end,

		---@type fun(this:self, key:string):IFieldObject
		get_fo = function(this, key)
			return this.data[key].fo
		end,

		---@type fun(this:self, key:string):IFieldObject
		dispose_item = function(this, key)
			quest_drop_item_util.dispose_item(this.data[key].item)
			this.data[key].item = nil
		end,

		---@type fun(this:self, target:IFieldObject):function
		is_interact = function(this, target)
			for key, info in pairs(this.data) do
				if lua_helper.reference_equals(target, this:get_fo(key)) then
					return info.cb
				end
			end

			return false
		end,

		---@type fun(this:self)
		dispose = function(this)
			if not this.is_load then
				return
			end

			--fo
			for key, _ in pairs(this.data) do
				local fo = this:get_fo(key)

				fo.Interactable = CS.Oak.NonInteractable.Instance
				field_object_util.set_active_state(fo, active_state_type.disabled)

				this:dispose_item(key)
			end
		end,

		fo_prefix = 'narration_interact_',
		marker_pos_name = 's3_junk_site_center_pos',
		is_load = false,

		data = {
			magi_item = {
				id = 21522,
				scale = 1,
				offset = vector(-4.5, 0, 0.5),
				cb = self.magi_item_interact_scene,
				fo = nil,
				item = nil,
			},
			stamp_paper = {
				id = 21523,
				scale = 1,
				offset = vector(3, 1.2, 2.5),
				cb = self.stamp_paper_interact_scene,
				fo = nil,
				item = nil,
			},
			paper_piece = {
				id = 21524,
				scale = 1,
				offset = vector(4.5, 0, -0.5),
				cb = self.paper_piece_interact_scene,
				fo = nil,
				item = nil,
			},
		},
	}

	--endregion Interact Narration Item

	--region Marker
	self.get_marker_pos = {
		center = function(number)
			return field_util.get_marker_pos('s1_center_pos_' .. number)
		end,
		quest_marker = function()
			return field_util.get_marker_pos('s1_quest_marker_pos')
		end,
		scrap_metal_move = function(number)
			return field_util.get_marker_pos('s1_scrap_metal_move_pos_' .. number)
		end,
	}
	--endregion Marker

	self.main_quest_id = 458

	self.zone_name = 's1_zone_'

	self.script = nil

	self.is_scrap_metal_scene = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.script:dispose()

	-- section1 고철 이벤트
	self.is_scrap_metal_scene = false

	self.cs_controller = nil

	self.interact_narration_item:dispose()

	self.script = nil
end

function local_class:load_resource()
	local script_path = 'Quest/Nightmare/QueenCastle/Common/WeaponNpcBattleLogic'

	self.script = CS.Oak.StageLuaScript.Create(script_path)
end

function local_class:on_event(e)
	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	self.script:load()

	if quest_progress and not quest_progress.IsComplete then
		self:start_npc_setting()

		if quest_progress.InnerProgress >= 1 then
			self.is_scrap_metal_scene = true

			start_coroutine(self.scrap_metal_scene, self)
		end
	end

	stage_start_util.start_function(quest_progress)

	self:pre_setting()
end

function local_class:on_interact_event(e)

	--region Interact Narration Item

	local cb = self.interact_narration_item:is_interact(e.Target)

	if type_util.is_function(cb) then
		sp_util.start_scene(cb, self)

		return true
	end

	--endregion Interact Narration Item

	return false
end

function local_class:on_zone_enter_event(e)
	--고철 무게 비강제 이벤트
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if self.is_scrap_metal_scene == false and
			(quest_progress and not quest_progress.IsComplete) and
			type_util.is_zone_full_enter(e, get_party_leader(), self.zone_name .. 1) then
		self.is_scrap_metal_scene = true

		start_coroutine(self.scrap_metal_scene, self)
	end
end

function local_class:pre_setting()
	self.interact_narration_item:load()

end

--region Section1 Event
function local_class:scrap_metal_scene()
	local move_pos_1 = self.get_marker_pos.scrap_metal_move(1)
	local move_pos_2 = self.get_marker_pos.scrap_metal_move(2)
	local move_pos_3 = self.get_marker_pos.scrap_metal_move(3)
	local move_pos_4 = self.get_marker_pos.scrap_metal_move(4)

	local npc_1_move_list = {
		move_pos_2 + vector(-0.25, 0, 0),
		move_pos_3 + vector(-0.25, 0, 0),
		move_pos_4 + vector(-0.25, 0, 0),
		move_pos_1 + vector(-0.25, 0, 0),
	}
	local npc_2_move_list = {
		move_pos_2 + vector(0.25, 0, 0),
		move_pos_3 + vector(0.25, 0, 0),
		move_pos_4 + vector(0.25, 0, 0),
		move_pos_1 + vector(0.25, 0, 0),
	}
	--local npc_3_move_list = {
	--	move_pos_2 + vector(0.25, 0, 0),
	--	move_pos_3 + vector(0.25, 0, 0),
	--	move_pos_4 + vector(0.25, 0, 0),
	--	move_pos_1 + vector(0.25, 0, 0),
	--}
	local npc_4_move_list = {
		move_pos_2,
		move_pos_3,
		move_pos_4,
		move_pos_1,
	}

	local npc_1 = self.get_character.s1_scrap_metal_android_npc(1)
	local npc_2 = self.get_character.s1_scrap_metal_android_npc(2)
	local npc_4 = self.get_character.s1_scrap_metal_android_npc(4)

	local speed_1 = 4
	local speed_2 = 2

	start_coroutine(function()
		while self.is_scrap_metal_scene do
			wp_util.move_async(npc_1, npc_4_move_list, speed_1, nil,
					{ locked_dir = 'right', last_direction = 'right' })
		end
	end)

	start_coroutine(function()
		while self.is_scrap_metal_scene do
			wp_util.move_async(npc_2, npc_4_move_list, speed_1, nil,
					{ locked_dir = 'right', last_direction = 'right' })
		end
	end)

	start_coroutine(function()
		while self.is_scrap_metal_scene do
			wp_util.move_with_end_callback(npc_4, npc_4_move_list, speed_2, nil,
					self, 'npc_4', { locked_dir = 'right', last_direction = 'right' })

			wp_util.wait_move_end(self, 'npc_4')
		end
	end)
end
--endregion Section1 Event

--region Setting
function local_class:start_npc_setting()
	-- 1 : 고철 무게 비강제 이벤트
	local center_pos_1 = self.get_marker_pos.center(1)

	local npc_data = {
		--region 고철 무게 비강제 이벤트
		--1번 npc (이더리얼 처리) (right, idle, prostrate)
		{
			target = self.get_character.s1_scrap_metal_android_npc(1),
			pos = center_pos_1 + vector(0.5, 0, 0),
			dir = 'right',
			emo = nil,
			anim = 'prostrate',
			crash_behaviour = CS.Oak.EtherealCrashBehaviour.Instance,
			tint = { color = unity_class.color.black, magnitude = 0.7 },
			is_level_ui = false
		},
		--1번 npc (이더리얼 처리) (right, idle, prostrate)
		{
			target = self.get_character.s1_scrap_metal_android_npc(2),
			pos = center_pos_1 + vector(1, 0, 0),
			dir = 'right',
			emo = nil,
			anim = 'prostrate',
			crash_behaviour = CS.Oak.EtherealCrashBehaviour.Instance,
			tint = { color = unity_class.color.black, magnitude = 0.7 },
			is_level_ui = false
		},
		--2번 npc (이더리얼 처리) (right, idle, prostrate)
		--아래 색상으로 틴트 30% 출력
		--R: 140 / G: 70 / B: 50
		{
			target = self.get_character.s1_scrap_metal_android_npc(4),
			pos = center_pos_1 + vector(-2, 0, 0),
			dir = 'right',
			emo = nil,
			anim = 'prostrate',
			crash_behaviour = CS.Oak.EtherealCrashBehaviour.Instance,
			--alpha = 0.5,
			tint = { color = unity_color({ 90 / 255, 40 / 255, 30 / 255, 1 }), magnitude = 0.7 },
			is_level_ui = false
		},
		--endregion 고철 무게 비강제 이벤트
	}

	self:npc_setting(npc_data)
end

function local_class:npc_setting(npc_data)
	for _, target_data in pairs(npc_data) do
		local target = target_data.target
		local target_pos = target_data.pos
		local target_dir = target_data.dir
		local target_emo = target_data.emo
		local target_anim = target_data.anim
		local target_tint = target_data.tint
		local target_shake = target_data.shake
		local target_is_anim_loop = target_data.is_anim_loop
		local target_effect = target_data.effect
		local target_alpha = target_data.alpha
		local target_function = target_data.coroutine_function
		local target_listener = target_data.listener
		local target_is_not_active = target_data.is_not_active
		local target_oneline_key = target_data.oneline_key
		local target_crash_behaviour = target_data.crash_behaviour
		local target_is_level_ui = target_data.is_level_ui

		if target_is_not_active then
			field_object_util.set_active_state(target, active_state_type.disabled)
		else
			field_object_util.set_active_state(target, active_state_type.enabled)
		end

		if target_crash_behaviour then
			target.CrashBehaviour = target_crash_behaviour
		end

		target.Interactable = CS.Oak.NPCInteractable()

		character_util.set_position(target, target_pos)

		character_util.remove_anim_and_emotion(target)

		scene_util.set_direction(target, target_dir, false)

		if target_emo then
			scene_util.set_emotion(target, self, target_emo)
		end

		if target_oneline_key then
			target.Interactable.Talk = target_oneline_key
		end

		if target_listener then
			character_util.add_listener(target, self.controller)
		end

		if target_anim then
			scene_util.set_anim(target, self, { name = target_anim, loop = target_is_anim_loop, one_shot_sfx = false })
		end

		if target_shake then
			scene_util.shake(target, 0.03, 9999, false)
		end

		if target_tint then
			character_util.add_color(target, 'dark_tint', target_tint.color, target_tint.magnitude, 0)
		end

		if target_alpha then
			character_util.spine_set_alpha_fade_v2(target, target_alpha, 0)
		end

		if target_effect then
			local fx = target_effect():Instantiate(target.Position)
			self.fx_list[target.Name] = fx
		end

		if not target_is_level_ui then
			field_ui_manager:RemoveUI(target, CS.Oak.FieldUiType.CharacterStats)
		end

		if target_function then
			start_coroutine(function()
				target_function(target)
			end)
		end
	end
end
--endregion Setting

--region Interact Narration Interact
function local_class:magi_item_interact_scene()
	--네오=페더레이션 인근 고대 유적 발견?! 시대 추정 불가….
	field_ui_util.show_narration_async({ key = 'nm_qc_sector_ds_narration_1' })
end

function local_class:stamp_paper_interact_scene()
	--네오=페더레이션 사업자등록 신청서
	field_ui_util.show_narration_async({ key = 'nm_qc_sector_ds_narration_2' })
end

function local_class:paper_piece_interact_scene()
	--나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어. 나만이 도울 수 있어.
	field_ui_util.show_narration_async({ key = 'nm_qc_sector_ds_narration_3' })
end

--endregion Interact Narration Interact

return local_class
