local local_class = newclass('MemorialSquirrelGirlController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	self.main_quest_id = 7200101

	self.quest_progress = nil

	self.stage_event = setmetatable({
		event_controllers = nil,
		quest_progress = nil,
		event_list = {
			--스테이지 진행도를 사용하지 않을 경우 : clear_value = -2
			{
				key = 'mayreel',
				path = 'stageeventcontrollers/Memorial/SquirrelGirl/Mayreel.lua',
				clear_value = 2,
			},
			{
				key = 'teatan_trap',
				path = 'stageeventcontrollers/Memorial/SquirrelGirl/SelfTrap.lua',
				clear_value = 1,
			},
			{
				key = 'mouse_costume',
				path = 'stageeventcontrollers/Memorial/SquirrelGirl/MouseCostume.lua',
				--4섹션 귀속
				clear_value = -2
			},
			{
				key = 'judgment',
				path = 'stageeventcontrollers/Memorial/SquirrelGirl/Judgment.lua',
				--4섹션 귀속
				clear_value = -2
			},
			{
				key = 'gas_room',
				path = 'stageeventcontrollers/Memorial/SquirrelGirl/GasRoom.lua',
				clear_value = 1,
			},
		},
	}, {
		__index = {
			init_event = function(this, quest_progress)
				if this.event_controllers == nil then
					this.event_controllers = {}
				end

				this.quest_progress = quest_progress

				for num, info in ipairs(this.event_list) do
					local custom_state = quest_util.get_custom_state(quest_progress, info.key)

					--진행도 판단
					if custom_state < info.clear_value or info.clear_value == -2 then
						local is_create, controller = global_table_util.try_create(info.path)

						if is_create then
							controller:init_controller(self, info.key)
							table.insert(this.event_controllers, controller)
						end
					end
				end
			end,

			clear_event = function(this, key, value)
				if CS.Oak.QuestReplaySystem.IsReplaying then
					return
				end

				quest_util.set_custom_state(this.quest_progress, key, value)

				local fail_count = 0
				local save_success = false

				local on_success = function(_)
					save_success = true
				end

				-- 저장 성공할 때까지 요청
				while true do
					save_success = false

					local r = CS.Oak.NetworkManager.ApiConnection:SendProgressQuest(stage.StageId,
							this.quest_progress.QuestId, this.quest_progress.InnerProgress, nil)
					r:Then(on_success)

					coroutine.yield(r:SuppressDefaultErrorHandler())
					coroutine.yield(nil)

					if not save_success then
						fail_count = fail_count + 1
						CS.UnityEngine.Debug.LogError('SquirrelGirl Stage Event Save Failed : SendProgressQuest Retry')
						wait_for_sec(5.0 + fail_count)
					else
						break
					end
				end
			end,

			dispose_event = function(this)
				for i = 1, #this.event_controllers do
					this.event_controllers[i] = nil
				end

				this.quest_progress = nil
				this.event_controllers = nil
			end
		}
	})

	-- 로프에 매달린 npc
	self.rope_npc = setmetatable({
		rope_state = nil,
		npc_name = 'rope_civilian',
	}, {
		__index = {
			set_rope_npc_async = function(this)
				local npc = get_character(this.npc_name)
				this.rope_state = CS.Oak.CharacterRopeTrappedState(npc,
						character_util.get_direction('left'), npc.Position)
				message_system:SendSync(npc, CS.Oak.StateChangeEvent.Create(this.rope_state))

				-- CharacterRopeTrappedState 전환 시 표정이 surprise 로 변경됨
				coroutine.yield()
				coroutine.yield()

				scene_util.set_emotion(npc, self, 'tired')
				npc.Interactable.Talk = 'mm_squirrel_girl_s2_32_7'
			end,
			exit_rope_npc = function(this)
				if this.rope_state ~= nil then
					this.rope_state:Fall()
					this.rope_state:End()
					this.rope_state = nil
				end
			end
		}
	})
end

function local_class:dispose()
	self.stage_event:dispose_event()
	self.rope_npc:exit_rope_npc()

	self.quest_progress = nil
	self.cs_controller = nil
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate('rope_trap')
end

function local_class:on_event(e)
	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:setting_door()
	self:setting_steampunk_npc()
	self:set_twins_quest()
	self.rope_npc:set_rope_npc_async()
	self.stage_event:init_event(self.quest_progress)

	stage_start_util.start_function(self.quest_progress)
end

--- 쌍둥이 퀘스트 체크
function local_class:set_twins_quest()
	local demon_twins_quest_id = 64
	local demon_twins_quest = user_progress:GetStartedQuest(demon_twins_quest_id)

	if demon_twins_quest ~= nil and demon_twins_quest.IsComplete then
		field_object_util.set_active_state(get_character('memorial_sg_demon_brother_2'), active_state_type.enabled)
		field_object_util.set_active_state(get_character('memorial_sg_demon_sister_2'), active_state_type.enabled)
	else
		field_object_util.set_active_state(get_character('memorial_sg_demon_brother_2'), active_state_type.disabled)
		field_object_util.set_active_state(get_character('memorial_sg_demon_sister_2'), active_state_type.disabled)
	end
end

function local_class:setting_steampunk_npc()
	--벽돌 곡괭이 npc setting

	local npcs = {
		get_character('s5_steampunk_female_1'),
		get_character('s5_steampunk_male_1'),
		get_character('s5_steampunk_male_2'),
	}

	local dir_data = {
		'right',
		'right',
		'up',
	}

	local emo_data = {
		'tired',
		'mad',
		'tired',
	}
	local talk_data = {
		--난민 1 (right, tired, twohand_attack) : 이게 무슨 어트랙션이야….
		'mm_squirrel_girl_s5_oneline_1',
		--난민 3 (right, mad, twohand_attack) : 누가 돈 주고 수용소 체험을 해?!
		'mm_squirrel_girl_s5_oneline_2',
		--난민 4 (up, tired, twohand_attack) : 이 어트랙션 재미없어….
		'mm_squirrel_girl_s5_oneline_4',
	}

	for i = 1, #npcs do
		local npc = npcs[i]
		local marker_pos = field_util.get_marker_pos('s5_steampunk_pos_' .. i)
		local fo = get_field_object('s5_rock_' .. i)

		field_object_util.set_active_state(npc, active_state_type.enabled)
		character_util.set_position(npc, marker_pos)
		scene_util.set_direction(npc, dir_data[i], false)
		scene_util.set_emotion(npc, self, emo_data[i])
		scene_util.set_anim(npc, self, { name = 'twohand_attack', sfx_callback = function()
			field_object_util.shake(fo, 0.05, 0.2)
		end })
		character_util.spine_set_attachment(npc, '[base]weapon1', 'pickaxe_bronze_sword')

		npc.Interactable = CS.Oak.NPCInteractable.Create()
		npc.Interactable.Talk = talk_data[i]
	end
end

function local_class:setting_door()
	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= 2 then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('s2_door', true))
	end
end

return local_class
