local local_class = newclass('LaboseWorldMagicEyeManager')

---@class LaboseWorldMagicEyeVirtualFieldObjectPool
local vfo_pool = newclass('LaboseWorldMagicEyeVirtualFieldObjectPool')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.fx = setmetatable({
		aura_white = function()
			return unity_object_pool.GetOrCreate('fx_lw_magic_eye_aura_white_under')
		end,
		aura_black = function()
			return unity_object_pool.GetOrCreate('fx_lw_magic_eye_aura_black_under')
		end,
		gimmick_reset = function()
			return unity_object_pool.GetOrCreate('FX_reset_object')
		end,

		---@type fun(this:self)
		load_async = nil,
		---@type fun(this:self, side_type:number)
		get_aura_pool = nil,
	}, {
		__index = {
			load_async = function(this)
				for _, func in pairs(this) do
					func()
				end

				yield_return(unity_object_pool, 'WaitAll')
			end,
			get_aura_pool = function(this, side_type)
				if side_type == self.side_types.white then
					return this.aura_white()
				end

				return this.aura_black()
			end
		}
	})

	self.aura_effect_offsets = {
		default = vector(0, 0.5, -0.2),
		small_pushable = vector(0, 0.6, -0.1),
		tesla_pushable = vector(0, 0.35, -0.1),
		tesla_fixed = vector(0, 0.35, -0.25),
		big = vector(0, 0.8, -0.4),
		big_pushable = vector(0, 1.3, -0.1),
		brazier = vector(0, 0.6, -0.35),
		accel = vector(0, 0.05, 0),
		switch = vector(0, 0.1, -0.1),
	}

	self.states = {
		before_loaded = 1,
		idle = 2,
		in_reversing = 3,
	}

	self.current_state = self.states.before_loaded

	self.side_types = setmetatable({
		white = 1,
		black = 2,
		---@type fun(this:self, side_type:number):any
		get_opposite = nil
	}, {
		__index = {
			get_opposite = function(this, side_type)
				return this.white + this.black - side_type
			end,
			get_switch_child_name = function(this, side_type)
				if side_type == this.white then
					return 'white'
				else
					return 'black'
				end
			end
		}
	})

	self.constants = require('stageeventcontrollers/LaboseWorldMagicEyeConstants')[stage.Name] or {}

	---@class LaboseWorldMagicEyeGroupInfo
	---@field revealing_side_type string
	---@field side_type_groups table<number, table<any, LaboseWorldMagicEyeFoInfo>>
	---@field side_switch any

	---@class LaboseWorldMagicEyeFoInfo
	---@field origin_pos any
	---@field revealed_active_state any
	---@field concealed_pos any
	---@field concealer any
	---@field aura_effect any

	---@type table<string, LaboseWorldMagicEyeGroupInfo>
	self.groups = {
		--key = {
		--	revealing_side_type = self.side_types.type_a,
		--
		--	side_type_groups = {
		--		[self.side_types.type_a] = {
		--			fo = fo,
		--			concealed_pos = unity_class.vector3.zero,
		--			concealer = nil,
		--			aura_effect = nil
		--		},
		--		[self.side_types.type_b] = {},
		--	},
		--}
	}

	---@class LaboseWorldMagicEyeResetSwitchInfo
	---@field group_name string
	---@field reset_targets any[]

	---@type table<any, LaboseWorldMagicEyeResetSwitchInfo>
	self.reset_switch_infos = {}

	self.side_switch_to_group_name = {}

	---@type LaboseWorldMagicEyeVirtualFieldObjectPool
	self.vfo_pool = vfo_pool()

	self.nowhere = vector(500, 0, 0)
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ResetSwitchTurnedOnEvent), 'on_reset_switch_turned_on_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	return util.cs_generator(self.load_resource_routine, self)
end

function local_class:load_resource_routine()
	self.fx:load_async()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ResetSwitchTurnedOnEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	if self.groups ~= nil then
		for _, group_info in pairs(self.groups) do
			for _, type_value in pairs(self.side_types) do
				local fo_infos = group_info.side_type_groups[type_value]

				for _, fo_info in pairs(fo_infos) do
					if fo_info.aura_effect ~= nil then
						if type_util.is_table(fo_info.aura_effect) then
							fo_info.aura_effect.block:Dispose()
							fo_info.aura_effect.accel:Dispose()
						else
							fo_info.aura_effect:Dispose()
						end

						fo_info.aura_effect = nil
					end

					if fo_info.concealer ~= nil then
						self.vfo_pool:return_to_pool(fo_info.concealer)
						fo_info.concealer = nil
					end
				end
			end
		end

		self.groups = nil
	end

	if self.vfo_pool ~= nil then
		self.vfo_pool:dispose()
		self.vfo_pool = nil
	end

	self.cs_controller = nil
