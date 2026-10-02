local local_class = newclass("MovieCostumePlayerController")

function local_class:init(cs_controller)
    self.cs_controller = cs_controller

    -- 코스플레이어 NPC
    self.costume_player_1 = nil
    self.costume_player_2 = nil

    -- 코스플레이어와 사진 찍었는지 저장
    self.take_picture_with_costume_player = false

    -- 기타 상수
    self.tip_price = 1

    -- NPC 이름
    self.costume_player_1_name = 'costume_player_1'
    self.costume_player_2_name = 'costume_player_2'

    -- 존 이름
    self.costume_player_zone_name = "costume_player"

    -- 커스텀 스테이트 이름
    self.custom_state = {
        -- 코스플레이어와 사진 찍기 이벤트를 끝냈는지
        see_costume_player_event = 0
    }
end

function local_class:load_resource()
    local cosplayer_1 = get_character(self.costume_player_1_name)
    local cosplayer_2 = get_character(self.costume_player_2_name)

    if not stage_progress:GetCustomData(self.custom_state.see_costume_player_event) then
        message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')

        character_util.set_position(cosplayer_1, vector(37.5, 0, -1.5))
        character_util.set_direction(cosplayer_1, "left")

        character_util.set_position(cosplayer_2, vector(36.5, 0, -1.5))
        character_util.set_direction(cosplayer_2, "right")
    end
end

function local_class:need_on_launch()
    return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
    message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

    self.cs_controller = nil
end

function local_class:on_event(e)
    if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
        self:on_zone_enter_event(e)
    end

    return false
end

function local_class:on_zone_enter_event(e)
    if e.FullEnter and e.FieldObject == user_party_leader then
        if e.Zone.Name == self.costume_player_zone_name then
            if not self.take_picture_with_costume_player then
                self.take_picture_with_costume_player = true
                sp_util.play_normal_screenplay(self.costume_player_event, self)
            end
        end
    end
end

