local local_class = newclass('HighSchool1At5Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 언론실 이벤트

	-- 이미 언론실 스타피스를 획득했는지
	self.get_journal_star_piece = false

	-- 언론실 이벤트를 보았는지
	self.see_journal_room_event = false

	-- 날려버린 기자 수
	self.get_off_journalist_num = 0

	-- 언론실 이벤트
	self.journal_room_event_routine = nil

	-- 언론실 기자들이 질문하는 이벤트
	self.journalist_ask_event_routine = nil

	-- 언론실 이벤트 오우거
	self.journal_ogre = nil

	-- 언론실 이벤트 오우거 이름
	self.journal_ogre_name = "press_rep"

	-- 언론실 이벤트 서브 캐릭터 이름
	self.journal_sub_name = "press_sub_"

	-- 언론실 이벤트 기자 리스트
	self.journalist_list = {}

	-- 언론실 이벤트 기자 수
	self.journalist_num = 4

	-- 언론실 이벤트 기자 이름
	self.journalist_name = "journalist_"

	-- 언론실 이벤트 존 이름
	self.journal_room_event_zone = "journal_room"

	-- 언론실 이벤트 스타피스 이름
	self.journal_star_piece_name = "highschool_1_5_press_star_piece"

	-- 비서실 위쪽 존 이름
	self.secretary_upper_zone_name = "secretary_room_upper"

	-- 박수치는 존 가장 가운데에 위치한 npc 이름 (이 npc 위치 기반으로 박수 sfx 재생할것임)
	self.clap_center_npc_name = 'elite_clap_left_6'

	-- 박수 갈채 sfx를 재생했는지
	self.clap_sfx_played = false

	-- 비서실 쓰레기통 이벤트

	-- 이미 비서실 스타피스를 획득했는지
	self.get_secretary_star_piece = false

	-- 어떤 방법으로든 쓰레기통에서 스타피스가 등장했는지
	self.appear_star_piece = false

	-- 강아지를 한 번이라도 들어올렸는지 (강아지 지키미 반응 변경)
	self.hold_pet = false

	-- 강아지를 들고 비서실에 들어갔는지
	self.pet_with_secretary_room = false

	-- 학생회 비서
	self.secretary = nil

	-- 학생회 비서 이름
	self.secretary_name = "secretary"

	-- 강아지
	self.secretary_pet = nil

	-- 강아지 이름
	self.secretary_pet_name = "secretary_pet"

	-- 강아지 지키미
	self.pet_keeper = nil

	-- 강아지 지키미 이름
	self.pet_keeper_name = "pet_keeper"

	-- 강아지를 보고 헤롱헤롱하는 비서 이벤트
	self.attracted_by_pet_event = nil

	-- 비서실 이벤트 존 이름
	self.secretary_event_zone_name = "secretary_room"

	-- 비서실 쓰레기통 근처 존 이름
	self.trash_zone_name = "secretary_room_trash"

	-- 비서실 쓰레기통 이름
	self.trash_bin_name = "secretary_star_piece_breakable"

	-- 비서실 쓰레기통 스타피스 이름
	self.secretary_star_piece_name = "highschool_1_5_secretary_star_piece"

	-- 입장 경례
	self.salute_0 = false
	self.salute_1 = false
	self.salute_2 = false
	self.salute_3 = false
	self.salute_4 = false
	self.salute_5 = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.HoldUpEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')

	self.journal_ogre = get_character(self.journal_ogre_name)

	for i = 0, self.journalist_num - 1 do
		table.insert(self.journalist_list, get_character(string.format("%s%d", self.journalist_name, i)))
	end

	self.secretary = get_character(self.secretary_name)

	self.secretary_pet = get_character(self.secretary_pet_name)
	self.secretary_pet.Holdable = CS.Oak.Holdable()

	self.pet_keeper = get_character(self.pet_keeper_name)
	self.pet_keeper.Interactable:AddListener(self.cs_controller)

	if stage_progress:HasStarPiece(self.journal_star_piece_name) == true then
		self.get_journal_star_piece = true

		for i = 1, #self.journalist_list do
			self.journalist_list[i].ActiveState = CS.Oak.ActiveState.Disabled
		end
	else
		get_character(string.format("%s%d", self.journal_sub_name, 0)):SetAnimation("cast", true)
		get_character(string.format("%s%d", self.journal_sub_name, 0)):SetEmotion("tired", true)

		get_character(string.format("%s%d", self.journal_sub_name, 1)):SetAnimation("cast", true)
		get_character(string.format("%s%d", self.journal_sub_name, 1)):SetEmotion("tired", true)

		self.journal_ogre.Interactable:AddListener(self.cs_controller)

		self.journal_ogre:SetEmotion("tired", true)
	end

	if stage_progress:HasStarPiece(self.secretary_star_piece_name) == true then
		self.get_secretary_star_piece = true
	end

	return
end

function local_class:need_on_launch()
	local main_quest = user_progress:GetStartedQuest(60001)
	return main_quest ~= nil and main_quest.InnerProgress >= 16 and main_quest.InnerProgress <= 17
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	-- 박수 갈채 sfx 중지
	self:stop_clap_sfx()

	-- 기자들의 질문 공세 앰비언스 sfx 루프 중지
	self:stop_journalist_ambience_sfx()

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.HoldUpEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.journal_ogre = nil
	self.journalist_list = nil
	self.secretary = nil
	self.secretary_pet = nil
	self.pet_keeper = nil

	self.journal_room_event_routine = nil
	self.attracted_by_pet_event_routine = nil
	self.journalist_ask_event_routine = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.DamageEvent) then
		self:on_damage_event(e)
	elseif event_type == typeof(CS.Oak.HoldUpEvent) then
		self:on_hold_up_event(e)
	elseif event_type == typeof(CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	local zone_name = e.Zone.Name

	if zone_name == self.journal_room_event_zone then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.see_journal_room_event == false and self.get_journal_star_piece == false then
				self.see_journal_room_event = true

				self.journal_room_event_routine = coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.journal_room_event, self))
			end
		end
	end

	if zone_name == self.secretary_event_zone_name then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			-- 강아지가 플레이어에게 들려 있지 않으면 체크할 필요 없이 플레이어만 입장한 경우임
			if self.secretary_pet.Holdable.IsHeld == false and self.pet_with_secretary_room == false then
				--speech_bubble_util.show_speech_bubble(self.secretary, { key = 'highschool_1_5_dog_lover_0' })
			-- 강아지가 들려 있을 경우 무조건 플레이어 손에 들린 것이므로 같이 입장한 경우임
			else
				if not self.pet_with_secretary_room then
					self.pet_with_secretary_room = true

					self.attracted_by_pet_event_routine = coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.attracted_by_pet, self))
				end
			end
		elseif lua_helper.reference_equals(e.FieldObject, self.secretary_pet) then
			if not self.pet_with_secretary_room then
				self.pet_with_secretary_room = true

				self.attracted_by_pet_event_routine = coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.attracted_by_pet, self))
			end
		end
	end

	if zone_name == self.secretary_upper_zone_name then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.clap_sfx_played == false then
				self.clap_sfx_played = true

				-- 박수 갈채 sfx 재생
				self:play_clap_sfx()
			end
		end
	end

	if zone_name == self.trash_zone_name then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.pet_with_secretary_room == false and self.get_secretary_star_piece == false and
					self.appear_star_piece == false then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.secretary_block, self))
			end
		end
	end

	if zone_name == "salute_0" then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.salute_0 == false then
				self.salute_0 = true
				-- 경례 sfx
				music_player:PlaySfxOneShot('02_twohand_stomp_jump_01')

				character_util.set_anim(get_character("elite_student_right_0"), { name = "salute", loop = false })
				character_util.set_anim(get_character("elite_student_left_0"), { name = "salute", loop = false })
			end
		end
	elseif zone_name == "salute_1" then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.salute_1 == false then
				self.salute_1 = true
				-- 경례 sfx
				music_player:PlaySfxOneShot('02_twohand_stomp_jump_01')

				character_util.set_anim(get_character("elite_student_right_1"), { name = "salute", loop = false })
				character_util.set_anim(get_character("elite_student_left_1"), { name = "salute", loop = false })
			end
		end
	elseif zone_name == "salute_2" then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.salute_2 == false then
				self.salute_2 = true
				-- 경례 sfx
				music_player:PlaySfxOneShot('02_twohand_stomp_jump_01')

				character_util.set_anim(get_character("elite_student_right_2"), { name = "salute", loop = false })
				character_util.set_anim(get_character("elite_student_left_2"), { name = "salute", loop = false })
			end
		end
	elseif zone_name == "salute_3" then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.salute_3 == false then
				self.salute_3 = true
				-- 경례 sfx
				music_player:PlaySfxOneShot('02_twohand_stomp_jump_01')

				character_util.set_anim(get_character("elite_student_right_3"), { name = "salute", loop = false })
				character_util.set_anim(get_character("elite_student_left_3"), { name = "salute", loop = false })
			end
		end
	elseif zone_name == "salute_4" then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.salute_4 == false then
				self.salute_4 = true
				-- 경례 sfx
				music_player:PlaySfxOneShot('02_twohand_stomp_jump_01')

				character_util.set_anim(get_character("elite_student_right_4"), { name = "salute", loop = false })
				character_util.set_anim(get_character("elite_student_left_4"), { name = "salute", loop = false })
			end
		end
	elseif zone_name == "salute_5" then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.salute_5 == false then
				self.salute_5 = true
				-- 경례 sfx
				music_player:PlaySfxOneShot('02_twohand_stomp_jump_01')

				character_util.set_anim(get_character("elite_student_right_5"), { name = "salute", loop = false })
				character_util.set_anim(get_character("elite_student_left_5"), { name = "salute", loop = false })
			end
		end
	end

