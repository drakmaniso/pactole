'use strict'

function log(msg) {
  console.log(`[client] ${msg}`)
}

let service = null

export function setup(serv) {
  service = serv

  navigator.serviceWorker.onmessage = (event) => {
    log(`Received ${event.data.msg}.`)
  }
}

export function send(message) {
  log(`Sending ${message.msg} to service...`)
  service.postMessage(message)
}
