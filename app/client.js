'use strict'

function log(msg) {
  console.log(`${msg}`)
}

let accounts, categories, transactions, transactionsByDate

let updateListeners = []

let service = null

export function setup(serv) {
  service = serv

  navigator.serviceWorker.onmessage = event => {
    log(`Received ${event.data.msg}.`)
    switch (event.data.msg) {

      case 'update accounts':
        accounts = new Map()
        for (const a of event.data.accounts) {
          accounts.set(a.name, a)
        }
        break

      case 'update categories':
        categories = new Map()
        for (const c of event.data.categories) {
          categories.set(c.name, c)
        }
        break

      case 'update transactions':
        transactions = event.data.transactions
        for (const t of transactions) {
          if (!transactionsByDate.get(t.date)) {
            transactionsByDate.set(t.date, [])
          }
          transactionsByDate.get(t.date).push(t)
        }
        break
        

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
