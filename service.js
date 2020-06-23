'use strict'

const files = [
  './',
  'favicon.ico',
  'manifest.json',
  'elm.js',
  'fonts/fa-solid-900.woff2',
  'fonts/work-sans-v7-latin-regular.woff2',
  'fonts/work-sans-v7-latin-700.woff2',
  'images/icon-512x512.png',
]

function log(msg) {
  console.log(`[SW] ${msg}`)
}

function error(msg) {
  console.error(`[SW] ${msg}`)
}

oninstall = event => {
  log('Installing service...')
  event.waitUntil(
    caches
      .open('pactole')
      .then(cache => {
        log('...installing cache...')
        return cache.addAll(
          files.map(f => {
            return new Request(f, { cache: 'no-store' })
          }),
        )
      })
      .then(() => {
        log('...service installed.')
        return self.skipWaiting()
      })
      .catch(err => {
        error(err)
      }),
  )
}

onactivate = event => {
  log('Activating service...')
  event.waitUntil(
    clients.claim().then(
      caches
        .keys()
        .then(names => {
          return Promise.all(
            names
              .filter(n => {
                // Return true to remove n from the cache
              })
              .map(n => {
                return caches.delete(n)
              }),
          )
        })
        .then(() => {
          log('...service activated.')
        }),
    ),
  )
}

onfetch = event => {
  log(`fetch: ${event.request.url}...`)
  event.respondWith(
    caches.match(event.request).then(response => {
      if (response) {
        //log(`Fetch cached: ${event.request.url}`)
        return response
      }
      error(`CACHE FAIL: ${event.request.url}`)
      //return
      return fetch(event.request, { cache: 'no-store' })
    }),
  )

  event.waitUntil(
    caches
      .open('pactole')
      .then(cache => {
        return fetch(event.request).then(response => {
          log(`updating cache for ${event.request.url}`)
          return cache.put(event.request, response)
        })
      })
  )
}

onmessage = event => {
  const msg = event.data

  log(`Received "${msg.title}" from client ${event.source} ${event.origin}`)
  switch (msg.title) {
    case 'get account list':
      respond(event, 'set account list', ["Fool", "Babar"])
      break
    case 'storeLedger':
      respond(event, 'BOOYA!', null)
      broadcast('updateLedger', null)
      break
  }
}


function respond(event, title, content) {
  log(`Responding "${title}" to client ${event.source}...`)
  event.source.postMessage({ title: title, content: content })
}


function broadcast(title, content) {
  return clients.matchAll({ includeUnctonrolled: true }).then(clients => {
    log(`Broadcasting "${title}" to ${clients.length} client(s)...`)
    for (const c of clients) {
      c.postMessage({ title: title, content: content })
    }
  })
}
