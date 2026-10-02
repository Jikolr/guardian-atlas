local local_class = newclass("FutureCastlePartB1At6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.stage_name = 'futurecastle_part2_1_6'

	self.count= 0

	-- 미래 공주
	self.future_princess = nil

	-- 베스
	self.beth = nil

	-- 드래곤
	self.dragon = nil

	-- 영웅 리스트
	self.hero_list = {}

	-- 기타 상수
	self.start_pos = vector(0.5, 0, 34.5)

	-- 커스텀 스테이트 키
	self.stage6_event = 'stage6_event'

	-- 이벤트 상태값
	self.stage6_event_state = {
		-- 5스테이지 첫 진입
		none = 0,
		-- 미래공주와 대화 이벤트
		talk_princess = 1,
		-- 베스 보스전 인트로 이벤트
		talk_beth = 2,
		-- 드래곤 보스전 인트로 이벤트
		talk_dragon = 3,
		-- 엔딩 분기
		last_scene = 4
	}

	-- 현재 이벤트 상태
	self.current_state = self.stage6_event_state.none

	self.coco_quest = 0

	--region 공주 / 리더 루프 움직임 전용
	self.is_late_updating = false

	self.loop_start_z = -22
	self.loop_end_z = -10
	self.is_stop = false
	self.is_follow = true

	self.princess_walk_anim = nil

	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == self.stage_name then
		quest_util.load_pool_resource(
			-- 'stage_item'
		)
	end
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	local main_quest_id = 195
	local q = user_progress:GetStartedQuest(main_quest_id)
	self.current_state = quest_util.get_custom_state(q, self.stage6_event)

	-- 공주 파티 합류 및 파티원 전원 날리기
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self, q.InnerProgress, q.IsComplete))
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.princess = nil

	self.cs_controller = nil
end

function local_class:on_stage_loaded_event(e)
	self.princess = get_character('princess')
	self.princess_walk_anim = CS.Oak.CharacterExtensions.GetCustomWalkAnimation(self.princess)

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'section18' then
		if e:GetParamAt(1) == 'loop_start' then
			self.is_late_updating = true
			return true

		elseif e:GetParamAt(1) == 'walk_start' then
			self.is_stop = false
			return true

		elseif e:GetParamAt(1) == 'loop_stop' then
			self.is_late_updating = false
			return true

		elseif e:GetParamAt(1) == 'walk_stop' then
			self.is_stop = true
			return true
		end
	end

	return false
end

function local_class:on_event(e)
	return false
end

--주인공 혼자 들어오도록 하는 함수
function local_class:opening_routine(innerprogress, IsComplete)
	local princess = get_character('princess')
	character_util.remove_anim_and_emotion(princess)

	if innerprogress == 16 and not IsComplete then
	elseif innerprogress == 17 and not IsComplete then
	elseif innerprogress == 18 and not IsComplete then
	elseif innerprogress == 19 and not IsComplete then
	elseif IsComplete then
	else
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(self.start_pos,
				CS.Oak.Direction.Right, game_string:GetString(stage.Name)))

	end

end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.is_late_updating == false then
		return
	end

	-- 무한루프 걷기
	-- is_stop 이면 일단 멈춤. 걷기 애니메이션은 연출 멈추고 시작할때 끄고 키는것으로.
	if self.is_stop == false then
		if user_party_leader.Position.z > self.loop_end_z then
			local diff_1 = user_party_leader.Position.z - self.loop_end_z
			local diff_2 = self.princess.Position.z - self.loop_end_z

			self.princess.Position = vector_util.get_xy0(self.princess.Position, self.loop_start_z + diff_2)
			user_party_leader.Position = vector_util.get_xy0(user_party_leader.Position, self.loop_start_z + diff_1)
			if self.rock_effect ~= nil then
				self.rock_effect.transform.localPosition = self.rock_effect.transform.localPosition
						- vector(0, 0, self.loop_end_z - self.loop_start_z)
			end
		elseif user_party_leader.Position.z < self.loop_start_z then
			--[[
			local diff_1 = user_party_leader.Position.z - self.loop_start_z
			local diff_2 = self.princess.Position.z - self.loop_start_z

			user_party_leader.Position = vector_util.get_xy0(user_party_leader.Position, self.loop_end_z + diff_1)
			self.princess.Position = vector_util.get_xy0(self.princess.Position, self.loop_end_z + diff_2)
			if self.rock_effect ~= nil then
				self.rock_effect.transform.localPosition = self.rock_effect.transform.localPosition
						+ vector(0, 0, self.loop_end_z - self.loop_start_z)
			end
			]]
		end
	end

	if user_party_leader.Position.z - self.princess.Position.z > 0 then
		--character_util.set_anim(self.princess, { name = self.princess_walk_anim})
		self.is_follow = true
	end

	if self.is_follow == true then
		character_util.set_anim(self.princess, { name = self.princess_walk_anim})
		if user_party_leader.Position.z - self.princess.Position.z > 0.3 then
			self.princess.Position = vector_util.get_xy0(self.princess.Position, self.princess.Position.z + (unity_class.time.deltaTime * 4))
		elseif user_party_leader.Position.z - self.princess.Position.z + 1 > (unity_class.time.deltaTime * 2.5) then
			self.princess.Position = vector_util.get_xy0(self.princess.Position, self.princess.Position.z + (unity_class.time.deltaTime * 2.5))
		else
			self.princess.Position = vector_util.get_xy0(self.princess.Position, user_party_leader.Position.z + 1)
			self.is_follow = false
			character_util.remove_anim(self.princess)
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
