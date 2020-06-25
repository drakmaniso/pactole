'use strict'


// SERVICE WORKER CALLBACKS ///////////////////////////////////////////////////


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


const cacheVersion = 'pactole-v0'


self.addEventListener('install', event => {
  log('Installing service worker...')
  event.waitUntil(
    caches
      .open(cacheVersion)
      .then(cache => {
        log('...installing cache...')
        return cache.addAll(
          files.map(f => {
            return new Request(f, { cache: 'no-store' })
          })
        )
      })
      .then(() => {
        log('...service worker installed.')
        return self.skipWaiting()
      })
      .catch(err => {
        error(err)
      })
  )
})
 

self.addEventListener('activate', event => {
  log('Service worker activated.')
  event.waitUntil(
    clients.claim()
      .then(
        caches.keys()
          .then(names => {
            return Promise.all(
              names
                .filter(n => {
                  // Return true to remove n from the cache
                  return n != cacheVersion
                })
                .map(n => {
                  return caches.delete(n)
                })
            )
          })
      )
      .catch(err => {
        error(err)
      })
  )
})


self.addEventListener('fetch', event => {
  //log(`fetch: ${event.request.url}...`)
  event.respondWith(
    caches.match(event.request)
  )
})


self.addEventListener('message', event => {
  const msg = event.data

  log(`Received "${msg.title}" from client.`)
  switch (msg.title) {
    case 'get account list':
      getSetting('accounts')
        .then(accounts => {
          log (`accounts = ${accounts}`)
          respond(event, 'set account list', accounts)
        })
        .catch(err => error(`get account list: ${err}`))
      break

    case 'get ledger':
      getLedger(msg.content)
        .then(transactions => {
          respond(event, 'set ledger', {transactions: transactions})
        })
        .catch(err => error(`get ledger: ${err}`))
      break

    case 'add transaction':
      try {
        const {
          account, date, amount, description
        } = msg.content
        addTransaction(account, {date: date, amount: amount, description: description, reconciled: false})
          .then(() => {
            broadcast('ledger updated', account)
          })
      }
      catch(err) {
        error(`add transaction: ${err}`)
      }
      break

    case 'put transaction':
      try {
        const {
          account, id, date, amount, description
        } = msg.content
        putTransaction(account, {id: id, date: date, amount: amount, description: description, reconciled: false})
          .then(() => {
            broadcast('ledger updated', account)
          })
      }
      catch(err) {
        error(`put transaction: ${err}`)
      }
      break

    case 'delete transaction':
      try {
        const {
          account, id
        } = msg.content
        deleteTransaction(account, id)
          .then(() => {
            broadcast('ledger updated', account)
          })
      }
      catch(err) {
        error(`delete transaction: ${err}`)
      }
      break
  }
})


