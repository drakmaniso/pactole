'use strict'

function log(msg) {
  console.log(`[client] ${msg}`)
}

if (!('serviceWorker' in navigator)) {
  log('FATAL: Service workers are not supported by the navigator.')
  throw(new Error('FATAL: Service workers are not supported by the navigator.'))
}

onload = () => {
  navigator.serviceWorker.register('/app/sw.js')
    .then((registration) => {
      log(`Service registration successful (scope: ${registration.scope})`)
      registration.onupdatefound = () => {
        let w = registration.installing
        log(`A new service is being installed`)
        w.onstatechange = (event) => {
          log(`Updated? ${event.target}`)
        }
      }
    })
    .catch((err) => {
      log(`Service registration failed: ${err}`)
    })
}

function sendToService(msg) {
  return new Promise((resolve, reject) => {
    const channel = new MessageChannel()

    channel.port1.onmessage = (event) => {
      if(event.data.error) {
        reject(event.data.error)
      } else {
        resolve(event.data)
      }
    }

    navigator.serviceWorker.controller.postMessage(msg, [channel.port2])
  })
}

function send(sw, msg) {
  return new Promise((resolve, reject) => {
    const channel = new MessageChannel()

    channel.port1.onmessage = (event) => {
      if(event.data.error) {
        reject(event.data.error)
      } else {
        resolve(event.data)
      }
    }

    sw.postMessage(msg, [channel.port2])
  })
}

navigator.serviceWorker.ready.then((registration) => {
	log(`Service ready.`)
	send(registration.active, 'Hi Service, this Client!')
		.then(m => log(`Message returned: ${m}`))
    .catch(e => log(`Message ERROR: ${e}`))
  fetch('/accounts.json')
    .then((response) => {
        return response.json()
      })
    .then((myJson) => {
        log(JSON.stringify(myJson))
      })
    .catch((e) => {
      log(e)
    })
})