end

--region 로직 연관 X
function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end
--endregion

function local_class:on_stage_loaded_event(_)
	start_coroutine(function()
		-- 기믹 내부에서 StageLoaded 관련 세팅이 완료된 이후에 처리하기 위해 한프레임 대기
		coroutine.yield()

		self:set()

		self.current_state = self.states.idle
	end)

	return true
end

function local_class:on_interact_event(e)
	local target_group_name = self.side_switch_to_group_name[e.Target]

	if self.current_state == self.states.idle and target_group_name ~= nil then
		self.current_state = self.states.in_reversing

		sp_util.start_scene(self.reverse_side_scene, self, get_party_leader(), e.Target, target_group_name):Then(function()
			self.current_state = self.states.idle
		end)

		return true
	end

	return false
end

function local_class:on_reset_switch_turned_on_event(e)
	local reset_info = self.reset_switch_infos[e.SwitchObject]

	if reset_info ~= nil then
		self:reset_fos(reset_info)

		return true
	end

	return false
end

function local_class:set()
	for group_name, group_constants in pairs(self.constants) do
		local group_info = {
			side_type_groups = {},
			revealing_side_type = self.side_types[group_constants.start_side_type],
		}

		for type, type_value in pairs(self.side_types) do
			local side_fo_names = group_constants.fo_names[type]
			local side_fo_infos = {}

			for i = 1, #side_fo_names do
				local fo = get_field_object(side_fo_names[i])

				if fo == nil then
					logger_util.error('Cannot find Group FieldObject named [' .. side_fo_names[i] .. '].')
				else
					side_fo_infos[fo] = {
						origin_pos = fo.Position,
					}
				end
			end

			group_info.side_type_groups[type_value] = side_fo_infos
		end

		for reset_switch_name, reset_target_names in pairs(group_constants.reset_switch_infos) do
			local reset_switch = get_field_object(reset_switch_name)

			if reset_switch == nil then
				logger_util.error('Cannot find Reset Switch named [' .. reset_switch_name .. '].')
			else
				local reset_info = {
					group_name = group_name,
					reset_targets = {}
				}

				for _, reset_target_name in pairs(reset_target_names) do
					local reset_target = get_field_object(reset_target_name)

					if reset_target == nil then
						logger_util.error('Cannot find Reset Target named [' .. reset_target_name .. '].')
					else
						table.insert(reset_info.reset_targets, reset_target)
					end
				end

				self.reset_switch_infos[reset_switch] = reset_info
			end
		end

		self.groups[group_name] = group_info

		for _, switch_name in pairs(group_constants.switch_names) do
			local side_switch = get_field_object(switch_name)

			if side_switch == nil then
				logger_util.error('Cannot find Switch Orb named [' .. switch_name .. '].')
			else
				self.side_switch_to_group_name[side_switch] = group_name

				self:set_switch_type(side_switch, group_info.revealing_side_type)
			end
		end

		local conceal_target_side_type = self.side_types:get_opposite(group_info.revealing_side_type)

		self:conceal_side_members(group_info.side_type_groups, conceal_target_side_type)

		local reveal_fo_infos = group_info.side_type_groups[group_info.revealing_side_type]

		for fo, fo_info in pairs(reveal_fo_infos) do
			fo_info.aura_effect = self:instantiate_aura_effect(group_info.revealing_side_type, fo, true)
		end
	end
end

function local_class:set_switch_type(switch_fo, target_side_type)
	local target_side_child_name = self.side_types:get_switch_child_name(target_side_type)
	local visualize_target_go = switch_fo.Transform:Find(target_side_child_name).gameObject

	visualize_target_go:SetActive(true)

	local opposite_side_type = self.side_types:get_opposite(target_side_type)
	local opposite_side_child_name = self.side_types:get_switch_child_name(opposite_side_type)
	local conceal_target_go = switch_fo.Transform:Find(opposite_side_child_name).gameObject

	conceal_target_go:SetActive(false)
end