function respond(event, title, content) {
  log(`Responding "${title}" to client...`)
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


// SETTINGS DATABASE ////////////////////////////////////////////////////////////////////


let _settingsDB


function openSettings() {
  return new Promise((resolve, reject) => {

    if (_settingsDB != null) {
      resolve(_settingsDB)
      return
    }

    log(`Opening settings database...`)
    let req = indexedDB.open("settings", 1)
    req.onerror = () => reject(new Error(`failed to open settings database: ${req.error}`))
    req.onblocked = () => log('settings database blocked...')

    req.onupgradeneeded = () => {
      log(`Upgrading settings database...`)
      const db = req.result
      const os = db.createObjectStore('settings')
      os.transaction.oncomplete = () => {
        const tr = db.transaction('settings', 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('settings')
        os.add(['Mon Compte'], 'accounts')
        os.add('calendar', 'defaultMode')
        os.add(false, 'categoriesEnabled')
        os.add(
          [
            {name: 'Autre', icon: ''},
            {name: 'Maison', icon: ''},
            {name: 'Santé', icon: ''},
            {name: 'Nourriture', icon: ''},
            {name: 'Habillement', icon: ''},
            {name: 'Transports', icon: ''},
            {name: 'Loisirs', icon: ''},
          ],
          'categories'
        )
        os.add(false, 'reconciliationEnabled')
        os.add(false, 'summaryEnabled')
        }
      log(`...settings database upgraded.`)
    }

    req.onsuccess = () => {
      const db = req.result
      _settingsDB = db
      db.onerror = event => {
        //TODO
        error(`settings database error: ${event.target.errorCode}`)
      }
      log(`...settings database opened.`)
      resolve(db)
    }
  })
}


function getSetting(key) {
  return new Promise((resolve, reject) => {
    openSettings()
      .then(db => {
        const tr = db.transaction('settings', 'readonly')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('settings')
        const req = os.get(key)
        req.onerror = () => reject(req.error)
        req.onsuccess = event => {
          resolve(req.result)
        }
      })
      .catch(err => reject(err))
  })
}


// LEDGERS DATABASES //////////////////////////////////////////////////////////


function ledgerName(account) {
  return `ledger:${account}`
}


let _ledgersDB = new Map()


function openLedger(account) {
  const name = ledgerName(account)
  return new Promise((resolve, reject) => {

    if (_ledgersDB.has(name)) {
      resolve(_ledgersDB.get(name))
      return
    }

    log(`Opening ledger database for "${account}"...`)
    let req = indexedDB.open(name, 1)
    req.onerror = () => reject(new Error(`failed to open ledger database for "${account}": ${req.error}`))
    req.onblocked = () => log(`ledger database for "${account}" blocked...`)

    req.onupgradeneeded = () => {
      log(`Upgrading ledger database for "${account}"...`)
      const db = req.result
      const os = db.createObjectStore('transactions', {keyPath: 'id', autoIncrement: true})
      os.createIndex('date', 'date')
      os.createIndex('category', 'category')
      log(`...ledger database for "${account}" upgraded.`)
    }

    req.onsuccess = () => {
      const db = req.result
      _ledgersDB.set(name, db)
      db.onerror = event => {
        //TODO
        error(`database error: ${event.target.errorCode}`)
      }
      log(`...ledger database for "${account}" opened.`)
      resolve(db)
    }
  })
}


function getLedger(account) {
  return new Promise((resolve, reject) => {
    openLedger(account)
      .then(db => {
        const tr = db.transaction('transactions', 'readonly')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('transactions')
        const req = os.getAll()
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}

/*
function getTransactionKeys(date) {
  return new Promise((resolve, reject) => {
    const errhandler = event => {
      reject(new Error(`getTransactionKeys('${date}'): ${event.target.error}`))
    }
    const tr = _database.transaction('transactions', 'readonly')
    tr.onerror = errhandler

    const os = tr.objectStore('transactions')
    const idx = os.index('date')
    const req = idx.getAllKeys(date)
    req.onerror = errhandler
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}


function getTransaction(key) {
  return new Promise((resolve, reject) => {
    const errhandler = event => {
      reject(new Error(`getTransaction('${key}): ${event.target.error}`))
    }
    const tr = _database.transaction('transactions', 'readonly')
    tr.onerrror = errhandler
    const os = tr.objectStore('transactions')
    const req = os.get(key)
    req.onerror = errhandler
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}
*/

function addTransaction(account, transaction) {
  return new Promise((resolve, reject) => {
    openLedger(account)
      .then(db => {
        const tr = db.transaction('transactions', 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('transactions')
        const req = os.add(transaction)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


function putTransaction(account, transaction) {
  return new Promise((resolve, reject) => {
    openLedger(account)
      .then(db => {
        const tr = db.transaction('transactions', 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('transactions')
        const req = os.put(transaction)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


function deleteTransaction(account, id) {
  return new Promise((resolve, reject) => {
    openLedger(account)
      .then(db => {
        const tr = db.transaction('transactions', 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('transactions')
        const req = os.delete(id)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


// UTILITIES //////////////////////////////////////////////////////////////////


function log(msg) {
  console.log(`[SW] ${msg}`)
}


function error(msg) {
  console.error(`[SW] ${msg}`)
}
