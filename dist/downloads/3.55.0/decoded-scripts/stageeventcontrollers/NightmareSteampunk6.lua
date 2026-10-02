local local_class = newclass("NightmareSteampunk6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- npc들 및 인베이더 크리스탈 가져오기
	self.get_talk_refugee_crystal = function(index) return get_field_object('talk_refugee_crystal_' .. index) end
	self.get_talk_refugee = function(index) return get_character('talk_refugee_' .. index) end
	self.get_pickaxe_refugee = function() return get_character('lagann_refugee_male') end
	self.get_pickaxe_solider = function() return get_character('lagann_solider_1') end
	self.get_pickaxe_crystal = function() return get_field_object('pickaxe_crystal') end

	-- get_pickaxe_refugee, get_pickaxe_solider 가 이야기중인지 체크
	self.is_talking = {false, false}

	-- 곡괭이 무기 이름
	self.pickaxe_weapon_name = 'pickaxe_bronze_sword'

	-- 수용민들 대화 이벤트 그리드 이름
	self.refugee_grid_name = 'refugee_grid'

	-- 곡괭이 후일담 대화 이벤트 그리드 이름
	self.pickaxe_grid_name = 'pickaxe_grid'

	-- 곡괭이 이팩트 이름
	self.pickaxe_effect_name = 'FX_lasthit'

	-- 곡괭이 이벤트가 재생중인가?
	self.is_playing_pickaxe_event = false

	-- 수용민들 대화 이벤트가 재생중인가?
	self.is_playing_talk_refugee = false

	-- 연출 중인지?
	self.is_directing = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
end

function local_class:on_stage_loaded_event()
	-- 곡괭이 세팅
	for i = 1, 4 do
		local talk_refugee = self.get_talk_refugee(i)
		talk_refugee.SpineController:SetAttachment('[base]weapon1', self.pickaxe_weapon_name)
	end
	local pickaxe_refugee = self.get_pickaxe_refugee()
	pickaxe_refugee.SpineController:SetAttachment('[base]weapon1', self.pickaxe_weapon_name)

	unity_object_pool.GetOrCreate(self.pickaxe_effect_name)

	character_util.add_listener(self.get_pickaxe_refugee(), self.cs_controller)
	character_util.add_listener(self.get_pickaxe_solider(), self.cs_controller)
	return true
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	character_util.remove_relate_event(self.get_pickaxe_refugee(), self.cs_controller)
	character_util.remove_relate_event(self.get_pickaxe_solider(), self.cs_controller)

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	local talker = {self.get_pickaxe_refugee(), self.get_pickaxe_solider()}
	local sfx_name = {'03_dialogue_emphasize_01', '01_clap_01'}
	local string_key = {'nightmare_steampunk_6_later_pickaxe_1', 'nightmare_steampunk_6_later_pickaxe_4'}
	--내 곡괭이는 하늘을 뚫는 곡괭이다!!
	--역시 노력은 배신하지 않는다니까, 저 녀석이 일을 제일 못했다면 믿겠나?

	for i = 1, #talker do
		if lua_helper.reference_equals(e.Target, talker[i]) and not self.is_talking[i] then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				self.is_talking[i] = true
				music_player_util.play_sfx_one_shot(sfx_name[i])
				speech_bubble_util.show_speech_bubble_async(talker[i], {key = string_key[i]})
				self.is_talking[i] = false
			end))
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	local grid_name = e.CameraGrid.name

	-- pickaxe_grid에 카메라가 들어왔을 때
	if grid_name == self.pickaxe_grid_name then
		local pickaxe_refugee = self.get_pickaxe_refugee()
		character_util.set_anim(pickaxe_refugee, { name = 'twohand_attack', scale = 1.5, sfx_name = '01_mining_01' })
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pickaxe_event_shake_rock, self))
		return true
	end

	-- refugee_grid에 카메라가 들어왔을 때
	if grid_name == self.refugee_grid_name then
		local emotions = { 'tired', 'damaged', 'smile', 'burning' }
		for i = 1, 4 do
			local talk_refugee = self.get_talk_refugee(i)
			character_util.set_anim_and_emotion(talk_refugee, { name = 'twohand_attack', sfx_name = '01_mining_01' }, { name = emotions[i] })
		end
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_refugee_event_shake_rocks, self))
		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	local grid_name = e.CameraGrid.name

	-- pickaxe_grid에서 카메라가 나갔을 때
	if grid_name == self.pickaxe_grid_name then
		local pickaxe_refugee = self.get_pickaxe_refugee()
		character_util.remove_anim(pickaxe_refugee)
		self.is_playing_pickaxe_event = false
		return true
	end
	-- refugee_grid에서 카메라가 나갔을 때
	if grid_name == self.refugee_grid_name then
		for i = 1, 4 do
			local talk_refugee = self.get_talk_refugee(i)
			character_util.remove_anim_and_emotion(talk_refugee)
		end
		self.is_playing_talk_refugee = false
		return true
	end

	return false
end

-- 수용민들 대화 이벤트에서 광석들 흔들리는 연출
function local_class:talk_refugee_event_shake_rocks()
	while self.is_directing do
		coroutine.yield()
	end

	local crystals = {}
	for i = 1, 4 do
		local crystal = self.get_talk_refugee_crystal(i)
		crystal:CancelShake()
		table.insert(crystals, crystal)
	end

	self.is_directing = true
	self.is_playing_talk_refugee = true

	while self.is_playing_talk_refugee do
		for i = 1, #crystals do
			crystals[i]:Shake(0.04, 0.2)
		end
		wait_for_sec(0.65)
	end
	self.is_directing = false
end

-- 곡괭이 후일담 이벤트에서 광석들 흔들리는 연출
function local_class:pickaxe_event_shake_rock()
	while self.is_directing do
		coroutine.yield()
	end

	local crystal = self.get_pickaxe_crystal()
	crystal:CancelShake()

	self.is_directing = true
	self.is_playing_pickaxe_event = true

	local pos = crystal.Position + unity_class.vector3.left * 0.5
	while self.is_playing_pickaxe_event do
		unity_object_pool.GetOrCreate(self.pickaxe_effect_name):Instantiate(pos)
		crystal:Shake(0.04, 0.2)
		wait_for_sec(0.45)
	end

	self.is_directing = false
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
