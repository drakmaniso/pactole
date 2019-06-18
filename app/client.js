'use strict'

function log(msg) {
  console.log(`[client] ${msg}`)
}

let service = null
let updateListeners = []

export function setup(serv) {
  service = serv

  navigator.serviceWorker.onmessage = event => {
    log(`Received ${event.data.msg}.`)
    switch (event.data.msg) {
      case 'update':
        for (const f of updateListeners) {
          f(event.data)
        }
        break
    }
  }
}

export function send(message) {
  log(`Sending ${message.msg} to service...`)
  return new Promise((resolve, reject) => {
    const chan = new MessageChannel()
    chan.port1.onmessage = event => {
      log(`received reply ${event.data}`)
      if (event.data.error) {
        reject(event.data.error)
      } else {
        resolve(event.data)
      }
    }
    service.postMessage(message, [chan.port2])
  })
}

export function addUpdateListener(func) {
  updateListeners.push(func)
}