end

function local_class:on_zone_leave_event(e)
	if not e.FullLeave then return end
	local zone_name = e.Zone.Name

	if zone_name == self.secretary_event_zone_name then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			-- 강아지가 들려 있을 경우 무조건 플레이어 손에 들린 것이므로 강아지가 나간 경우임
			if self.secretary_pet.Holdable.IsHeld then
				if self.pet_with_secretary_room then
					self:reset_secretary()
				end
			end
		elseif lua_helper.reference_equals(e.FieldObject, self.secretary_pet) then
			if self.pet_with_secretary_room then
				self:reset_secretary()
			end
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.journal_ogre) then
		if self.get_off_journalist_num >= 4 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.complete_journal_event, self))
		else
			speech_bubble_util.show_speech_bubble(self.journal_ogre, "highschool_1_5_journal_room_6")
		end
	elseif lua_helper.reference_equals(e.Target, self.pet_keeper) then
		if not self.hold_pet then
			speech_bubble_util.show_speech_bubble(self.pet_keeper, "highschool_1_5_dog_lover_2")
		else
			speech_bubble_util.show_speech_bubble(self.pet_keeper, "highschool_1_5_dog_lover_3")
		end
	end
end

function local_class:on_damage_event(e)
	for i = 1, #self.journalist_list do
		if lua_helper.reference_equals(e.Info.target, self.journalist_list[i]) then
			if e.Info.type == CS.Oak.DamageType.Melee or e.Info.type == CS.Oak.DamageType.Explosion then
				local target = self.journalist_list[i]

				target:SetAnimation("embarrassed", true)
				target:SetEmotion("damaged", true)

				message_system:Send(target.CharacterBehaviour, CS.Oak.StateChangeEvent.Create(
						CS.Oak.CharacterAirSpinState.Create(
								target, (target.Position - e.Info.sender.Position), 1, 0.15, true, true)))

				self.get_off_journalist_num = self.get_off_journalist_num + 1

				if self.get_off_journalist_num == 4 then
					-- 기자들의 질문 공세 앰비언스 sfx 루프 중지
					self:stop_journalist_ambience_sfx()

					stop_coroutine(self.journalist_ask_event_routine)

					self.journal_ogre:CancelShake()
					self.journal_ogre:SetAnimation("clap", true)
					self.journal_ogre:SetEmotion("smile", true)

					character_util.set_direction(get_character(
							string.format("%s%d", self.journal_sub_name, 0)), CS.Oak.Direction.Right)
					get_character(
							string.format("%s%d", self.journal_sub_name, 0)):SetAnimation("victory_extra", true)
					get_character(
							string.format("%s%d", self.journal_sub_name, 0)):SetEmotion("smile", true)

					character_util.set_direction(get_character(
							string.format("%s%d", self.journal_sub_name, 1)), CS.Oak.Direction.Left)
					get_character(
							string.format("%s%d", self.journal_sub_name, 1)):SetAnimation("victory_extra", true)
					get_character(
							string.format("%s%d", self.journal_sub_name, 1)):SetEmotion("smile", true)
				end

				break
			end
		end
	end
