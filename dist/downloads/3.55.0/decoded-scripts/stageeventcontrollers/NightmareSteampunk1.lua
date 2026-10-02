local local_class = newclass('NightmareSteampunk1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 관사 입구 Exit
	self.entry_residence_name = 'residence_entry'

	self.get_crystal = function(num) return get_field_object('crystal_' .. num) end
	self.get_orient_npc = function(num) return get_character('orient_npc_' .. num) end

	self.is_crystal_shaking = true
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	local event_type = e:GetType()

	return false
end

function local_class:on_stage_start_event(e)
	-- 관사 Entry Hitbox 키우기
	local entry_residence = get_field_object(self.entry_residence_name)
	entry_residence.Hitbox = CS.Oak.Hitbox(vector(0.25, 0, 0.5), vector(2, 3, 3.1))

	for i = 1, 3 do
		local orient_npc = self.get_orient_npc(i)
		orient_npc.SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')
		character_util.remove_anim(orient_npc)
		character_util.set_anim(orient_npc, {name = 'twohand_attack', sfx_name = '01_mining_01'})
	end

	for i = 9, 10 do
		local orient_npc = self.get_orient_npc(i)
		orient_npc.SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')
		character_util.remove_anim(orient_npc)
		character_util.set_anim(orient_npc, {name = 'twohand_attack', sfx_name = '01_mining_01'})
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shake_crystal, self))
end

function local_class:dispose()
	self.is_crystal_shaking = false

	for i = 1, 3 do
		local orient_npc = self.get_orient_npc(i)
		orient_npc.SpineController:SetAttachment('[base]weapon1', 'empty')
	end

	for i = 9, 10 do
		local orient_npc = self.get_orient_npc(i)
		orient_npc.SpineController:SetAttachment('[base]weapon1', 'empty')
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	self.cs_controller = nil
end

function local_class:shake_crystal()
	local duration = 0.73
	local timer = 0.4

	local crystal_table = { nil, nil, nil, nil, nil }
	for i = 1, 5 do
		local crystal = self.get_crystal(i)
		crystal_table[i] = crystal
	end

	self.is_crystal_shaking = true

	while self.is_crystal_shaking do
		timer = timer + unity_class.time.deltaTime

		if timer >= duration then
			timer = 0
			for i = 1, 5 do
				crystal_table[i]:Shake(0.04, 0.2)
			end
		end

		coroutine.yield(nil)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
