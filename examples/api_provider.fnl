
ns main

import stdrpc
import stddbc
import stdtime

import namezlib

my-handler = proc(counter)
	_ = print('my-handler: received: ' counter)
	map('counter' plus(counter 1))
end

my-addr = 'localhost:9902'

main = proc()
		ok err server = call(stdrpc.new-server my-addr):
	_ = call(stddbc.assert ok err)

	_ = call(stdrpc.register server 'my-service' my-handler)
	_ = print('reg -> ' call(namezlib.register-service 'my-service' my-addr) )

	# just loop forever
	call(proc()
		while(call(proc()
			_ = call(stdtime.sleep 3)
			_ = print('...wait...')
			true
		end) 'none')
	end)
end

endns


