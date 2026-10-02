local local_class = newclass('StageStartManager')

function local_class:init()
	local chapter_code = stage.Spec.ChapterCode.Value

	-- 챕터 코드에 의한 경로 (메인,서브,단편집,외전등 다 챕터 코드가 다름)
	local data_path = 'utils/StageStart/StageStart'..chapter_code

	local chapter_constants = get_or_create_global_variable(data_path)

	self.constants = chapter_constants[stage.Name]
end

function local_class:dispose()
	self.constants = nil
end

function local_class:stage_start(quest_progress)
	-- 데이터가 없으면 default_start 위치로 출력
	if self.constants == nil then
		self:default_start_stage()
		return
	end

	local start_data

	-- quest_progress 체크
	if quest_progress == nil or quest_progress.IsComplete then
		-- 퀘스트 없음 or 완료된 퀘스트일 경우 default_start
		start_data = self.constants['default_start']
	else
		-- InnerProgress 기준 으로 세팅
		local progress = quest_progress.InnerProgress

		start_data = self.constants['start_data_list'][progress]

		-- 설정 된 프로그레스가 없으면 default_start로
		if start_data == nil then
			start_data = self.constants['default_start']
		end
	end

	-- 여기 까지 없으면 default_start 위치로 출력
	if start_data == nil then
		self:default_start_stage()
		return
	end

	local pos, dir, directional_stage_entry, play_stage_music

	directional_stage_entry = lua_helper.get_or_default(start_data.directional_stage_entry, true)
	play_stage_music = lua_helper.get_or_default(start_data.play_stage_music, true)

	-- 마커 세팅
	if start_data.marker_key == nil then
		pos = start_data.position
	-- skip이 들어올 경우
	elseif start_data.marker_key == 'skip' then
		-- StageStartEvent는 보내주는게 좋을지 좀 더 사용된 곳을 찾아봐야함
		return
	else
		pos = field_util.get_marker_pos(start_data.marker_key)
	end

	-- direction 세팅, direction 수치가 있으면 우선, 없으면 마커에 direction 기준
	if start_data.direction ~= nil then
		dir = start_data.direction
	elseif start_data.marker_key ~= nil and start_data.direction == nil then
		dir = field_util.get_marker_dir(start_data.marker_key)
	end

	stage_launch_util.play_launch_stage_ignore_disabled_member(dir,
			pos, directional_stage_entry, play_stage_music)
end

function local_class:default_start_stage()
	local default_start_marker = field_util.get_marker('default_start')

	stage_launch_util.play_launch_stage_ignore_disabled_member(default_start_marker.direction,
			default_start_marker.position, true, true)
end

return {
	create = function()
		return local_class()
	end
}
