local local_class = newclass('FireWorld6Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 478
	self.quest_progress = nil

	self.get_statue = function()
		return get_character('fw_fire_dragon_king_statue')
	end

	self.stage_event = {
		event_data = {
			fire_rager = {
				id = 479,
				load_func = self.fire_rager_load,
				handler = self,
			},
			hotspring = {
				id = 480,
				load_func = self.hot_spring_load,
				handler = self,
				enter_event = {
					enter_condition = false,
					zone_name = 'hot_spring_enter_zone',
					action = self.hot_spring_enter_scene,
				}
			},
			wyvern = {
				id = 481,
				load_func = self.wyvern_load,
				handler = self,
			},
			layton = {
				id = 482,
				load_func = self.layton_load,
				handler = self,
			},
			dokkaebi = {
				id = 483,
				load_func = self.dokkaebi_load,
				handler = self,
			},
			oni_girl = {
				id = 484,
				load_func = self.oni_girl_load,
				handler = self,
			},
			mine_craft = {
				id = 487,
				load_func = self.mine_craft_load,
				handler = self,
			},
			terminator = {
				id = 488,
				load_func = self.terminator_load,
				handler = self,
			},
			tamagotchi = {
				id = 489,
				load_func = self.tamagotchi_load,
				handler = self,
			},
			vampire_idol = {
				id = 490,
				load_func = self.vampire_idol_load,
				handler = self,
			},
			viking = {
				id = 491,
				load_func = self.viking_load,
				handler = self,
			},
		},

		---@type fun(this:self)
		load_async = function(this)
			this:foreach(function(key, info)
				local quest_progress = user_progress:GetStartedQuest(info.id)
				if type_util.is_function(info.load_func) then
					info.load_func(info.handler, quest_progress)
				end
			end)
		end,

		---@type fun(this:self, action:function)
		foreach = function(this, action)
			for key, info in pairs(this.event_data) do
				action(key, info)
			end
		end,

		---@type fun(this:self, e:ZoneEnterEvent):boolean
		on_zone_enter_event = function(this, e)
			for key, info in pairs(this.event_data) do
				local enter_event = info.enter_event
				if enter_event ~= nil and info.enter_event.enter_condition and
						type_util.is_zone_full_enter(e, get_party_leader(), enter_event.zone_name) then
					this.event_data[key].enter_event.enter_condition = false
					enter_event.action(info.handler)

					return true
				end
			end
			return false
		end,

		---@type fun(this:self, e:ZoneLeaveEvent):boolean
		on_zone_leave_event = function(this, e)
			for key, info in pairs(this.event_data) do
				local leave_event = info.leave_event
				if leave_event ~= nil and leave_event.leave_condition and
						type_util.is_zone_full_enter(e, get_party_leader(), leave_event.zone_name) then
					this.event_data[key].leave_event.enter_condition = false
					enter_event.action(info.handler)

					return true
				end
			end
			return false
		end,
	}

	self.dynamic_npc = {
		dict = {},
		loop_sfx = {},

		---@type fun(this:self)
		load_async = function(this, data)
			local npc_spec = {}
			for key, info in pairs(data) do
				npc_spec[key] = info.spec
			end

			local dict_inst = load_util.create_dynamic_npcs_async(npc_spec)

			--키 중복 방지
			for key, value in pairs(dict_inst) do
				if this.dict[key] == nil then
					this.dict[key] = value
				end
			end
		end,

		load_npc_async = function(this, data)
			this:load_async(data)
			this:set_by_npc_data(data)
		end,

		---@type fun(this:self)
		dispose = function(this)
			for _, sfx in pairs(this.loop_sfx) do
				sfx:Stop()
				sfx = nil
			end
			this.loop_sfx = nil

			load_util.dispose_dynamic_npcs(this.dict)
			this.dict = nil
		end,

		---@type fun(this:self, key:string)
		get = function(this, key)
			return this.dict[key]
		end,

		---@type fun(this:self, data:table)
		set_by_npc_data = function(this, data)
			for key, info in pairs(data) do
				local scale = lua_helper.get_or_default(info.scale, 1)
				local active_state = lua_helper.get_or_default(info.active_state, active_state_type.enabled)

				local npc = this:get(key)

				if npc == nil then
					CS.Debug.Log(key)
				end

				field_object_util.set_active_state(npc, active_state)

				character_util.set_direction(npc, info.dir)
				character_util.set_emotion(npc, info.emo)
				character_util.set_anim(npc, info.anim)
				character_util.spine_scale(npc, unity_class.vector3.one * scale, 0)

				if info.oneline ~= nil then
					npc.Interactable = CS.Oak.NPCInteractable.Create()
					npc.Interactable.Talk = info.oneline

					if info.talksfx ~= nil then
						npc.Interactable.TalkSfx = info.talksfx
					end
				end

				npc.Position = info.center + info.offset

				field_ui_manager:RemoveUI(npc, CS.Oak.FieldUiType.CharacterStats)
			end
		end,
	}

	--IDisposable을 갖는 오브젝트 데이터 스토리지
	self.disposable_data = {
		data = {},

		---@type fun(this:self, obj:PooledUnityObject | QuestDropItem)
		insert = function(this, obj)
			table.insert(this.data, obj)
		end,

		---@type fun(this:self)
		dispose = function(this)
			for i = 1, #this.data do
				this.data[i]:Dispose()
				this.data[i] = nil
			end
		end
	}

	self.fx = metatable_helper.create_fx_accessor({
		lava_boat_trail = function()
			return unity_object_pool.GetOrCreate('fx_fw_lava_boat_trail')
		end,
		flamethrower_loop = function()
			return unity_object_pool.GetOrCreate('fx_qc_flamethrower')
		end
	})

	self.oni_girl_boat = {
		trail = nil,
		boat_name = 'oni_girl_boat',
		speed = 6,
		is_move = false,
		is_talk = false,
		talk_distance = 4,

		---@type fun(this:self):IFieldObject
		get = function(this)
			return get_field_object(this.boat_name)
		end,

		---@type fun(this:self, oni_girl:Character)
		talk_check = function(this, oni_girl)
			if this.is_talk then
				return
			end

			local distance = vector_util.distance(oni_girl.Position, get_party_leader().Position)
			if distance < this.talk_distance then
				this.is_talk = true
				start_coroutine(function()
					--라나 (smile 표정) : 번개보다 빠르게!!
					music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', loop = false, parent = oni_girl})
					scene_util.play_normal_speech_action(oni_girl, self, nil,
							nil, nil, 'fw_stage_6_oni_girl_oneline_4')
				end)
			end
		end,

		---@type fun(this:self, boat:IFieldObject, wp:Vector3 | Vector3[])
		move_waypoint_loop = function(this, npc, boat, wp)
			--현재 이동 여부 체크 및 wp 체크
			if this.is_move or wp == nil then
				return
			end

			--이동 이펙트 생성
			local trail = self.fx.lava_boat_trail():Instantiate(
					boat.Position, unity_class.quaternion.identity, boat.Transform)

			local cur_wp = 1
			local start_pos = unity_class.vector3.zero
			local target_pos = wp[cur_wp]

			local move_pos = unity_class.vector3.zero
			local distance = 0
			local progress = 0
			local time_passed = 0
			local duration = -1
			local dir = nil

			this.is_move = true
			while this.is_move and not self.is_stage_end do
				--이동 연산
				time_passed = time_passed + unity_class.time.deltaTime
				progress = time_passed / duration

				if time_passed < duration then
					local current_pos = unity_class.vector3.Lerp(start_pos, target_pos, progress)

					npc.Position = current_pos
					boat.Position = current_pos
				else
					npc.Position = target_pos
					boat.Position = target_pos

					if cur_wp < #wp then
						cur_wp = cur_wp + 1
					else
						cur_wp = 1
					end

					start_pos = target_pos
					target_pos = wp[cur_wp]

					move_pos = target_pos - start_pos
					distance = move_pos.magnitude

					duration = distance / this.speed
					time_passed = 0

					local current_dir = vector_util.to_direction(move_pos)
					if dir ~= current_dir then
						dir = current_dir
						scene_util.set_direction(npc, dir, false)
					end
				end

				this:talk_check(npc)

				coroutine.yield(nil)
			end

			trail:Dispose()
			trail = nil
		end,
	}

	self.viking_run = {
		is_move = false,
		speed = 5.5,

		---@type fun(this:self, npc_group:Character[], wp:Vector3[])
		start_loop = function(this, npc_group, wp)
			if #npc_group > #wp or this.is_move then
				--순환 웨이포인트 구간보다 npc가 많은것은 상정하지 않는다.
				return
			end

			local run_data = {}
			for i = 1, #npc_group do
				local npc = npc_group[i]
				table.insert(run_data, {
					npc = npc,
					current_wp = i - 1,
					start_pos = unity_class.vector3.zero,
					target_pos = wp[i],

					move_pos = unity_class.vector3.zero,
					time_passed = 0,
					duration = -1,
					dir = nil,
				})
			end

			local progress = 0
			local distance = 0
			local move_pos = unity_class.vector3.zero
			local next_wp = 0

			this.is_move = true
			while this.is_move and not self.is_stage_end do
				local dt = unity_class.time.deltaTime
				for num, info in ipairs(run_data) do
					local npc = info.npc

					--이동 연산
					run_data[num].time_passed = run_data[num].time_passed + dt
					progress = run_data[num].time_passed / info.duration

					if run_data[num].time_passed < info.duration then
						local current_pos = unity_class.vector3.Lerp(info.start_pos, info.target_pos, progress)
						npc.Position = current_pos
					else
						npc.Position = info.target_pos

						if run_data[num].current_wp < #wp then
							next_wp = run_data[num].current_wp + 1
						else
							next_wp = 1
						end

						run_data[num].current_wp = next_wp

						run_data[num].start_pos = info.target_pos
						run_data[num].target_pos = wp[next_wp]

						move_pos = run_data[num].target_pos - run_data[num].start_pos
						distance = move_pos.magnitude

						run_data[num].duration = distance / this.speed
						run_data[num].time_passed = 0

						local current_dir = vector_util.to_direction(move_pos)
						if run_data[num].dir ~= current_dir then
							run_data[num].dir = current_dir
							scene_util.set_direction(npc, current_dir, false)
						end
					end
				end

				coroutine.yield(nil)
			end
		end,
	}

	self.is_stage_end = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	self.fx:create_all()
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	local statue = self.get_statue()

	field_ui_manager:RemoveUI(statue, CS.Oak.FieldUiType.CharacterStats)
	character_util.spine_scale(statue, vector(3, 3, 3), 0)
	character_util.force_update_spines(statue, 0.1)

	return true
end

function local_class:on_zone_enter_event(e)
	if self.stage_event:on_zone_enter_event(e) then
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.stage_event:on_zone_leave_event(e) then
		return true
	end

	return false
end

function local_class:on_stage_end_event(_)
	self.is_stage_end = true

	self.disposable_data:dispose()
	self.dynamic_npc:dispose()

	return false
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.stage_event:load_async()

	self:visible_all_safe_stone()

	self:visible_all_lava_fire_flow()

	stage_start_util.start_function(self.quest_progress)
end

function local_class:hot_spring_load(quest_progress)
	if quest_progress ~= nil and quest_progress.IsComplete then
		local center_pos = field_util.get_marker_pos('hot_spring_center_pos')

		--원라인 6번 (라피스)
		--스파인명 fw_uptown_lancer_girl
		--라피스 (left, tired, eat)
		local npc_data = {
			lancer_girl = {
				spec = 'fw_uptown_lancer_girl',
				dir = 'left',
				emo = { name = 'tired' },
				anim = { name = 'eat', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

		self.dynamic_npc.loop_sfx['lancer_girl'] = music_player_util.play_sfx({
			sfx_name = '03_equipping_01', loop = true, parent = self.dynamic_npc:get('lancer_girl')})

		self.stage_event.event_data.hotspring.enter_event.enter_condition = true

		local item_info = {
			--a - 유니폼
			uniform = {
				spec = 'fw_hotspring_uniform',
				center = center_pos,
				offset = vector(-1, 0, 0),
			},
			--b - 라피스 전무
			lapice_thing = {
				spec = 'fw_hotspring_lapice_thing',
				center = center_pos,
				offset = vector(-0.5, 0, 1),
			},
			--c - 종이
			paper = {
				spec = 'fw_hotspring_paper',
				center = center_pos,
				offset = vector(0.5, 0, 1),
			},
			--d -  젬
			gem_field = {
				spec = 'fw_gem_field',
				center = center_pos,
				offset = vector(1.5, 0, 1),
			},
		}

		local item_data = game_data_service.GetData('ItemData')
		for key, info in pairs(item_info) do
			local item_id = item_data:GetSpec(info.spec).Id
			local item = quest_drop_item_util.create_item({
				pos = info.center + info.offset,
				item_id = item_id,
				show_on_character = false,
				loot_state = quest_drop_item_loot_state.dont_find_looter,
			})

			self.disposable_data:insert(item)
		end
	end
end

function local_class:hot_spring_enter_scene()
	local lancer_girl = self.dynamic_npc:get('lancer_girl')

	start_coroutine(function()
		--라피스 (left, tired, eat) : 모든 물건에 이름을 적어놔야 안 잊어버릴거야.
		scene_util.play_normal_speech_action(lancer_girl, self, 'left',
				nil, nil, { key = 'fw_stage_6_lancer_girl_1' })

		if self.is_stage_end then
			return
		end

		--라피스 (left, tired, eat) : 그러면 앞으로 물건을 볼 때마다 생각나겠지.
		scene_util.play_normal_speech_action(lancer_girl, self, 'left',
				nil, nil, { key = 'fw_stage_6_lancer_girl_2' })

		if self.is_stage_end then
			return
		end

		--라피스 (left, tired, eat) : 이름… 슉…슉… 아니 이게 아니지….
		music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', loop = false, parent = lancer_girl})
		scene_util.play_normal_speech_action(lancer_girl, self, 'left',
				nil, nil, { key = 'fw_stage_6_lancer_girl_3' })

		if self.is_stage_end then
			loop_sfx:Stop()
			return
		end

		--라피스 (left, tired, eat) : 뭐더라….
		music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = lancer_girl})
		scene_util.play_normal_speech_action(lancer_girl, self, 'left',
				nil, nil, { key = 'fw_stage_6_lancer_girl_4' })
	end)
end

function local_class:oni_girl_load(quest_progress)
	local center_pos = field_util.get_marker_pos('oni_girl_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			oni_girl = {
				spec = 'fw_onigirl',
				dir = 'left',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
			},
		}
		local wp = {}
		local count = 8
		for i = 1, count do
			local pos = field_util.get_marker_pos('oni_girl_pos_' .. i)
			table.insert(wp, pos)
		end

		self.dynamic_npc:load_npc_async(npc_data)

		local oni_girl = self.dynamic_npc:get('oni_girl')
		local boat = self.oni_girl_boat:get()

		scene_util.set_emotion(oni_girl, self, 'smile')

		--무한 루프
		start_coroutine(function()
			self.oni_girl_boat:move_waypoint_loop(oni_girl, boat, wp)
		end)

	else
		local npc_data = {
			--라나 (right, tired, cast) : 으으… 갈고 닦은 나의 광차 운전 실력을 겨뤄줄 상대가 필요한데…
			oni_girl = {
				spec = 'fw_onigirl',
				dir = 'left',
				emo = { name = 'tired' },
				anim = { name = 'cast', loop = true },
				center = center_pos,
				offset = vector(1, 0, 0),
				oneline = 'fw_stage_6_oni_girl_oneline_1',
			}
		}

		self.dynamic_npc:load_npc_async(npc_data)

		local boat = self.oni_girl_boat:get()

		boat.Position = center_pos + vector(-0.5, 0, 0)
		boat.Interactable = CS.Oak.NonInteractable.Instance
		boat.Holdable = CS.Oak.NonHoldable.Instance
	end
end

function local_class:terminator_load(quest_progress)
	local center_pos = field_util.get_marker_pos('terminator_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--더미네이터 (right, idle, idle): 파괴되기 싫은데 누굴 따라가야 하지?
			terminator_1 = {
				spec = 'fw_war_machine',
				dir = 'right',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(-0.5, 0, 0),
				oneline = 'fw_stage_6_terminator_oneline_1',
				talksfx = '01_rustle_01'
			},
			--더미네이터 (left, idle, cross_arm): 너도 x축에 0이 하나 더 입력된 거냐?
			terminator_2 = {
				spec = 'fw_war_machine',
				dir = 'left',
				emo = { name = 'idle' },
				anim = { name = 'cross_arm', loop = true },
				center = center_pos,
				offset = vector(0.5, 0, 0),
				oneline = 'fw_stage_6_terminator_oneline_2',
				talksfx = '01_beep_02'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	else
		local npc_data = {
			--더미네이터 (right, idle, cross_arm): 먼저 온 D-800는 어디있는 거지?
			terminator_1 = {
				spec = 'fw_war_machine',
				dir = 'right',
				emo = { name = 'idle' },
				anim = { name = 'cross_arm', loop = true },
				center = center_pos,
				offset = vector(-0.5, 0, 0),
				oneline = 'fw_stage_6_terminator_oneline_3',
				talksfx = '02_terminator_shot_01'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	end
end

function local_class:layton_load(quest_progress)
	local center_pos = field_util.get_marker_pos('layton_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--뱃사공 (right, tired, cross_arm) : 이 양반 아직도 이러고 있네….
			layton_male = {
				spec = 'fw_nm_fh_male',
				dir = 'right',
				emo = { name = 'tired' },
				anim = { name = 'cross_arm', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_layton_oneline_1',
				talksfx = '03_dialogue_bad_01'
			},
			--루트 (right, tired, sing) : 교수님… 반대로 가면 된다니까요….
			layton_citizen_boy = {
				spec = 'fw_steampunk_citizen_boy',
				dir = 'right',
				emo = { name = 'tired' },
				anim = { name = 'sing', loop = true },
				center = center_pos,
				offset = vector(2, 0, 0),
				oneline = 'fw_stage_6_layton_oneline_2',
				talksfx = '03_dialogue_tipsy_01'
			},
			--레이큰 교수 (right, smile, question 정지) : 계속 같은 길이 나오다니… 새로운 수수께끼로군!
			layton = {
				spec = 'fw_steampunk_citizen_male',
				dir = 'right',
				emo = { name = 'smile' },
				anim = { name = 'question', loop = false },
				center = center_pos,
				offset = vector(3, 0, 0),
				oneline = 'fw_stage_6_layton_oneline_3',
				talksfx = '01_turn_page_02'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	else
		local npc_data = {
			--뱃사공 (right, damaged, frustration 정지) : 끄흡… 결국 동물들을 구하지 못했어….
			layton_male = {
				spec = 'fw_nm_fh_male',
				dir = 'right',
				emo = { name = 'damaged' },
				anim = { name = 'frustration', loop = false },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_layton_oneline_4',
				talksfx = '03_dialogue_sadness_01'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)
	end
end

function local_class:dokkaebi_load(quest_progress)
	local center_pos = field_util.get_marker_pos('dokkaebi_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--은하 (down, smile, dance_voodoo) : 용의 발톱 파~
			dokkaebi = {
				spec = 'fw_dokkaebi',
				dir = 'down',
				emo = { name = 'smile' },
				anim = { name = 'dance_voodoo', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_dokkaebi_oneline_1',
			},
			--란팡 (down, smile, dance_voodoo) : 조금 더 팔을 쭉쭉 뻗는 거다!
			dokkaebi_doll_girl = {
				spec = 'fw_doll_girl',
				dir = 'down',
				emo = { name = 'smile' },
				anim = { name = 'dance_voodoo', loop = true },
				center = center_pos,
				offset = vector(0, 0, 1),
				oneline = 'fw_stage_6_dokkaebi_oneline_2',
				talksfx = '03_dialogue_emphasize_01'
			},
			--다빈치 (down, smile, dance_voodoo) : 보스, 왜 우리까지 연습하는 거냐!
			dokkaebi_doctor_bear = {
				spec = 'fw_doctor_bear',
				dir = 'down',
				emo = { name = 'smile' },
				anim = { name = 'dance_voodoo', loop = true },
				center = center_pos,
				offset = vector(-1, 0, 0),
				oneline = 'fw_stage_6_dokkaebi_oneline_3',
			},
			--동태 (down, smile, dance_voodoo) : 배우는 게 빠르군, 신참!
			dokkaebi_minion = {
				spec = 'fw_sapa_dragontalon_minion',
				dir = 'down',
				emo = { name = 'smile' },
				anim = { name = 'dance_voodoo', loop = true },
				center = center_pos,
				offset = vector(1, 0, 0),
				oneline = 'fw_stage_6_dokkaebi_oneline_4',
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	else
		local npc_data = {
			--미니 은하 (right, damaged, cast2) : 다른 은하들은 어디에 있는 것일까요오…
			dokkaebi = {
				spec = 'fw_dokkaebi',
				dir = 'right',
				emo = { name = 'damaged' },
				anim = { name = 'cast2', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_dokkaebi_oneline_5',
				talksfx = '01_die_ant_01',
				scale = 0.5,
			},
			--란팡 (down, sleep_deep, cross_arm) : 이번 비밀작전은 실패인가….
			dokkaebi_doll_girl = {
				spec = 'fw_doll_girl',
				dir = 'down',
				emo = { name = 'sleep_deep' },
				anim = { name = 'cross_arm', loop = true },
				center = center_pos,
				offset = vector(0, 0, 1),
				oneline = 'fw_stage_6_dokkaebi_oneline_6',
			},
			--다빈치 (right, tired, idle) : 쪼끄맣구만.
			dokkaebi_doctor_bear = {
				spec = 'fw_doctor_bear',
				dir = 'right',
				emo = { name = 'tired' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(-1, 0, 0),
				oneline = 'fw_stage_6_dokkaebi_oneline_7',
			},
			--동태 (left, idle, cross_arm) : 작은 몸으로 사는 것도 꽤 즐겁단다.
			dokkaebi_minion = {
				spec = 'fw_sapa_dragontalon_minion',
				dir = 'left',
				emo = { name = 'idle' },
				anim = { name = 'cross_arm', loop = true },
				center = center_pos,
				offset = vector(1, 0, 0),
				oneline = 'fw_stage_6_dokkaebi_oneline_8',
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	end
end

function local_class:fire_rager_load(quest_progress)
	local center_pos = field_util.get_marker_pos('fire_rager_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--신틸라 (right, attack, cast) : 뭣?! 용염광전사가 사실 최약체였다고?!
			fire_harpy = {
				spec = 'fw_fire_harpy',
				dir = 'right',
				emo = { name = 'attack' },
				anim = { name = 'cast', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_fire_rager_oneline_1',
				talksfx = '03_dialogue_negative_01'
			},
			--얼음 광전사 (left, idle, idle) : 그 녀석은 우리 중 최약체에 불과하지.
			rager_1 = {
				spec = 'fw_golem_ice',
				dir = 'left',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(2, 0, 0),
				oneline = 'fw_stage_6_fire_rager_oneline_2',
				scale = 0.8,
			},
			--암용 광전사 (left, idle, idle) : 용염 광전사, 최대체력이 1에 불과한 범부여…
			rager_2 = {
				spec = 'fw_golem_shadow_spirit',
				--spec = 'fw_golem_ice',
				dir = 'left',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(3.5, 0, 0.5),
				oneline = 'fw_stage_6_fire_rager_oneline_3',
				scale = 0.8,
			},
			--바위 광전사 (left, idle, idle) : 그놈 하나 이겼다고 자만하지 마라, 물근육.
			rager_3 = {
				spec = 'fw_golem_sand',
				dir = 'left',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(5, 0, 0),
				oneline = 'fw_stage_6_fire_rager_oneline_4',
				scale = 0.8,
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	else
		local npc_data = {
			--신틸라 (right, damaged, frustration 마지막 프레임 유지) : 난 패배자야…
			fire_harpy = {
				spec = 'fw_fire_harpy',
				dir = 'right',
				emo = { name = 'damaged' },
				anim = { name = 'frustration', loop = false },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_fire_rager_oneline_5',
				talksfx = '03_dialogue_sadness_01'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	end
end

function local_class:mine_craft_load(quest_progress)
	local center_pos = field_util.get_marker_pos('mine_craft_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--스팅 (right, smile, cross_arm) :강탈하기... 아니, 집 짓기 딱 좋은 마을이군!
			mine_steve = {
				spec = 'fw_mine_sting',
				dir = 'right',
				emo = { name = 'smile' },
				anim = { name = 'cross_arm', loop = true },
				center = center_pos,
				offset = vector(-1, 0, 3),
				oneline = 'fw_stage_6_mine_craft_oneline_1',
				talksfx = '01_rustle_01'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	end
end

function local_class:vampire_idol_load(quest_progress)
	local center_pos = field_util.get_marker_pos('vampire_idol_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--세실 (down, sing, sing2) : 나를… 기억해 줘…….
			vampire_idol = {
				spec = 'fw_vampireidol',
				dir = 'down',
				emo = { name = 'sing' },
				anim = { name = 'sing2', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_vampire_idol_oneline_1',
			},
			petal_1 = {
				spec = 'fw_petal',
				dir = 'down',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(-2, 0, -1),
				active_state = active_state_type.visible,
			},
			petal_2 = {
				spec = 'fw_petal',
				dir = 'down',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(0, 0, -1),
				active_state = active_state_type.visible,
			},
			petal_3 = {
				spec = 'fw_petal',
				dir = 'down',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(2, 0, -1),
				active_state = active_state_type.visible,
			},
			petal_4 = {
				spec = 'fw_petal',
				dir = 'down',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(-1, 0, -2),
				active_state = active_state_type.visible,
			},
			petal_5 = {
				spec = 'fw_petal',
				dir = 'down',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(1, 0, -2),
				active_state = active_state_type.visible,
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)
	else
		local npc_data = {
			--세실 (down, tired, sing2)
			vampire_idol = {
				spec = 'fw_vampireidol',
				dir = 'down',
				emo = { name = 'tired' },
				anim = { name = 'sing2', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	end
end

function local_class:wyvern_load(quest_progress)
	local center_pos = field_util.get_marker_pos('wyvern_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--아이샤 (down, doyagao, question 정지) : 명령 불복종에 대한 벌이다….
			steam_princess = {
				spec = 'fw_steam_princess',
				dir = 'down',
				emo = { name = 'doyagao' },
				anim = { name = 'question', loop = false },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_wyvern_oneline_1',
			},
			--드래곤 인형 샤피라 (right, blush, cast) : 황녀님… 이 옷은 이제 그만 입고 있으면 안될까요…?
			steam_knight_dragon_doll = {
				spec = 'fw_steam_knight_dragon_doll',
				dir = 'right',
				emo = { name = 'blush' },
				anim = { name = 'cast', loop = true },
				center = center_pos,
				offset = vector(0, 0, -1),
				oneline = 'fw_stage_6_wyvern_oneline_2',
				talksfx = '03_dialogue_tipsy_01'
			},
			--검은 폭포 (left, tired, prostrate) / 인터랙트 불가
			wyvern_fafnir = {
				spec = 'fw_wyvern_fafnir',
				dir = 'down',
				emo = { name = 'tired' },
				anim = { name = 'prostrate', loop = true },
				center = center_pos,
				offset = vector(1, 0, -1),
			},
			--노란 와이번 (right, smile, happy) / 인터랙트 불가
			wyvern_yellow = {
				spec = 'fw_wyvern_yellow',
				dir = 'right',
				emo = { name = 'smile' },
				anim = { name = 'happy', loop = true },
				center = center_pos,
				offset = vector(0, 0, -2),
			},

			--스파인명 fw_wyvern_purple
			--보라 와이번 (left, smile, happy) / 인터랙트 불가
			wyvern_purple = {
				spec = 'fw_wyvern_purple',
				dir = 'left',
				emo = { name = 'smile' },
				anim = { name = 'happy', loop = true },
				center = center_pos,
				offset = vector(1, 0, -2),
			},

			--스파인명 fw_wyvern_red
			--붉은 와이번 (up, idle, happy) / 인터랙트 불가
			wyvern_red = {
				spec = 'fw_wyvern_red',
				dir = 'up',
				emo = { name = 'idle' },
				anim = { name = 'happy', loop = true },
				center = center_pos,
				offset = vector(0.5, 0, -3),
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	else
		local npc_data = {
			--아이샤 (right, sleep_deep, idle) : 애초에 어려운 일이었으니, 상심하지마라.
			steam_princess = {
				spec = 'fw_steam_princess',
				dir = 'right',
				emo = { name = 'sleep_deep' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_wyvern_oneline_3',
				talksfx = '01_rustle_01'
			},
			--샤피라 (left, damaged, frustration 정지) : 제가 조금만 더 노력했다면….
			steam_knight = {
				spec = 'fw_steam_knight',
				dir = 'left',
				emo = { name = 'damaged' },
				anim = { name = 'frustration', loop = false },
				center = center_pos,
				offset = vector(1, 0, 0),
				oneline = 'fw_stage_6_wyvern_oneline_4',
				talksfx = '03_dialogue_sadness_01'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	end
end

function local_class:tamagotchi_load(quest_progress)
	local center_pos = field_util.get_marker_pos('tamagotchi_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--하피1(right, tired, cast) : 이 말이 순식간에 목적지까지 데려다준다던데… 나도 이 말 타고 출퇴근 시간 줄이고 싶다…
			harpy_1 = {
				spec = 'fw_nm_fh_male',
				dir = 'right',
				emo = { name = 'tired' },
				anim = { name = 'cast', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_tamagotchi_oneline_1',
			},
			--하피2(right, smile, idle) : 출퇴근 시간을 줄이고 싶다고? 그냥 출근을 안하면 출퇴근 시간이 아예 없어지잖아! 나 좀 똑똑한데?
			harpy_2 = {
				spec = 'fw_nm_fh_female',
				dir = 'right',
				emo = { name = 'smile' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(0, 0, -1),
				oneline = 'fw_stage_6_tamagotchi_oneline_2',
				talksfx = '03_dialogue_positive_01'
			},
			--불타는말(left, idle, bite)
			harpy_3 = {
				spec = 'fw_egg_horse',
				dir = 'left',
				emo = { name = 'idle' },
				anim = { name = 'happy', loop = true },
				center = center_pos,
				offset = vector(1, 0, -0.5),
			},
			--원라인 4번 (마그마)
			--스파인명 fw_egg_magma
			--마그마(right, attack, idle) 상태로 우측 방향으로 FX_Flamethrower_loop 지속
			harpy_4 = {
				spec = 'fw_egg_magma',
				dir = 'right',
				emo = { name = 'attack' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(5, 0, -5),
			},
			--원라인 5번 (하피(여))
			--스파인명 fw_nm_fh_female
			--하피2(left, tired, idle) : 테라피 효과 있는거 확실한거지?
			harpy_5 = {
				spec = 'fw_nm_fh_female',
				dir = 'left',
				emo = { name = 'tired' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(8, 0, -5),
				oneline = 'fw_stage_6_tamagotchi_oneline_4',
			},
			--원라인 6번 (하피(여))
			--스파인명 fw_nm_fh_female
			--하피2(left, attack, idle) : 믿어봐. 이 불 쬔 사람들 전부 기미에 주름까지 다 없어졌 데.
			harpy_6 = {
				spec = 'fw_nm_fh_female',
				dir = 'left',
				emo = { name = 'attack' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(9, 0, -5),
				oneline = 'fw_stage_6_tamagotchi_oneline_5',
			},
			--미노타우러스(right, idle, idle)
			harpy_7 = {
				spec = 'fw_egg_minotaur',
				dir = 'right',
				emo = { name = 'idle' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(7, 0, -0.5),
			},
			--인간1(left, love, sing) : 머, 멋져…! 이 근육, 내 이상형이야…!
			harpy_8 = {
				spec = 'fw_nm_human_female',
				dir = 'left',
				emo = { name = 'love' },
				anim = { name = 'sing', loop = true },
				center = center_pos,
				offset = vector(10, 0, 0),
				oneline = 'fw_stage_6_tamagotchi_oneline_7',
				talksfx = '01_bad_fairy_01'
			},
			--인간2(left, attack, cast2) : 근육이 이상형이라고? 운동, 또 운동이다!
			harpy_9 = {
				spec = 'fw_nm_human_male',
				dir = 'left',
				emo = { name = 'attack' },
				anim = { name = 'cast2', loop = true },
				center = center_pos,
				offset = vector(10, 0, -1),
				oneline = 'fw_stage_6_tamagotchi_oneline_8',
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

		local loop_fx = self.fx.flamethrower_loop():Instantiate(center_pos + vector(5.2, 0.5, -5))

		loop_fx.transform.localRotation = unity_class.quaternion.Euler(vector(0, 90, 0))
		self.disposable_data:insert(loop_fx)
	else
		local npc_data = {
			--하피1(right, tired, cast) : 목적지까지 이동하는 시간이 너무 아까워.
			harpy_1 = {
				spec = 'fw_nm_fh_male',
				dir = 'right',
				emo = { name = 'tired' },
				anim = { name = 'cast', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_tamagotchi_oneline_9',
			},
			--하피2(right, tired, idle) : 엄청 빠른 말이 있다는 소문을 들었는데, 그 말 타고 이동하면 어디든지 순식간이래.
			harpy_2 = {
				spec = 'fw_nm_fh_female',
				dir = 'right',
				emo = { name = 'tired' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(0, 0, -1),
				oneline = 'fw_stage_6_tamagotchi_oneline_10',
			},
			--하피2(left, tired, idle) : 요즘 피부가 푸석푸석해졌어….
			harpy_3 = {
				spec = 'fw_nm_fh_female',
				dir = 'right',
				emo = { name = 'tired' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(6, 0, -5),
				oneline = 'fw_stage_6_tamagotchi_oneline_11',
			},
			--하피2(left, attack, idle) : 요즘 새로운 피부 관리 방법이 있다고 소문이 돌던데…
			harpy_4 = {
				spec = 'fw_nm_fh_female',
				dir = 'left',
				emo = { name = 'attack' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(7, 0, -5),
				oneline = 'fw_stage_6_tamagotchi_oneline_12',
			},
			--인간1(right, attack, staff_idle) : 내 이상형? 그건 알아서 뭐 하게.
			harpy_5 = {
				spec = 'fw_nm_human_female',
				dir = 'right',
				emo = { name = 'attack' },
				anim = { name = 'staff_idle', loop = true },
				center = center_pos,
				offset = vector(8, 0, 0),
				oneline = 'fw_stage_6_tamagotchi_oneline_13',
			},
			--인간2(left, blush, idle) : 저기… 너 이상형이 어떻게 돼…?
			harpy_6 = {
				spec = 'fw_nm_human_male',
				dir = 'left',
				emo = { name = 'blush' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(9, 0, 0),
				oneline = 'fw_stage_6_tamagotchi_oneline_14',
				talksfx = '03_dialogue_tipsy_01'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	end
end

function local_class:viking_load(quest_progress)
	local center_pos = field_util.get_marker_pos('viking_center_pos')

	if quest_progress ~= nil and quest_progress.IsComplete then
		local npc_data = {
			--네바 (greed 표정, twohand_run 자세) : 드래고오오온!!!!
			viking = {
				spec = 'fw_viking',
				dir = 'right',
				emo = { name = 'greed' },
				anim = { name = 'twohand_run', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_viking_oneline_1',
				talksfx = '01_gatcha_point_01'
			},
			--염룡 남자 (scared 표정, run 자세) : 히이익!!! 오, 오지마!!!
			viking_male_1 = {
				spec = 'fw_nm_fd_male',
				dir = 'right',
				emo = { name = 'scared' },
				anim = { name = 'run', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_viking_oneline_2',
				talksfx = '03_runaway_02'
			},
			--염룡 남자 (right, scared, idle) : 저, 저런 미친 인간은 처음 봐…!
			viking_male_2 = {
				spec = 'fw_nm_fd_male',
				dir = 'right',
				emo = { name = 'scared' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_viking_oneline_3',
				talksfx = '03_runaway_01'
			},
			--염룡 여자 (right, scared, idle) : 빨,빨리 신고해야하는거 아냐…?
			viking_female_1 = {
				spec = 'fw_nm_fd_female',
				dir = 'right',
				emo = { name = 'scared' },
				anim = { name = 'idle', loop = true },
				center = center_pos,
				offset = vector(0, 0, -1),
				oneline = 'fw_stage_6_viking_oneline_4',
				talksfx = '03_dialogue_negative_02'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

		local viking = self.dynamic_npc:get('viking')
		local viking_male_1 = self.dynamic_npc:get('viking_male_1')
		local track_wp = {
			center_pos + vector(2, 0, -2),
			center_pos + vector(5, 0, -2),
			center_pos + vector(5, 0, 1),
			center_pos + vector(2, 0, 1),
		}

		viking.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		viking_male_1.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		start_coroutine(function()
			self.viking_run:start_loop({ viking, viking_male_1 }, track_wp)
		end)
	else
		local npc_data = {
			--염룡 남자 (right, scared, cast) : 정말 봤다니까…! 막 드래곤 드래곤 거리면서 미친듯이 쫓아오는 인간을 봤다고…!
			viking_male_1 = {
				spec = 'fw_nm_fd_male',
				dir = 'right',
				emo = { name = 'scared' },
				anim = { name = 'cast', loop = true },
				center = center_pos,
				offset = vector(0, 0, 0),
				oneline = 'fw_stage_6_viking_oneline_5',
				talksfx = '03_runaway_01'
			},
			--염룡 여자 (left, tired, bomb_idle) : 그게 무슨… 악몽이라도 꾼거 아냐?
			viking_female_1 = {
				spec = 'fw_nm_fd_female',
				dir = 'left',
				emo = { name = 'tired' },
				anim = { name = 'bomb_idle', loop = true },
				center = center_pos,
				offset = vector(1, 0, 0),
				oneline = 'fw_stage_6_viking_oneline_6',
				talksfx = '03_dialogue_bad_01'
			},
		}

		self.dynamic_npc:load_npc_async(npc_data)

	end
end

--region boss gimmick phase

function local_class:visible_all_safe_stone()
	local tilemap = field.Tilemap

	local gimmick_layer = tilemap.transform:Find('gimmick_safe_stone')

	for i = 0, gimmick_layer.childCount - 1 do
		local fieldobject = gimmick_layer:GetChild(i):GetComponent(typeof(CS.Oak.FieldObject))

		field_object_util.set_active_state(fieldobject, active_state_type.visible)
	end
end

function local_class:visible_all_lava_fire_flow()
	local tilemap = field.Tilemap

	local gimmick_layer = tilemap.transform:Find('gimmick_lava')

	for i = 0, gimmick_layer.childCount - 1 do
		local fieldobject = gimmick_layer:GetChild(i):GetComponent(typeof(CS.Oak.FieldObject))

		if fieldobject.Name == '[gimmick]lava_fire_flow' then
			field_object_util.set_active_state(fieldobject, active_state_type.visible)
		end
	end
end

--endregion boss gimmick phase

return local_class