function local_class:reverse_side_scene(hitter, target_switch, target_group)
	local anim_duration = 0.5
	local hit_delay = 0.2
	local after_hit_duration = anim_duration - hit_delay

	--플레이어 컨트롤 뺏음.
	--플레이어가 기존 청홍벽 때리는 연출과 동일한 연출을 진행.
	scene_util.set_emotion(hitter, self, 'attack')
	scene_util.set_anim(hitter, self, { name = 'sword_attack', count = 1, sfx_name = '01_swing_01' })

	local to_switch_dir = target_switch.Position - hitter.Position

	character_util.spine_deviate_local(hitter, to_switch_dir * 0.3, hit_delay, after_hit_duration)

	wait_for_sec(hit_delay)

	music_player_util.play_sfx_one_shot('01_break_cube_01')
	field_object_util.shake(target_switch, 0.04, 0.3)

	wait_for_sec(after_hit_duration)

	character_util.remove_anim_and_emotion(hitter)

	--때리는 연출이 끝난 후, 0.2초 대기.
	wait_for_sec(0.2)

	music_player_util.play_sfx_one_shot('01_fade_out_08')
	music_player_util.play_sfx_one_shot('01_unlock_02')

	--0.2초만에 화면 하얗게 페이드 아웃.
	screen_util.fade_out_async(0.2, unity_class.color.white)

	self:reverse_side(target_group)

	--0.4초만에 화면 하얗게 페이드 인.
	screen_util.fade_in_async(0.4, unity_class.color.white)

	--플레이어 컨트롤 돌려줌.
end

function local_class:reverse_side(target_group_name)
	local group_info = self.groups[target_group_name]

	local prev_side_type = group_info.revealing_side_type
	local next_side_type = self.side_types:get_opposite(prev_side_type)

	for switch_fo, group_name in pairs(self.side_switch_to_group_name) do
		if group_name == target_group_name then
			self:set_switch_type(switch_fo, next_side_type)
		end
	end

	-- VFO 풀의 카운트를 최대한 줄이기 위함
	self:reveal_side_members(group_info.side_type_groups, next_side_type)
	self:conceal_side_members(group_info.side_type_groups, prev_side_type)

	group_info.revealing_side_type = next_side_type
end

function local_class:conceal_side_members(side_type_groups, side_type)
	local fo_infos = side_type_groups[side_type]

	for fo, fo_info in pairs(fo_infos) do
		if type_util.is_table(fo_info.aura_effect) then
			for _, effect in pairs(fo_info.aura_effect) do
				effect:Dispose()
			end

			fo_info.aura_effect = nil
		else
			if fo_info.aura_effect ~= nil then
				fo_info.aura_effect:Dispose()
				fo_info.aura_effect = nil
			end
		end

		local need_crash = ((fo.ActiveState & active_state_type.infield) == active_state_type.infield) and
				not CS.Oak.ICrashBehaviourExtensions.IsEthereal(fo.CrashBehaviour)
		local need_visualize = (fo.ActiveState & active_state_type.visible) == active_state_type.visible

		if need_crash then
			if fo_info.concealer ~= nil then
				logger_util.warning('[' .. fo.Name .. '] already has concealer VFO.')
			else
				fo_info.concealer = self.vfo_pool:instantiate(fo.Position, fo.Hitbox)
			end
		else
			fo_info.concealed_pos = fo.Position
		end

		if need_visualize then
			fo_info.aura_effect = self:instantiate_aura_effect(side_type, fo, false)
		end

		fo_info.revealed_active_state = fo.ActiveState

		-- visible로 둬야 애니메이션 업데이트가 정상적으로 진행됨
		fo.ActiveState = active_state_type.visible
		fo.Position = self.nowhere
	end
end

function local_class:reveal_side_members(side_type_groups, side_type)
	local fo_infos = side_type_groups[side_type]

	for fo, fo_info in pairs(fo_infos) do
		if type_util.is_table(fo_info.aura_effect) then
			for _, effect in pairs(fo_info.aura_effect) do
				effect:Dispose()
			end

			fo_info.aura_effect = nil
		else
			if fo_info.aura_effect ~= nil then
				fo_info.aura_effect:Dispose()
				fo_info.aura_effect = nil
			end
		end

		if fo_info.concealer ~= nil then
			fo.Position = fo_info.concealer.Position

			self.vfo_pool:return_to_pool(fo_info.concealer)
			fo_info.concealer = nil
		else
			fo.Position = fo_info.concealed_pos
		end

		fo_info.aura_effect = self:instantiate_aura_effect(side_type, fo, true)

		local collided_fos = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(unity_class.vector3.zero, fo.Bounds)

		-- 겹쳐있는 스위치가 존재하는 경우 밟도록 처리
		for i = 1, collided_fos.Count do
			local collided_fo = collided_fos[i - 1]

			if lua_helper.type_compare(collided_fo.FieldObjectBehaviour, CS.Oak.FloorSwitchBehaviour) then
				message_system:SendSync(collided_fo, CS.Oak.FloorSwitchStepOnEvent.Create(fo))
			end
		end

		collided_fos:Dispose()

		fo.ActiveState = fo_info.revealed_active_state
	end