-- 코스플레이어가 돈 갈취하는 이벤트
function local_class:costume_player_event()
    local cosplayer_1 = get_character(self.costume_player_1_name)
    local cosplayer_2 = get_character(self.costume_player_2_name)
    local position = user_party_leader.Position

    -- 플레이어에 접근
    wait_all({
        util.cs_generator(character_util.move_waypoint_async, cosplayer_1, position + 2.5 * unity_class.vector3.left, 4, false, nil, nil, 'right'),
        util.cs_generator(character_util.move_waypoint_async, cosplayer_2, position + 2.5 * unity_class.vector3.right, 4, false, nil, nil, 'left'),
        util.cs_generator(self.position_party_arc, self, position, 'up', 1, 'right')
    })

    -- 플레이어 좌우에 왼쪽 오른쪽 각각 보고이씅(플레이어 보는중)
    party_util.set_direction('down')
    character_util.set_direction(cosplayer_1, 'right')
    character_util.set_emotion(cosplayer_1, {key = 'greed'})

    character_util.set_direction(cosplayer_2, 'left')
    character_util.set_emotion(cosplayer_2, {key = 'greed'})

    --포즈 잡기
    character_util.set_direction(cosplayer_1, 'down')
    character_util.set_direction(cosplayer_2, 'down')
    character_util.set_anim(cosplayer_1, {name = 'get', loop = false})
    character_util.set_anim(cosplayer_2, {name = 'get', loop = false})

    wait_for_sec(0.5)
    -- 치즈~
    speech_bubble_util.show_speech_bubble(cosplayer_2, {key = 'movie_1_1_costume_player_0', skip = true})
    speech_bubble_util.show_speech_bubble_async(cosplayer_1, {key = 'movie_1_1_costume_player_0', skip = true})
    -- 일단 강제로 찍음(fade in white로 하면 될 듯)
    music_player:PlaySfxOneShot('01_shutter_01')
    screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

    character_util.remove_anim(cosplayer_1)
    character_util.remove_anim(cosplayer_2)
    character_util.remove_emotion(cosplayer_1)
    character_util.remove_emotion(cosplayer_2)

    -- 플레시 이후
    wait_for_sec (0.2)
    -- 감사합니다~
    music_player:PlaySfxOneShot('03_dialogue_positive_01')
    speech_bubble_util.show_speech_bubble(cosplayer_1, {key = 'movie_1_1_costume_player_1', skip = true})
    speech_bubble_util.show_speech_bubble_async(cosplayer_2, {key = 'movie_1_1_costume_player_1', skip = true})

    character_util.remove_anim(cosplayer_1)
    character_util.remove_anim(cosplayer_2)
    -- 플레이어 바라보기
    music_player:PlaySfxOneShot('01_swing_01')
    character_util.set_direction(cosplayer_1, "right")
    character_util.set_direction(cosplayer_2, "left")

    --플레이어 두리번거리기
    character_util.set_direction(user_party_leader, "right")
    wait_for_sec(1)
    character_util.set_direction(user_party_leader, "left" )
    character_util.set_anim(cosplayer_1, { name = 'sing',loop = true})
    character_util.set_anim(cosplayer_2, { name = 'cast',loop = true})
    --팁을 주세요~
    character_util.set_direction(user_party_leader, "right" )
    speech_bubble_util.show_speech_bubble_async(cosplayer_2, {key = 'movie_1_1_costume_player_2', skip = true})
    wait_for_sec(0.5)
    character_util.remove_anim(cosplayer_1)
    character_util.remove_anim(cosplayer_2)

    -- 팁을 준다 / 안준다 (선택지)
    local result_1 = choose_util.play_choose_event({{'movie_1_1_costume_player_3'}, {'movie_1_1_costume_player_4'}})

    if result_1 == 1 then
        yield_return_func(self.robber_money, self)
    else
        ----팁 없어?? 그럼 사진을 지우던가!
        music_player:PlaySfxOneShot('03_dialogue_negative_02')
        character_util.set_direction(user_party_leader, "left" )
        speech_bubble_util.show_speech_bubble_async(cosplayer_1, {key = 'movie_1_1_costume_player_5', skip = true})

        while true do
            -- 팁을 준다 / 안준다 (선택지)
            local result_2 = choose_util.play_choose_event({{'movie_1_1_costume_player_3'}, {'movie_1_1_costume_player_4'}})

            if result_2 == 2 then
                -- 지금 그냥 가려고 하는겁니까?
                character_util.set_direction(user_party_leader, "left" )
                character_util.set_anim(cosplayer_1, {name = 'release', sfx_name = '01_swing_01', loop = true})
                character_util.set_direction(user_party_leader, "left" )
                speech_bubble_util.show_speech_bubble_async(cosplayer_1, {key = 'movie_1_1_costume_player_6', skip = true})
                character_util.remove_anim(cosplayer_1)
            else
                yield_return_func(self.robber_money, self)
                break
            end
        end
    end
end

