
ns main

import stdrpc
import namezlib

do-rpc-periodically = proc(client)
	call(proc(counter)
		while( true
			call(proc()
				ok err px = call(namezlib.get-service client 'my-service'):
				ret-value = if( ok
					call(stdrpc.rcall px 'my-service' counter)
					list(ok err px)
				)
				_ _ received-counter = ret-value:
				_ = print('rcall -> ' ret-value)

				import stdtime
				_ = call(stdtime.sleep 1)

				plus(get(received-counter 'counter') 1)
			end)
			'none'
		)
	end 0)
end

main = proc()
	client-ref = call(namezlib.init-client)
	call(do-rpc-periodically client-ref)
end

endns
