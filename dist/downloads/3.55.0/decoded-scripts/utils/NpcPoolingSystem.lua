---@class LuaNpcPoolingSystem
local local_class = newclass('NpcPoolingSystem')
local npc_pool = newclass('NpcPool')

local nowhere = vector(999, 0, 999)

local origin_skin_names = {}

local common_dispose_actions = {
	anim = function(npc)
		character_util.remove_anim(npc)
		-- 애니메이션 업데이트가 제대로 되지 않는 문제가 있어서, 강제로 스파인 업데이트를 해줌
		-- FIXME : 더 좋은 방법은 없을까??
		npc.SpineController:ForceUpdateSpines(1)
	end,

	upper_anim = function(npc)
		character_util.remove_anim(npc, true)

		npc.SpineController:ForceUpdateSpines(1)
	end,

	emotion = function(npc)
		character_util.remove_emotion(npc)
	end,

	talk_key = function(npc)
		npc.Interactable.Talk = nil
	end,

	talk_sfx = function(npc)
		npc.Interactable.TalkSfx = nil
	end,

	talk_scale = function(npc)
		npc.Interactable.BubbleScale = 1
	end,

	bubble_type = function(npc)
		npc.Interactable.BubbleType = CS.Oak.SpeechBubbleNew.BubbleType.Talk
	end,

	add_color = function(npc)
		character_util.remove_color(npc, npc.Name, 0)

		npc.SpineController:ForceUpdateSpines(0.1)
	end,

	set_alpha = function(npc)
		character_util.spine_set_alpha_fade(npc, 1, 0)

		npc.SpineController:ForceUpdateSpines(0.1)
	end,

	emoticon = function(npc)
		npc.Interactable = CS.Oak.NPCInteractable.Create()
	end,
	
	change_skin = function(npc)
		local skin_name = origin_skin_names[npc.Name]

		if skin_name == nil then
			return
		end

		npc.SpineController.SkinName = skin_name
		origin_skin_names[npc.Name] = nil
	end,

	set_attachment = function(npc)
		character_util.spine_remove_attachment(npc, '[base]weapon1')
		character_util.spine_remove_attachment(npc, '[base]weapon2')
	end,

	shake = function(npc)
		character_util.stop_shake(npc)
	end,
}

---@class LuaNpcPoolHandler
local handler_base = {}

local handler_meta = {
	__index = handler_base
}

function local_class:init()
	self.pools = {}
end

function local_class:dispose()
	if self.pools ~= nil then
		for _, pool in pairs(self.pools) do
			pool:dispose()
		end

		self.pools = nil
	end
end

---@param data table<string, { prefix:string, count:number }>
function local_class:init_pools(data)
	for key, pool_data in pairs(data) do
		if self.pools[key] == nil then
			self.pools[key] = npc_pool(pool_data.prefix, pool_data.count)
		else
			logger_util.warning(string.format('Overwriting spec is not available. [Key : %s]', key))
		end
	end
end

---주의!!! 해당 NPC를 더 이상 사용하지 않게 되면(더 이상 보이지 않아도 되면) 꼭 dispose해줘야 함!!
---@param key string
---@param position Vector3
---@param direction Direction
---@return LuaNpcPoolHandler
function local_class:get_npc_handler(key, position, direction, is_fly)
	local pool = self.pools[key]
	local item = pool:get_item()

	if item == nil then
		logger_util.error(string.format('Not enough Pooled Npc [Key : %s]', key))

		-- 에러는 뱉었지만 일단 테스트 동작에는 문제 없게 하는 게 목적.
		item = pool:get_any_using_item()
	end

	field_object_util.set_active_state(item, active_state_type.enabled)
	character_util.set_position(item, position, is_fly)
	character_util.set_direction(item, direction)

	return setmetatable({
		---@private
		item = item,
		---@private
		pool = pool,
	}, handler_meta)
end

