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
  console.log(`* ${msg}`)
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
      })
      .catch(err => {
        console.error(err)
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
  //log(`fetch: ${event.request.url}...`)
  event.respondWith(
    caches.match(event.request).then(response => {
      if (response) {
        //log(`cached: ${event.request.url}`)
        return response
      }
      console.error(`* CACHE FAIL: ${event.request.url}`)
      //return
      return fetch(event.request, { cache: 'no-store' })
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
    case 'update application':
      log('Updating application...')
      event.waitUntil(
        caches
          .open('pactole')
          .then(cache => {
            log('...updating cache...')
            //return cache.addAll(files)
            return cache.addAll(
              files.map(f => {
                return new Request(f, { cache: 'reload' })
              }),
            )
          })
          .then(() => {
            return send('reload')
          })
          .then(() => {
            log('...application updated.')
          })
          .catch(err => {
            console.error(err)
          }),
      )
      break
  }
}

function send(title, content) {
  return clients.matchAll({ includeUnctonrolled: true }).then(clients => {
    log(`Sending ${title} to ${clients.length} client(s).`)
    for (const c of clients) {
      c.postMessage({ title: title, content: content })
    }
  })
}
