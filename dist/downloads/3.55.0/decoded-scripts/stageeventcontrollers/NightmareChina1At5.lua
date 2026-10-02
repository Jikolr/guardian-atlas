local local_class = newclass("NightmareChina1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_crystal = function()
		return get_field_object('crystal_1')
	end
	self.get_gate = function()
		return get_field_object('gate_1')
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local crystal = self.get_crystal()

	if lua_helper.reference_equals(e.Target, crystal) then
		sp_util.play_normal_screenplay(self.destroy_crystal, self, crystal)
		return true
	end

	return false
end

function local_class:destroy_crystal(fo)
	local gate = self.get_gate()
	local deviate_pos = (fo.Position - user_party_leader.Position).normalized * 0.5
	local angle = 0

	if user_party_leader.Direction == CS.Oak.Direction.Down then
		angle = 180
	elseif user_party_leader.Direction == CS.Oak.Direction.Up then
		angle = 0
	elseif user_party_leader.Direction == CS.Oak.Direction.Left then
		angle = 270
	elseif user_party_leader.Direction == CS.Oak.Direction.Right then
		angle = 90
	end

	character_util.set_anim(user_party_leader, { name = 'attack' })
	character_util.spine_deviate_local(user_party_leader, deviate_pos, 0.2, 0.1)

	fo.Interactable = CS.Oak.NonInteractable.Instance

	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('02_hit_stab_critical_01')

	local slash_effect = unity_object_pool.GetOrCreate('FX_SwordSlash'):Instantiate(user_party_leader.Position + vector(0, 0.5, 0))
	slash_effect.transform.localRotation = unity_class.quaternion.Euler(0, angle, 0)

	fo:Deviate(deviate_pos * 0.5, 0.2, 0.1)
	fo:Shake(0.04, 1)

	wait_for_sec(0.15)

	character_util.remove_anim(user_party_leader)

	music_player:PlaySfxOneShot('01_break_crystal_01')

	fo:GetComponent(typeof(CS.UnityEngine.Animator)):Play('sealstone_boss_destroy')

	wait_for_sec(2)

	fo.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance;
	fo.ActiveState = CS.Oak.ActiveState.Disabled;

	yield_return_func(self.open_gate, self, gate)
end

function local_class:open_gate(fo)

	camera_util.move_async(fo.Position, 1.5)

	fo:GetComponent(typeof(CS.UnityEngine.Animator)):Play('gate_open')

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('01_gate_open_01')

	wait_for_sec(2.5)

	fo.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance;

	camera_util.move_async(user_party_leader.Position, 1.5, { end_target = user_party_leader })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}