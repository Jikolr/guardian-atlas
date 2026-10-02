local local_class = newclass("HellForestMadPanda")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	-- 스테이지 시작 이벤트 구독
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageStartEvent), 'on_state_start_event')
	-- 보스 타이틀 로드
	local pool = unity_object_pool.GetOrCreate("boss_title")
	coroutine.yield(unity_object_pool.WaitUntilLoaded(pool))
end

function local_class:launch_routine(_)
	-- 보스 타이틀 중에 일시정지가 가능해져서 꼬이는 문제가 존재하여 Hide 처리
	field_ui_manager:Hide()
	-- 보스
	self.boss = get_character('boss')
	-- 보스 위치로 카메라 이동
	camera_util.move_to_target_async(self.boss, 0)

	screen_util.fade_in(0, unity_class.color.black, 'linear')
	screen_util.fade_in_circular(1, 'ease_in_out_sine')

	wait_for_sec(0.75)

	-- 보스 타이틀 출력
	screen_util.show_boss_title(
		'hell_forest_main_boss_title', 'hell_forest_main_boss_subtitle', 2, false
	)
	wait_for_sec(1.5)

	-- 보스 위치로 카메라 이동
	camera_util.return_to_leader(1)

	wait_for_sec(0.5)

	field_ui_manager:Show()
end

function local_class:on_state_start_event(_)
	self.boss = get_character('boss')
	message_system:Publish(CS.Oak.ShowBossHPEvent.Create(self.boss))
end

function local_class:dispose()
	-- 스테이지 시작 이벤트 구독 취소
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_state_start_event')
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
