local local_class = newclass("DesignerTestController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

end

function local_class:load_resource()
	--CS.UnityEngine.Debug.LogError("Designer Test")
	local character = get_character("eg1")
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), "on_event")
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), "on_event")
	message_system:Subscribe(self, typeof(CS.Oak.StageControlStartEvent), 'on_event')
	character.Interactable:AddListener(self.cs_controller)
	entered_event_1 = false
    entered_event_2 = false
    entered_event_3 = false
    caught_robber = false
    unity_object_pool.GetOrCreate("FX_hit")
    unity_object_pool.GetOrCreate("FX_Common_SmokeScreen")
    --CS.UnityEngine.Debug.LogError("entered new tilemap")



	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
    local character = stage.GetCharacter("eg1")
    message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
    message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
    message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	self.cs_controller = nil
	entered_event_1 = nil
	entered_event_2 = nil
	entered_event_3 = nil
	character.Interactable:RemoveRelatedEvent(self.cs_controller)


end



function local_class:on_event(e)
    local event_type = e:GetType()
    if(event_type == typeof(CS.Oak.ZoneEnterEvent)) then  --3 zone events, npc_event_1-3
        self:zone_enter_event(e)
    elseif(event_type == typeof(CS.Oak.InteractEvent)) then -- robber_catch
        self:interact_event(e)
    elseif(event_type == typeof(CS.Oak.ZoneLeaveEvent))then -- out_of_bounds
        self:zone_leave_event(e)
    elseif(event_type == typeof(CS.Oak.StageControlStartEvent)) then -- check for starpiece
        		self.earned_npc_star_piece = stage_progress:HasStarPiece('npc_star_piece')
    end

	return false
end
function local_class:zone_enter_event(e)
    if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
    if not (e.FullEnter) then return end

    local name = e.Zone.Name
    if name == 'npc_event_1' then
        if not (entered_event_1) then
            coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.npc_event_1, self))
        end
    elseif(name == 'npc_event_2') then
         if not (entered_event_2) then
            coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.npc_event_2, self))
         end
    elseif(name == 'npc_event_3') then
        if not (entered_event_3) then
            coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.npc_event_3, self))
        end
    end
end
function local_class:zone_leave_event(e)
   if e.Zone.Name ~= "npc_event_3" then return end
   if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
   if not (e.FullLeave) then return end
   if (caught_robber) then return end

   coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.out_of_bounds, self))

end
function local_class:interact_event(e)
    local character = get_character("eg1")
    if lua_helper.reference_equals(e.Target, character) and not(caught_robber) then
        coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.robber_catch, self))
    end
end



function local_class:npc_event_1()
 --npc event 1 setup
    user_party:StopAndDisableControl()
    stage.FieldUIManager:Hide()
    entered_event_1 = true;
    local character = get_character("eg1")
    party_util.align_to_target(character.Position, 'left', 2, "linear")
    coroutine.yield(coroutine_class.wait_for_sec(1))

    --girl found in snow, shakes, leader pulls her out

    character_util.shake(character, 0.05, 1)
    character_util.set_anim(user_party_leader, {name = 'embarrassed', loop = true})
    character_util.set_emotion(user_party_leader, {name = 'surprise', loop = true})
    coroutine.yield(coroutine_class.wait_for_sec(0.5))
    character_util.set_anim(user_party_leader, {name = 'eat', loop = true})
    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_1", skip =  true })
    coroutine.yield(coroutine_class.wait_for_sec(1))
    character_util.remove_anim_and_emotion(character)
    character_util.remove_anim_and_emotion(user_party_leader)
    character_util.mario_jump_async(character, "down")
    coroutine.yield(coroutine_class.wait_for_sec(0.5))

    -- girl steals item from leader

    character_util.set_emotion(character, {name = 'smile', loop = true})
    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_2", skip =  true })
    character_util.set_emotion(user_party_leader, {name = 'love', loop = true})
    coroutine.yield(coroutine_class.wait_for_sec(1))
    character_util.set_emotion(character, {name = 'smile', loop = true})
    character_util.look_at(character, user_party_leader)

    --girl attacks leader

    camera_util.resize_to(2, 1)
    character_util.set_emotion(character, {name = 'greed', loop = false})
    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_3",bubble_type = 'shout', skip =  true })
    coroutine.yield(coroutine_class.wait_for_sec(0.5))
    character_util.set_anim(character, {name = 'attack', loop = true})
    unity_object_pool.GetOrCreate('FX_hit'):Instantiate(user_party_leader.Position)
    character_util.set_anim(user_party_leader, {name = 'prostrate', loop = true})
    character_util.set_emotion(user_party_leader, {name = 'hurt', loop = true})
    wait_for_sec(1)
    character_util.spine_damage_red_pulse(user_party_leader)
    character_util.spine_damage_squish_default(user_party_leader)

    --steals gold

    camera_util.resize_to_default(0.5)
    character_util.set_anim(character,{name = 'eat', loop = true})
    coroutine.yield(coroutine_class.wait_for_sec(1))
    local stolen_gold = drop_item_util.create_item({pos = user_party_leader.Position, target =
            	character.Position+vector(0,0,-1), itemid = 70001, notforinven = true, lootstate = "dontfindlooter"})
    stolen_gold.ConsumeTarget = character

    --run away

    character_util.remove_anim(character)
    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_4", skip =  true })
    unity_object_pool.GetOrCreate("FX_Common_SmokeScreen"):Instantiate(character.Position)


    --setup npc to npc_event_2

    character_util.remove_emotion(character)
    character_util.set_position(character, vector(-43,0, 36))

    --main character revive

    coroutine.yield(coroutine_class.wait_for_sec(1))
    character_util.shake(user_party_leader, 0.05, 2)
    coroutine.yield(coroutine_class.wait_for_sec(2))
    character_util.remove_anim_and_emotion(user_party_leader)
    character_util.mario_jump_async(user_party_leader, "down")
    character_util.set_emotion(user_party_leader, {name = 'confused', loop = true})
    coroutine.yield(coroutine_class.wait_for_sec(1.5))
    character_util.remove_emotion(user_party_leader)
    coroutine.yield(coroutine_class.wait_for_sec(0.5))

    --main character angry

    character_util.set_anim(user_party_leader, {name = 'jingak', loop = true})
    character_util.set_emotion(user_party_leader, {name = 'attack', loop = true})
    coroutine.yield(coroutine_class.wait_for_sec(3))
    character_util.remove_anim_and_emotion(user_party_leader)
    coroutine.yield(coroutine_class.wait_for_sec(1))


	user_party:ResetControllers()
	stage.FieldUIManager:Show()
