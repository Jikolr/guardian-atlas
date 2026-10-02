local give_dollar_reward_routine
local remove_dollar_routine

--- 퀘스트에서 마계 달러를 보상으로 지급하는 연출 함수
--- @param pos any 지급될 마계 달러가 생성될 위치
--- @param amount number 지급될 마계 달러의 액수
--- @param temporary number 플레이어가 게임오버되서 스테이지 퇴장시에 잃어버리는 마계 달러인지 저장
function give_dollar_reward(pos, amount, temporary)
	temporary = lua_helper.get_or_default(temporary, false)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(give_dollar_reward_routine, pos, amount, temporary))
end

--- 퀘스트에서 마계 달러를 감소 시키는 연출 함수
--- @param amount number 감소될 마계 달러의 액수
--- @param temporary number 플레이어가 게임오버되서 스테이지 퇴장시에 복구되는 마계 달러인지 저장
function remove_dollar(amount, temporary, play_sfx)
	temporary = lua_helper.get_or_default(temporary, false)
	play_sfx = lua_helper.get_or_default(play_sfx, true)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(remove_dollar_routine, amount, temporary, play_sfx))
end

function give_dollar_reward_routine(pos, amount, temporary, end_pos)
	local dollar_item_id = 20339

	local target_pos
	if end_pos == nil then
		local rand_x = unity_class.random.Range(-0.5, 0.5)
		local rand_z = unity_class.random.Range(-0.5, 0.5)
		target_pos = pos + vector(rand_x, 0, rand_z)
	else
		target_pos = end_pos
	end

	music_player_util.play_sfx_one_shot('01_dollars_01')

	local dollar_item = drop_item_util.create_item({ pos = pos, target = target_pos,
													 itemid = dollar_item_id, notforinven = true, sprscale = 0.5,
													 lootstate = 'dontfindlooter', skip_text = true })

	wait_for_sec(1)

	dollar_item.ConsumeTarget = user_party.Leader
	dollar_item:Fly()

	while ((user_party_leader.Position:GetX0z() -
			dollar_item.Position:GetX0z()).magnitude > 0.3) do
		coroutine.yield(nil)
	end

	CS.Oak.FieldUIFloatingText.Get(user_party.Leader):JustPrintItemName('+' .. (amount) .. ' ' ..
			game_string:GetString('demonworld_part1_dollar'), 0)

	if not temporary then
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'dollar_add', amount }))
	else
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'dollar_add', amount, 'temporary' }))
	end
end

function remove_dollar_routine(amount, temporary, play_sfx)

	local minus_string = '-'
	if amount == 0 then
		minus_string = ''
	end

	if play_sfx then
		music_player_util.play_sfx_one_shot('01_hit_comic_01')
	end

	CS.Oak.FieldUIFloatingText.Get(user_party.Leader):JustPrintItemName(minus_string .. (amount) .. ' ' ..
			game_string:GetString('demonworld_part1_dollar'), 0)

	if not temporary then
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'dollar_remove', amount }))
	else
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'dollar_remove', amount, 'temporary' }))
	end
end

return {
	give_dollar_reward = give_dollar_reward,
	remove_dollar = remove_dollar,
	give_dollar_reward_routine = give_dollar_reward_routine,
}
