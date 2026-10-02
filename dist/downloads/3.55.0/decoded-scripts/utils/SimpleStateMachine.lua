SimpleStateMachine = newclass('SimpleStateMachine')

function SimpleStateMachine:init()
	self.current_state = nil
end

function SimpleStateMachine:dispose()
	if self.current_state then
		self.current_state:exit(nil)
		self.current_state:dispose()
	end
	self.current_state = nil
end

function SimpleStateMachine:change_state(state)
	local prev_state = self.current_state

	if prev_state then
		prev_state:exit(state)
	end

	self.current_state = state
	if self.current_state then
		self.current_state:enter(prev_state)
	end

	if prev_state then
		prev_state:dispose()
	end
end
