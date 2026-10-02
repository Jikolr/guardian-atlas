local function create_data(quest_marker_key, quest_id, is_story, control_data)
  return {
    quest_marker_key = quest_marker_key,
    quest_id = quest_id,
    is_story = is_story,
    control_data = control_data
  }
end

-- 아무것도 없는 (타겟 없는) 데이터 생성
local function create_none_data()
  return {
    type = 'none',
    name = nil,
  }
end

local function create_fo_data(fo_name)
  return {
    type = 'fo',
    name = fo_name
  }
end

-- Field Marker 데이터 생성
local function create_marker_data(marker_name)
  return {
    type = 'marker',
    name = marker_name
  }
end

return {
  -- 세이라
  bridgestory_seira = {
    parent_meet_quest = create_data('parent_meet_quest', 60068, true, {
      main_field = create_none_data(),
    }),
    old_soldier_quest = create_data('old_soldier_quest', 60068, true, {
      main_field = create_none_data(),
    }),
    archivist_quest = create_data('archivist_quest', 60068, true, {
      main_field = create_none_data(),
    }),
  },

  -- 페퍼
  bridgestory_seira_pepper = {
    s2_1_food_box = create_data('s2_1_food_box', 60069, true, {
      main_field = create_none_data(),
      s2_1_food_box_zone = create_none_data(),
      s2_3_mushroom_cave_zone = create_none_data(),
      s2_4_main_zone = create_none_data(),

    }),
    s2_2 = create_data('s2_2_quest', 60069, true, {
      main_field = create_fo_data('s2_2_well_keeper'),
      s2_1_food_box_zone = create_none_data(),
      s2_3_mushroom_cave_zone = create_none_data(),
      s2_4_main_zone = create_none_data()
    }),
    s2_3 = create_data('s2_3_quest', 60069, true, {
      main_field = create_fo_data('s2_3_enter'),
      s2_1_food_box_zone = create_none_data(),
      s2_3_mushroom_cave_zone = create_marker_data('s2_3_mushroom'),
      s2_4_main_zone = create_none_data()
    }),
    s2_4_lava = create_data('s2_4_lava', 60069, true, {
      main_field = create_none_data(),
      s2_1_food_box_zone = create_none_data(),
      s2_3_mushroom_cave_zone = create_none_data(),
      s2_4_main_zone = create_none_data()
    })
  },

}
