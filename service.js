'use strict'

function log(msg) {
  console.log(`* ${msg}`)
}

oninstall = event => {
  log('Installing service...')
  event.waitUntil(
    caches
      .open('pactole')
      .then(cache => {
        return cache.addAll([
          './',
          'favicon.ico',
          'manifest.json',
          'styles/main.css',
          'styles/normalize.css',
          'styles/palette.css',
          'styles/fonts/fa-solid-900.woff2',
          'styles/fonts/fa-solid.css',
          'scripts/calendar.js',
          'scripts/ledger.js',
          'scripts/main.js',
          'scripts/page.js',
          'scripts/settings.js',
          'images/icon-192x192.png',
          'images/icon-512x512.png',
        ])
      })
      .then(() => {
        log('done caching.')
      })
      .catch(err => {
        console.error(err)
      }),
  )
  log('...service installed.')
}

onactivate = event => {
  log('Activating service...')
  event.waitUntil(
    caches.keys().then(names => {
      return Promise.all(
        names
          .filter(n => {
            // Return true to remove n from the cache
          })
          .map(n => {
            return caches.delete(n)
          }),
      )
    }),
  )
  log('...service activated.')
}

onfetch = event => {
  // log(`fetch: ${event.request.url}...`)
  event.respondWith(
    caches.match(event.request).then(response => {
      if (response) {
        return response
      }
      console.error(`* CACHE FAIL: ${event.request.url}`)
      return fetch(event.request)
    }),
  )
}

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
