local local_class = newclass('NightmareDesert1At4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	-- 뚱보 엘프 선언  시작 pos: (-84,0,13)
	self.desertelf_fat = nil
	self.is_standing = false
	-- 라일라 잡화점 : 라일라 와 고기 (+고기 이미지 = banquet, id: 20032 ), 매대 ---> 라일라 에서 desertelf_female 로 변경
	self.laila = nil
	self.meat = nil
	self.meat_loc = vector(-84,0.5,19)
	self.meat_stand = nil
	self.stop_talking = false
	-- 고기를 취득 했는 지,  고기를 먹었는 지, 고기를 따라 가고 있는지
	self.has_meat = false
	self.has_eaten = false
	self.is_following = false
	-- 고기 판매 진행 여부, 고기가 팔렸는 지, 점프존에 있는지
	self.playing_market_event = false
	self.is_meat_sold = false
	self.food_in_zone = false
	-- 점프 연출 지역 입장 플래그
	self.npc_has_entered = false
	-- 유저가 지역 밖으로 나갔는 지
	self.user_in_area = false

	--스타피스 이벤트 완료 체크 flag
	self.already_eaten = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StarPieceGetEvent), 'on_event')

	-- 고기 상점 주인 = 라일라
	self.laila = get_character('laila')
	-- 쫓아 가야 되는 고기
	self.meat = get_field_object('fake_meat')
	self.meat_stand = get_field_object('meat_stand')
	self.meat_stand.Interactable = CS.Oak.PublishInteractable.Create()
	-- 뚱보 사막 엘프 기본 상태 설정
	self.desertelf_fat = get_character('desertelf_fat')
	self.desertelf_fat.Interactable:AddListener(self.cs_controller)
	character_util.set_direction(self.desertelf_fat, 'right')
	--lie_side 가 아니라 특정 캐릭터 전용 애니메이션이라 unique/ 붙고 끝에 _side 는 적용 되는 방향 표시.
	character_util.set_anim(self.desertelf_fat,{ name = 'unique/lie' })
	character_util.set_emotion(self.desertelf_fat,{ name = 'idle' })
	self.is_standing = false


	if stage_progress:HasStarPiece('fat_meat_star_piece') then
		self.already_eaten = true
	end
	if self.already_eaten then
		character_util.set_active_state(self.desertelf_fat, 'disabled')
		character_util.set_active_state(get_character('desertelf_kid_girl (1)'), 'disabled')
		self.is_meat_sold = true
	end
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StarPieceGetEvent))

	if type_util.is_npc_interactable(self.desertelf_fat) then
		self.desertelf_fat.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.desertelf_fat = nil
	self.laila = nil
	self.meat = nil
	self.cs_controller = nil
	self.meat_stand = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StarPieceGetEvent) then
		self:on_star_piece_get_event(e)
	end
	return false
end

-- onEvent 나누기
function local_class:on_interact_event(e)
	-- 뚱보 사막 엘프 idle 상태 기본 대사
	if lua_helper.reference_equals(e.Target, self.desertelf_fat) and not self.is_standing then
		local num = 0
		if not self.has_eaten then num = 1 else num = 3 end

		speech_bubble_util.show_speech_bubble(
				self.desertelf_fat, { key = 'nightmare_desert_s4_fat_'..num, skip = false })

	elseif lua_helper.reference_equals(e.Target, self.meat_stand) then
		self.stop_talking = true
		self.playing_market_event = false
		speech_bubble_util.remove_bubble(self.laila)
		if self.is_meat_sold then
			self:she_said(8,false)
		elseif self.already_eaten then
			self:she_said(10,false)
		else
			sp_util.play_normal_screenplay(self.sell_meat_buy, self)
		end
	end
end

