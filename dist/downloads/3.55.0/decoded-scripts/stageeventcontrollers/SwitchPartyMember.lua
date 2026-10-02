local local_class = newclass('SwitchPartyMemberController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 변경할 파티 멤버 데이터 (첫번째가 리더)
	self.constants_data = nil

	-- 파티멤버로 편입할 npc 정보
	self.npc_data = nil

	-- 파티 멤버 교체 타입별 함수
	self.switching_func = {
		['all'] = self.switching_all_party_member,
		['exclude_leader'] = self.switching_party_member_exclude_leader,
		['add'] = self.add_party_member,
	}

	self.npc_following_state_in_battle = {
		['keep'] = CS.Oak.NpcFollowingStateInBattle.Keep,
		['leader_following'] = CS.Oak.NpcFollowingStateInBattle.LeaderFollowing,
		['in_battle_zone'] = CS.Oak.NpcFollowingStateInBattle.InBattleZone,
		['out_battle_zone'] = CS.Oak.NpcFollowingStateInBattle.OutBattleZone,
	}
end

function local_class:load_resource()
	self.legacy_stage_data = get_or_create_global_variable('utils/SwitchPartyMember/SwitchPartyMemberLegacyStage')

	local contain_value = table_util.contain_value(self.legacy_stage_data, stage.Name)

	-- contain_value는 레가시 데이터 인지 체크 유무
	local constants_data = self:get_switch_party_member_data(contain_value)

	-- 스테이지 Constant 데이터 세팅
	self.constants_data = constants_data[stage.Name]

	-- npc 데이터 세팅
	self.npc_data = require('stageeventcontrollers/SwitchPartyMemberNpcConstant')

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	-- 캐릭터 인포를 세팅해주지 않는 구 버전 Constant 라면 BattleActionsChangedEvent를 구독한다.
	if not self.constants_data.is_set_character_info then
		message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	end
end

function local_class:get_switch_party_member_data(contain_value)
	local data_path
	local party_member_data

	-- contain_value 가 true이면 레가시 데이터 이므로 이전 Constant 데이터
	if contain_value then
		data_path = 'stageeventcontrollers/SwitchPartyMemberConstant'
	else
		local chapter_code = stage.Spec.ChapterCode.Value

		-- 새로 만들어진 데이터 경로
		data_path = 'utils/SwitchPartyMember/SwitchPartyMember'..chapter_code
	end

	party_member_data = get_or_create_global_variable(data_path)

	return party_member_data
end

function local_class:on_stage_loaded_event(_)
	-- 스테이지 로드 후에 파티 파티 멤버 교체
	start_coroutine(self.switching_party_member_routine, self)

	return true
end

function local_class:on_battle_actions_changed_event(e)
	if lua_helper.reference_equals(e.Target, user_party.Leader) then
		-- 리더 배틀액션이 변경된 후에 캐릭터 더미 인포 세팅
		self:set_leader_character_info(user_party.Leader)
		return true
	end

	return false
end

function local_class:switching_party_member_routine()
	if self.constants_data == nil then
		CS.UnityEngine.Debug.LogError('constants_data must not be nil')
		return
	end

	-- 타겟 퀘스트 가져오기
	local quest_id = self.constants_data.quest_id
	local quest_progress = user_progress:GetStartedQuest(quest_id)

	-- 퀘스트 진행도에 따른 값 세팅
	local progress_data
	if quest_progress.IsComplete then
		-- 퀘스트를 클리어 했을 경우 complete_data로 세팅
		progress_data = self.constants_data.complete_data
	else
		local cur_progress_data = self.constants_data.progress_data_list[quest_progress.InnerProgress]

		if cur_progress_data ~= nil then
			progress_data = cur_progress_data
		else
			-- 섹션 정보가 없을 경우 fallback_data로 세팅
			progress_data = self.constants_data.fallback_data
		end
	end

	-- switching_type 별로 다른 로직 타도록
	yield_return_func(self.switching_func[progress_data.switching_type], self, progress_data.characters)

	-- 파티원 교체가 끝났다고 알려줌
	message_system:Publish(CS.Oak.CompleteSwitchingPartyMemberEvent.Instance)
end

-- 모든 파티원 교체
function local_class:switching_all_party_member(characters)
	for i = 1, #characters do
		local character_data = self.npc_data[characters[i]]
		local character = self:get_character(character_data)
		character_util.set_active_state(character, 'enabled')

		if i == 1 then
			-- 첫번째 인덱스일 경우 메뉴얼 캐릭터로 세팅
			self:convert_to_manual_character(character)
		else
			-- 나머지 캐릭터들은 파티 멤버 or 따라다니는 npc로 편입
			self:add_member(character_data, character)
		end
	end
end

-- Constant 값의 is_set_character_info에 따라 v2를 사용할지 정해서 메뉴얼 캐릭터를 변경해주는 함수
function local_class:convert_to_manual_character(character)
	local param = CS.Oak.CharacterConvertParam:ManualDefault()

	if not self.constants_data.is_set_character_info then
		character_util.convert_to_manual_character(character, param, true)
		return
	end

	character_util.convert_to_manual_character_v2(character, param, true)
end

-- 리더 제외 파티원 교체
function local_class:switching_party_member_exclude_leader(characters)
	-- 리더 빼고 파티 제외
	for i = user_party.Count - 1, 1, -1 do
		local character = user_party[i]
		character_util.convert_to_npc(character)
		character_util.set_position(character, vector(999, 0, 999))
		character_util.set_active_state(character, 'disabled')
	end

	-- characters에 포함된 파티원들 파티 멤버로 컨버트
	for i = 1, #characters do
		local character_data = self.npc_data[characters[i]]
		local character = self:get_character(character_data)

		character_util.set_active_state(character, 'enabled')
		self:add_member(character_data, character)
	end
end

-- 파티 멤버만 추가
function local_class:add_party_member(characters)
	for i = 1, #characters do
		local character_data = self.npc_data[characters[i]]
		local character = self:get_character(character_data)

		character_util.set_active_state(character, 'enabled')
		self:add_member(character_data, character)
	end
end

-- character_data에서 핸들네임을 찾아 파티 멤버가 될 캐릭터 리턴
function local_class:get_character(character_data)
	if character_data.type ~= nil then
		-- 특수 케이스인 경우 (기사나 페이, 메이)
		if character_data.type == 'knight' then
			return user_util.get_knight_character(character_data.name[1], character_data.name[2])
		elseif character_data.type == 'china_hero' then
			return user_util.get_china_hero_character(character_data.name[1], character_data.name[2])
		elseif character_data.type == 'quest_clear' then
			local quest_progress = user_progress:GetStartedQuest(character_data.type_value)

			if quest_progress == nil or not quest_progress.IsComplete then
				return get_character(character_data.name[1])
			end

			return get_character(character_data.name[2])
		else
			CS.UnityEngine.Debug.LogError('not exist type, default character is nil')
		end
	end

	return get_character(character_data.name[1])
end

function local_class:set_leader_character_info(leader)
	--TODO: 퀘스트 진행중에 리더가 변경 되었을 때도 캐릭터 인포 세팅 되도록 구독 해지 안함
	local origin_id = leader.CharacterStatsBehaviour.CharacterSpec.Id
	leader.CharacterInfo = CS.Oak.CharacterInfo.CreateStoryCharacterInfo(
			user_party_leader.CharacterInfo.User, origin_id)
end

-- 파티에 멤버 추가하는 함수 (파티원으로 추가할 것인지, 팔로잉 npc로 추가할 것인지)
function local_class:add_member(character_data, character)
	if character_data.add_type == 'follow_npc' then
		local follower_battle_state = character_data.following_state ~= nil
				and self.npc_following_state_in_battle[character_data.following_state]
				or CS.Oak.NpcFollowingStateInBattle.OutBattleZone

		local scared = lua_helper.get_or_default(character_data.scared, false)
		character_util.convert_to_following_npc(character, user_party, scared, follower_battle_state)
		return
	end

	if not self.constants_data.is_set_character_info then
		character_util.convert_to_party_member(character, user_party, character_data.is_immortal)
		return
	end

	character_util.convert_to_party_member_v2(character, user_party, character_data.is_immortal)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))

	self.constants_data = nil
	self.npc_data = nil
	self.switching_func = nil
	self.npc_following_state_in_battle = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
