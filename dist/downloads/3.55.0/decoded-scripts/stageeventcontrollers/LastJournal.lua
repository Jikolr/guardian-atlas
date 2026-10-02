local local_class = newclass("LastJournalController")

function local_class:init_scene()
	--- action cache
	self.action = {
		['dir'] = function (fo, x) character_util.set_direction(fo, table.unpack(x)) end,
		['emo'] = function (fo, x) character_util.set_emotion(fo, table.unpack(x)) end,
		['ani'] = function (fo, x) character_util.set_anim(fo, table.unpack(x)) end,
		['emoji'] = function (fo, x) character_util.show_emoticon_async(fo, table.unpack(x)) end,
		['remove_emo'] = function (fo, _) character_util.remove_emotion(fo) end,
		['talk'] = function (fo, x) speech_bubble_util.show_speech_bubble_async(fo, table.unpack(x)) end,
		['mario'] = function (fo, x) character_util.mario_jump_async(fo, table.unpack(x)) end,
		['jump'] = function (fo, x) character_util.normal_jump(fo, table.unpack(x)) end,
		['move'] = function (fo, x) character_util.move_waypoint_async(fo, table.unpack(x)) end,
		['shake'] = function (fo, x) character_util.shake(fo, table.unpack(x)) end,
		['alpha'] = function(fo, x) character_util.spine_set_alpha_fade(fo, table.unpack(x)) end,
		['wait'] = function (_, x) wait_for_sec(table.unpack(x)) end,
		['fade_in'] = function (_, x) screen_util.fade_in_async(table.unpack(x)) end,
		['fade_out'] = function (_, x) screen_util.fade_out_async(table.unpack(x)) end,
		['one_shot'] = function (_, x) music_player:PlaySfxOneShot(table.unpack(x)) end,
		['play_sfx'] = function (_, x) music_player_util.play_sfx(x) end,
		['play_stage_music'] = function(_, x) music_player_util.play_stage_music(x) end
	}

	--- action param
	self.param = {
		{
			--- wait camera move
			'wait', { 1.3 },
			--- character alpha fade in
			'alpha', { 0.75, 0.5 },
			'wait', { 0.75 },
			--- 쉬버링 산맥에서도 험하기로 유명한 이곳...
			'talk', {{ key = 'substage_lastjournal_1_1', skip = true }},
			--- 하지만 그녀의 대답을 위해서라면 절대 포기할 수 없어.
			'talk', {{ key = 'substage_lastjournal_1_2', skip = true }},
			'one_shot', { '01_jump_01' },
			'mario', { 'right' },
			'wait', { 0.5 },
			--- 기다려... 반드시 갖고 말테니까!
			'talk', {{ key = 'substage_lastjournal_1_3', skip = true }},
			'wait', { 0.5 },
			'alpha', { 0, 0.5 },
			'wait', { 0.75 },
		},
		{
			'dir', { 'down' },
			--- wait camera move
			'wait', { 1.3 },
			--- character alpha fade in
			'alpha', { 0.75, 0.5 },
			'wait', { 0.75 },
			'emo', {{ name = 'scared' }},
			--- 부르르 떠는 sfx
			'one_shot', { '03_runaway_01' },
			'shake', { 0.04, 0.5 },
			'wait', { 0.5 },
			--- 체온이 떨어져 간다.
			'talk', {{ key = 'substage_lastjournal_2_1', skip = true }},
			--- 더 이상은 무리다. 이성적으론 돌아가는 것이 맞다.
			'talk', {{ key = 'substage_lastjournal_2_2', skip = true }},
			'emoji', { nil, 'silence' },
			'dir', { 'right' },
			'one_shot', { '01_jump_01' },
			'jump', {},
			--- 아니, 그럴 수 없지.
			'talk', {{ key = 'substage_lastjournal_2_3', skip = true }},
			--- 그녀가 처음으로 내 마음에 답해준 쪽지가 저 위에 있다고!
			'talk', {{ key = 'substage_lastjournal_2_4', skip = true }},
			--- 나란 남자... 이런 곳에 포기할 정도로 시시하진 않잖아?!
			'talk', {{ key = 'substage_lastjournal_2_5', skip = true }},
			'remove_emo', {},
			'alpha', { 0, 0.5 },
			'wait', { 0.75 },
		},
		{
			'dir', { 'up' },
			--- wait camera move
			'wait', { 1.3 },
			--- character alpha fade in
			'alpha', { 0.75, 0.5 },
			'wait', { 0.75 },
			'move', { vector(-0.5, 0, 59.5), 0.5, false },
			--- 눈 앞이 흐려진다.
			'talk', {{ key = 'substage_lastjournal_3_1', skip = true }},
			'wait', { 0.5 },
			'move', { vector(-0.5, 0, 60.5), 0.5, false },
			--- 여기까지가 한계인가...?
			'talk', {{ key = 'substage_lastjournal_3_2', skip = true }},
			'wait', { 0.5 },
			'move', { vector(-0.5, 0, 61.5), 0.5, false },
			--- 그녀가... 기다릴... 텐데......
			'talk', {{ key = 'substage_lastjournal_3_3', skip = true }},
			'wait', { 0.5 },
			'alpha', { 0, 0.5 },
			'wait', { 0.75 },
		}
	}
end