function local_class:on_zone_enter_event(e)
	-- 유저 스타피스 이벤트 지역 입장시 매점 대사 출력
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		if e.Zone.Name == 'fat_elf_zone' and not self.playing_market_event and not self.already_eaten then
			self.playing_market_event = true
			if not self.stop_talking then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.sell_meat_marketing, self))
			end
		end
	end
	-- 점프대 zone에 뚱보 엘프 진입 확인
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, self.desertelf_fat) then
		if e.Zone.Name == 'invisible_jump_npc' then
			self.npc_has_entered = true
		end
	end
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, self.meat) then
		if e.Zone.name == 'fat_elf_zone' then
			self.food_in_zone = true
		end
		if e.Zone.Name == 'starpiece_area_fat' then
			message_system:Send(self.meat, CS.Oak.GimmickResetEvent.Instance)
			music_player_util.play_sfx({ sfx_name = '01_guild_warp_01', play_pos = self.meat.Position	})
			self.is_following = false
			--[[ 위 또는 아래를 보고 눕는 애니메이션 (unique/lie) 를 사용 할 경우, 따로 전용 모션이 없어 이전에 출력 하던
			 애니메이션이 이어서 출력 된다. 따라서 특별한 이동 방향이 있는게 아닌 이상 오른쪽을 보고 눕게 설정 ]]
			character_util.set_direction(self.desertelf_fat, 'right')
			music_player_util.play_sfx({
				sfx_name = '01_rustle_01',
				play_pos = self.desertelf_fat.Position,
				type_priority = 4000,
				player_priority = 900
			})
			character_util.set_anim(self.desertelf_fat, {name = 'unique/lie'})
			character_util.remove_emotion(self.desertelf_fat)
			self.is_standing = false
		end
		if e.Zone.Name == 'starpiece_area_fat_2' then
			message_system:Send(self.meat, CS.Oak.GimmickResetEvent.Instance)
			music_player_util.play_sfx({ sfx_name = '01_guild_warp_01', play_pos = self.meat.Position	})
			self.is_following = false
			character_util.set_direction(self.desertelf_fat, 'right')
			music_player_util.play_sfx({
				sfx_name = '01_rustle_01',
				play_pos = self.desertelf_fat.Position,
				type_priority = 4000,
				player_priority = 900
			})
			character_util.set_anim(self.desertelf_fat, {name = 'unique/lie'})
			character_util.remove_emotion(self.desertelf_fat)
			self.is_standing = false
		end
	end
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		if e.Zone.Name == 'fat_elf_zone' then
			self.user_in_area = true
		end
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		-- 점프대 밖으로 벗어 났을 때 플래그 소멸
		if e.Zone.Name == 'starpiece_area_fat' and user_party_leader.Position.y > 1 then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.party_jump, self))
		elseif e.Zone.Name == 'fat_elf_zone' then
			self.user_in_area = false
			self.stop_talking = true
		end
	end
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, self.desertelf_fat) then
		-- 점프 zone 밖으로 뚱보 엘프 나갔을 때 플래그 소멸
		if e.Zone.Name == 'invisible_jump_npc' then
			self.npc_has_entered = false
			self.desertelf_fat.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		end
	end
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, self.meat) then
		if e.Zone.Name == 'fat_elf_zone' then
			message_system:Send(self.meat, CS.Oak.GimmickResetEvent.Instance)
			music_player_util.play_sfx({ sfx_name = '01_guild_warp_01', play_pos = self.meat.Position	})
			self.is_following = false
			character_util.set_direction(self.desertelf_fat, 'right')
			music_player_util.play_sfx({
				sfx_name = '01_rustle_01',
				play_pos = self.desertelf_fat.Position,
				type_priority = 4000,
				player_priority = 900
			})
			character_util.set_anim(self.desertelf_fat, {name = 'unique/lie'})
			character_util.remove_emotion(self.desertelf_fat)
			self.is_standing = false
		end
	end
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, user_party_leader) then

	end
end

function local_class:on_stage_loaded_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.followfollowmeat, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject,	util.cs_generator(self.desertelf_fat_chase, self))
end

function local_class:on_stage_start_event(e)
	self.meat_item = drop_item_util.create_item({
		itemid = 20032,
		notforinven = true,
		sprscale = 1.5,
		pos = self.meat_loc,
		lootstate = 'dontfindlooter'
	})
	self.meat_item:SetSortingLayer(true)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_meat_image, self))
	self.meat.ActiveState = CS.Oak.ActiveState.Disabled
end

function local_class:on_star_piece_get_event(e)
	if CS.Oak.StageProgress.Current:HasStarPiece('fat_meat_star_piece') then
		self.already_eaten = true
	end
end
--- 이하 coroutine 목록

