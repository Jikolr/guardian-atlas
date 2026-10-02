local local_class = newclass('Test')

--- 여기에 테스트 코드 작성
function local_class:start()
	coroutine_manager:StartCoroutine(stage_camera, util.cs_generator(self.routine))
end

function local_class:routine()
	wait_for_sec(1)
	print('[#3] 1')
	coroutine.yield(nil)
	print('[#3] 2')
end

return { create = function() return local_class() end }