end

function local_class:on_hold_up_event(e)
	if lua_helper.reference_equals(e.Target, self.secretary_pet) then
		if not self.hold_pet then
			self.hold_pet = true

			speech_bubble_util.show_speech_bubble(self.pet_keeper, "highschool_1_5_dog_lover_3")

			music_player:PlaySfxOneShot('03_runaway_01')

			self.pet_keeper:SetAnimation("embarrassed", true)
			self.pet_keeper:SetEmotion("damaged", true)
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	if e.FieldObject.Name == self.trash_bin_name then
		self.appear_star_piece = true

		if not self.pet_with_secretary_room then
			character_util.look_at(self.secretary, user_party_leader)
			self.secretary:SetEmotion("tired", true)

			speech_bubble_util.show_speech_bubble(self.secretary, "highschool_1_5_dog_lover_5")
		end
	end
end

-- 언론실 입장 시 발생하는 기자들의 질문 이벤트
function local_class:journal_room_event()
	-- 플레이어 조작이 가능하므로 안보이는 곳에서 들리지 않도록 3d 재생
	music_player_util.play_sfx({
		sfx_name = '01_jump_01', parent = self.journalist_list[1]
	})

	character_util.jump(self.journalist_list[1], 1, 0.5)

	-- 이 이벤트가 처음 한번만 불리기에 남아있는 기자 수 체크하지 않고 재생한다. 혹시나 연출이 바뀌게 된다면 이곳도 재 확인 해야함.
	-- 기자들 질문 공세 앰비언스 sfx 루프 재생 시작
	self:play_journalist_ambience_sfx()

	speech_bubble_util.show_speech_bubble_async(
			self.journalist_list[1], { key = 'highschool_1_5_journal_room_0', skip = false })

	self.journal_ogre:Shake(0.02, 9999)

	speech_bubble_util.show_speech_bubble_async(
			self.journal_ogre, { key = 'highschool_1_5_journal_room_1', skip = false })

	if self.journalist_list[3].ActiveState == CS.Oak.ActiveState.Enabled then
		-- 플레이어 조작이 가능하므로 안보이는 곳에서 들리지 않도록 3d 재생
		music_player_util.play_sfx({
			sfx_name = '01_jump_01', parent = self.journalist_list[3]
		})

		character_util.jump(self.journalist_list[3], 1, 0.5)

		speech_bubble_util.show_speech_bubble_async(
				self.journalist_list[3], { key = 'highschool_1_5_journal_room_2', skip = false })

		self.journal_ogre:Shake(0.02, 9999)

		speech_bubble_util.show_speech_bubble_async(
				self.journal_ogre, { key = 'highschool_1_5_journal_room_3', skip = false })
	end

	if self.get_off_journalist_num < 4 then
		for i = 1, #self.journalist_list do
			if self.journalist_list[i].ActiveState == CS.Oak.ActiveState.Enabled then
				self.journalist_list[i]:SetAnimation("success", true)
			end
		end

		-- 기자 질문 공세하는 이벤트 시작
		self.journalist_ask_event_routine = coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.journalist_ask_event, self))
	end