function local_class:init(_)
	--- boolean checker
	self.interact_check = false

	--- tile map character
	self.dead_man = function ()
		return get_character('dead_man')
	end

	self.marker = function (index)
		local name = string.format('last_journal_%i', index)
		return field:GetMarker(name)
	end

	self.journal = function ()
		return get_field_object('substage_lastjournal_5')
	end
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	if user_progress:IsStageCleared(stage.Name) then
		return
	end

	--- 스테이지를 클리어 못한 경우에만
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	self:init_scene()

	--- 눈보라 preset
	local blizzard = unity_object_pool.GetOrCreate('FX_Blizzard')

	--- 이펙트 로드 대기
	while not CS.Oak.UnityObjectPoolExtensions.IsLoaded(blizzard) do
		coroutine.yield(nil)
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	if self.action ~= nil then
		for k, _ in pairs(self.action) do
			self.action[k] = nil
		end

		self.action = nil
	end

	self.param = nil

	self.dead_man = nil
	self.marker = nil
	self.journal = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
end


--- Stage Loaded Event
function local_class:on_stage_loaded_event(_)
	--- clear check
	if user_progress:IsStageCleared(stage.Name) then
		self:dead_man_last_scene()
	else
		character_util.spine_set_alpha_fade(self.dead_man(), 0, 0)
	end

	local item_data = CS.Oak.GameDataService.GetData('ItemData')

	local journal = self.journal()

	if journal == nil then
		CS.UnityEngine.Debug.LogError('journal is null')
		return false
	end

	local item = CS.Oak.ItemPlaceholder()
	item.ItemId = item_data:GetSpec('paper_piece').Id
	item.NotForInventory = true

	drop_item_util.create_item({ pos = journal.Position, target = journal.Position,
		item = item, lootstate = 'dontfindlooter' })

	return true
end

--- Zone Enter Event
function local_class:on_zone_enter_event(e)
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

	local zone_name = e.Zone.Name

	for index = 1, 3 do
		local target_name = string.format('last_journal_%i', index)

		if zone_name == target_name and type_util.is_array(self.param[index]) then
			sp_util.play_normal_screenplay(self.show_journal, self, index)

			return true
		end
	end

	return false
end

--- Interact Event
function local_class:on_interact_event(e)
	--- 중복 상호 작용 방지
	if self.interact_check then return false end

	--- target cache
	local target = e.Target

	if lua_helper.reference_equals(target, self.dead_man()) then
		sp_util.play_normal_screenplay(self.interact, self, 'substage_lastjournal_2')

		return true
	elseif lua_helper.reference_equals(target, self.journal()) then
		sp_util.play_normal_screenplay(self.interact, self, 'substage_lastjournal_3')

		return true
	end

	return false
end

--- Interact Narration
function local_class:interact(key)
	self.interact_check = true

	field_ui_util.show_narration_async({ key = key })

	self.interact_check = false
end

--- Zone Enter
function local_class:show_journal(no)
	--- npc cache
	local npc = self.dead_man()

	if npc == nil then
		CS.UnityEngine.Debug.LogError('dead_man is null')
		return
	end

	self.interact_check = true

	character_util.set_position(npc, self.marker(no).position)
	character_util.set_active_state(npc, 'enabled')
	camera_util.move(npc.Position, 1.3, { end_target = npc })
	field:Tint(npc.Name, unity_color({ 0.5, 0.3, 0 }), 1.3)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.blizzard, self))

	local scene = self.param[no]

	for index = 1, #scene, 2 do
		self.action[scene[index]](npc, scene[index + 1])
	end

	self.interact_check = false

	field:RemoveTint(npc.Name, 1.3)
	camera_util.move_async(user_party_leader.Position, 1.3, { end_target = user_party_leader })
	character_util.set_active_state(npc, 'disabled')

	if no == #self.param then
		self:dead_man_last_scene()
	end

	self.param[no] = 'end'
end

function local_class:blizzard()
	local camera = stage_camera
	local property_name = '_TintColor'
	local fade_duration = 1

	--- blizzard preset
	local blizzard_preset = unity_object_pool.GetOrCreate('FX_Blizzard')
	local blizzard = blizzard_preset:Instantiate(
		camera.Transform.position + vector(0, 5, 10), unity_class.quaternion.identity, camera.Transform)
	local material = blizzard.transform:GetComponentInChildren(typeof(CS.UnityEngine.Renderer)).material
	local cache_color = material:GetColor(property_name)

	--- fade in
	material:SetColor(property_name, unity_color({ 244 / 255, 141 / 255, 109 / 255, 0 }))

	--- audio source cache
	local audio_holder = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true, fade_in_time = fade_duration })
	local time_passed = 0

	while self.interact_check do
		time_passed = time_passed + unity_class.time.deltaTime

		local alpha =  math.min(time_passed / fade_duration, 1) * 128 / 255
		material:SetColor(property_name, unity_color({ cache_color.r, cache_color.g, cache_color.b, alpha}))

		coroutine.yield(nil)
	end

	time_passed = fade_duration

	--- audio source fade
	audio_holder:FadeOut(fade_duration)

	--- fade out
	while 0 < time_passed do
		time_passed = time_passed - unity_class.time.deltaTime

		local alpha =  math.min(time_passed / fade_duration, 1)
		material:SetColor(property_name, unity_color({ cache_color.r, cache_color.g, cache_color.b, alpha}))

		coroutine.yield(nil)
	end

	material:SetColor(property_name, cache_color)
	blizzard:Dispose()
end

function local_class:dead_man_last_scene()
	--- npc cache
	local npc = self.dead_man()

	if npc == nil then
		CS.UnityEngine.Debug.LogError('dead_man is null')
		return
	end

	character_util.set_active_state(npc, 'enabled')
	character_util.set_position(npc, vector(86.5, 0, 32))
	character_util.spine_set_alpha_fade(npc, 1, 0)
	character_util.set_direction(npc, 'left')
	character_util.set_anim(npc, { name = 'prostrate' })
	npc.SpineController:AddColor(npc.Name, unity_color({ 0.3, 0.3, 0.7 }), 1, 0)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
