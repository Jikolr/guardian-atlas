local local_class = newclass('ExpeditionHiddenEventDrum')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.drums = {}
	self.hit_drums = {}
	self.hit_orders = { 2, 2, 1, 1, 2, 2, 3 } --중중 좌좌 중중 우

	self.drum_gate = nil

	self.hit_correctly = false

	self.music_sheet_item_id = 20091
	self.music_sheet_input = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.AnimationEvent), 'on_animation_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
end

function local_class:on_stage_loaded_event(e)
	-- 필드 오브젝트 찾아서 등록하기
	--드럼 등록
	for index = 1, 3, 1 do
		local drum = get_field_object('hittable_drum_' .. tostring(index))
		if drum ~= nil then
			table.insert(self.drums, drum)
		end
	end

	-- 문 등록
	self.drum_gate = get_field_object('drum_gate')

	--음악을 읇는 로봇
	self.music_sheet_robot = get_field_object("musicsheet_robot");

	--획득 가능한 아이템 유무로 스테이지 클리어 판단을 한다.
	local floating_item = get_field_object('floating_item_1')
	local user_has_music_sheet = false
	if floating_item ~= nil then
		local floating_behaviour = floating_item.FieldObjectBehaviour
		if floating_behaviour ~= nil then
			if floating_behaviour.ExpeditionCollectibleId ~= 0 then
				user_has_music_sheet = CS.Oak.UserExpedition.Me.Collectibles:Contains(floating_behaviour.ExpeditionCollectibleId);
			end
		end
	end

	--아이템을 보유중이면 클리어한거다. 문을 열어둔다.
	if user_has_music_sheet == true then
		self.hit_correctly = true

		local animator = self.drum_gate:GetComponent(typeof(CS.UnityEngine.Animator))
		if animator ~= nil then
			animator:Play('gate_open')
			self.drum_gate.ActiveState = CS.Oak.ActiveState.Visible;
		end

		self.music_sheet_input = true	--로봇도 처해준다.
	else
		message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	end

	--시작 마커를 기준으로 파티원들을 정렬시킨다.
	local default_start_marker = field:GetMarker('default_start')
	if default_start_marker ~= nil then
		for i = 0, user_party.Count - 1 do
			character_util.set_active_state(user_party[i], "enabled")
			character_util.set_position(user_party[i], default_start_marker.position - CS.Oak.DirectionExtensions.ToVector3(default_start_marker.direction) * CS.Oak.Constants.DistBetweenPartyMembers * i)
			character_util.set_direction(user_party[i], default_start_marker.direction)
		end
	end

	message_system:Publish(CS.Oak.FieldUITopHPBarActivationEvent.Create(false))

	return true
end

--징이 피격시 순서 판정을 하고 맞다면 게이트를 열어준다.
function local_class:on_damage_event(e)
	if lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		local info = e.Info
		if info == nil then return false end

		local target = info.target
		if target == nil then return false end
		if self.hit_correctly == true then return false end

		local is_drum, index = self:is_drum(target)
		if is_drum == false then return false end

		table.insert(self.hit_drums, index)

		local hit_count = #self.hit_drums
		if hit_count <= #self.hit_orders then
			local is_correct = self.hit_drums[hit_count] == self.hit_orders[hit_count]
			if is_correct == true then
				if hit_count == #self.hit_orders then
					self.hit_correctly = true
					start_coroutine(self.open_drum_gate, self)
				end
			else	--잘못 쳤다. 쳤던 드럼 목록을 날린다.
				self.hit_drums = {}
			end
		end
	end
end
function local_class:is_drum(target)
	if target == nil then
		return false, -1
	end

	if self.drums == nil or #self.drums < 1 then
		return false, -1
	end

	for index = 1, #self.drums, 1 do
		if self.drums[index] == target then
			return true, index
		end
	end

	return false, -1
end

--게이트를 연다
function local_class:open_drum_gate()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	stage_camera:Move(self.drum_gate.Position, 1.0)
	wait_for_sec(1.0)

	local animator = self.drum_gate:GetComponent(typeof(CS.UnityEngine.Animator))
	if animator ~= nil then
		animator:Play('gate_open')
	end

	stage_camera:Shake(0.05, 3)
	music_player_util.play_sfx({
				sfx_name = '01_earthquake_03',
				parent = self.drum_gate,
				loop = true,
				duration = 3,
				fade_out_time = 0.7
	})

	music_player:PlaySfxOneShot('01_gate_open_01')

	while self.drum_gate.ActiveState == CS.Oak.ActiveState.Enabled do
		coroutine.yield()
	end

	stage:ClearHiddenEvent()	--이벤트 클리어 처리
	wait_for_sec(1.0)

	camera_util.move(user_party.Leader.Position, 1, { end_target = user_party.Leader })
	wait_for_sec(1.0)

	party_util.reset_controllers()
	field_ui_manager:Show()
end

--게이트가 열리면 실행되는 일회성 이벤트
function local_class:on_animation_event(e)
	if lua_helper.type_compare(e, CS.Oak.AnimationEvent) then
		local gate = e.FieldObject
		if gate == nil then return false end

		if CS.System.Object.ReferenceEquals(gate, self.drum_gate) then
			self.drum_gate.ActiveState = CS.Oak.ActiveState.Visible
			message_system:Unsubscribe(self, typeof(CS.Oak.AnimationEvent))
		end
	end

	if e.EventName == 'wing_sfx' then
		music_player_util.play_sfx_one_shot('02_wing_fire_02')
		return true
	end
	return false
end

--게이트가 열리면 실행되는 일회성 이벤트
function local_class:on_interact_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		local robot = e.Target
		if robot == nil then
			return false
		end

		if user:HasItem(self.music_sheet_item_id) == true then
			if self.music_sheet_input == true then
				start_coroutine(self.talk_music_sheet_lastonly, self)
			else
				self.music_sheet_input = true
				start_coroutine(self.talk_music_sheet, self)
			end
		else
			start_coroutine(self.talk_music_sheet_needed, self)
		end
		return true
	end
	return false
end

function local_class:talk_music_sheet_lastonly()
	coroutine.yield(CS.Oak.IFieldObjectExtensions.TalkAsync(self.music_sheet_robot, game_string:GetString('input_music_sheet_3'), false))
end

function local_class:talk_music_sheet()
	field_ui_manager:Hide();
	party_util.stop_and_disable_control()

	coroutine.yield(CS.Oak.IFieldObjectExtensions.TalkAsync(self.music_sheet_robot, game_string:GetString('input_music_sheet_1'), true))
	coroutine.yield(CS.Oak.IFieldObjectExtensions.TalkAsync(self.music_sheet_robot, game_string:GetString('input_music_sheet_2'), true))
	coroutine.yield(CS.Oak.IFieldObjectExtensions.TalkAsync(self.music_sheet_robot, game_string:GetString('input_music_sheet_3'), true))

	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:talk_music_sheet_needed()
	coroutine.yield(CS.Oak.IFieldObjectExtensions.TalkAsync(self.music_sheet_robot, game_string:GetString('not_have_music_sheet'), false))
end

--=================================================================================================
function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.AnimationEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
	self.scene = nil

	self.drum_gate = nil
	self.drums = nil

	self.hit_drums = nil
	self.hit_orders = nil
	self.music_sheet_robot = nil

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
