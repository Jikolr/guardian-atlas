---@class FireWorld5Controller
local local_class = newclass('FireWorld5Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 478
	self.quest_progress = nil

	self.object = {
		mural = function(idx)
			return get_field_object('mural_' .. idx)
		end,
	}

	--region 벽화 관련

	--22섹션 관련 벽화 인터랙트 가능 여부 플래그
	self.can_interact_mural = true

	self.mural_name_list = {
		'first_mural',
		'second_mural',
		'third_mural',
		'fourth_mural',
		'fifth_mural',
		'sixth_mural',
		'seventh_mural',
	}
	---@class FireWorld5MuralBit
	self.mural_bit = {
		-- bitfield 구조: 각 mural은 2비트로 상태 저장 (예: 00 00 00 = 3개의 mural)
		-- 상태 코드:
		--   00 = 비활성화 (deactivate)
		--   01 = 벽화 획득 (acquire)
		--   10 = 벽화 활성화 (activate)
		--   11 = 미사용 (unused)
		bitfield = 0,

		--index의 벽화의 상태 반환
		---@param this self
		---@param index number
		get_state = function(this, index)
			local shift = (index - 1) * 2
			return (this.bitfield >> shift) & 3
		end,

		--index의 벽화 비활성화
		---@param this self
		---@param index number
		deactivate_mural = function(this, index)
			local shift = (index - 1) * 2

			-- 해당 index 위치의 2비트를 00으로 클리어하여
			-- mural 상태를 '비활성화'로 만든다.
			this.bitfield = this.bitfield & ~(3 << shift)
		end,

		--index의 벽화조각 획득
		---@param this self
		---@param index number
		acquire_mural = function(this, index)
			local shift = (index - 1) * 2

			-- 해당 index 위치의 2비트를 00으로 클리어한 뒤,
			-- 01(=1)을 설정하여 mural 상태를 '획득'으로 만든다.
			this.bitfield = (this.bitfield & ~(3 << shift)) | (1 << shift)
		end,

		--index의 벽화 활성화
		---@param this self
		---@param index number
		activate_mural = function(this, index)
			local shift = (index - 1) * 2

			-- 해당 index 위치의 2비트를 00으로 클리어한 뒤,
			-- 10(=2)을 설정하여 mural 상태를 '활성화'로 만든다.
			this.bitfield = (this.bitfield & ~(3 << shift)) | (2 << shift)
		end,
	}
	--endregion 벽화 관련
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

function local_class:load_resource()
	self.mural = get_or_create_global_table('Quest/Main/FireWorld/Common/MuralTheatreController')
	self.mural:load_async()
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	--22섹션에서는 어떤 벽화를 인터랙트 하던 전용 연출이 나와야 하므로
	if not self.can_interact_mural then
		return true
	end

	for idx = 1, #self.mural_name_list do
		local mural_interact = self.object.mural(idx)
		if type_util.is_interacted_target(e, mural_interact) then
			--짝수 번째 벽화(복원 필요한 벽화)가 복원 되었는지 체크. 홀수 번째는 통과.
			if idx % 2 == 1 or self.mural_bit:get_state(idx / 2) == 2 then
				sp_util.start_scene(self.show_mural_theatre_async, self, idx, true)

				return true
			end
		end
	end

	return false
end

function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	self:set_mural_bit(self.quest_progress)
	self:activate_mural_animation(self.quest_progress)

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= 23 then
		self:gate_open(1)
	end

	stage_start_util.start_function(self.quest_progress)
end

function local_class:set_mural_bit(quest_progress)
	if quest_progress ~= nil then
		--22섹션 이후에는 항상 활성화 하기 위함.
		if quest_progress.IsComplete or
				quest_progress.InnerProgress >= 21 then
			self.mural_bit:activate_mural(1)
			self.mural_bit:activate_mural(2)
			self.mural_bit:activate_mural(3)
		end
	end
end

function local_class:activate_mural_animation(quest_progress)
	if quest_progress ~= nil then
		--22섹션 이후에는 항상 활성화 하기 위함.
		if quest_progress.IsComplete or
				quest_progress.InnerProgress >= 21 then

			local murals = {
				self.object.mural(2),
				self.object.mural(4),
				self.object.mural(6),
			}

			for i = 1, #murals do
				local mural = murals[i]
				local animator = mural.Transform:GetComponent(typeof(CS.UnityEngine.Animator))
				animator:Play('[gimmick]wall_mural_sleb', 0, 1.0)
			end
		end
	end
end

function local_class:show_mural_theatre_async(index, show_dialogue, start_fade, end_fade, bubble_data)
	local mural_name = self.mural_name_list[index]
	music_player_util.play_sfx_one_shot('01_walk_03')
	self.mural:show_theatre_async(mural_name, show_dialogue, start_fade, end_fade, bubble_data)
end

function local_class:gate_open(normalized_time)
	local door = get_field_object('s23_gate_1')

	local animator = door:GetComponent(typeof(CS.UnityEngine.Animator))

	if is_unity_null(animator) then
		return
	end

	normalized_time = lua_helper.get_or_default(normalized_time, 0)
	animator:Play('open', -1, normalized_time)
	door.ActiveState = active_state_type.visible
end

return local_class
