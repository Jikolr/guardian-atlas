local local_class = newclass('QTEEvent')

function local_class:init()
	-- 로드 시간 기다려줄 것
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')
	CS.Oak.CommonScreenplay.PreloadTutorialSpine()

	-- swite 타입
	self.swipe_type = ''

	-- 탭 카운트
	self.turbo_tap_count = 0

	-- qte 시작 변수
	self.is_qte_start = false

	-- time mod key값
	self.time_mod_key = 'qte'

	-- sfx name
	self.tap_sfx_name = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.TouchEvent) then
		return self:on_touch_event(e)
	end

	return false
end

function local_class:on_touch_event(e)
	if not self.is_qte_start then
		return false
	end

	if e.TouchEventType == CS.Oak.TouchEventType.SwipeLeft then
		self.swipe_type = 'left'
		return true
	elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeRight then
		self.swipe_type = 'right'
		return true
	elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeUp then
		self.swipe_type = 'up'
		return true
	elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeDown then
		self.swipe_type = 'down'
		return true
	elseif e.TouchEventType == CS.Oak.TouchEventType.TouchDown then
		if self.tap_sfx_name then
			music_player_util.play_sfx_one_shot(self.tap_sfx_name)
		end
		self.swipe_type = 'tap'
		self.turbo_tap_count = self.turbo_tap_count + 1
		return true
	end

	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	self.tap_sfx_name = nil
end

--- QTE 함수
--- @param type nil key: qte 타입
--- @param duration number key: qte 제한시간
--- @param is_wait boolean key: 성공 시에도 duration 시간만큼 기다려줄지
--- @param time_mod number key: qte 시간동안 타임 스케일을 줄여줄 것인지
--- @return boolean key: duration 이후 qte 성공 시 true 실패 시 false
function local_class:qte_swipe(data)
	local type = lua_helper.get_value(data, 'type', 'tap')
	local duration = lua_helper.get_value(data, 'duration', 9999)
	local is_wait = lua_helper.get_value(data, 'is_wait', false)
	local time_mod = lua_helper.get_value(data, 'time_mod', nil)

	if type == 'tap' then
		CS.Oak.CommonScreenplay.ShowTap()
	else
		CS.Oak.CommonScreenplay.QTESwipe(type)
	end

	self.swipe_type = ''
	self.is_qte_start = true
	local time_passed = 0

	if time_mod ~= nil then time_util.mod(self.time_mod_key, time_mod) end

	while self.is_qte_start and self.swipe_type ~= type and time_passed < duration do
		coroutine.yield()

		time_passed = time_passed + unity_class.time.deltaTime
	end

	self.is_qte_start = false
	CS.Oak.CommonScreenplay.CloseTutorialSpine()

	if time_mod ~= nil then time_util.unmod(self.time_mod_key) end

	-- 실패시
	if self.swipe_type ~= type then return false end

	-- 기다리는 경우
	while is_wait and time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield()
	end

	return true
end

--- 터치 연타함수
--- @param duration number key: qte 연타 제한시간
--- @param is_wait boolean key: 성공 시에도 duration 시간만큼 기다려줄지
--- @param time_mod number key: qte 연타 시간동안 타임 스케일을 줄여줄 것인지
--- @param pre_delay number key: qte 연타 시작 시 일정 시간동안 입력을 받지 않고 싶을 때 사용
--- @param count number key: qte 연타 성공을 위한 횟수
--- @param animation_time_scale number key: qte 스파인 손가락 애니메이션 빠르기
--- @param tap_sfx nil key: qte 터치 시 마다 재생할 sfx
--- @return boolean key: duration 이후 연타 성공 시 true 실패 시 false
function local_class:turbo_tap(data)
	local duration = lua_helper.get_value(data, 'duration', 9999)
	local is_wait = lua_helper.get_value(data, 'is_wait', false)
	local time_mod = lua_helper.get_value(data, 'time_mod', nil)
	local delay = lua_helper.get_value(data, 'pre_delay', nil)
	local count = lua_helper.get_value(data, 'count', 1)
	local animation_time_scale = lua_helper.get_value(data, 'animation_time_scale', 1)
	self.tap_sfx_name = lua_helper.get_value(data, 'tap_sfx', nil)

	music_player_util.play_sfx_one_shot('01_tap_guide_01')
	CS.Oak.CommonScreenplay.ShowTurboTap(animation_time_scale)

	if time_mod ~= nil then time_util.mod(self.time_mod_key, time_mod) end
	if delay then wait_for_sec(delay) end

	local time_passed = 0

	self.turbo_tap_count = 0
	self.is_qte_start = true

	while self.is_qte_start and self.turbo_tap_count < count and time_passed < duration do
		coroutine.yield()

		time_passed = time_passed + unity_class.time.deltaTime
	end

	if time_mod ~= nil then time_util.unmod(self.time_mod_key) end

	self.is_qte_start = false
	CS.Oak.CommonScreenplay.CloseTutorialSpine()

	-- 실패시
	if self.turbo_tap_count < count then return false end

	-- 기다리는 경우
	while is_wait and time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield()
	end

	return true
end

return {
	create = function(quest_id)
		return local_class(quest_id)
	end
}