function local_class:she_said(i, tf)
	speech_bubble_util.show_speech_bubble(
			self.laila, { key = 'nightmare_desert_s4_meatsale_'..i, skip = tf })
	--bubble_direction = 'cb' 제거. 굳이 아래로 안 표현 해도 될 거 같음
end

function local_class:party_jump()
	self.can_jump = true
	self.is_first_jiggling = true
	self.all_jump = user_party.Count

	for i = 0, user_party.Count - 1 do
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.checking_first_jump, self, user_party[i]))
	end
end

function local_class:checking_first_jump(character)
	local offset = 0.6

	while self.can_jump do
		if character.Position.y < offset then
			if self.has_eaten and self.npc_has_entered then
				-- 점프 실행
				user_party:StopAndDisableControl()
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.second_jump, self, character))
				self.all_jump = self.all_jump - 1
			elseif lua_helper.reference_equals(character, user_party_leader) then
				self.can_jump = false
				user_party:ResetControllers()
			end
			return
		end
		coroutine.yield(nil)
	end
end

function local_class:second_jump(character)
	local target_pos = vector(-91, 1, 13)
	character_util.remove_anim(character)
	if self.is_first_jiggling then
		self.is_first_jiggling = false
		character_util.spine_damage_squish(self.desertelf_fat, 1.5, 1, 1, 0.5)
		character_util.set_anim(self.desertelf_fat,{ name = 'unique/jiggling', loop = false})
	end

	local jump_dur = 1

	music_player:PlaySfxOneShot('01_fat_gnome_03')
	character_util.move_to(character, target_pos,
			jump_dur, nil, true, false, false)
	character_util.jump(character, 3, jump_dur)
	self.all_jump = self.all_jump - 1
	music_player:PlaySfxOneShot('01_land_01')
	if self.all_jump <= 0 then --or user_party_leader.Position.y <=1 n
		user_party:ResetControllers()
	end
end

--fake meat 에 meat skin 씌워주는 코루틴
function local_class:set_meat_image()
	self.meat.Hitbox = CS.Oak.Hitbox(vector(.5, .5, .5))
	while true do
		if not self.is_meat_sold or self.already_eaten then
			self.meat_item.Position = vector (999,0,999)
		else
			self.meat_item.Position = self.meat.Position + 0.2 * unity_class.vector3.up
		end
		coroutine.yield(nil)
	end
end

--뚱보 엘프가 고기를 쫓아 가는 동안 대사: 1.5초 마다 '오오! 맛있는 고기 냄새!'
function local_class:desertelf_fat_chase()
	while true do
		if self.is_following and not self.has_eaten and not self.has_meat then
			music_player_util.play_sfx({
				sfx_name = '02_die_fat_ogre_01',
				play_pos = self.desertelf_fat.Position
			})
			speech_bubble_util.show_speech_bubble_async( self.desertelf_fat,
					{ key = 'nightmare_desert_s4_fat_2', skip = true })
		end
		wait_for_sec(1.5)
	end
end

-- 매대 에서 고기 파는 사막엘프 여자가 호객 하는 대사
function local_class:sell_meat_marketing()
	while(true) do
		character_util.set_direction(self.laila, 'down')
		character_util.set_anim(self.laila,{ name = 'idle' })
		character_util.set_emotion(self.laila,{ name = 'idle' })
		wait_for_sec(3)
		if not lua_helper.type_compare(self.meat_stand.Interactable, CS.Oak.NonInteractable) or
				not self.already_eaten then
			if not self.stop_talking then
				local random_number = random_util.get_random_int(1, 2)
				speech_bubble_util.show_speech_bubble_async(self.laila, {
					key = 'nightmare_desert_s4_meatsale_'..random_number,
					offset = vector(0, 0, 1.5),
					auto_layout = true,
					bubble_direction = 'ct'
				})
			else
				self.stop_talking = false
				break
			end
		end
		coroutine.yield(nil)
	end
	character_util.remove_emotion(self.laila)
end

