local local_class = newclass('SideStoryBlossom1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 60065
	self.quest_progress = nil

	self.fx = setmetatable({
		portal_red = function()
			return unity_object_pool.GetOrCreate('fx_bs_event_portalspawn_red_open')
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

	self.object = {
		--idx~6
		chasm_hole = function(idx)
			return get_field_object('s3_chasm_hole_' .. idx)
		end,
	}

	self.portal_red_num = 6
	self.portal_additional_num = 2
	self.portal_red_list = {}

	self.field = {
		none = 1,
		main = 2,
		teatan = 3,
	}
	self.current_field = self.field.none
end

function local_class:dispose()
	self:dispose_red_portal()

	message_system:Unsubscribe(self, typeof(CS.Oak.FallInHoleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FallInHoleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
end

function local_class:load_resource()
	self.fx:create_all()

	message_system:Subscribe(self, typeof(CS.Oak.FallInHoleStartEvent), 'on_fall_in_hole_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.FallInHoleEndEvent), 'on_fall_in_hole_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)

	if type_util.is_zone_full_enter(e, get_party_leader(), 'main_field') or
			type_util.is_zone_full_enter(e, get_party_leader(), 'boss_field') then
		self.current_field = self.field.main

		return true

	elseif type_util.is_zone_full_enter(e, get_party_leader(), 'bob_chasm_field') or
			type_util.is_zone_full_enter(e, get_party_leader(), 'hyper_chasm_field') or
			type_util.is_zone_full_enter(e, get_party_leader(), 'student_bad_chasm_field') then
		self.current_field = self.field.teatan

		return true

	end
end

function local_class:on_fall_in_hole_start_event(e)
	if lua_helper.reference_equals(e.Target, get_party_leader()) then
		music_player_util.play_stage_music({ state = 'muted', mix = 0.5 })
	end
end

function local_class:on_fall_in_hole_end_event(e)
	if lua_helper.reference_equals(e.Target, get_party_leader()) then
		if self.current_field == self.field.main then

			music_player_util.play_stage_music({ state = 'field' })

			return true
		elseif self.current_field == self.field.teatan then

			music_player_util.play_stage_music({ state = 'event', name = 'bgm_teatans_main'})

			return true
		end
	end
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	stage_start_util.start_function(quest_progress)

	self:create_red_portal()
	self:setting_red_crystal()
	self:close_battle_gate()

	if quest_progress ~= nil and quest_progress.InnerProgress > 3 then
		self:create_additional_portal()
		field_object_util.set_active_state(get_character('red_crystal'), active_state_type.enabled)
	end
end

function local_class:create_red_portal()
	for idx = 1, self.portal_red_num do
		local chasm_hole = self.object.chasm_hole(idx)

		chasm_hole.Position = chasm_hole.Position + vector(-0.5, 0, -0.5)

		chasm_hole.Hitbox = CS.Oak.Hitbox(vector(0.25, 0, 0.25), vector(2, 1, 2))

		local portal_red = self.fx.portal_red():Instantiate(chasm_hole.Position + vector(0.5, 0, 0.5))

		table.insert(self.portal_red_list, portal_red)
	end
end

function local_class:create_additional_portal()
	for idx = self.portal_red_num + 1, self.portal_red_num + self.portal_additional_num do
		local chasm_hole = self.object.chasm_hole(idx)

		chasm_hole.Position = chasm_hole.Position + vector(-0.5, 0, -1.75)

		chasm_hole.Hitbox = CS.Oak.Hitbox(vector(0.25, 0, 0.125), vector(2, 1, 4))

		local portal_red = self.fx.portal_red():Instantiate(chasm_hole.Position + vector(0.5, 0, 1.75))
		portal_red.transform.localScale = unity_class.vector3.one

		field_object_util.set_active_state(chasm_hole, active_state_type.enabled)

		table.insert(self.portal_red_list, portal_red)
	end
end

function local_class:dispose_red_portal()
	for idx = 1, self.portal_red_num do
		if self.portal_red_list[idx] ~= nil then
			self.portal_red_list[idx]:Dispose()
			self.portal_red_list[idx] = nil
		end
	end

	self.portal_red_list = nil
end

function local_class:setting_red_crystal()
	-- 크리스탈 hit 키우기, ui 제거 및 WallCrashBehaviour 로 변경
	local red_crystal = get_character('red_crystal')

	red_crystal.Hitbox = CS.Oak.Hitbox(vector(2.2, 1.5, 2.2))
	red_crystal.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	red_crystal.Transform.localScale = unity_class.vector3.one * 2

	red_crystal.Position = vector(red_crystal.Position.x, red_crystal.Position.y - 1, red_crystal.Position.z)
	red_crystal.SpineController.ShadowTransform.localPosition = vector(0, 0.03, 0) + vector(0, 0.5, 0)
	red_crystal.SpineController.ShadowTransform.localScale = unity_class.vector3.one * 0.5

	field_ui_manager:RemoveUI(red_crystal, CS.Oak.FieldUiType.CharacterStats)
end

function local_class:close_battle_gate()
	for idx = 1, 4 do
		message_system:PublishSync(CS.Oak.BattleGateCloseEvent.Create('s4_red_crystal_battlegate_' .. idx, true))

	end
end

return local_class
