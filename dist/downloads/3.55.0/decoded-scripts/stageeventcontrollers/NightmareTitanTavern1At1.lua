local local_class = newclass("NightmareTitanTavern1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	return user_progress:GetStartedQuest(124).InnerProgress == 0 and not user_progress:ClearedQuest(124)
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 2 then
		if e.Params[0] == 'wasted' then
			sp_util.play_normal_screenplay(self.gnome_detect, self, e.Sender)
		end
	end

	return false
end

function local_class:on_stage_start_event(e)
	local fat_gnome = get_character('fat_gnome')
	local bomb_bug = get_character('hiding_bug')

	-- 뚱보 노움을 폭탄 벌레에 못 타도록 블랙 리스트에 추가
	bomb_bug.FieldObjectBehaviour:AddBlackList(fat_gnome)

	for i = 1, 3 do
		local supervisor = get_character('supervisor_' .. i)
		supervisor.SpineController:SetAttachment('[base]weapon1', 'basic_rifle')
		character_util.set_anim(supervisor, {name = 'rifle_idle'})
		character_util.set_emotion(supervisor, {name = 'attack'})
	end

	for i = 1, 9 do
		local gnome = get_character('first_gnome_' .. (i - 1))
		gnome.ActiveState = active_state('disabled')
	end

	local gnome = get_character('first_gnome')
	gnome.ActiveState = active_state('disabled')

	for i = 1, 7 do
		local gnome = get_character('hidden_gnome_' .. (i - 1))
		gnome.ActiveState = active_state('disabled')
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mining, self))

	return true
end

function local_class:mining()
	local ants = {}

	local ores = {}

	for i = 1, 3 do
		ants[i] = get_character('ant_worker_' .. i)
		ores[i] = get_field_object('ant_ore_' .. i)
	end

	local anim_duration = 0.6
	local total_duration = 1
	local attack = total_duration / 4 * 3
	local destroy = total_duration / 4

	for i = 1, 3 do
		ants[i].SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')

	end

	while true do
		for i = 1, 3 do
			character_util.set_anim(ants[i], {name = 'twohand_attack', scale = anim_duration / total_duration, sfx_name = '01_mining_01', loop = false})
		end

		wait_for_sec(attack - 0.1)

		for i = 1, 3 do
			coroutine_manager:StartCoroutine(stage.StageGameObject, CS.Oak.CommonScreenplay.Shake(ores[i].Transform, 0.1, destroy))
		end

		wait_for_sec(destroy + 0.1)

		for i = 1, 3 do
			character_util.remove_anim(ants[i])
		end
	end
end

function local_class:gnome_detect(supervisor)

	character_util.set_emotion(user_party.Leader, {name = 'surprise'})
	character_util.set_anim(user_party.Leader, {name = 'embarrassed'})

	camera_util.shake(0.3, 0.5)
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	music_player:PlaySfxOneShot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(supervisor, {key = 'nightmare_titantavern_gnome_detect',
															 bubble_type = 'shout', skip = true})
	--거기 누구냐!

	music_player:PlaySfxOneShot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	character_util.remove_anim_and_emotion(user_party.Leader)
	party_util.align_party(field:GetMarker('supervisor_reset').position, 'down', 0)
	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}