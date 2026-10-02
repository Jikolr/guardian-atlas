local local_class = newclass('ExpeditionHiddenLeftAloneCandidate')

function local_class:init(cs_controller, _)
    self.cs_controller = cs_controller

    -- scene_util 버전. 버전 올라갈 때 + N 해서 사용
    self.scene_version = scene_util.default_version

    self.progress = {
        none = 1,
        playing = 2,
        done = 3
    }
    self.current_progress = self.progress.none

    -- 스테이지 클리어 여부
    self.is_stage_clear = false

    self.stage_id = 250014007

    self.zone_name = 'battle1'
    -- battle group 이름
    self.battle_group_name = 'battle1'
    -- 획득하는 기록물 id
    self.special_collectible_item_id = 4
    -- 보스 이름.
    self.boss_name = 'exp_left_alone_candidate'
    -- 보스 가져오기
    self.boss = get_character(self.boss_name)
end

function local_class:load_resource()
    message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
    return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

--region Event

function local_class:on_event(e)
    return false
end

function local_class:on_stage_loaded_event(e)
    local user_expedition = CS.Oak.UserExpedition.Me

    -- 스테이지 클리어 시에는 세팅 안함
    self.is_stage_clear = CS.Oak.UserExpeditionExtensions.IsExpeditionStageCleared(user_expedition, self.stage_id)
    if self.is_stage_clear then
        -- 클리어한 스테이지라면 보스 disabled 시켜둠
        character_util.set_active_state(self.boss, 'disabled')
        return false
    end

    message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

    self:set_hidden_event()
end

function local_class:on_zone_enter_event(e)
    if self.current_progress == self.progress.none and
            type_util.is_zone_full_enter(e, get_party_leader(), self.zone_name) then
        -- 플레이 상태로 전환
        self.current_progress = self.progress.playing
        sp_util.start_scene(self.pre_event, self)
        return true
    end
    return false
end


--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
    return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
    return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
    message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

    if not self.is_stage_clear then
        message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
    end

    self.cs_controller = nil
    self.scene = nil
end

function local_class:set_hidden_event()
    -- 몬스터 사용 처리
    character_util.set_active_state(self.boss, 'enabled')
    -- 시작시 처음엔 위를 바라보고 있음.
    character_util.set_locked_dir(self.boss, 'up')
end

function local_class:pre_event()
    -- 보스 세팅
    -- 파티원이 가까이 접근함
    party_util.align_party(vector(0.5, 0, 21), 'down', 3, 'arc')
    camera_util.move(vector(0.5, 0, 23), 1)
    -- 대기
    wait_for_sec(1.4)
    -- 처음에 뒤돌아보고 있는 상태에서 뒤로 돌아봄.
    character_util.set_locked_dir(self.boss, 'down')
    -- 대기
    wait_for_sec(1)
    -- 말풍선 출력 '.....'
    character_util.show_emoticon_async(self.boss, nil, 'silence')
    -- 대기
    wait_for_sec(1)

    -- 루틴 종료하고 전투 시작
    self.current_progress = self.progress.done
    camera_util.resize_to(self.boss.CharacterStatsBehaviour.CharacterSpec.BattleCamSize, 0.5)

    -- 카메라 다시 리더에게
    camera_util.return_to_leader(0.5)


    -- 몬스터로 변경
    character_util.convert_to_monster(self.boss, self.battle_group_name, self.zone_name)
    character_util.set_death_type(self.boss, 'bossexplosion')
    character_util.set_locked_dir(self.boss, 'none')
    command_util.execute_monster_notice(self.boss, get_party_leader(), 'battle')
end

return {
    create = function(cs_controller, scene)
        return local_class(cs_controller, scene);
    end
}