end

function local_class:npc_event_2()
    --npc event 2 setup
    user_party:StopAndDisableControl()
    stage.FieldUIManager:Hide()
    entered_event_2 = true;
    local character = get_character("eg1")
    party_util.align_to_target(character.Position, 'left', 2, "linear")
    coroutine.yield(coroutine_class.wait_for_sec(1))

    -- girl taunts main character

    character_util.set_anim(user_party_leader, {name = 'jingak', loop = true})
    character_util.set_emotion(user_party_leader, {name = 'burning', loop = true})
    character_util.jump(character, 0.5, 0.5)
    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_5", skip =  true })
    character_util.move_to_async(character,character.Position + vector(2, 0,3), 0.5, nil, true)
    character_util.remove_anim_and_emotion(user_party_leader)

    -- main character chases girl

    for i = 1, 3 do
        character_util.set_direction(character, 'down')
        character_util.remove_anim(user_party_leader)
        speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_".. (i+5), skip =  true })
        character_util.move_to_async(character, character.Position + vector(-8,0,0), 0.5, nil, true)
        character_util.set_anim(user_party_leader, {name = 'attack', loop = true})
        character_util.move_to_async(user_party_leader, character.Position+vector(2,0,0), 0.5, nil, true)
        character_util.move_to_async(character,character.Position + vector(0,0,-7), 0.5, nil, true)
        character_util.move_to_async(user_party_leader, character.Position+vector(0,0,2), 0.5, nil, true)
        character_util.move_to_async(character,character.Position + vector(8,0,0), 0.5, nil, true)
        character_util.move_to_async(user_party_leader, character.Position+vector(-2,0,0), 0.5, nil, true)
        character_util.move_to_async(character,character.Position + vector(0,0,7), 0.5, nil, true)
        character_util.move_to_async(user_party_leader, character.Position+vector(0,0,-2), 0.5, nil, true)
    end

    --girl taunts leader again

    character_util.remove_anim(user_party_leader)
    character_util.set_emotion(character, {name = 'greed', loop = true})
    character_util.set_direction(character, 'down')
    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_9", skip =  true })
    character_util.move_to_async(character, character.Position + vector(-4,0,0), 0.25, nil, true)
    character_util.move_to_async(character, character.Position + vector(0,0,7), 1, nil, true)

    --reset npc to npc_event_3

    character_util.move_to(character, vector(-25,0, 72))
    character_util.set_direction(character, "left")
    coroutine.yield(coroutine_class.wait_for_sec(1))

    --leader is mad

    character_util.set_direction(user_party_leader, 'down')
    character_util.set_anim(user_party_leader, {name = 'jingak', loop = true})
    character_util.set_emotion(user_party_leader, {name = 'burning', loop = true})



    coroutine.yield(coroutine_class.wait_for_sec(1))
    character_util.remove_anim_and_emotion(character)
    character_util.remove_anim_and_emotion(user_party_leader)
   	user_party:ResetControllers()
   	stage.FieldUIManager:Show()
