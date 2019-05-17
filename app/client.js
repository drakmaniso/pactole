'use strict'

function log(msg) {
  console.log(`[client] ${msg}`)
}

let service = null
let updateListeners = []
let accountsListeners = []

export function setup(serv) {
  service = serv

  navigator.serviceWorker.onmessage = (event) => {
    log(`Received ${event.data.msg}.`)
    switch(event.data.msg) {
      case 'update':
        for(const f of updateListeners) {
          f(event.data)
        }
        break
      case 'accounts':
        for(const f of accountsListeners) {
          f(event.data)
        }
        break
    }
  }
}

export function send(message) {
  log(`Sending ${message.msg} to service...`)
  service.postMessage(message)
}

export function addUpdateListener(func) { updateListeners.push(func) }
export function addAccountsListener(func) { accountsListeners.push(func) }