-- fat_desertelf 가 범위 내에 고기가 들어오면 고기를 따라가도록 만드는 코루틴
function local_class:followfollowmeat()
	self.is_following = false
	self.has_eaten = false
	self.is_standing = false
	local fatty = self.desertelf_fat
	local food = self.meat
	local dir = vector(10, 10, 10)
	local range = 5.0
	local distance = 1.1
	local jump_loc = vector(-91.5, 0, 15.5)
	while (true) do
		--if self.user_in_area then
			-- 범위 내 타겟이 있다면 쫓아간다.
			local fos = field:GetFieldObjectsInRadius(fatty.Position, range)
			for k, v in pairs(fos) do
				if lua_helper.reference_equals(v, food) then
					dir = food.Position - fatty.Position
				end
			end
			fos:Dispose()
			-- 음식이 보이는 거리 안에 있으며 매대 밖에 있을 때
			if food.Position.y <= 1.2 then
				if dir.magnitude <= range then
					--음식이 조금 멀리 있을 때 걸어감
					if dir.magnitude > distance and self.is_meat_sold then
						if food.Position ~= self.meat_loc and
								food.Position ~= (self.meat_loc - vector(1,0,0)) then
							self.is_following = true
							if not self.is_standing then
								music_player_util.play_sfx({
									sfx_name = '01_rustle_01',
									play_pos = self.desertelf_fat.Position,
									type_priority = 4000,
									player_priority = 900
								})
								character_util.set_anim(fatty, {name = 'idle'})
								self.is_standing = true
							end
							character_util.set_emotion(fatty, {name = 'love'})
							character_util.set_anim(fatty, {name = 'walk'})
							fatty.Direction = dir:ToDirection()
							CS.Oak.MoveOneFrameStageLogic.ExecuteMove(fatty, dir.normalized,
									1 * unity_class.time.deltaTime)
							self.has_eaten = false
						end
					end

					if dir.magnitude <= distance then -- 고기에 도착 했을 때

						fatty.Direction = direction_util.to_side_dir(fatty.Direction)
						self.has_meat = true
						-- 고기를 먹는 도중
						if self.has_meat and self.is_meat_sold then
							--CS.UnityEngine.Debug.LogError(food.Position)
							if self.npc_has_entered then
								fatty.Direction = (jump_loc - fatty.Position):ToDirection()
								character_util.move_to_async(
										fatty,
										jump_loc,
										nil,
										3,
										false,
										false
								)
								if food.Position.x < jump_loc.x then
									character_util.set_direction(fatty, 'right')
								else
									character_util.set_direction(fatty, 'left')
								end
							end
							food.Position = fatty.Position
							local eatSfx = music_player_util.play_sfx({
								sfx_name = '01_eat_01',
								play_pos = self.desertelf_fat.Position,
								type_priority = 4000,
								player_priority = 900,
								loop = true
							})
							character_util.set_anim(fatty, {name = 'unique/eat'})
							self:meat_being_eaten()
							eatSfx:FadeOut(0.2)
							self.is_standing = false
							self.meat.ActiveState = CS.Oak.ActiveState.Disabled
							food.Position = self.meat_loc
							self.meat_item.SpriteTransform.localScale = vector(1,1,1) * 1.5
							self.meat_item.ShadowTransform.localScale = vector(1,1,1) * 1.5
							dir = food.Position - fatty.Position
							-- 고기를 다 먹었을 때 (2초 후)
							music_player_util.play_sfx({
								sfx_name = '01_rustle_01',
								play_pos = self.desertelf_fat.Position,
								type_priority = 4000,
								player_priority = 900
							})
							character_util.set_anim(fatty, {name = 'unique/lie'})
							character_util.remove_emotion(fatty)
							self.has_eaten = true
							self.has_meat = false
							self.is_meat_sold = false
						elseif dir.magnitude < 1.5 and dir.magnitude > distance then
							character_util.set_anim(fatty, {name = 'idle'})

						end
					end
				end
				--타겟이 범위 밖으로 나갔을 때
				if dir.magnitude > range or food.Position == self.meat_loc then
					if not self.has_eaten then
						self.is_following = false
						self.has_meat = false
						if self.is_standing then
							music_player_util.play_sfx({
								sfx_name = '01_rustle_01',
								play_pos = self.desertelf_fat.Position,
								type_priority = 4000,
								player_priority = 900
							})
						end
						character_util.set_direction(self.desertelf_fat, 'right')
						character_util.set_anim(self.desertelf_fat,{ name = 'unique/lie'})
						self.is_standing = false
						character_util.remove_emotion(fatty)
					end
				end
			else
				if self.is_standing then
					music_player_util.play_sfx({
						sfx_name = '01_rustle_01',
						play_pos = self.desertelf_fat.Position,
						type_priority = 4000,
						player_priority = 900
					})
				end
				character_util.set_direction(self.desertelf_fat, 'right')
				character_util.set_anim(fatty, {name = 'unique/lie'})
				character_util.remove_emotion(fatty)
				self.is_standing = false
				self.is_following = false
			end
		--end
		coroutine.yield(nil)
	end
