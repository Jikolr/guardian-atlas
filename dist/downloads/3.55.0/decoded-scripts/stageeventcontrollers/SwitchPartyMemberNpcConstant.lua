return {
  --TODO: 네이밍 규칙: 챕터약어_캐릭터스팩네임_타입(중복될 경우) ex) qc_innuit_follow
  -- [311] = {  manual_knight = {}, china_hero = {} }  같이

  -- 기사
  manual_knight = {
    type = 'knight',
    name = { 'knight_female', 'knight_male' },
    is_immortal = false,
  },

  -- 페이, 메이
  china_hero = {
    type = 'china_hero',
    name = { 'pei', 'mei' },
    is_immortal = true,
  },

  -- 메뉴얼 꼬마 공주
  manual_princess = {
    name = { 'manual_princess' },
    is_immortal = false,
  },

  -- 파티원 꼬마 공주
  princess = {
    name = { 'princess' },
    is_immortal = true,
  },

  --region Short Story Rosetta

  -- 엘비라
  red_hood = {
    name = { 'red_hood' },
  },

  -- 승급 엘비라
  red_hood_battle_mode = {
    name = { 'red_hood_battle_mode' },
  },

  -- 로제타
  rosetta = {
    name = { 'rosetta' },
    is_immortal = true,
  },

  --endregion

  --region Short Story Dai

  -- dai
  dai = {
    name = { 'dai' },
  },

  -- popp
  popp = {
    name = { 'popp' },
    is_immortal = true,
  },

  -- maam
  maam = {
    name = { 'maam' },
    is_immortal = true,
  },

  -- princess_bat
  princess_bat = {
    name = { 'princess_bat' },
    is_immortal = true,
  },

  -- leona
  leona = {
    name = { 'leona' },
    add_type = 'follow_npc',
    following_state = 'keep',
  },

  -- hyunckel
  hyunckel = {
    name = { 'hyunckel' },
    add_type = 'follow_npc',
  },

  -- gome
  gome = {
    name = { 'gome' },
    add_type = 'follow_npc',
    following_state = 'keep',
  },

  --endregion

  --region queencastle

  -- 케이든(임시)
  qc_hero_ai = {
    name = { 'hero_ai' },
    is_immortal = true,
  },

  -- 코코 follow_npc
  qc_innuit_follow = {
    name = { 'innuit_helmet' },
    add_type = 'follow_npc',
    following_state = 'out_battle_zone',
  },

  -- 코코
  qc_innuit = {
    name = { 'innuit' },
    is_immortal = true,
  },

  -- 마리안
  qc_teatan_hero = {
    name = { 'teatan_hero' },
    is_immortal = true,
  },

  -- 마빈
  qc_desert_slave = {
    name = { 'desert_slave' },
    is_immortal = true,
  },

  -- 크레이그
  qc_tanker = {
    name = { 'tanker' },
    is_immortal = true,
  },

  -- 안드로이드 변장 기사
  qc_knight_maid = {
    type = 'knight',
    name = { 'knight_maid_female', 'knight_maid_male' },
    is_immortal = false,
  },
  -- 안드로이드 변장 케이든(임시)
  qc_hero_ai_maid = {
    name = { 'hero_ai_maid' },
    is_immortal = true,
  },
  -- 폴 가디언즈 전용 기사
  qc_fg_manual_knight = {
    type = 'knight',
    name = { 'fg_knight_female', 'fg_knight_male' },
    is_immortal = false,
  },

  -- AA72 서브 스테이지 npc
  qc_summer_android = {
    name = { 'sm_kid_android' },
    add_type = 'follow_npc',
  },
  qc_dungeon_succubus_a = {
    name = { 'dungeon_succubus_a' },
    add_type = 'follow_npc',
  },
  qc_bad_student_female = {
    name = { 'bad_student_female' },
    add_type = 'follow_npc',
  },
  qc_succubus_researcher = {
    name = { 'succubus_researcher' },
    add_type = 'follow_npc',
  },
  qc_teatan_ninja = {
    name = { 'teatan_ninja' },
    add_type = 'follow_npc',
  },

  -- 마리오 서브 스테이지
  qc_mario_knight = {
    type = 'knight',
    name = { 'knight_female_mario', 'knight_male_mario' },
    is_immortal = true,
  },

  qc_maria = {
    name = { 'maria' },
    is_immortal = true,
  },

  qc_lisa = {
    name = { 'lisa' },
    is_immortal = true,
  },

  --endregion

  --region Short Story Mermaid

  -- sohee
  mm_sohee = {
    name = { 'surfer_sohee' },
  },

  -- yuze
  mm_yuze = {
    name = { 'lifeguard_yuze' },
    is_immortal = true,
  },

  --mermaid
  mm_mermaid = {
    name = { 'mermaid' },
  },
  --mermaid
  mm_mermaid_country = {
    name = { 'mermaid_country' },
  },
  --endregion

  --region civilwar
  cw_demon_engineer = {
    name = { 'demon_engineer' },
    is_immortal = true
  },

  cw_demon_queen = {
    name = { 'demon_queen' }
  },

  --3 스테이지 마족으로 변장한 기사
  manual_demon_knight = {
    type = 'knight',
    name = { 'demon_knight_female', 'demon_knight_male' },
    is_immortal = false,
  },

  cw_demon_powergirl = {
    name = { 'demon_powergirl' }
  },

  cw_reine = {
    name = { 'reine' }
  },

  cw_hela = {
    name = { 'hela' },
    add_type = 'follow_npc',
  },

  cw_onigirl_mother = {
    name = { 'onigirl_mother' }
  },

  cw_onigirl = {
    name = { 'onigirl' }
  },

  cw_half_vampire = {
    name = { 'half_vampire' }
  },

  cw_vampire_captain = {
    name = { 'vampire_captain' }
  },

  cw_sheep_girl = {
    name = { 'sheep_girl' }
  },

  --endregion civilwar

  --region Short Story Shuran

  -- shuran
  shuran = {
    name = { 'shuran' },
  },

  shuran_battle = {
    name = { 'shuran_battle' },
  },

  -- onegirl
  jungpa_master = {
    name = { 'jungpa_master' },
  },

  -- nanok
  nanok = {
    name = { 'nanok' },
  },

  -- spirit_rabbit
  spirit_rabbit = {
    name = { 'spirit_rabbit' },
    add_type = 'follow_npc',
    following_state = 'out_battle_zone',
  },

  -- cyborg_monk
  cyborg_monk = {
    name = { 'cyborg_monk' },
  },

  -- cyborg_monk_battle
  cyborg_monk_battle = {
    name = { 'cyborg_monk_battle' },
    is_immortal = true,
  },

  --endregion

  --region nightmare_lilithtower

  nightmare_lt_trouble_shooter = {
    name = { 'trouble_shooter' }
  },
  nightmare_lt_mad_scientist = {
    name = { 'mad_scientist' },
    is_immortal = true,
  },

  --endregion nightmare_lilithtower

  --region laboseWorld

  lw_demon_engineer = {
    name = { 'demon_engineer' },
    is_immortal = true,
  },

  lw_demon_queen = {
    name = { 'demon_queen' },
    is_immortal = true,
  },

  lw_demon_governor = {
    name = { 'demon_governor' },
    is_immortal = true,
  },

  lw_half_vampire = {
    name = { 'half_vampire' },
    is_immortal = true,
  },

  lw_vampire_captain = {
    name = { 'vampire_captain' },
    is_immortal = true,
  },

  lw_sheep_girl = {
    name = { 'sheep_girl' },
    add_type = 'follow_npc',
    following_state = 'out_battle_zone',
  },

  lw_goat_girl = {
    name = { 'goat_girl' },
    add_type = 'follow_npc',
    following_state = 'out_battle_zone',
  },

  lw_maiden = {
    name = { 'maiden' },
    is_immortal = true,
  },

  lw_demon_slayer = {
    name = { 'demon_slayer' },
    is_immortal = true,
  },

  lw_demon_powergirl = {
    name = { 'demon_powergirl' },
    is_immortal = true,
  },

  lw_demon_operator = {
    name = { 'demon_operator' },
    is_immortal = true,
  },

  lw_onigirl_mother = {
    name = { 'onigirl_mother' }
  },

  lw_onigirl = {
    name = { 'onigirl' }
  },
  --endregion LaboseWorld

  --region Short Story Slime
  ss_slime_rimuru = {
    name = { 'rimuru' }
  },
  ss_slime_shuna = {
    name = { 'shuna' },
    is_immortal = true,
  },
  ss_slime_legendary_hero = {
    name = { 'legendary_hero' }
  },
  ss_slime_souei = {
    name = { 'souei' }
  },
  ss_slime_benimaru = {
    name = { 'benimaru' }
  },
  ss_slime_shion = {
    name = { 'shion' }
  },
  ss_slime_hakurou = {
    name = { 'hakurou' }
  },
  ss_slime_milim = {
    name = { 'milim' },
    is_immortal = true,
  },
  ss_slime_veldora = {
    name = { 'veldora' }
  },
  --endregion Short Story Slime

  --region NightmareDemonShire
  nightmare_ds_vampire_lord = {
    name = { 'vampire_lord' }
  },

  nightmare_ds_vampire_lord_flower = {
    name = { 'vampire_lord_flower' }
  },

  nightmare_ds_vampire_captain = {
    name = { 'vampire_captain' },
    is_immortal = true,
  },

  nightmare_ds_two_horn_goat_girl = {
    name = { 'goat_girl' },
    is_immortal = true,
  },

  --endregion NightmareDemonShire

  --region pixyworld
  pw_pixy_girl = {
    name = { 'pixy_girl' }
  },

  pixy_detective = {
    name = { 'pixy_detective' }
  },

  princess_pixy = {
    name = { 'princess_pixy' }
  },
  --endregion pixyworld

  --region Short Story Milkyway

  ss_milkyway_pirate = {
    name = { 'pirate' }
  },

  ss_milkyway_teatan_kid_girl = {
    name = { 'teatan_kid_girl' }
  },

  ss_milkyway_innuit_kid_boy = {
    name = { 'innuit_kid_boy' }
  },

  ss_milkyway_civilian_kid_boy = {
    name = { 'civilian_kid_boy' }
  },

  ss_milkyway_star_girl = {
    name = { 'star_girl' }
  },

  ss_milkyway_teatan_hero = {
    name = { 'teatan_hero' }
  },

  --endregion Short Story Milkyway

  --region NightmareQueenShip
  nightmare_qs_beth = {
    type = 'quest_clear',
    type_value = 264,
    name = { 'invader_knight_normal_weapon', 'invader_knight' }
  },

  nightmare_qs_little_girl = {
    name = { 'little_girl' },
    add_type = 'follow_npc',
    following_state = 'out_battle_zone',
  },

  nightmare_qs_little_girl_hair_down = {
    name = { 'little_girl_hair_down' },
    add_type = 'follow_npc',
    following_state = 'out_battle_zone',
  },

  --endregion NightmareQueenShip

  --region DreamVillage

  dv_princess = {
    name = { 'princess' },
    is_immortal = true,
  },

  dv_twins_younger = {
    name = { 'twins_younger' },
    is_immortal = true,
  },

  museum_knight = {
    name = { 'museum_knight' },
  },

  dv_sub_cyborg_china_hero = {
    type = 'china_hero',
    name = { 'china_hero_boy', 'china_hero_girl' },
    add_type = 'follow_npc',
    is_immortal = true,
  },

  dv_chris = {
    name = { 'chris' },
    add_type = 'follow_npc',
    following_state = 'out_battle_zone',
  },

  dv_museum_male = {
    name = { 'museum_male' },
    add_type = 'follow_npc',
    following_state = 'out_battle_zone',
  },

  dv_akayuki = {
    name = { 'akayuki' },
    add_type = 'follow_npc',
  },

  dv_kunoichi = {
    name = { 'kunoichi' },
    add_type = 'follow_npc',
  },

  dv_ninja_leader = {
    name = { 'ninja_leader' },
    add_type = 'follow_npc',
  },
  --endregion DreamVillage

  --region ShortStoryFrieren

  ss_frieren_frieren = {
    name = { 'frieren' }
  },

  ss_frieren_fern = {
    name = { 'fern' }
  },

  ss_frieren_stark = {
    name = { 'stark' }
  },

  ss_frieren_ailie = {
    name = { 'ailie' }
  },

  ss_frieren_held = {
    name = { 'held' }
  },

  ss_frieren_tanker = {
    name = { 'dungeon_tanker' }
  },

  --endregion ShortStoryFrieren

  --region WaterWorld
  ww_princess = {
    name = { 'princess' },
    is_immortal = true,
  },

  ww_wrestler = {
    name = { 'wrestler' }
  },

  ww_pirate = {
    name = { 'pirate' }
  },

  ww_mermaid_spy = {
    name = { 'mermaid_spy' }
  },

  ww_knight_pink_soldier = {
    name = { 'knight_pink_soldier' }
  },

  ww_mermaid_spy_pink_soldier = {
    name = { 'mermaid_spy_pink_soldier' }
  },

  ww_mermaid_spy_battle = {
    name = { 'mermaid_spy_battle' }
  },
  --endregion WaterWorld

  --region NightmareQueenCastle

  nightmare_qc_android = {
    name = { 'twins_android' }
  },

  nightmare_qc_android_b = {
    name = { 'twins_android_b' },
    is_immortal = true,
  },

  nightmare_qc_android_maid = {
    name = { 'twins_android_maid' }
  },

  nightmare_qc_android_b_maid = {
    name = { 'twins_android_b_maid' },
    is_immortal = true,
  },
  --endregion NightmareQueenCastle

  --region Blossom

  fake_knight = {
    type = 'knight',
    name = { 'fake_knight_male', 'fake_knight_female' },
    is_immortal = false,
  },

  bs_teatan_hero = {
    name = { 'teatan_hero' },
    is_immortal = true,
  },

  bs_ghost_buster = {
    name = { 'ghost_buster' },
    is_immortal = true,
  },

  bs_teatan_hero_another = {
    name = { 'teatan_hero_another' },
    is_immortal = true,
  },

  bs_ghost_buster_another = {
    name = { 'ghost_buster_another' },
    is_immortal = true,
  },

  --endregion Blossom

  --region Bootcamp

  bc_summer_android = {
    name = { 'summer_android' },
    is_immortal = true,
  },

  --endregion Bootcamp

  --region ShortStoryBattleBall
  bb_teaten_hero = {
    name = { 'teatan_hero' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },

  bb_innuit = {
    name = { 'innuit' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },

  battleball_girl = {
    name = { 'battleball_girl' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },

  battleball_girl_myth = {
    name = { 'battleball_girl_myth' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },

  battleball_pitcher = {
    name = { 'battleball_pitcher' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },

  battleball_pitcher_myth = {
    name = { 'battleball_pitcher_myth' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },

  battleball_princess = {
    name = { 'princess' },
    following_state = 'keep',
    add_type = 'follow_npc',
  },

  --endregion ShortStoryBattleBall

  --region SquirrelGirl
  sq_squirrel_girl = {
    name = { 'squirrel_girl' },
    is_immortal = true,
  },
  --endregion SquirrelGirl

  --region FireWorld

  fw_princess = {
    name = { 'princess' },
    is_immortal = true,
  },

  fw_dragon_boy = {
    name = { 'dragon_boy' },
    is_immortal = true,
  },

  fw_fire_bishop = {
    name = { 'fire_bishop' },
    is_immortal = true,
  },

  fw_eternal_flame = {
    name = { 'eternal_flame' },
    is_immortal = true,
  },

  -- 와이번 길들이기 서브 스테이지
  fw_steam_knight = {
    name = { 'steam_knight' },
    is_immortal = true,
  },

  fw_steam_knight_dragon_doll = {
    name = { 'steam_knight_dragon_doll' },
    is_immortal = true,
  },

  fw_steam_princess = {
    name = { 'steam_princess' },
    is_immortal = true,
  },

  -- 라피스의 행방불명 서브 스테이지
  fw_knight_sauna = {
    type = 'knight',
    name = { 'knight_female_sauna', 'knight_male_sauna' },
    is_immortal = true,
  },

  fw_uptown_lancer_girl_hotspring = {
    name = { 'lancer_girl' },
    is_immortal = true,
  },
  --endregion FireWorld

  --region ShortStoryClevatess
  ct_klen = {
    name = { 'klen' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },
  ct_alicia = {
    name = { 'alicia' },
    is_immortal = true,
  },
  ct_alicia_2 = {
    name = { 'alicia_2' },
    is_immortal = true,
  },
  ct_alicia_3 = {
    name = { 'alicia_3' },
    is_immortal = true,
  },
  ct_neruru = {
    name = { 'neruru' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },
  ct_neruru_luna = {
    name = { 'neruru_luna' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },
  --endregion ShortStoryClevatess

  --region MagicalGirl
  mm_mg_magical_girl_student = {
    name = { 'magical_girl_student' },
    is_immortal = true,
  },

  mm_mg_magical_girl = {
    name = { 'magical_girl' },
    is_immortal = true,
  },

  mm_mg_dog = {
    name = { 'mg_dog' },
    add_type = 'follow_npc',
  },
  --endregion MagicalGirl

  --region Sunyeo
  sunyeo_sunyeo = {
    name = { 'sunyeo' },
    is_immortal = true,
  },
  --endregion Sunyeo

  --region ShortStoryNoel
  ss_noel_noel = {
    name = { 'noel' },
  },

  ss_noel_noel_myth = {
    name = { 'noel_myth' },
  },
  --endregion ShortStoryNoel

  --region Thief
  mm_th_disguised_demon_inspector = {
    name = { 'disguised_demon_inspector' },
    is_immortal = true,
  },

  mm_th_demon_inspector = {
    name = { 'demon_inspector' },
    is_immortal = true,
  },
  --endregion Thief

  --region BridgeStorySeira
  seira_seira = {
    name = { 'seira' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },

  seira_seira_myth = {
    name = { 'seira_myth' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },
  --endregion

  --region BridgeStoryPepper
  pepper_pepper = {
    name = { 'pepper' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },
  --endregion

  --region BridgeStoryV
  v_driver = {
    name = { 'v_driver' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },
  --endregion

  --region BridgeEpilogue
  seira_epilogue = {
    name = { 'seira' },
    add_type = 'follow_npc',
    following_state = 'keep',
    is_immortal = true,
  },
  --endregion

	--region CarpGirl
	mm_cg_carp_girl = {
		name = { 'carp_girl' },
		is_immortal = true,
	},
	mm_cg_carp_girl_myth = {
		name = { 'carp_girl_myth' },
		is_immortal = true,
	},
	mm_cg_shuran = {
		name = { 'shuran' },
		is_immortal = true,
	},
	mm_cg_civilian_male_1 = {
		name = { 'civilian_male_1' },
		add_type = 'follow_npc',
		following_state = 'keep',
		is_immortal = true,
	},


	--endregion CarpGirl
}
