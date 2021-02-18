
ns main

import stddbc
import stdtime
import stdrpc

import valulib

reg-service-provider = proc(vs-client)
	proc(service-name addr)
		#_ = print(sprintf('reg-service-provider: %s, %s' service-name addr))

		# lets take previous values for same servive away first (if any)
		take-function = eval(sprintf('func(x) eq(get(x \'service-name\') \'%s\') end' service-name))
		take-result = call(valulib.take-values vs-client 'apis' take-function)

		call(valulib.put-value vs-client 'apis' map('service-name' service-name 'addr' addr))
	end
end

unreg-service-provider = proc(vs-client)
	proc(service-name)
		#_ = print(sprintf('unreg-service-provider: %s' service-name))

		# lets take previous values for same servive away first (if any)
		take-function = eval(sprintf('func(x) eq(get(x \'service-name\') \'%s\') end' service-name))
		ok err taken = call(valulib.take-values vs-client 'apis' take-function):
		and(
			ok
			gt(len(taken) 0)
		)
	end
end

just-waiting = proc()
	call(proc()
		while( call(proc() _ = call(stdtime.sleep 10) true end) 'none')
	end)
end

main = proc()
	import stdos

	vs-addr-found vs-addr = call(stdos.getenv 'NAMEZ_VS_ADDR'):
	_ = call(stddbc.assert vs-addr-found 'NAMEZ_VS_ADDR not found')

	vs-client = call(valulib.new-client vs-addr)
	#_ = print('vs-client: ' vs-client)

	port-number-found port-number-value = call(stdos.getenv 'NAMEZ_PORT'):
	port-number = if(port-number-found port-number-value '9991')
	ok err server = call(stdrpc.new-server plus(':' port-number)):
	_ = call(stddbc.assert ok err)

	_ = call(stdrpc.register server 'reg-service-provider' call(reg-service-provider vs-client))
	_ = call(stdrpc.register server 'unreg-service-provider' call(unreg-service-provider vs-client))
	call(just-waiting)
end

endns
