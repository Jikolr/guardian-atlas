local local_class = newclass('CoopExpeditionStormCurtainController')

--시작하는/끝나는 타이밍 sync 필요?
function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.zone_prefix = 'curtain_zone_'
	self.zone_count = 4
	self.modifier = 0.65
	self.damage_term = 0.3
	self.center_pos = vector(0,0,0)

	self.curtain_list = {}
	self.sender = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CoopEndEvent), 'on_coop_end')
	unity_object_pool.GetOrCreate('fx_boss_pan_stage_effect')
	--boss 받아오기
	self.boss = nil
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		if e:GetParamAt(0) == 'generate_storm_curtain' then
			self.sender = e.Sender
			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Strings:Add('generate_storm_curtain')
			info.Strings:Add(self.sender.Name)
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionStormCurtainController', info)
			--todo: owner를 보스로?
			command_util.publish_cmd(self.sender.Owner, command)

		elseif e:GetParamAt(0) == 'remove_storm_curtain' then
			self.sender = e.Sender
			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Strings:Add('remove_storm_curtain')
			info.Strings:Add(self.sender.Name)
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionStormCurtainController', info)
			command_util.publish_cmd(self.sender.Owner, command)
			--info 해제
			--fx 해제
		end
	end

	return false
end

function local_class:on_coop_end(e)
	if lua_helper.type_compare(e, CS.Oak.CoopEndEvent) then
		self:remove_curtain()
	end
end

function local_class:sync(info)
	if info.Strings[0] == 'generate_storm_curtain' then
		self.sender = stage:GetCharacter(info.Strings[1])
		self:remove_curtain()
		self:generate_curtain()
	elseif info.Strings[1] == 'remove_storm_curtain' then
		self:remove_curtain()
	end
end

function local_class:generate_curtain()
	for i = 1, self.zone_count do
		local zone = field:GetZone(self.zone_prefix .. i)
		self.center_pos = self.center_pos + zone.Bounds.center

		local info = CS.Oak.RotatableCubeCollisionInfo()
		info.Size = vector(zone.Bounds.extents.x * 2, 1, zone.Bounds.extents.z * 2)
		info.Duration, info.DamageTerm = CS.System.Single.MaxValue, self.damage_term

		local calculator = CS.Oak.AreaBattleCollision(self.sender, info)
		calculator.Position = zone.Bounds.center

		calculator:Start()
		table.insert(self.curtain_list, {
			calculator = calculator,
			fx = nil
		})
	end

	self.center_pos = self.center_pos / self.zone_count
	self.fx = unity_object_pool.GetOrCreate('fx_boss_pan_stage_effect'):Instantiate(self.center_pos)
	music_player_util.play_sfx_one_shot('02_pan_wall_01')
end

function local_class:remove_curtain()
	for i = 1, #self.curtain_list do
		self.curtain_list[i].calculator:End()
	end
	self.curtain_list = {}
	if self.fx ~= nil then
		self.fx:Dispose()
		self.fx = nil
	end
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	for i = 1, #self.curtain_list do
		local calculator = self.curtain_list[i].calculator

		local objects = self.curtain_list[i].calculator:UpdateFrame(dt)
		for index = 0, objects.Count - 1 do
			local fo = objects[index]

			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Melee | CS.Oak.DamageType.Passive
			damage_info.sender = self.sender
			damage_info.target = fo
			damage_info.modifier = self.modifier

			music_player_util.play_sfx({ sfx_name = '02_hit_snow_01', play_pos = self.sender.Position })

			command_util.publish_damage(damage_info)
		end
		objects:Dispose()
	end
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopEndEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
