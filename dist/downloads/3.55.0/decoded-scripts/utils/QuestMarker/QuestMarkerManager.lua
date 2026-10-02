local local_class = newclass('QuestMarkerManager')

function local_class:init()
	self.zone_infos = {
		-- ['zone'] = { key_1 = { target, executor, quest_id, is_story }, key_2 = ... }
	}

	self.executors = {
		point = function(this, key)
			quest_marker_util.remove(key)
			quest_marker_util.add_quest_marker_to_point(key, this.quest_id, this.is_story, this.target)
		end,
		ifo = function(this, key)
			quest_marker_util.remove(key)
			quest_marker_util.add_quest_marker_to_ifo(key, this.quest_id, this.is_story, this.target)
		end,
		-- FIXME : 타겟이 없는 구역의 경우에는 QuestId를 통한 제어가 불가능한데, 이를 해결할 필요성이 있는지?
		none = function(this, key)
			quest_marker_util.remove(key)
		end
	}

	self.legacy_stage_data = get_or_create_global_variable('utils/QuestMarker/QuestMarkerLegacyStage')

	local contain_value = table_util.contain_value(self.legacy_stage_data, stage.Name)

	-- contain_value는 레가시 데이터 인지 체크 유무
	local constants_data = self:get_quest_marker_data(contain_value)

	-- 이 스테이지에 대한 데이터가 없더라도 이 유틸은 동작해야하기 때문에, 없으면 빈 테이블을 하나 만들어줌
	self.constants = self:build_to_usable_constants(constants_data[stage.Name] or {})

	-- 여러 개의 마커가 한 곳에 찍힌다면 대표 혹은 대리자를 뽑아 한개만 찍히도록 하려 했으나,
	-- C# QuestId를 이용해 마커를 제어하는 메소드가 존재하여 대리자를 세우면 해당 메소드를 사용하지 못하는 문제가 있어 포기

	-- 사용할 때에만 ZoneEnterEvent를 구독해둬야 하지만, 동프레임 구독/구독해제 순서가 무시되는 고질적인 문제로 일단 패스
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.constants = nil
	self.zone_infos = nil
end

function local_class:get_quest_marker_data(contain_value)
	local data_path
	local quest_marker_data

	-- contain_value 가 true이면 레가시 데이터 이므로 이전 Constant 데이터
	if contain_value then
		data_path = 'utils/QuestMarker/QuestMarkerConstants'
	else
		local chapter_code = stage.Spec.ChapterCode.Value

		-- 새로 만들어진 데이터 경로
		data_path = 'utils/QuestMarker/QuestMarker'..chapter_code
	end

	quest_marker_data = get_or_create_global_variable(data_path)

	return quest_marker_data
end

function local_class:on_zone_enter_event(e)
	if not (e.FullEnter and lua_helper.reference_equals(e.FieldObject, get_party_leader())) then
		return false
	end

	local key_to_marker_info = self.zone_infos[e.Zone.Name]

	if key_to_marker_info ~= nil then
		for key, info in pairs(key_to_marker_info) do
			self:add_or_move_marker_inner(key, info)
		end

		return true
	end

	return false
end

function local_class:build_to_usable_constants(constants)
	local built = {}

	for constants_key, data in pairs(constants) do
		built[constants_key] = {
			quest_marker_key = data.quest_marker_key,
			quest_id = data.quest_id,
			is_story = data.is_story,
			control_data = {}
		}

		for zone, target_data in pairs(data.control_data) do
			local target

			if target_data.type == 'character' then
				target = get_character(target_data.name)
			elseif target_data.type == 'fo' then
				target = get_field_object(target_data.name)
			elseif target_data.type == 'marker' then
				target = field_util.get_marker_pos(target_data.name)
			elseif target_data.type == 'none' then
				target = nil
			else
				-- 예상치 못한 데이터가 들어가 있는 경우에는 패스
				goto continue
			end

			table.insert(built[constants_key].control_data, {
				zone = zone,
				target = target
			})

			::continue::
		end
	end

	return built
end

function local_class:create_marker_info(target, quest_id, is_story)
	local executor

	if target == nil then
		executor = self.executors.none
	elseif lua_helper.type_compare(target, CS.UnityEngine.Vector3) then
		executor = self.executors.point
	elseif lua_helper.type_compare(target, CS.Oak.Character) or
			lua_helper.type_compare(target, CS.Oak.FieldObject) then
		executor = self.executors.ifo
	end

	-- 맞는 값이 아닌 경우 데이터 구성하지 않음
	if target ~= nil and executor == nil then
		return nil
	end

	return {
		target = target,
		execute_add = executor,
		quest_id = quest_id,
		is_story = is_story,
	}
end