function local_class:robber_money()
    local cosplayer_1 = get_character(self.costume_player_1_name)
    local cosplayer_2 = get_character(self.costume_player_2_name)

    local money = user.Gold -- 플레이어 잔고 확인

    if money < self.tip_price then
        -- 뭐야 이거 완전 거지 잖아?
        speech_bubble_util.show_speech_bubble_async(cosplayer_1, {key = 'movie_1_1_costume_player_7', skip = true})

        -- 에이 더러워서~ 그냥 보내준다.
        speech_bubble_util.show_speech_bubble_async(cosplayer_2, {key = 'movie_1_1_costume_player_8', skip = true})

    else
        -- 플레이어 돈 1원 지출
        local stage_custom = stage_progress:SetCustomData(self.custom_state.see_costume_player_event, true)
        coroutine.yield(CS.Oak.StageApiRouter.SendPayGold(stage.StageId, self.tip_price, stage_custom))

        music_player:PlaySfxOneShot('03_drop_gold_01')
        character_util.set_direction(user_party_leader, "left")
        local coin = drop_item_util.create_item({pos = user_party_leader.Position, skip_text = true,
                                                 target = cosplayer_1.Position + vector(0.5, 0, 0), sprscale = 0.5,
                                                 itemid = 20021, notforinven = true, lootstate = 'dontfindlooter'})

        coin.ConsumeTarget = cosplayer_1
        character_util.set_direction(cosplayer_2, "left")
        wait_for_sec(1)

        character_util.set_emotion(user_party_leader, { name = "tired"})
        -- 고마워~~~~~~

        music_player:PlaySfxOneShot('03_dialogue_positive_01')
        character_util.set_emotion(cosplayer_1, {name = 'awesome'})
        speech_bubble_util.show_speech_bubble_async(cosplayer_1, {key = 'movie_1_1_costume_player_9', skip = true})
        -- 역시~
        character_util.set_emotion(cosplayer_2, {name = 'awesome'})
        speech_bubble_util.show_speech_bubble_async(cosplayer_2, {key = 'movie_1_1_costume_player_10', skip = true})
        character_util.remove_emotion(user_party_leader)


        wp_util.move_way_points(cosplayer_1, {waypoints = vector(-100, 0, 0), speed = 6,
                                              last_direction = CS.Oak.Direction.Down})
        wp_util.move_way_points(cosplayer_2, {waypoints = vector(-100, 0, 0), speed = 6,
                                              last_direction = CS.Oak.Direction.Down})

        wait_for_sec (3)
        character_util.remove_emotion(cosplayer_1)
        character_util.remove_emotion(cosplayer_2)
    end
end

-- party align 하는데 필요한 position 을 계산하는 함수.
function local_class:calculate_party_member_align_position_arc(align_pos, align_direction, party_index)
    local party_member_count = user_party.Count

    if party_member_count == 2 then
        return align_pos + CS.Oak.DirectionExtensions.ToVector3(align_direction) * party_index * CS.Oak.Constants.DistBetweenPartyMembers
    elseif party_member_count == 3 then
        if party_index == 1 then
            return align_pos + unity_class.quaternion.AngleAxis(-45, unity_class.vector3.up) * CS.Oak.DirectionExtensions.ToVector3(align_direction) * CS.Oak.Constants.DistBetweenPartyMembers
        elseif party_index == 2 then
            return align_pos + unity_class.quaternion.AngleAxis(45, unity_class.vector3.up) * CS.Oak.DirectionExtensions.ToVector3(align_direction) * CS.Oak.Constants.DistBetweenPartyMembers
        end
    elseif party_member_count == 4 then
        if party_index == 1 then
            return align_pos + unity_class.quaternion.AngleAxis(-60, unity_class.vector3.up) * CS.Oak.DirectionExtensions.ToVector3(align_direction) * CS.Oak.Constants.DistBetweenPartyMembers
        elseif party_index == 2 then
            return align_pos + CS.Oak.DirectionExtensions.ToVector3(align_direction) * CS.Oak.Constants.DistBetweenPartyMembers
        elseif party_index == 3 then
            return align_pos + unity_class.quaternion.AngleAxis(60, unity_class.vector3.up) * CS.Oak.DirectionExtensions.ToVector3(align_direction) * CS.Oak.Constants.DistBetweenPartyMembers
        end
    end

    return align_pos
end

-- party align 함수. last_direction이 필요해서 새로 만듦.
function local_class:position_party_arc(position, dir, duration, last_direction)
    dir = type_util.is_string(dir) and character_util.get_direction(dir) or dir
    duration = lua_helper.get_or_default(duration, 1)

    local min_speed = 1
    local coroutine_list = {}

    for i = 0, user_party.Count - 1 do
        local target_pos = self:calculate_party_member_align_position_arc(position, dir, i)
        local diff = target_pos - user_party[i].Position
        local dist = diff.magnitude

        local speed = dist / duration
        if speed <= min_speed then
            speed = min_speed
        end

        table.insert(coroutine_list, util.cs_generator(character_util.move_waypoint_async, user_party[i], target_pos, speed, false, nil, nil, last_direction))
    end

    wait_all(coroutine_list)
end


return {
    create = function(cs_controller, scene)
        return local_class(cs_controller, scene);
    end
}