end

function local_class:instantiate_aura_effect(side_type, fo, is_following, origin_fo)
	local effect_pivot = self:get_aura_effect_pivot(fo)

	origin_fo = origin_fo or fo

	local effect_offset = self:get_aura_effect_offset(origin_fo)
	local effect_pos = effect_pivot + effect_offset

	local effect

	if is_following then
		effect = self.fx:get_aura_pool(side_type):Instantiate(effect_pos, unity_class.quaternion.identity, fo.Transform)
	else
		effect = self.fx:get_aura_pool(side_type):Instantiate(effect_pos)
	end

	if lua_helper.type_compare(origin_fo.FieldObjectBehaviour, CS.Oak.FloorSwitchBehaviour) then
		effect.transform.localScale = vector(0.7, 1, 0.7)
	else
		effect.transform.localScale = fo.Bounds.size
	end

	if self:is_pushable_accel(origin_fo) then
		local block_effect = effect
		local accel_effect
		local accel_effect_pos = effect_pivot + self:get_pushable_accel_offset(origin_fo) + self.aura_effect_offsets.accel

		if is_following then
			accel_effect = self.fx:get_aura_pool(side_type)
					:Instantiate(accel_effect_pos, unity_class.quaternion.identity, fo.Transform)
		else
			accel_effect = self.fx:get_aura_pool(side_type):Instantiate(accel_effect_pos)
		end

		accel_effect.transform.localScale = unity_class.vector3.one

		effect = {
			block = block_effect,
			accel = accel_effect,
		}
	end

	return effect
end

function local_class:get_aura_effect_offset(fo)
	local offset = self.aura_effect_offsets.default

	if lua_helper.type_compare(fo.CrashBehaviour, CS.Oak.AccelerateCrashBehaviour) then
		offset = self.aura_effect_offsets.accel

	elseif lua_helper.type_compare(fo.CombustibleBehaviour, CS.Oak.BrazierCombustibleBehaviour) or
			lua_helper.type_compare(fo.CombustibleBehaviour, CS.Oak.ToggleBrazierCombustibleBehaviour) then
		offset = self.aura_effect_offsets.brazier

	elseif lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.FloorSwitchBehaviour) then
		offset = self.aura_effect_offsets.switch

	elseif lua_helper.type_compare(fo.Electrocutable, CS.Oak.TeslaCoilElectrocutable) then
		if lua_helper.type_compare(fo.Pushable, CS.Oak.Pushable)
				or lua_helper.type_compare(fo.Pushable, CS.Oak.UnitPushable)
				or lua_helper.type_compare(fo.Pushable, CS.Oak.DirectionLimitPushable) then
			offset = self.aura_effect_offsets.tesla_pushable
		else
			offset = self.aura_effect_offsets.tesla_fixed
		end

	elseif lua_helper.type_compare(fo.Pushable, CS.Oak.Pushable)
			or lua_helper.type_compare(fo.Pushable, CS.Oak.UnitPushable)
			or lua_helper.type_compare(fo.Pushable, CS.Oak.DirectionLimitPushable) then
		if fo.Bounds.size.x > 1.5 and fo.Bounds.size.z > 1.5 then
			offset = self.aura_effect_offsets.big_pushable
		else
			offset = self.aura_effect_offsets.small_pushable
		end

	elseif fo.Bounds.size.x > 1.5 and fo.Bounds.size.z > 1.5 then
		offset = self.aura_effect_offsets.big
	end

	return offset
end

function local_class:get_aura_effect_pivot(fo)
	return vector_util.get_x0z(fo.Bounds.center, fo.Position.y)
end