end

function local_class: npc_event_3()

    --npc_event_3 setup

    user_party:StopAndDisableControl()
    stage.FieldUIManager:Hide()
    entered_event_3 = true;
    local character = get_character("eg1")
    party_util.align_to_target(character.Position, 'left', 2, "linear")
    coroutine.yield(coroutine_class.wait_for_sec(1))

    --girl taunts leader again

    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_10", skip =  true })
    character_util.move_to_async(character, character.Position+vector(3,0,0), 1, nil, true)

    --chase game starts

    user_party:ResetControllers()
    stage.FieldUIManager:Show()

    speech_bubble_util.show_speech_bubble(character, {key = "practice_stage_6", skip =  true })
    while not(caught_robber) do
        if(math.random(1,30) == 2) then
             speech_bubble_util.show_speech_bubble(character, {key = "practice_stage_6", skip =  true })
        end
        character_util.move_to_async(character,vector((0-math.random(20,28)),0,(math.random(71,76))), nil, 7, true)
    end


end


function local_class: out_of_bounds(e)
    --out of bounds specifically for npc_event_3

    user_party:StopAndDisableControl()
    stage.FieldUIManager:Hide()

    character_util.set_anim(user_party_leader, {name = 'embarrassed', loop = true})
    character_util.set_emotion(user_party_leader, {name = 'surprise', loop = true})

    screen_util.fade_out_circular_async(0.75, 'ease_in_out_sine')

    party_util.align_to_target(vector(-25, 0, 73), 'left', 0, "linear")
    character_util.remove_anim_and_emotion(user_party_leader)

    screen_util.fade_in(0, unity_class.color.black, 'linear')
    screen_util.fade_in_circular(1, 'ease_in_out_sine')

    user_party:ResetControllers()
    stage.FieldUIManager:Show()

end

function local_class:robber_catch(e)
    -- begin last animation
    user_party:StopAndDisableControl()
    stage.FieldUIManager:Hide()
    caught_robber = true
    local character = get_character("eg1")
    character_util.stop(character)

    -- girl gets caught

    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_11", skip =  true })
    party_util.align_to_target(character.Position, 'left', 1, "linear")
    character_util.look_at(user_party_leader, character)
    character_util.look_at(character, user_party_leader)

    -- leader attacks girl

    CS.GlobalTimeManager.Instance:Mod(0.4, "main_character_attack")
    camera_util.resize_to(2, 1)
    character_util.set_emotion(user_party_leader, {name = 'attack', loop = true})
    character_util.move_to_async(user_party_leader, character.Position+vector(-1,0,0), 0.5, nil, true)
    character_util.look_at(user_party_leader, character)
    character_util.jump(user_party_leader, 1, 0.5)
    character_util.set_anim(user_party_leader, {name = 'attack', loop = false})
    character_util.set_anim(character, {name = 'prostrate', loop = false})
    character_util.set_emotion(character, {name = 'hurt', loop = true})
    character_util.spine_damage_red_pulse(character)
    character_util.spine_damage_squish_default(character)
    unity_object_pool.GetOrCreate('FX_hit'):Instantiate(character.Position)
    CS.GlobalTimeManager.Instance:Unmod("main_character_attack")
    camera_util.resize_to_default(1)

    -- leader collects stolen gold
    local stolen_gold = drop_item_util.create_item({pos = character.Position, target =
                	user_party_leader.Position + vector(0,0,-1), itemid = 70001, notforinven = true, lootstate = "dontfindlooter"})
        stolen_gold.ConsumeTarget = user_party_leader

    -- girl revives
    character_util.remove_emotion(character)
    character_util.mario_jump_async(character, "down")
    character_util.set_emotion(character, {name = 'confused', loop = true})
    coroutine.yield(coroutine_class.wait_for_sec(1.5))

    --girl walks away

    character_util.set_emotion(character, {name = 'mad', loop = true})
    speech_bubble_util.show_speech_bubble_async(character, {key = "practice_stage_12", skip =  true })
    character_util.remove_anim(user_party_leader)
    character_util.move_to_async(character, vector(character.Position.x,0,74), 0.5, nil, true)

    --girl drop starpiece

    if not (self.earned_npc_star_piece) then
        self.earned_npc_star_piece = true
        local star_piece = get_field_object('npc_star_piece')
    	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(character.Position))
    end

    -- girl continues to walk away

    character_util.move_to_async(character, character.Position+vector(-20, 0,0), 5, nil, true)
    character_util.move_to(character, vector(0,0,0))

    character_util.remove_anim_and_emotion(character)
    character_util.remove_anim_and_emotion(user_party_leader)



    user_party:ResetControllers()
    stage.FieldUIManager:Show()

end




return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
