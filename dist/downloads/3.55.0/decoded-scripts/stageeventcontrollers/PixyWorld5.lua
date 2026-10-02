local local_class = newclass('PixyWorld5Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 412

	self.marker = {
		before_race_run_pos = function()
			return field_util.get_marker_pos('default_start')
		end,
		pixy_race_pos = function(idx)
			return field_util.get_marker_pos('s16_race_pivot_' .. idx)
		end,

		elder_pos = function()
			return field_util.get_marker_pos('s16_race_pivot_2')
		end,

		after_race_pixy_run_pos = function(idx)
			return field_util.get_marker_pos('s17_pixy_run_pivot_' .. idx)
		end,

		doodle_jump_pos = function(idx)
			return field_util.get_marker_pos('s17_doodle_jump_pivot_' .. idx)
		end,

		beast_pos = function()
			return field_util.get_marker_pos('s18_beast_pivot')
		end,

		trophy_pos = function()
			return field_util.get_marker_pos('s19_trophy_pos')
		end,

		prostrate_pos = function()
			return field_util.get_marker_pos('s19_npc_pos_1')
		end,
		magic_circle_pos = function(idx)
			local marker_pos = lua_helper.get_conditional_value(idx == 1,
					field_util.get_marker_pos('s19_magic_circle_pos_2'),
					field_util.get_marker_pos('s19_magic_circle_pos_3'))
			return marker_pos
		end
	}

	self.object = {
		magic_circle = function(idx)
			return get_field_object('magic_circle_' .. idx)
		end
	}

	self.fx = {
		magic_circle = function()
			return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')
		end,

		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}

	self.magic_circle_fx_list = {}
	self.magic_circle_num = 2
	self.is_magic_circle_activated = false

	self.bomb_fail_zone = {
		fail_zone = 'bomb_fail_zone',
	}

	self.zone_name = {
		magic_circle = function(idx)
			local zone_name = lua_helper.get_conditional_value(idx == 1,
					'magic_circle_zone_2',
					'magic_circle_zone_3')
			return zone_name
		end
	}

	self.stage_ended = false

	self.zone_enter_available = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	for i = 1, #self.magic_circle_fx_list do
		if self.magic_circle_fx_list[i] ~= nil then
			self.magic_circle_fx_list[i]:Dispose()
			self.magic_circle_fx_list[i] = nil
		end
	end

	self.stage_ended = true

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	self.fx:load_all()

end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if not self.zone_enter_available then
		return false
	end

	local target = e.FieldObject

	if e.FullEnter and e.Zone.Name == self.bomb_fail_zone.fail_zone and
			lua_helper.type_compare(target.FieldObjectBehaviour, CS.Oak.BarrelFieldObjectBehaviour) then
		start_coroutine(self.bomb_fail_routine, self, target)

		return true
	end

	if not self.is_magic_circle_activated then
		return false
	end
	for idx = 1, self.magic_circle_num do
		if e.FullEnter and
				e.Zone.Name == self.zone_name.magic_circle(idx) then
			sp_util.start_scene(self.interact_magic_circle, self, idx)
			return true
		end
	end

	return false
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- npc 세팅
	if quest_progress ~= nil and not quest_progress.IsComplete then
		self:set_npc_by_inner_progress(quest_progress.InnerProgress)
	end

	-- 마법진 세팅
	if quest_progress ~= nil and
			quest_progress.InnerProgress >= 19 or
			quest_progress.IsComplete then
		self:set_magic_circle()
	end


	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 15 then
		stage_launch_util.play_launch_stage('left',
				field_util.get_marker_pos('default_start'), false, false)
	elseif quest_progress.InnerProgress == 16 then
		stage_launch_util.play_launch_stage('right',
				field_util.get_marker_pos('s16_race_pivot_1'), true, true)
	elseif quest_progress.InnerProgress == 17 then
		stage_launch_util.play_launch_stage('left',
				field_util.get_marker_pos('s17_doodle_jump_pivot_2'), true, true)
	elseif quest_progress.InnerProgress == 18 then
		stage_launch_util.play_launch_stage('left',
				field_util.get_marker_pos('s17_doodle_jump_pivot_2'), true, true)
	else
		stage_launch_util.play_launch_stage('left',
				field_util.get_marker_pos('default_start'), true, true)
	end

	self.zone_enter_available = true
end

function local_class:set_npc_by_inner_progress(inner_progress)
	if inner_progress == nil then
		return
	elseif inner_progress == 15 then
		self:set_npc_by_tag_list({
			'before_race_others',
			--'before_race_runner',
		})
	elseif inner_progress == 16 then
		self:set_npc_by_tag_list({
			'after_race_others',
			'after_race_runner',
			'after_race_bully',
			'before_doodle_jump',
		})
	elseif inner_progress == 17 then
		self:set_npc_by_tag_list({
			'after_race_others',
			'after_race_bully',
			'after_doodle_jump',
		})
	elseif inner_progress == 18 then
		self:set_npc_by_tag_list({
			'after_race_others',
			'after_doodle_jump',
			'pixy_traitor_trophy',
			'prostrate_npc',
		})
	else
		return
	end
end

function local_class:set_npc_by_tag_list(tag_list)
	local race_pos = self.marker.pixy_race_pos(1)
	local elder_pos = self.marker.pixy_race_pos(2)
	local before_race_run_pos = self.marker.before_race_run_pos()
	local after_race_run_pos = self.marker.after_race_pixy_run_pos(1)
	local beast_pos = self.marker.beast_pos()
	local doodle_jump_pos_1 = self.marker.doodle_jump_pos(1)
	local doodle_jump_pos_2 = self.marker.doodle_jump_pos(2)
	local trophy_pos = self.marker.trophy_pos()
	local prostrate_pos = self.marker.prostrate_pos()

	local tag_info_list = {
		before_race_others = {
			--알베리히 (left, idle, question)
			pixy_traitor = {
				direction = 'left',
				emotion = 'idle',
				anim = 'question',
				pos = race_pos + vector(-5.5, 0, 1)
			},
			--부하1 (left, smile ,idle)
			--스파인 : 픽시 (남) 스파인
			pixy_follower_1 = {
				direction = 'left',
				emotion = 'smile',
				anim = 'idle',
				pos = race_pos + vector(-4.5, 0, 1.5)
			},
			--부하2 (left, smile, idle)
			--스파인 : 픽시 (여) 스파인
			pixy_follower_2 = {
				direction = 'left',
				emotion = 'smile',
				anim = 'idle',
				pos = race_pos + vector(-4.5, 0, 0.5)
			},
			--픽시 남1 (right, smile, idle)
			pixy_male_10 = {
				direction = 'right',
				emotion = 'smile',
				anim = 'idle',
				pos = race_pos + vector(-1.5, 0, 1.5)
			},
			--픽시 남2 (left, idle, idle)
			pixy_male_11 = {
				direction = 'left',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(-0.5, 0, 1.5)
			},
			--픽시 남3 (down, smile, idle)
			pixy_male_12 = {
				direction = 'down',
				emotion = 'smile',
				anim = 'idle',
				pos = race_pos + vector(3.5, 0, 1.5)
			},
			--픽시 남4 (right, idle, release)
			pixy_male_13 = {
				direction = 'right',
				emotion = 'idle',
				anim = 'release',
				pos = race_pos + vector(5.5, 0, 1.5)
			},
			--픽시 남5 (left, idle, idle)
			pixy_male_14 = {
				direction = 'left',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(6.5, 0, 1.5)
			},
			--픽시 남6 (right, smile, idle)
			pixy_male_15 = {
				direction = 'right',
				emotion = 'smile',
				anim = 'idle',
				pos = race_pos + vector(5.5, 0, -1)
			},
			--픽시 남7 (right, idle, idle)
			pixy_male_16 = {
				direction = 'right',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(-5.5, 0, 3.5)
			},
			--픽시 남8 (down, idle, idle)
			pixy_male_17 = {
				direction = 'down',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(-4.5, 0, 6.5)
			},
			--픽시 남9 (up, idle, idle)
			pixy_male_18 = {
				direction = 'up',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(5.5, 0, 5.5)
			},
			--픽시 여1 (right, idle, question)
			pixy_female_10 = {
				direction = 'right',
				emotion = 'idle',
				anim = 'question',
				pos = race_pos + vector(-3.5, 0, -1)
			},
			--픽시 여2 (left, smile, release)
			pixy_female_11 = {
				direction = 'left',
				emotion = 'smile',
				anim = 'release',
				pos = race_pos + vector(-2.5, 0, -1)
			},
			--픽시 여3 (up, idle, idle)
			pixy_female_12 = {
				direction = 'up',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(3.5, 0, 0.5)
			},
			--픽시 여4 (left, smile, cast2)
			pixy_female_13 = {
				direction = 'left',
				emotion = 'smile',
				anim = 'cast2',
				pos = race_pos + vector(6.5, 0, -1)
			},
			--픽시 여5 (right, idle, cross_arm)
			pixy_female_14 = {
				direction = 'right',
				emotion = 'idle',
				anim = 'cross_arm',
				pos = race_pos + vector(5.5, 0, 3.5)
			},
			--픽시 여6 (left, idle, idle)
			pixy_female_15 = {
				direction = 'left',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(6.5, 0, 3.5)
			},
			--픽시 여7 (left, idle, cast)
			pixy_female_16 = {
				direction = 'left',
				emotion = 'idle',
				anim = 'cast',
				pos = race_pos + vector(-4.5, 0, 3.5)
			},
			--픽시 여8 (up, idle, idle)
			pixy_female_17 = {
				direction = 'up',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(-4.5, 0, 5.5)
			},
			--픽시 여9 (down, idle, idle)
			pixy_female_18 = {
				direction = 'down',
				emotion = 'idle',
				anim = 'idle',
				pos = race_pos + vector(5.5, 0, 6.5)
			},
			--촌장 (down, idle, idle)
			pixy_elder_scene = {
				direction = 'down',
				anim = 'idle',
				emotion = 'idle',
				pos = elder_pos + vector(0, -1, 4.5)
			},
		},
		before_race_runner = {
			pixy_runner_1 = {
				direction = 'left',
				emotion = 'attack',
				anim = 'run',
				pos = before_race_run_pos + vector(4.5, 0, 1),
				alpha = 0,
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			pixy_runner_2 = {
				direction = 'left',
				emotion = 'attack',
				anim = 'run',
				pos = before_race_run_pos + vector(4.5, 0, -2),
				alpha = 0,
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},
		},
		after_race_runner = {
			--픽시 남1 (up, idle, run)
			pixy_runner_1 = {
				direction = 'up',
				emotion = 'idle',
				anim = 'run',
				pos = after_race_run_pos + vector(-1.5, 0, 0),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			--픽시 남2 (up, idle, run)
			pixy_male_9 = {
				direction = 'up',
				emotion = 'idle',
				anim = 'run',
				pos = after_race_run_pos + vector(0.5, 0, 2.5),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			--픽시 여1 (up, idle, run)
			pixy_runner_2 = {
				direction = 'up',
				emotion = 'idle',
				anim = 'run',
				pos = after_race_run_pos + vector(1.5, 0, 0.5),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			--픽시 여2 (up, idle, run)
			pixy_female_9 = {
				direction = 'up',
				emotion = 'idle',
				anim = 'run',
				pos = after_race_run_pos + vector(-1, 0, 2),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},
		},
		after_race_bully = {
			--부하1 (left, attack, attack 지속)
			pixy_follower_1 = {
				direction = 'left',
				emotion = 'attack',
				anim = nil,
				pos = beast_pos + vector(-6.5, 0, 0.5),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			--부하2 (left, attack, attack 지속)
			pixy_follower_2 = {
				direction = 'left',
				emotion = 'attack',
				anim = nil,
				pos = beast_pos + vector(-7, 0, -1),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},
			--맹수
			s18_beast = {
				direction = 'down',
				emotion = 'idle',
				anim = 'idle',
				pos = beast_pos + vector(-4, 0, 7),
			}
		},
		after_race_others = {
			--촌장 설정
			pixy_elder = {
				direction = 'down',
				emotion = 'idle',
				anim = 'idle',
				pos = elder_pos,
				oneline = 'pw_main_s16_oneline_1'
			},

			pixy_elder_scene = {
				direction = 'down',
				anim = 'idle',
				emotion = 'idle',
				pos = elder_pos + vector(999, 0, 999)
			},

			--region 두들 점프 연출 npc 설정

			--최초 NPC는 다음과 같이 배치.

			--픽시 남1 (right, scared, cast)
			pixy_male_1 = {
				direction = 'right',
				emotion = 'scared',
				anim = 'cast',
				pos = doodle_jump_pos_1 + vector(-3.5, 0, -0.5),
			},

			--픽시 남2 (left, tired, idle)
			pixy_male_2 = {
				direction = 'left',
				emotion = 'tired',
				anim = 'idle',
				pos = doodle_jump_pos_1 + vector(2.5, 0, 0.5),
			},

			--픽시 남3 (right, confused, prostrate)
			pixy_male_3 = {
				direction = 'right',
				emotion = 'confused',
				anim = 'prostrate',
				pos = doodle_jump_pos_1 + vector(-4.5, 0, 1.5),
			},

			--픽시 남4 (left, confused, prostrate)
			pixy_male_4 = {
				direction = 'left',
				emotion = 'confused',
				anim = 'prostrate',
				pos = doodle_jump_pos_1 + vector(4.5, 0, 1.5),
			},

			--픽시 여2 (left, scared, cast)
			pixy_female_2 = {
				direction = 'left',
				emotion = 'scared',
				anim = 'cast',
				pos = doodle_jump_pos_1 + vector(-2.5, 0, -0.5),
			},

			--픽시 여3 (left, confused, prostrate)
			pixy_female_3 = {
				direction = 'left',
				emotion = 'confused',
				anim = 'prostrate',
				pos = doodle_jump_pos_1 + vector(5.5, 0, -1.5),
			},

			--endregion 두들 점프 연출 npc 설정

			--region 두들 점프 이후 원라인 npc 설정

			--픽시 남1 (right, confused, prostrate) : 마력을 너무 많이 소모해서 몸이 안 움직여…
			pixy_male_5 = {
				direction = 'right',
				emotion = 'confused',
				anim = 'prostrate',
				pos = doodle_jump_pos_2 + vector(-3.5, 0, 4),
				oneline = 'pw_main_s17_oneline_1',
			},

			--픽시 여1 (left, confused, prostrate) : 고유 스킬을 너무 많이 썼나…
			pixy_female_4 = {
				direction = 'left',
				emotion = 'confused',
				anim = 'prostrate',
				pos = doodle_jump_pos_2 + vector(4.5, 0, 5),
				oneline = 'pw_main_s17_oneline_2',
			},

			--픽시 여2 (left, confused, prostrate) : 힘, 힘들어… 더는 못가…
			pixy_female_5 = {
				direction = 'left',
				emotion = 'confused',
				anim = 'prostrate',
				pos = doodle_jump_pos_2 + vector(2.5, 0, 2.5),
				oneline = 'pw_main_s17_oneline_3',
			},

			--endregion 두들 점프 이후 원라인 npc 설정

			--region 괴롭힘 관련 NPC
			--남1 (left, hurt, prostrate)
			pixy_male_6 = {
				direction = 'left',
				emotion = 'hurt',
				anim = 'prostrate',
				pos = beast_pos + vector(-2, 0, -1.5),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			--남2 (right, hurt, prostrate)
			pixy_male_7 = {
				direction = 'right',
				emotion = 'hurt',
				anim = 'prostrate',
				pos = beast_pos + vector(-7.5, 0, 0.5),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			--남3 (right, hurt, prostrate)
			pixy_male_8 = {
				direction = 'right',
				emotion = 'hurt',
				anim = 'prostrate',
				pos = beast_pos + vector(-8, 0, -1),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			--여1 (right, hurt, prostrate)
			pixy_female_6 = {
				direction = 'right',
				emotion = 'hurt',
				anim = 'prostrate',
				pos = beast_pos + vector(-9, 0, 1.5),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},

			--여2 (left, hurt, prostrate)
			pixy_female_7 = {
				direction = 'left',
				emotion = 'hurt',
				anim = 'prostrate',
				pos = beast_pos + vector(-4, 0, -2.5),
				crash_behaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
			},
			--endregion 괴롭힘 관련 NPC
		},
		before_doodle_jump = {
			--픽시 여1 (left, confused, prostrate)
			pixy_female_1 = {
				direction = 'left',
				emotion = 'confused',
				anim = 'prostrate',
				pos = doodle_jump_pos_1 + vector(0, 0, 5),
			},
		},
		after_doodle_jump = {
			--픽시 여1 (left, confused, prostrate)
			pixy_female_1 = {
				direction = 'left',
				emotion = 'confused',
				anim = 'prostrate',
				pos = doodle_jump_pos_1,
			},
		},
		pixy_traitor_trophy = {
			-- 최초 알베리히 NPC가 (down, idle, question) 자세로 배치되어 있음.
			pixy_traitor = {
				direction = 'down',
				emotion = 'idle',
				anim = 'question',
				pos = trophy_pos + vector(0, -1, 5),
			}

		},
		--region 지쳐서 포기한 인원들
		prostrate_npc = {
			s19_pixy_1 = {
				direction = 'right',
				emotion = 'tired',
				anim = 'seat',
				pos = prostrate_pos + vector(-3, -1, 2),
				oneline = 'pw_main_s19_oneline_1',
			},
			s19_pixy_2 = {
				direction = 'left',
				emotion = 'tired',
				anim = 'prostrate',
				pos = prostrate_pos + vector(3.5, -1, 1.5),
				oneline = 'pw_main_s19_oneline_2',
			},
			s19_pixy_3 = {
				direction = 'right',
				emotion = 'tired',
				anim = 'sleep',
				pos = prostrate_pos + vector(-2.5, -1, -2),
				oneline = 'pw_main_s19_oneline_3',
			},
			s19_pixy_4 = {
				direction = 'right',
				emotion = 'tired',
				anim = 'seat',
				pos = prostrate_pos + vector(2.5, -1, -2.5),
				oneline = 'pw_main_s19_oneline_4',
			},
		}

	}
	for i = 1, #tag_list do
		local tag = tag_list[i]
		self:set_npc_by_list(tag_info_list[tag])
	end

end

function local_class:set_npc_by_list(npc_info_list)
	for name, info_list in pairs(npc_info_list) do
		local npc = nil
		local pos = info_list.pos
		local direction = info_list.direction
		local anim = info_list.anim
		local emotion = info_list.emotion
		local hide_weapon = info_list.hide_weapon
		local oneline = info_list.oneline
		local alpha = info_list.alpha
		local crash_behaviour = info_list.crash_behaviour

		if name == 'china_hero' then
			npc = user_util.get_china_hero_character('china_hero_boy', 'china_hero_girl')
		elseif name == 'knight' then
			npc = user_util.get_knight_character('knight_female', 'knight_male')
		else
			npc = get_character(name)
		end

		field_object_util.set_active_state(npc, active_state_type.enabled)

		if pos ~= nil then
			character_util.set_position(npc, pos)
		end

		if direction ~= nil then
			character_util.set_direction(npc, direction)
		end

		if anim ~= nil then
			if type_util.is_table(anim) then
				scene_util.set_anim(npc, self, anim)
			else
				scene_util.set_anim(npc, self, { name = anim, sfx_name = false, one_shot_sfx = false })
			end
		end

		if emotion ~= nil then
			scene_util.set_emotion(npc, self, emotion)
		end

		if hide_weapon ~= nil then
			character_util.hide_weapon(npc, hide_weapon)
		end

		if oneline ~= nil then
			if oneline == 'nil' then
				npc.Interactable.Talk = nil
			else
				npc.Interactable.Talk = oneline
			end
		end

		if alpha ~= nil then
			character_util.spine_set_alpha_fade_v2(npc, alpha, 0)
		end

		if crash_behaviour ~= nil then
			npc.CrashBehaviour = crash_behaviour
		end
	end
end

function local_class:bomb_fail_routine(bomb)
	message_system:SendSync(bomb, CS.Oak.GetThrownEndEvent.Instance)

	local origin_size = bomb.Transform.localScale
	local target_size = unity_class.vector3.zero
	local origin_pos = bomb.Position
	local move_pos = bomb.Position + vector(0, -4, -2)

	local time_passed = 0
	local duration = 0.7

	coroutine_util.while_each_frame(duration, function(progress)
		local cur_size = unity_class.vector3.Lerp(origin_size, target_size, progress)
		local cur_pos = unity_class.vector3.Lerp(origin_pos, move_pos, progress)

		bomb.Transform.localScale = cur_size
		bomb.Position = cur_pos

		return not self.stage_ended
	end)

	local fail_line = field_util.get_marker_pos('bomb_fail_line')
	local fail_pos = field_util.get_marker_pos('bomb_fail_pos')

	bomb.Position = fail_line.x < bomb.Position.x and vector(900, 0, 999) or fail_pos
	bomb.Transform.localScale = origin_size

	message_system:SendSync(bomb.FieldObjectBehaviour, CS.Oak.BombProvokeEvent.Create(bomb, CS.Oak.BombProvokeType.Fire))

	coroutine_util.while_each_frame(1, function(progress)
		return not self.stage_ended
	end)

	camera_util.shake(0.1, 1)
end

function local_class:set_magic_circle()
	for i = 1, self.magic_circle_num do
		local magic_circle = self.object.magic_circle(i)
		local magic_circle_pos = self.marker.magic_circle_pos(i)

		magic_circle.Position = magic_circle_pos
		--magic_circle.Interactable = CS.Oak.PublishInteractable.Create()

		local magic_circle_fx = self.fx.magic_circle():Instantiate(magic_circle_pos)
		table.insert(self.magic_circle_fx_list, magic_circle_fx)

	end

	self.is_magic_circle_activated = true
end

function local_class:interact_magic_circle(magic_circle_idx)
	local leader = get_party_leader()

	local other_idx = lua_helper.get_conditional_value(magic_circle_idx == 1, 2, 1)
	local direction = lua_helper.get_conditional_value(magic_circle_idx == 1, 'down', 'down')

	local end_pos = self.marker.magic_circle_pos(other_idx) + vector(0, 0, -2)

	music_player_util.play_sfx_one_shot('02_cast_magic_02')
	screen_util.fade_out_async(0.6, unity_class.color.white, 'linear')

	camera_util.move_async(end_pos, 0)
	leader.Position = end_pos

	character_util.set_direction(leader, direction)
	character_util.remove_anim_and_emotion(leader)

	wait_for_sec(0.5)

	screen_util.fade_in_async(1, unity_class.color.white, 'linear')
	camera_util.return_to_leader(0)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
