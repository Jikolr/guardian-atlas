require('base/class')

local local_class = newclass('QuestDataStorage')


function local_class:init(quest_id)
	self.quest_id = quest_id
	self.quest_progress = CS.Oak.UserProgress.Instance:GetStartedQuest(quest_id)
	self.util = require('xlua.util')
	self.key_to_id = {}

	if quest_id == 221 then
		self.key_to_id.dollar = 1
		self.key_to_id.store_soylent_red = 2
		self.key_to_id.dollar_remove_beer = 3
	end

end

function local_class:get_data(data_name)
	local qp = self.quest_progress

	if self.key_to_id[data_name] ~= nil then
		return CS.Oak.DemonWorldHelper.GetCurrency(self.quest_id, self.key_to_id[data_name])
	else
		return qp:GetCustomState(data_name)
	end
end

-- it runs by CoroutineManager
function local_class:set_data(data_name, value, on_success, on_error)
	CS.Foundations.CoroutineManager.Instance:StartCoroutine(
			CS.Oak.Stage.Instance.StageGameObject, self.util.cs_generator(self.set_data_async, self, data_name, value, on_success, on_error))
end

function local_class:set_data_array_sync(data_array, on_success, on_error)
	CS.Foundations.CoroutineManager.Instance:StartCoroutine(CS.Oak.Stage.Instance.StageGameObject,
			self.util.cs_generator(self.set_data_array, self, data_array, on_success, on_error))
end

-- it runs with coroutine.yield
function local_class:set_data_async(data_name, value, on_success, on_error)
	local data_array = {
		{
			key = data_name,
			value = value
		}
	}
	self:set_data_array(data_array, on_success, on_error)
end

-- data format: { {key:string, value:number}, {key:string, value: number}...}
function local_class:set_data_array(data_list, on_success, on_error)
	-- 마계 달러 관련 다시 하기 예외 처리 추가
	-- 다시하기 이전에 작성된 코드 이기도 하고 따로 성공,실패 콜백 처리가 들어 있어서 기존 래핑 함수를 이용 하지 않고 별도 처리
	if CS.Oak.QuestReplaySystem.IsReplaying then
		for i,v in pairs(data_list) do
			CS.Oak.QuestReplaySystem.SetCustomState(self.quest_progress, v.key, v.value)
		end

		-- 무조건 성공 호출
		if on_success ~= nil then
			on_success()
		end
		return
	end

	local clone = CS.System.Collections.Generic.Dictionary(CS.System.String, CS.System.Int32)()

	-- c#과 루아의 string의 타입이 다른 탓인지 인덱싱하면 내용이 같은 문자열이더라도 정상동작하지 않아 루아 데이터를 먼저 Add로 값을 추가함
	for i,v in pairs(data_list) do
		clone:Add(v.key, v.value)
	end

	for k,v in pairs(self.quest_progress.CustomStates) do
		-- data_list의 값이 우선순위가 더 높기 때문에 먼저 저장된 같은 키가 있는 경우 무시함
		if not clone:ContainsKey(k) then
			clone:Add(k, v)
		end
	end

	local stage_custom = CS.Oak.StageCustom()
	stage_custom.QuestId = self.quest_progress.QuestId
	stage_custom.QuestCustomState = clone
	local req = CS.Oak.NetworkManager.ApiConnection:SendSetCustom(CS.Oak.Stage.Instance.StageId, stage_custom)
			:Then(function(res)
				for i,v in pairs(data_list) do
					CS.Oak.UserProgress.Instance:SetQuestCustomState(self.quest_progress, v.key, v.value)
				end

				if on_success ~= nil then
					on_success(res)
				end
			end)

	if on_error ~= nil then
		req:Catch(on_error)
	end

	coroutine.yield(req)
end

function local_class:dispose()
	self.quest_progress = nil
	self.util = nil
end

return {
	create = function(quest_id)
		return local_class(quest_id)
	end
}
