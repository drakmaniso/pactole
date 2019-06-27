'use strict'

function log(msg) {
  console.log(`${msg}`)
}

let service = null

export function setup(serv) {
  service = serv

  navigator.serviceWorker.onmessage = event => {
    log(`Received ${event.data.title}.`)
    switch (event.data.title) {
      case 'accounts':
        ledger.updateAccounts(event.data.content)
        break

      case 'categories':
        ledger.updateCategories(event.data.content)
        break

      case 'transactions':
        ledger.updateTransactions(event.data.content)
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
