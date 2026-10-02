local controller_base = get_or_create_global_variable('Quest/Base/QuestControllerBase')

---@class "$NAME$" : QuestControllerBase
local local_class = newclass('"$NAME$"', controller_base)

function local_class:init(cs_controller)
	self.super:init(cs_controller)

	-- 사용할 섹션 스크립트 정보. 주석 해제하고 사용
	self.script_config = {
		HasPreSection = "$HAS_PRE_SECTION$",
		NormalSectionCount = "$NORMAL_SECTION_COUNT$",
		HasPostSection = "$HAS_POST_SECTION$"
	}

	self.scene_version = scene_util.default_version + 1
end

function local_class:load_resource()
end

function local_class:dispose()
	self.super:dispose()
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded()
end

function local_class:on_stage_end()
end

return local_class
