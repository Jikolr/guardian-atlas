local local_class = newclass("SnowmountainPrincessController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.princess_name = 'snowmountain_princess'
	self.worker_name = 'princess_worker'
	self.snowman_name = 'princess_snowman_'
end

function local_class:load_resource()
	local princess = get_character(self.princess_name)
	local worker = get_character(self.worker_name)
	local snowmen = {}
	for i = 1, 3 do
		local snowman = get_character(self.snowman_name .. i)
		table.insert(snowmen, snowman)
	end

	-- 눈사람 크기 변경, 살아 있는 것처럼 안 보이도록 변경
	for k, v in pairs(snowmen) do
		character_util.set_anim(v, { name = 'idle', loop = false })
		v.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		field_ui_manager:RemoveUI(v, CS.Oak.FieldUiType.CharacterStats)
		v:SetGiantFactor('snowman_' .. k, 0.5 * k)
	end

	-- 스타피스 획득 여부에 따른 처리
	if not stage_progress:HasStarPiece('snowman_princess_star_piece') then
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')

		princess.Interactable:AddListener(self.cs_controller)
		worker.Interactable:AddListener(self.cs_controller)
	else
		princess.ActiveState = active_state('disabled')
		worker.ActiveState = active_state('disabled')
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	local princess = get_character(self.princess_name)
	if lua_helper.type_compare(princess.Interactable, CS.Oak.NPCInteractable) then
		princess.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	local worker = get_character(self.worker_name)
	if lua_helper.type_compare(worker.Interactable, CS.Oak.NPCInteractable) then
		worker.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		local princess = get_character(self.princess_name)
		if lua_helper.reference_equals(e.Target, princess) then
			sp_util.play_normal_screenplay(self.talk_princess, self)
			return true
		end

		local worker = get_character(self.worker_name)
		if lua_helper.reference_equals(e.Target, worker) then
			music_player:PlaySfxOneShot('03_dialogue_worker_01')
			speech_bubble_util.show_speech_bubble(worker, { key = 'snowmountain_5_snowman_princess_7' })
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then

		if not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

		if e.CameraGrid.name == 'snowman_princess_grid' then
			local worker = get_character(self.worker_name)
			-- 떨고있는 꼬마 공주 옆 일꾼 (요청이 쌓이지 않도록 이름 설정)
			local shake_info = CS.Oak.ShakeInfo('worker_shake', 0.02, 9999, false)
			worker.SpineController:Shake(shake_info)
			return true
		end
	end

	return false
end

-- 꼬마 공주와 대화
function local_class:talk_princess()
	local princess = get_character(self.princess_name)
	princess.Interactable:RemoveRelatedEvent(self.cs_controller)

	local worker = get_character(self.worker_name)
	speech_bubble_util.remove_bubble(worker)

	party_util.align_to_target(princess, 'down', 1, 'arc')

	wait_for_sec(0.5)

	character_util.set_direction(princess, 'down')
	character_util.set_emotion(princess, { name = 'smile' })
	character_util.set_anim(princess, { name = 'idle' })
	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.normal_jump_async(princess)

	-- 아, <플레이어 이름>!
	speech_bubble_util.show_speech_bubble_async(princess,
			{ key = { 'snowmountain_5_snowman_princess_1', user.Name }, skip = true })

	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.set_direction(princess, 'left')
	character_util.set_anim(princess, { name = 'victory_get', loop = false })
	-- 이 눈사람들, 내가 만든 거다?
	speech_bubble_util.show_speech_bubble_async(princess,
		{ key = 'snowmountain_5_snowman_princess_2', skip = true })

	character_util.remove_anim(princess)

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_direction(princess, 'left')
	character_util.set_anim(princess, { name = 'sing' })

	speech_bubble_util.show_speech_bubble_async(princess,
		{ key = 'snowmountain_5_snowman_princess_3', skip = true })

	character_util.set_direction(princess, "down")
	character_util.set_anim(princess, { name = "success" })

	speech_bubble_util.show_speech_bubble_async(princess,
			{ key = 'snowmountain_5_snowman_princess_3_1', skip = true })

	character_util.remove_anim(princess)

	character_util.set_anim(princess, { name = 'idle' })
	-- 맞다! 이거 또 찾았어!
	speech_bubble_util.show_speech_bubble_async(princess,
		{ key = 'snowmountain_5_snowman_princess_4', skip = true })

	-- 스타피스 드랍
	local star_piece = get_field_object('snowman_princess_star_piece')
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(princess.Position))
	wait_for_sec(2.5)

	character_util.remove_anim(princess)

	character_util.set_direction(princess, 'left')
	character_util.set_anim(princess, { name = 'sing' })
	-- 이거 반짝반짝 빛나니까 따뜻하겠지? 추우니까 <플레이어 이름> 가져!
	speech_bubble_util.show_speech_bubble_async(princess,
			{ key = { 'snowmountain_5_snowman_princess_5', user.Name }, skip = true })

	character_util.remove_anim_and_emotion(princess)
	character_util.set_direction(princess, 'down')

	-- 쉬버링 산의 챔피언은 눈사람 몇개나 만들어봤을까?
	princess.Interactable.Talk = 'snowmountain_5_snowman_princess_6'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
