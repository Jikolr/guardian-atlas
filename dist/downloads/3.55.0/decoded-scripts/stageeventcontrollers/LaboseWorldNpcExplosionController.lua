local local_class = newclass('LaboseWorldNpcExplosionController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- fx
	self.fx = {
		virus_death_explosion = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_death_explosion')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}
	-- zone 처리용
	self.npc_zone_info = nil

	-- stage end 체크용
	self.stage_ended = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	self.npc_zone_info = nil

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.fx:load_all()
	yield_return(unity_object_pool, 'WaitAll')

	local data = get_or_create_global_variable('Quest/Main/LaboseWorld/Common/LaboseWorldNpcExplosionConstants.lua')

	self:zone_fx_setting(data)

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if self.npc_zone_info == nil then
		return false
	end

	for i = 1, #self.npc_zone_info do
		if not self.npc_zone_info[i].explosion_check and
			type_util.is_zone_full_enter(e, get_party_leader(), self.npc_zone_info[i].zone_name) then
			self.npc_zone_info[i].explosion_check = true
			start_coroutine(self.create_zone_cracked_effect, self, self.npc_zone_info[i])

			return true
		end
	end
	return false
end

function local_class:on_stage_end_event(e)
	self.stage_ended = true

	return true
end
--endregion

--- 존 세팅
function local_class:zone_fx_setting(data)
	local zone_info = data[stage.Name]

	if zone_info == nil then
		return
	end

	self.npc_zone_info = {}

	for i = 1, #zone_info do
		local cur_npcs = {}

		for j = 1, #zone_info[i].npcs do
			table.insert(cur_npcs, get_character(zone_info[i].npcs[j]))
		end

		local cur_info = {
			zone_name = zone_info[i].zone,
			delay = zone_info[i].delay,
			npcs = cur_npcs,
			explosion_check = false
		}

		table.insert(self.npc_zone_info, cur_info)
	end
end

function local_class:create_zone_cracked_effect(info)
	local delay = info.delay
	local npcs = info.npcs

	for i = 1, #npcs do
		local cur_npc = npcs[i]

		--카메라 shake (0.5, 0.4)
		camera_util.shake(0.5, 0.4)
		--NPC 위치에 fx_lilithtower_virus_death_explosion 이펙트 생성
		self.fx.virus_death_explosion():Instantiate(cur_npc.Position)
		music_player_util.play_sfx({ sfx_name = '01_fly_explosion_02', play_pos = cur_npc.Position })
		--NPC 캐릭터 제거
		character_util.set_active_state(cur_npc, 'disabled')

		coroutine_util.while_each_frame(delay, function(progress)
			return not self.stage_ended
		end)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