do
	---@return ICharacter | nil
	function handler_base:get_npc()
		return self.item
	end

	function handler_base:dispose()
		if self.item ~= nil then
			if self.dispose_actions ~= nil then
				for _, action in pairs(self.dispose_actions) do
					action(self.item)
				end

				self.dispose_actions = nil
			end

			character_util.set_position(self.item, nowhere)
			field_object_util.set_active_state(self.item, active_state_type.disabled)
		end

		if self.pool ~= nil then
			self.pool:return_item(self.item)

			self.item = nil
			self.pool = nil
		end
	end

	---@param key string | "'anim'" | "'upper_anim'" | "'emotion'" | "'talk_key'" | "'talk_sfx'"
	---@param action fun(npc:ICharacter):void | "function(npc) end"
	function handler_base:add_dispose_action(key, action)
		if self.pool == nil then
			return
		end

		if self.dispose_actions == nil then
			self.dispose_actions = {}
		end

		self.dispose_actions[key] = action
	end

	function handler_base:set_anim(version_holder, args)
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		scene_util.set_anim(npc, version_holder, args)

		if args.upper then
			self:add_dispose_action('upper_anim', common_dispose_actions.upper_anim)
		else
			self:add_dispose_action('anim', common_dispose_actions.anim)
		end
	end

	function handler_base:remove_anim(upper)
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		character_util.remove_anim(npc, upper)

		if upper then
			self:add_dispose_action('upper_anim', nil)
		else
			self:add_dispose_action('anim', nil)
		end
	end

	function handler_base:set_emotion(version_holder, args)
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		scene_util.set_emotion(npc, version_holder, args)

		self:add_dispose_action('emotion', common_dispose_actions.emotion)
	end

	function handler_base:remove_emotion()
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		character_util.remove_emotion(npc)

		self:add_dispose_action('emotion', nil)
	end

	function handler_base:set_add_color(color)
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		character_util.add_color(npc, npc.Name, color, 1, 0)
		npc.SpineController:ForceUpdateSpines(0.1)

		self:add_dispose_action('add_color', common_dispose_actions.add_color)
	end

	function handler_base:set_alpha(alpha)
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		character_util.spine_set_alpha_fade(npc, alpha, 0)
		npc.SpineController:ForceUpdateSpines(0.1)

		self:add_dispose_action('alpha', common_dispose_actions.set_alpha)
	end

	function handler_base:set_one_line(talk_key, talk_sfx, talk_scale, bubble_type)
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		if talk_key ~= nil then
			npc.Interactable.Talk = talk_key
			self:add_dispose_action('talk_key', common_dispose_actions.talk_key)
		end

		if talk_sfx ~= nil then
			npc.Interactable.TalkSfx = talk_sfx
			self:add_dispose_action('talk_sfx', common_dispose_actions.talk_sfx)
		end

		if talk_scale ~= nil then
			npc.Interactable.BubbleScale = talk_scale
			self:add_dispose_action('talk_scale', common_dispose_actions.talk_scale)
		end

		if bubble_type ~= nil then
			npc.Interactable.BubbleType = speech_bubble.bubble_type[bubble_type]
			self:add_dispose_action('bubble_type', common_dispose_actions.bubble_type)
		end

	end

	function handler_base:remove_one_line()
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		npc.Interactable.Talk = nil
		self:add_dispose_action('talk_key', nil)

		npc.Interactable.TalkSfx = nil
		self:add_dispose_action('talk_sfx', nil)
	end

	function handler_base:set_emoticon(emoticon_key, emoticon_sfx)
		local npc = self:get_npc()

		if emoticon_key == nil or npc == nil then
			return
		end

		npc.Interactable = CS.Oak.EmoticonInteractable.Create(emoticon_key)

		if emoticon_sfx ~= nil then
			npc.Interactable.InteractingSfx = emoticon_sfx
		end

		self:add_dispose_action('emoticon', common_dispose_actions.emoticon)
	end

	function handler_base:force_update_spines()
		local npc = self:get_npc()
		npc.SpineController:ForceUpdateSpines(0.1)
	end


	function handler_base:change_skin(skin_name)
		local npc = self:get_npc()

		if npc == nil then
			return
		end

		origin_skin_names[npc.Name] = skin_name
		npc.SpineController.SkinName = skin_name
		self:add_dispose_action('change_skin', common_dispose_actions.change_skin)
	end

	function handler_base:set_attachment(region)
		local npc = self:get_npc()

		if region == nil or npc == nil then
			return
		end

		if type_util.is_string(region) then
			character_util.spine_set_attachment(npc, '[base]weapon1', region)
		else
			character_util.spine_set_attachment(npc, region.slot, region.region)
		end

		self:add_dispose_action('set_attachment', common_dispose_actions.set_attachment)
	end

	function handler_base:set_shake(shake_value)
		local npc = self:get_npc()

		if shake_value == nil or shake_value <= 0 or npc == nil then
			return
		end

		character_util.shake(npc, shake_value, 99999)

		self:add_dispose_action('shake', common_dispose_actions.shake)
	end
end

do
	function npc_pool:init(prefix, count)
		self.prefix = prefix
		self.container = {}

		self.using_items = create_lua_hashset()

		for i = 1, count do
			self.container[i] = get_character(prefix .. i)
		end
	end

	function npc_pool:dispose()
		if self.using_items ~= nil then
			-- 원래라면 여기서 풀에 반환되지 않은 NPC들을 찍어줘야 한다.
			-- 다만 해당 풀의 dispose가 풀링NPC를 사용한 모든 스크립트의 dispose보다 늦게 불릴거라는 보장이 없다.
			-- 또한 스테이지를 나갈 때에만 호출되므로, 혹시라도 반환되지 않은 아이템이 있더라도 큰 문제가 발생하진 않을 것
			self.using_items:clear()
			self.using_items = nil
		end

		self.container = nil
	end

	function npc_pool:get_item()
		if #self.container == 0 then
			-- 바깥쪽에서 에러 로그 출력하게 함
			return nil
		end

		local item = self.container[#self.container]

		self.using_items:add(item)

		self.container[#self.container] = nil

		return item
	end

	function npc_pool:get_any_using_item()
		for npc in pairs(self.using_items) do
			return npc
		end
	end

	function npc_pool:return_item(item)
		if self.using_items == nil then
			return
		end

		if self.using_items:remove(item) then
			self.container[#self.container + 1] = item
		else
			logger_util.warning(string.format('Trying to return [Npc : %s] on Npc Pool Twice.', item.Name))
		end
	end
end

return {
	create = function()
		return local_class()
	end
}
