local paths = {
	-- ChapterCode -> 스크립트 경로
	--[10019] = 'stageeventcontrollers/NpcPool/PixyWorldPooledNpcConstants',

	-- Main

	-- Nightmare

	-- ShortStory
	[70014] = 'stageeventcontrollers/NpcPool/ShortStory/MilkyWayPooledNpcConstants',
}

local cached_constants = nil

return {
	get_stage_constants = function(chapter_code, stage_name)
		if cached_constants == nil then
			local path = paths[chapter_code]

			cached_constants = get_or_create_global_variable(path)
		end

		return cached_constants[stage_name]
	end
}
