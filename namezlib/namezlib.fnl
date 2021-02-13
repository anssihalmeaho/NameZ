
ns namezlib

import stdrpc
import stdvar
import valuview
import stdos

registry-addr = call(proc()
	import stddbc

	addr-found addr = call(stdos.getenv 'NAMEZ_SERVER_ADDR'):
	_ = call(stddbc.assert addr-found 'NAMEZ_SERVER_ADDR not found')
	addr
end)

valuserver-addr = call(proc()
	import stddbc

	addr-found addr = call(stdos.getenv 'NAMEZ_VS_ADDR'):
	_ = call(stddbc.assert addr-found 'NAMEZ_VS_ADDR not found')
	addr
end)

# service provider registers service
register-service = proc(service-name addr)
	px = call(stdrpc.new-proxy registry-addr)
	call-ok call-err retval = call(stdrpc.rcall px 'reg-service-provider' service-name addr):
	if( call-ok
		retval
		list(false call-err '')
	)
end

# init client
init-client = proc()
	client = call(valuview.new-view valuserver-addr 'apis' func(item) true end)
	call(stdvar.new client)
end

# get-service returns service provider for service name
get-service = proc(client-ref service-name)
	client = call(stdvar.value client-ref)
	has-value value = call(valuview.value client):

	import stdfu
	has-item err-text serv-addr = if( has-value
		call(proc()
			slist = call(stdfu.filter value func(sm) eq(get(sm 'service-name') service-name) end)
			if( empty(slist)
				list(false 'this service not found' 'none')
				list(true '' get(head(slist) 'addr'))
			)
		end)

		call(proc()
			import stdtime

			_ = call(stdtime.sleep 1)
			has-value-retry value-retry = call(valuview.value client):

			if( has-value-retry
				call(proc()
					slist = call(stdfu.filter value-retry func(sm) eq(get(sm 'service-name') service-name) end)
					if( empty(slist)
						list(false 'this service not found' 'none')
						list(true '' get(head(slist) 'addr'))
					)
				end)
				list(false 'service not found' 'none')
			)
		end)
	):
	if( has-item
		list(true '' call(stdrpc.new-proxy serv-addr))
		list(false err-text serv-addr)
	)
end

endns

