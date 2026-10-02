local local_class = newclass("SnowMountain1At5Controller")

function local_class:init(cs_controller, _)
    self.cs_controller = cs_controller

    -- 눈공의 원래 비주얼 스케일
    self.snowball_visual_scale = nil

    -- 눈공의 원래 히트박스
    self.snowball_original_hitbox = nil

    -- 눈공 위치
    self.snowball_1_original_pos = nil
    self.snowball_2_original_pos = nil
    self.snowball_3_original_pos = nil

    -- 눈공 이름
    self.snowball_1_name = "catapult_snowball"
    self.snowball_2_name = "snowball_2"
    self.snowball_3_name = "snowball_3"

    -- 눈공 리셋할 스위치 이름
    self.snowball_reset_switch_1_name = "snowball_1_reset_switch"
    self.snowball_reset_switch_2_name = "snowball_2_reset_switch"

    -- 리셋 이펙트 프리셋
    self.reset_effect = "FX_reset_object"
end

function local_class:load_resource()
    return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
    message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')

    unity_object_pool.GetOrCreate(self.reset_effect)

    -- 두 눈덩이 크기가 같으니 비주얼 스케일과 히트박스는 1개만 계산해서 저장해 둔다.
    local snowball_1 = get_field_object(self.snowball_1_name)

    self.snowball_visual_scale = snowball_1.Transform.localScale
    self.snowball_original_hitbox = snowball_1.Hitbox
    self.snowball_1_original_pos = snowball_1.Position

    local snowball_2 = get_field_object(self.snowball_2_name)

    self.snowball_2_original_pos = snowball_2.Position

    local snowball_3 = get_field_object(self.snowball_3_name)

    self.snowball_3_original_pos = snowball_3.Position

    return
end

function local_class:dispose()
    message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

    self.snowball_visual_scale = nil
    self.snowball_original_hitbox = nil

    self.snowball_1_original_pos = nil
    self.snowball_2_original_pos = nil

    self.cs_controller = nil
end

-- 입장 연출 함수를 부를 필요가 있는지
function local_class:need_on_launch()
    local snow_mountain_main_quest_id = 92

    local main_quest = user_progress:GetStartedQuest(snow_mountain_main_quest_id)
    return main_quest ~= nil and not main_quest.IsComplete and (main_quest.InnerProgress ~= 1)
end

function local_class:on_launch(_)
    coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

-- 스테이지 시작시에 입장 연출을 위해 불리는 함수
function local_class:on_launch_routine()
    -- 메세지만 보냄, 실제 진입 처리는 main quest 에서 한다.
    message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
    local event_type = e:GetType()

    if event_type == typeof(CS.Oak.InteractEvent) then
        local otaku = get_character(self.otaku_name)
        if lua_helper.reference_equals(e.Target, otaku) then
            sp_util.play_normal_screenplay(self.talk_otaku, self)
            return true
        end
    end

    if event_type == typeof(CS.Oak.SwitchOnOffEvent) then
        if not e.IsTurningOn then
            return false
        end

        if lua_helper.reference_equals(e.SwitchObject, get_field_object(self.snowball_reset_switch_1_name)) then
            self:reset_snowball(self.snowball_1_name)
        elseif lua_helper.reference_equals(e.SwitchObject, get_field_object(self.snowball_reset_switch_2_name)) then
            self:reset_snowball(self.snowball_2_name)
            self:reset_snowball(self.snowball_3_name)
        end
    end

    return false
end

function local_class:reset_snowball(snowball_name)
    local snowball = get_field_object(snowball_name)

    --이미 기믹을 사용해서 눈덩이가 Disabled 됐다면 Reset하지 않는다.
    if snowball.ActiveState == CS.Oak.ActiveState.Disabled then
        return
    end

    unity_object_pool.GetOrCreate(self.reset_effect):Instantiate(snowball.Position)

    snowball.Transform.localScale = self.snowball_visual_scale
    snowball.Hitbox = self.snowball_original_hitbox

    if snowball_name == self.snowball_1_name then
        snowball.Position = self.snowball_1_original_pos
    elseif snowball_name == self.snowball_2_name then
        snowball.Position = self.snowball_2_original_pos
    else
        snowball.Position = self.snowball_3_original_pos
    end

    unity_object_pool.GetOrCreate(self.reset_effect):Instantiate(snowball.Position)
end

return {
    create = function(cs_controller, scene)
        return local_class(cs_controller, scene);
    end
}
