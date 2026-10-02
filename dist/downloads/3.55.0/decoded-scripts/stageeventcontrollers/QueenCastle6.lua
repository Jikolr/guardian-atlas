local local_class = newclass('QueenCastle6Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- 메인 퀘스트 id
	self.main_quest_id = 330

	-- 크레이그 섹터 퀘스트 id
	self.sector_quest_id = 336

	-- scene_util 버전
	self.scene_version = scene_util.default_version

	-- 필드 오브젝트
	self.get_statue = function()
		return get_field_object('s3_shield_statue')
	end

	self.get_shield = function()
		return get_field_object('s3_shield_1')
	end

	self.get_s2_star_piece_puzzle_rock = function()
		return get_field_object('s2_puzzle_star_piece_rock')
	end

	self.s2_star_piece_name = 's2_puzzle_star_piece'

	-- 이펙트
	self.get_twinkle_effect = function()
		return unity_object_pool.GetOrCreate('FX_Object_Twinkle')
	end

	self.get_smoke_effect = function()
		return unity_object_pool.GetOrCreate('FX_dead')
	end

	self.statue_twinkle_effect = nil

	self.score_ui = nil

	self.scores = {
		battle_end = {
			score = 10
		},
		breakable = {
			score = 1
		},
		purple_coin = {
			score = 3,
		},
		star_piece = {
			score = 5,
		},
		item = {
			score = 5,
		}
	}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	--몬스터 1 그룹 처치 시마다 포인트 + 10
	--브레이커블 오브젝트 파괴 시마다 포인트 + 1
	--퍼플 코인 습득 시마다 포인트 + 3
	--스타피스 획득 시마다 포인트 + 5
	--아이템 획득 시마다 포인트 + 5
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	--message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.PurpleCoinGetEvent), 'on_purple_coin_get_event')
	message_system:Subscribe(self, typeof(CS.Oak.StarPieceGetEvent), 'on_star_piece_get_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_item_get_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.score_ui = get_or_create_global_table('Quest/Main/QueenCastle/Common/SectorTankerUiController')
	self.score_ui:load_async()

	local mural = get_or_create_global_table('Quest/Main/QueenCastle/Common/MuralTheatreController')
	mural:load_async()

	self.get_twinkle_effect()
	self.get_smoke_effect()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	self:set_shield_statue()
	start_coroutine(self.launch_routine, self)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	--message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PurpleCoinGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StarPieceGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))

	self.score_ui = nil

	if self.statue_twinkle_effect ~= nil then
		self.statue_twinkle_effect:Dispose()
	end
	self.statue_twinkle_effect = nil

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	do
		local qc_util = get_or_create_global_table('Quest/Main/QueenCastle/Common/Util')
		qc_util:set_sector_directional_light(2)
	end

	return true
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_statue()) then
		sp_util.start_scene(self.drop_shield_scene, self)
	end
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, self.get_s2_star_piece_puzzle_rock()) and
			not star_piece_util.has_star_piece(self.s2_star_piece_name) then

		sp_util.start_scene(self.star_piece_puzzle_rock_scene, self, e.FieldObject)

		return true
	end

	if lua_helper.type_compare(e.FieldObject.CrashBehaviour, CS.Oak.PotCrashBehaviour) then
		self:try_add_score('breakable')
		return true
	end

	return false
end

function local_class:on_battle_group_eliminated_event(e)
	self:try_add_score('battle_end')

	return false
end

function local_class:on_purple_coin_get_event(e)
	self:try_add_score('purple_coin')

	return false
end

function local_class:on_star_piece_get_event(e)
	self:try_add_score('star_piece')

	return false
end

function local_class:on_item_get_event(e)
	self:try_add_score('item')

	return false
end

--endregion

function local_class:launch_routine()
	local sector_quest_progress = user_progress:GetStartedQuest(self.sector_quest_id)

	-- 시작 연출 관리
	if sector_quest_progress == nil or sector_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
				true, true)
	elseif sector_quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
				true, true)
	elseif sector_quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s2_knight_start'),
				true, true)
	elseif sector_quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s3_knight_start'),
				true, true)
	elseif sector_quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s4_knight_start'),
				true, true)
	elseif sector_quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s4_race_end_knight'),
				false, true)
	elseif sector_quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s6_knight_battle_pos'),
				false, true)
	elseif sector_quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

-- 방패 들고있는 석상 세팅
function local_class:set_shield_statue()
	local effect_pos = self.get_statue().Position + vector(0.5, 1, -0.3)
	self.statue_twinkle_effect = self.get_twinkle_effect():Instantiate(effect_pos)
end

-- 석상에서 방패 떨어뜨리기
function local_class:drop_shield_scene()
	local statue = self.get_statue()
	local shield = self.get_shield()
	local align_pos = statue.Position + vector(0.5, 0, -1)
	local shield_pos = statue.Position + vector(0.5, 0, -1)
	local leader = get_party_leader()

	statue.Interactable = CS.Oak.NonInteractable.Instance

	party_util.align_party(align_pos, 'left', 0.5, 'linear')

	local equipping_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01',
		type_priority = 'event',
		player_priority = 'npc'
	})
	scene_util.set_anim(leader, self, 'eat')
	wait_for_sec(1)

	local smoke = self.get_smoke_effect():Instantiate(statue.Position + vector(0.5, 0.5, -1.1))
	smoke.transform.localScale = 2 * unity_class.vector3.one

	self.statue_twinkle_effect:Dispose()
	self.statue_twinkle_effect = nil

	wait_for_sec(0.1)

	music_player_util.play_sfx_one_shot('03_drop_recovery_01')
	shield.Position = shield_pos
	shield.Holdable = CS.Oak.Holdable()

	character_util.remove_anim(leader)

	music_player_util.fade_out_sfx(equipping_sfx, 0.3)
end

function local_class:try_add_score(type)
	if self.score_ui == nil then
		return
	end

	self.score_ui:add_score(self.scores[type].score)
end

function local_class:star_piece_puzzle_rock_scene(rock)
	-- 만약 카메라 그리드를 넘어가고 있는 상황이었다면 터질수도 있으므로 timescale 영향 받는 0.1초를
	wait_for_sec(0.1)
	--해당 맵의 2x2 바위가 부숴질 때 플레이어 정지한 뒤, 부숴진 바위 1회 포커싱. 이후 플레이어 컨트롤 복귀.

	camera_util.move_async(rock.Bounds.center, 1)

	wait_for_sec(1)

	camera_util.return_to_leader(1)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
