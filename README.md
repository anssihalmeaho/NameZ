# NameZ
Name server for FunL RPC.

[FunL programming language](https://github.com/anssihalmeaho/funl) supports [RPC communication](https://github.com/anssihalmeaho/funl/wiki/stdrpc) between processes.

NameZ implements name service for FunL RPC API endpoints.

It works in following way:

* API provider registers service to NameZ: service name (string) -> address (IP:port, string)
* API client asks API endpoint address by service name (gets address of provider)

## NameZ components

NameZ solution consists of following parts:

1. **namezlib** is interface for client and provider to NameZ
2. **namezerver** is server process which receives registrations (from API provider via RPC)
3. **valuserver** serving as store service endpoint data. See [valuserver](https://github.com/anssihalmeaho/valuserver) for more information.

API provider calls **namezlib** for adding service endpoint.
Service data is sent from **namezlib** to **namezerver** which stores it to **valuserver**.

Client process calls **namezlib** for getting address of given service.
Service data is maintained in cache behind **namezlib** (which uses **valuview** library for maintaining that from **nameserver**).

Note that client can inquire service data whenever it needs that without big performance penalty as data is cached.

### Environment Variables

There are several environment variables that NameZ assumes:

Environment Variable | Meaning | Needed in | Mandatory
-------------------- | ------- | --------- | ---------
NAMEZ_VS_ADDR | address of valuserver | namezlib, namezerver | Yes
NAMEZ_SERVER_ADDR | address of namezerver | namezlib | Yes
NAMEZ_PORT | port number of namezerver | namezerver | No, default value is '9991'

## namezlib provided interface
There are following services for API user/client and API provider to use.

### For API user/client

#### init-client
Returns new client data structure.

```
call(init-client) -> <opaque:var-ref>
```

#### get-service
Returns address for given service name.

```
call(get-service <client:var-ref> <service-name:string>) -> list(<ok:bool> <error-text:string> <service-address:string>)
```

### For API provider

#### register-service
API provider registers service endpoint. Service name (string) and address (string) are given as arguments.

```
call(register-service <service-name:string> <address:string>) -> list(<ok:bool> <error-text:string>)
```

#### unregister-service
API provider unregisters service endpoint. Service name (string) is given as argument.

```
call(unregister-service <service-name:string>) -> bool
```

Return value is true if the service was found, false if it was not found.

## Setup

### Setting up

#### Get FunL interpreter first
Make FunL interpreter first, see: https://github.com/anssihalmeaho/funl

```
git clone https://github.com/anssihalmeaho/funl.git
cd funl
make
```

-> **funla** is interpreter executable

#### Make valuserver and start it
See: https://github.com/anssihalmeaho/valuserver

```
git clone https://github.com/anssihalmeaho/valuserver
cd valuserver
make
./valuserver
```

#### Make namezerver and start it
Note that FUNLPATH needs to be set so that valuserver/clientlib is found.

```
export FUNLPATH=<directory having valuserver/clientlib>
export NAMEZ_VS_ADDR=localhost:9901
export NAMEZ_PORT=9911

./funla namezerver.fnl
```

#### Starting API providers and clients
Note that FUNLPATH needs to be set so that **valuserver/clientlib** and **NameZ/namezlib** is found.

Get NameZ codes from Github:

```
git clone https://github.com/anssihalmeaho/NameZ.git
```

Then setup environment variables:

```
export FUNLPATH=<directory having NameZ/namezlib and valuserver/clientlib>
export NAMEZ_VS_ADDR=localhost:9901
export NAMEZ_SERVER_ADDR=localhost:9911
```

Then start providers and clients with **funla**.

## Example
Here is example of one API provider and one API client.
Client periodically asks service address from NameZ and makes RPC to service provider.
API client and provider both increase counter and send it to each other.

### API provider

```
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
```

### API client

```
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
```

### Output
Set environment variables and start **valuserver** and **namezerver**.

Then start API provider and client.

Provider output:

```
./funla api_provider.fnl

reg -> list(true, '')
...wait...
my-handler: received: 0
my-handler: received: 2
...wait...
my-handler: received: 4
my-handler: received: 6
my-handler: received: 8
...wait...
my-handler: received: 10
...wait...
```

Client output:

```
./funla api_client.fnl

rcall -> list(true, '', map('counter' : 1))
rcall -> list(true, '', map('counter' : 3))
rcall -> list(true, '', map('counter' : 5))
rcall -> list(true, '', map('counter' : 7))
rcall -> list(true, '', map('counter' : 9))
rcall -> list(true, '', map('counter' : 11))
```

## To do
There should be supervision so that **namezerver** would supervise existence of API provider.
This could be done **namezlib** implementing special supervision RPC API which **namezerver** would call (RPC).
In case of supervision failure service data would be removed from **valuserver**.

This is to be done in future.

