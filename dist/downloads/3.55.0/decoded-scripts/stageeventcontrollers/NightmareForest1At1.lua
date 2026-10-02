local local_class = newclass("NightmareForest1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.burning_skull_name = 'burning_skull'
	self.fire_signboard_name = 'fire_signboard'

	self.is_talking_signboard = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.HoldUpEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BurnEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageControlStartEvent), 'on_event')

	-- 이모티콘 중복으로 뜨는 것을 방지하는 방식에서 필요해서 self 사용
	self.slimes = create_generic_list(CS.Oak.Character)
	for i = 0, 5 do
		self.slimes:Add(get_character('slime' .. i))
		self.slimes[i].Interactable:AddListener(self.cs_controller)
	end

	unity_object_pool.GetOrCreate('FX_starpiece_in_character')

	local burning_skull = get_character(self.burning_skull_name)
	burning_skull.Interactable.Talk = 'nightmare_forest_1_burningskull_1'

	return
end

function local_class:need_on_launch()
	return user_progress:GetStartedQuest(80).InnerProgress < 1
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.HoldUpEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BurnEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageControlStartEvent))

	for i = 0, self.slimes.Count - 1 do
		if lua_helper.type_compare(self.slimes[i].Interactable, typeof(CS.Oak.NPCInteractable)) then
			self.slimes[i].Interactable:RemoveRelatedEvent(self.cs_controller)
		end
	end

	if self.star_piece_effect ~= nil then
		self.star_piece_effect:Dispose()
	end

	self.star_piece_effect = nil

	self.slimes:Clear()

	self.slimes = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	local signboard = get_field_object(self.fire_signboard_name)

	if event_type == typeof(CS.Oak.HoldUpEvent) then
		if lua_helper.reference_equals(e.Target, signboard) then
			self:hold_up_signboard()
			return true
		end
	end

	if event_type == typeof(CS.Oak.BurnEvent) then
		if lua_helper.reference_equals(e.Target, signboard) and not self.earned_signboard_star_piece then
			self.earned_signboard_star_piece = true
			coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.burn_signboard, self))
			return true
		end
	end

	if event_type == typeof(CS.Oak.InteractEvent) then
		if self.slimes:Contains(e.Target) then
			coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.slime_emoticon, self, e.Target))
			return true
		end
	end

	if event_type == typeof(CS.Oak.StageControlStartEvent) then
		-- 스타피스 이펙트
		local fx_star_piece_pool = unity_object_pool.GetOrCreate('FX_starpiece_in_character')
		self.star_piece_effect = fx_star_piece_pool:Instantiate(
			signboard.Bounds.center, unity_class.quaternion.identity, signboard.transform)
		self.earned_signboard_star_piece = stage_progress:HasStarPiece('signboard_star_piece')
		self:earned_star_piece()
		return true
	end

	return false
end

-- 슬라임 이모티콘
function local_class:slime_emoticon(target)
	self.slimes:Remove(target)

	music_player_util.play_sfx({ sfx_name = '01_small_jump_01', parent = target })

	character_util.jump(target, 0.5, 0.25)

	coroutine.yield(coroutine_class.wait_for_sec(0.3))

	local emoticon_pool = unity_object_pool.GetOrCreate('emoticon'):Instantiate(target.Position)
	local emoticon = emoticon_pool.transform:GetComponent(typeof(CS.Oak.Emoticon))
	emoticon:Init()
	emoticon:ShowOn(target, vector(1, 1, 1), CS.Oak.EmoticonType.Heart)

	coroutine.yield(coroutine_class.wait_for_sec(2))

	self.slimes:Add(target)
end

-- 표지판 들었을 때
function local_class:hold_up_signboard()
	local signboard = get_field_object(self.fire_signboard_name)
	signboard.CrashBehaviour = CS.Oak.PortableCrashBehaviour()

	-- 스타피스 획득 여부에 따라 다른 연출
	if self.earned_signboard_star_piece then
		speech_bubble_util.show_speech_bubble(signboard, { key = 'nightmare_forest_1_sign_4' })
	else
		speech_bubble_util.show_speech_bubble(signboard, { key = 'nightmare_forest_1_sign_3' })
	end
end

-- 표지판이 불타기 시작할 때
function local_class:burn_signboard()
	self.star_piece_effect:Dispose()

	local burning_skull = get_character(self.burning_skull_name)
	local signboard = get_field_object(self.fire_signboard_name)

	speech_bubble_util.show_speech_bubble(signboard, { key = 'forest_1_3_signboard_burn' })

	character_util.jump(burning_skull, 0.5, 0.5)
	character_util.set_emotion(burning_skull, { name = 'surprise' })

	local star_piece = get_field_object('signboard_star_piece')
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(signboard.Position))

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	character_util.remove_anim(burning_skull)

	burning_skull.Interactable.Talk = 'nightmare_forest_1_burningskull_2'
end

-- 스타피스 획득 후
function local_class:earned_star_piece()
	local burning_skull = get_character(self.burning_skull_name)
	local signboard = get_field_object(self.fire_signboard_name)

	if self.earned_signboard_star_piece then
		self.star_piece_effect:Dispose()
		signboard.Position = burning_skull.Position + unity_class.vector3.right
		signboard.Holdable = CS.Oak.NonHoldable.Instance
		burning_skull.Interactable.Talk = 'nightmare_forest_1_burningskull_2'
		signboard.Interactable = CS.Oak.SignboardInteractable()
		signboard.Interactable.Message = 'nightmare_forest_1_sign_4'
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