function local_class:add_zone_info(control, quest_marker_key, quest_id, is_story, need_init)
	local zone_name = control.zone
	local target = control.target
	local in_zone = zone_util.contains_fo(zone_name, get_party_leader(), true)

	local marker_info = self:create_marker_info(target, quest_id, is_story)

	-- 마커 정보가 생성되지 않았다면 타겟 정보가 잘못 기입된 것임. 명확한 트래킹을 위해 에러로그 출력
	if marker_info == nil then
		exception_stage_exit('[Argument: control_data] has invalid [key : target] for QuestMarker.')

		return not need_init
	end

	if self.zone_infos[zone_name] == nil then
		self.zone_infos[zone_name] = {}
	end

	local marker_info_dict = self.zone_infos[zone_name]

	marker_info_dict[quest_marker_key] = marker_info

	if need_init and in_zone then
		-- 활성화가 필요하면 퀘스트 마커를 찍어줌
		self:add_or_move_marker_inner(quest_marker_key, marker_info)

		return true
	end

	return not need_init
end

function local_class:add(constants_key, control_data, quest_marker_key, quest_id, is_story)
	-- constants_key에 맞는 constants 정보가 존재하지 않으면 빈 테이블
	local origin_constants = lua_helper.get_value(self.constants, constants_key, {})

	quest_marker_key = lua_helper.get_or_default(quest_marker_key, origin_constants.quest_marker_key)
	quest_id = lua_helper.get_or_default(quest_id, origin_constants.quest_id)
	is_story = lua_helper.get_or_default(is_story, origin_constants.is_story)

	-- IsStory 데이터가 없으면 퀘스트 아이디를 통해 읽어옴
	if is_story == nil then
		local quest_data = game_data_service.GetData('QuestData')
		local quest_spec = quest_data:GetQuest(quest_id)

		is_story = quest_spec.IsStoryQuest
	end

	-- 데이터 덮어쓰기가 발생하면 조건이 복잡해지기 때문에 일단은 삭제해줌
	self:remove(constants_key, quest_marker_key)

	local origin_control_data = origin_constants.control_data

	-- 마커가 세팅되었는지
	local is_initialized = false

	-- 먼저 우선도가 높은 override 데이터를 처리
	for i = 1, #control_data do
		is_initialized = self:add_zone_info(control_data[i],
				quest_marker_key, quest_id, is_story, not is_initialized)
	end

	-- 오버라이드된 데이터를 제외한 나머지를 추가
	for i = 1, #origin_control_data do
		if self.zone_infos[origin_control_data[i].zone] == nil or
				self.zone_infos[origin_control_data[i].zone][quest_marker_key] == nil then
			is_initialized = self:add_zone_info(origin_control_data[i],
					quest_marker_key, quest_id, is_story, not is_initialized)
		end
	end

	if not is_initialized then
		exception_stage_exit('[Argument: control_data] contains no initialized Data')
	end
end

--- 마커 위치 이동 및 세팅 함수 호출
function local_class:add_or_move_marker_inner(key, marker_info)
	marker_info:execute_add(key)
end

function local_class:remove(constants_key, quest_marker_key)
	-- 퀘스트 마커 키가 없으면 constants를 참조
	if quest_marker_key == nil and self.constants[constants_key] ~= nil then
		quest_marker_key = self.constants[constants_key].quest_marker_key
	end

	local zones_to_remove = {}

	for zone_name, key_to_marker_infos in pairs(self.zone_infos) do
		if key_to_marker_infos[quest_marker_key] == nil then
			goto continue
		end

		-- 퀘스트 마커 키를 가지고 있는 마커 정보를 지워줌
		key_to_marker_infos[quest_marker_key] = nil

		-- info가 비어있는지 확인
		local has_no_data = true

		for _ in pairs(key_to_marker_infos) do
			has_no_data = false
			break
		end

		-- 해당 존에 대한 데이터가 남아있지 않은 경우에는 삭제
		-- 현재 순회하고 있는 테이블 참조가 깨지지 않도록 바로 지우지 않고 리스트에 넣어둠
		if has_no_data then
			table.insert(zones_to_remove, zone_name)
		end

		::continue::
	end

	-- 비어있는 zone to info는 삭제
	-- remove와 돌때마다 모든 존의 데이터를 순회하기에, 순회 카운트를 최대한 줄이기 위함
	for i = 1, #zones_to_remove do
		self.zone_infos[zones_to_remove[i]] = nil
	end

	-- 퀘스트 마커 비활성화
	quest_marker_util.remove(quest_marker_key)
end

--- 내부 데이터 디버깅용.
--- 추후 트래킹이 어려울 것을 감안하여 테스트 기능은 살려둠
function local_class:debug_print(added)
	local str = added and '[Added] ' or '[Removed] '

	local get_marker_info_str = function(info)
		return 'Target[' .. (info.target and info.target:ToString() or 'None') .. '], QuestId[' ..
				info.quest_id .. '], IsStory[' .. (info.is_story and 'true' or 'false') .. ']'
	end

	for zone, info in pairs(self.zone_infos) do
		str = str .. 'In Zone [' .. zone .. '] -> \n{\n'

		for key, data in pairs(info) do
			str = str .. '    QuestMarkerKey[' .. key .. '] : ' .. get_marker_info_str(data) .. '\n'
		end

		str = str .. '},\n'
	end

	CS.UnityEngine.Debug.Log(str)
end

return {
	create = function()
		return local_class()
	end
}