end

-- 기자들이 질문 공세를 퍼붓는 이벤트
function local_class:journalist_ask_event()
	local talk_flag = true

	while true do
		local npc_rand = random_util.get_random_int(1, #self.journalist_list)

		if self.journalist_list[npc_rand].ActiveState == CS.Oak.ActiveState.Enabled then
			local talk_string = ""

			if talk_flag then
				talk_flag = false
				talk_string = "highschool_1_5_journal_room_4"

				-- 첫 대사에만 효과음 재생
				-- music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
			else
				talk_flag = true
				talk_string = "highschool_1_5_journal_room_5"
			end

			speech_bubble_util.show_speech_bubble_async(
					self.journalist_list[npc_rand], { key = talk_string, skip = false })

			coroutine.yield(coroutine_class.wait_for_sec(1))
		else
			coroutine.yield(nil)
		end
	end
end

-- 기자들의 취재 앰비언스 sfx 루프 재생
function local_class:play_journalist_ambience_sfx()
	-- 이미 재생중이었다면 끊고 다시 재생
	if self.interview_sfx ~= nil then
		self.interview_sfx:FadeOut(0.2)
	end

	-- 적당한 기자 위치에 3d로 인터뷰 앰비언스 사운드 루프 재생
	-- 8개의 효과음 채널중 1개를 이 사운드가 점유하게 되므로, 남용하면 안됨!
	self.interview_sfx = music_player_util.play_sfx({
		sfx_name = '01_amb_interview_01', play_pos = self.journalist_list[1].Position, loop = true, fade_in_time = 0.4,
		type_priority = 'event', player_priority = 'npc'
	})
end

-- 기자들의 취재 앰비언스 sfx 중지
function local_class:stop_journalist_ambience_sfx()
	if self.interview_sfx ~= nil then
		self.interview_sfx:FadeOut(0.2)
	end

	self.interview_sfx = nil
end

-- 박수 갈채 sfx 재생
function local_class:play_clap_sfx()
	if self.clap_sfx ~= nil then
		self.clap_sfx:FadeOut(0.2)
	end

	local clap_center_npc = get_character(self.clap_center_npc_name)
	local clap_position

	if clap_center_npc ~= nil then
		clap_position = clap_center_npc.Position
	end

	-- 어차피 루프형 사운드가 아니기에 실제 루프보다 효과음 풀 점유 부하가 조금이라도 적은 repeat_term으로 재생한다.
	-- 루프로 재생할 경우 효과음 풀에서 밀려서 끊어진 경우, 다시 재생하지 않는 한 복구되지 않으나, 반복재생으로 재생한 경우 끊어지더라도 다시 재생됨.
	-- 근접한 그리드에서 들리지 않도록 max_distance를 적절히 조절
	self.clap_sfx = music_player_util.play_sfx({
		sfx_name = '01_applaud_01', repeat_term = 0.2, play_pos = clap_position, max_distance = 11,
		type_priority = 'loop', player_priority = 'npc'
	})
end

-- 박수 갈채 sfx 중지
function local_class:stop_clap_sfx()
	if self.clap_sfx ~= nil then
		self.clap_sfx:FadeOut(0.2)
	end

	self.clap_sfx = nil
end

-- 기자 4명을 날려버리고 오우거와 대화하면 스타피스 주는 이벤트
function local_class:complete_journal_event()
	field_ui_manager:Hide()
	character_util.align_party(self.journal_ogre, "down", nil, "arc")

	self.journal_ogre:SetAnimation("clap", true)

	speech_bubble_util.show_speech_bubble_async(
			self.journal_ogre, { key = 'highschool_1_5_journal_room_7', skip = true })

	self.journal_ogre:SetAnimation("get", true)

	speech_bubble_util.show_speech_bubble_async(
			self.journal_ogre, { key = 'highschool_1_5_journal_room_8', skip = true })

	self.journal_ogre:RemoveAnimation()

	-- 스타피스 등장
	local star_piece = get_field_object(self.journal_star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(self.journal_ogre.Position))

	self.journal_ogre.Interactable:RemoveRelatedEvent(self.cs_controller)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 강아지에게 홀린 비서
function local_class:attracted_by_pet()
	character_util.jump(self.secretary, 1, 0.5)

	self.secretary:SetAnimation("sing", true)
	self.secretary:SetEmotion("love", true)

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')

	speech_bubble_util.show_speech_bubble(self.secretary, "highschool_1_5_dog_lover_4")

	while true do
		character_util.set_direction(self.secretary,
				CS.Oak.DirectionExtensions.GetSideDirection(
						(self.secretary_pet.Position - self.secretary.Position):ToDirection()))

		coroutine.yield(nil)
	end
end

-- 플레이어가 쓰레기통에 가지 못하게 막는 비서 이벤트
function local_class:secretary_block()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	camera_util.move(self.secretary.Position, 0.5)

	music_player:PlaySfxOneShot('01_player_jump_01')

	character_util.jump(user_party_leader, 1, 0.5)
	character_util.set_direction(user_party_leader, CS.Oak.Direction.Down)

	character_util.set_direction(self.secretary,
			(user_party_leader.Position - self.secretary.Position):ToDirection())
	self.secretary:SetAnimation("release", true)
	self.secretary:SetEmotion("attack", true)

	-- secretary release 애니메이션 키에 휙- 휙- 효과음 추가
	character_util.add_animation_sfx(self.secretary, '01_swing_01')

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	music_player:PlaySfxOneShot('01_jump_01')

	character_util.jump(self.secretary, 1, 0.5)

	speech_bubble_util.show_speech_bubble_async(
			self.secretary, { key = 'highschool_1_5_dog_lover_1', skip = true })

	character_util.set_direction(self.secretary, CS.Oak.Direction.Down)
	self.secretary:RemoveAnimation()
	self.secretary:RemoveEmotion()

	camera_util.move(user_party_leader.Position, 0.5)

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	stage_camera:SetTarget(user_party_leader)

	coroutine.yield(nil)

	coroutine.yield(CS.Oak.IFieldObjectExtensions.MoveTo(user_party_leader,
			user_party_leader.Position + vector(0, 0, -2.5), 1, nil, true, true))

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 강아지에게 홀렸던 비서 리셋
function local_class:reset_secretary()
	character_util.set_direction(self.secretary, CS.Oak.Direction.Down)
	self.secretary:RemoveAnimation()
	self.secretary:RemoveEmotion()

	self.pet_with_secretary_room = false

	stop_coroutine(self.attracted_by_pet_event_routine)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