end

function local_class:meat_being_eaten()
	for i=1, 99 do
		self.meat_item.SpriteTransform.localScale = vector(1,1,1) * (1.5-(i*3)/200)
		self.meat_item.ShadowTransform.localScale = vector(1,1,1) * (1.5-(i*3)/200)
		coroutine.yield(nil)
	end
	return
end

-- 고기 구매 대화 [나메 티탄 1 꽃 파는 상인과 대화 참조]
function local_class:sell_meat_buy()
	self.meat_stand.Interactable = CS.Oak.NonInteractable.Instance
	local meat_merchant = self.laila
	local pos = self.meat_loc
	party_util.align_party(pos, 'down', 0.5, 'linear')
	pos = self.meat_stand.Position + unity_class.vector3.forward
	character_util.move_to_async(meat_merchant, pos, nil, 2, true, true)
	character_util.set_direction(meat_merchant, 'down')
	-- 호객행위
	coroutine.yield(self:she_said(9, true))
	-- 고기 구매 선택지
	local choose_result = choose_util.play_choose_event({
		{'nightmare_desert_s4_meatsale_4', 'normal'},
		{'nightmare_desert_s4_meatsale_5', 'normal'}})
	-- 선택지: 구매하기
	if choose_result == 1 then
		-- 내 소지금이 100원이 되는지 체크
		if CS.Oak.User.Me.Gold >= 100 then
			coroutine.yield(CS.Oak.StageApiRouter.SendPayGold(stage.StageId, 100, stage_custom))
			music_player:PlaySfxOneShot('03_drop_gold_01')
			--감사
			speech_bubble_util.show_speech_bubble_async(
					meat_merchant, { key = 'nightmare_desert_s4_meatsale_3', skip = true })

			coroutine.yield(self:buy_meat())			---- 구매 연출
			-- 좋은하루
			coroutine.yield(self:she_said(7, true))
		elseif choose_result == 2 then
			-- 미안 고기 100골
			coroutine.yield(self:she_said(6, true))
		end
		-- 선택지: 무시하기
	else

	end
	self.meat_stand.Interactable = CS.Oak.PublishInteractable.Create()
	self.is_interacting = false

	if not self.stop_talking then
		coroutine_manager:StartCoroutine(stage.StageGameObject,	util.cs_generator(self.sell_meat_marketing, self))
	end
end

-- 고기 구매 연출 [나이트메어 티탄 1 꽃 구매 연출 참조]
function local_class:buy_meat()
	local meat_merchant = self.laila
	local before_pos = meat_merchant.Position
	local pos = meat_merchant.Position + 0.5 * unity_class.vector3.back

	character_util.move_to_async(
			meat_merchant,
			vector (meat_merchant.Position.x,0,pos.z),
			nil,
			4,
			false,
			false
	)
	character_util.set_direction(meat_merchant, 'left')
	character_util.move_to_async(
			meat_merchant,
			pos - vector(1,0,0),
			nil,
			4,
			false,
			false
	)
	character_util.set_direction(meat_merchant, 'down')
	music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = meat_merchant.Position	})

	self.meat.Position = self.meat_loc - vector(1,0,0)
	self.meat.ActiveState = CS.Oak.ActiveState.Enabled
	self.is_meat_sold = true

	character_util.set_direction(meat_merchant, 'up')
	character_util.move_to_async(
			meat_merchant,
			vector(meat_merchant.Position.x,0,before_pos.z),
			nil,
			5,
			false,
			true
	)
	character_util.set_direction(meat_merchant, 'right')
	character_util.move_to_async(
			meat_merchant,
			before_pos,
			nil,
			5,
			false,
			true
	)
	character_util.set_direction(meat_merchant, 'down')
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
