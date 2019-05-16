'use strict'

function log(msg) {
  console.log(`[service] ${msg}`)
}

oninstall = (event) => {
	log('Installed.')
}

onactivate = (event) => {
	event.waitUntil(clients.claim())
	log('Activated.')
}

onfetch = (event) => {
	//log(`Fetch: ${event.request.url}`)
	switch(event.request.url) {
    case 'http://localhost:8383/accounts.json':
			event.respondWith(new Response('{"name": "foobar"}'))
		default:
	}
//  event.respondWith(
//    caches.match(event.request)
//      .then(function(response) {
//         if (response) {
//           return response
//         }
//        return fetch(event.request)
//      }
//    )
//  )
}

onmessage = (event) => {
  log(`Received ${event.data.msg}.`)
  switch(event.data.msg) {
    case 'open':
      send({msg: 'update'})
      break
  }
}

async function send(message) {
  const all = await clients.matchAll({
    includeUnctonrolled: true
  })
  log(`Sending ${message.msg} to ${all.length} client(s)...`)
  for(const c of all) {
    c.postMessage(message)
  }
}
