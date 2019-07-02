'use strict'

function log(msg) {
  console.log(`* ${msg}`)
}

oninstall = event => {
  log('Installing service...')
  event.waitUntil(skipWaiting())
  log('...service installed.')
}

onactivate = event => {
  log('Activating service...')
  event.waitUntil(clients.claim())
  log('...service activated.')
}

/*
onfetch = event => {
  //log(`Fetch: ${event.request.url}`)
  switch (event.request.url) {
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
*/

onmessage = event => {
  const msg = event.data
  log(`Received ${msg.title}.`)
  switch (msg.title) {
    case 'new transaction':
      send('transactions', null)
      break
  }
}

function send(title, content) {
  clients.matchAll({ includeUnctonrolled: true }).then(clients => {
    log(`Sending ${title} to ${clients.length} client(s)...`)
    for (const c of clients) {
      c.postMessage({ title: title, content: content })
    }
  })
}