---@param reset_info LaboseWorldMagicEyeResetSwitchInfo
function local_class:reset_fos(reset_info)
	local group_info = self.groups[reset_info.group_name]

	for _, fo in pairs(reset_info.reset_targets) do
		for side_type, fo_infos in pairs(group_info.side_type_groups) do
			local fo_info = fo_infos[fo]

			if fo_info == nil then
				goto continue
			end

			if side_type == group_info.revealing_side_type then
				message_system:SendSync(fo, CS.Oak.GimmickResetEvent.Instance)
			elseif side_type ~= group_info.revealing_side_type then
				-- 돌멩이가 너무 특수해서 이렇게 처리했음...
				if self:is_small_rock(fo) then
					message_system:SendSync(fo, CS.Oak.GimmickResetEvent.Instance)

					self:show_gimmick_reset_effect(fo_info.origin_pos, fo.Bounds)

					if fo_info.concealer == nil then
						fo_info.concealer = self.vfo_pool:instantiate(fo_info.origin_pos, fo.Hitbox)
					end

					if fo_info.aura_effect == nil then
						fo_info.aura_effect = self:instantiate_aura_effect(side_type, fo_info.concealer, false)
					end

					fo_info.revealed_active_state = fo.ActiveState

					fo.ActiveState = active_state_type.disabled
				else
					-- 컨실러가 있고, 위치가 이전 위치랑 같다면 리셋하지 않음
					if fo_info.concealer ~= nil and
							vector_util.almost_close_to(fo_info.concealer.Position, fo_info.origin_pos) then
						goto continue
					end

					local consumed = CS.Oak.MessageSystem.Instance:SendSync(fo, CS.Oak.GimmickResetEvent.Instance)

					if not consumed then
						goto continue
					end

					if fo_info.concealer ~= nil then
						self:show_gimmick_reset_effect(fo_info.concealer.Position, fo.Bounds)

						fo_info.concealer.Position = fo_info.origin_pos

						if self:is_pushable_accel(fo) then
							local effect_pivot = self:get_aura_effect_pivot(fo_info.concealer)
							local block_effect_offset = self:get_aura_effect_offset(fo)

							fo_info.aura_effect.block.transform.position = effect_pivot + block_effect_offset
							fo_info.aura_effect.accel.transform.position = effect_pivot +
									self:get_pushable_accel_offset(fo) + self.aura_effect_offsets.accel
						else
							local effect_pivot = self:get_aura_effect_pivot(fo_info.concealer)
							local effect_offset = self:get_aura_effect_offset(fo)

							fo_info.aura_effect.transform.position = effect_pivot + effect_offset
						end
					end

					-- 리셋 직후 되돌려버림
					-- FIXME : 더 좋은 방법이 있을까?
					fo.ActiveState = active_state_type.disabled
					fo.Position = self.nowhere
				end
			end

			::continue::
		end
	end
end

function local_class:is_small_rock(fo)
	return lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.SmallRockBehaviour)
end

function local_class:is_pushable_accel(fo)
	return lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.PushableAccelTileBehaviour)
end

function local_class:get_pushable_accel_offset(fo)
	return direction_util.to_vector3_ver2(fo.Direction)
end

function local_class:show_gimmick_reset_effect(position, bounds)
	local effect = self.fx.gimmick_reset():Instantiate(position)

	effect.transform.localScale = bounds.size
end

--region VirtualFieldObjectPool
---@private
function vfo_pool:init()
	---@private
	self.container = {}
	self.nowhere = vector(500, 0, 0)
end

function vfo_pool:instantiate(position, hit_box)
	local vfo

	if #self.container == 0 then
		vfo = field_object_util.create_virtual_field_object(position, {
			hit_box = hit_box
		})
	else
		vfo = table.remove(self.container, #self.container)

		vfo.Position = position
		vfo.Hitbox = hit_box
		vfo.ActiveState = active_state_type.enabled
	end

	return vfo
end

function vfo_pool:return_to_pool(vfo)
	--FIXME : 디버그용 코드. 성능 문제가 존재하므로 라이브 이전에 지워야됨
	for i = 1, #self.container do
		if lua_helper.reference_equals(vfo, self.container[i]) then
			logger_util.warning('Vfo is already contained in VirtualFieldObjectPool')

			return
		end
	end

	vfo.ActiveState = active_state_type.disabled
	vfo.Position = self.nowhere

	table.insert(self.container, vfo)
end

function vfo_pool:dispose()
	if self.container == nil then
		return
	end

	for i = 1, #self.container do
		self.container[i]:Dispose()
	end

	self.container = nil
end

--endregion VirtualFieldObjectPool

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
