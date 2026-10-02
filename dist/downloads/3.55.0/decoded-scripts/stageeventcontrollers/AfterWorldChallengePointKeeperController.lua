local local_class = newclass('AfterWorldChallengePointKeeperController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3,
		failed = 4
	}

	self.stage_battle_info = require('stageeventcontrollers/AfterWorldChallengePointKeeperData.lua')

	self.current_stage_info = nil
	self.current_progress = self.progress.none

	self.battle1_door_name = 'd_7'
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	-- 저승 외전 메인의 경우 메인 컨트롤러가 로드함
	CS.Oak.RollingNumberManager.Instance:PreLoad()

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	self.current_point = self.current_stage_info.start_point
	self.number_color = unity_color({ 0, 0.7, 1, 1 })
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	-- 리더 캐릭터 위에 점수 표시
	character_util.set_rolling_number(user_party.Leader.Transform, self.current_point, nil, 1, self.number_color)
	-- HP의 변화가 없도록 (자체 수치 사용)
	user_party.Leader.FieldObjectStatsBehaviour:AddCharacterStatsOption(CS.Oak.CharacterStatsOptions.Invincible)
	-- 대미지 넘버 연출도 하지 않도록
	user_party.Leader.DamagedBehaviour.ShowDamageNumber = false

	-- 나레이션 키 있으면 나레이션 연출
	if not string_helper.is_nil_or_empty(self.current_stage_info.narration) then
		sp_util.play_normal_screenplay(field_ui_util.show_narration_async, {key = self.current_stage_info.narration, stop_timer = true})
	end
end

function local_class:on_zone_enter_event(e)
	if self.current_progress == self.progress.none
			and lua_helper.reference_equals(e.FieldObject, user_party.Leader)
			and e.FullEnter
			and e.Zone.Name == self.current_stage_info.start_battle_zone then
		-- 첫번째 존 시작시 스테이지 이벤트 시작
		self.current_progress = self.progress.playing
		-- 첫번째 존 시작시 도어 닫기
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.battle1_door_name))
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if self.current_progress == self.progress.playing and e.BattleGroupName == self.current_stage_info.end_battle_group then
		-- 마지막 존만 섬멸해도 클리어 판정
		self.current_progress = self.progress.cleared
	end
end

function local_class:on_damage_event(e)
	if self.current_progress == self.progress.playing and lua_helper.reference_equals(e.Info.target, user_party.Leader) then
		-- 파티 리더가 피격시 현재 포인트를 차감한다.

		if e.Info.type & CS.Oak.DamageType.Trap == CS.Oak.DamageType.Trap then
			self.current_point = self.current_point + self.current_stage_info.hit_gimmick
		else
			self.current_point = self.current_point + self.current_stage_info.hit_monster
		end

		if self.current_point > 0 then
			-- 포인트 표시 갱신
			character_util.rolling_number(user_party.Leader.Transform, self.current_point, nil, 1, self.number_color)
		else
			-- 게임오버 처리
			self:game_over_proccess(true)
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_progress == self.progress.playing and not lua_helper.reference_equals(e.FieldObject, user_party.Leader)then
		local fo = e.FieldObject
		local earn_point = nil
		for _, node in ipairs(self.current_stage_info.earn_table) do
			if string_helper.start_with(fo.Name, node.header) then
				earn_point = node.value
				break
			end
		end

		if earn_point then
			self.current_point = math.min(self.current_point + earn_point, self.current_stage_info.max_point)
			-- 포인트 표시 갱신
			character_util.rolling_number(user_party.Leader.Transform, self.current_point, nil, 1, self.number_color)
		end
	end
end

function local_class:on_game_over_event(e)
	if self.current_progress == self.progress.playing then
		self:game_over_proccess()
	end
end
--endregion

function local_class:game_over_proccess(kill_leader)
	self.current_progress = self.progress.failed
	character_util.remove_rolling_number(user_party.Leader.Transform)

	if kill_leader then
		-- 리더 즉사 처리
		local damage_info = CS.Oak.DamageInfo()
		damage_info.sender = user_party.Leader
		damage_info.target = user_party.Leader
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		command_util.publish_cmd(damage_info.Owner, cmd)
	end
end

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

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))

	CS.Oak.RollingNumberManager.Instance:ReturnRollingNumberAll();

	self.current_stage_info = nil
	self.stage_battle_info = nil

	self.current_progress = nil
	self.progress = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
