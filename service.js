'use strict'


// SERVICE WORKER CALLBACKS ///////////////////////////////////////////////////


const files = [
  './',
  'favicon.ico',
  'manifest.webmanifest',
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
  //TODO: handle favicon?
  event.respondWith(
    caches.match(event.request)
  )
})


self.addEventListener('message', event => {
  const msg = event.data

  log(`Received "${msg.title}" from client.`)
  switch (msg.title) {
    case 'get account list':
      getAccountList()
        .then(accounts => {
          log (`accounts = `, accounts)
          respond(event, 'set account list', accounts)
        })
        .catch(err => error(`get account list: ${err}`))
      break

    case 'create account':
      createAccount(msg.content) 
        .then(() => getAccountList())
        .then(accounts => respond(event, 'set account list', accounts))
        .catch(err => error(`create account "${msg.content}": ${err}`))
      break

    case 'get ledger':
      getLedger(msg.content)
        .then(transactions => {
          //log(`responding set ledger for "${msg.content}" with `, transactions)
          respond(event, 'set ledger', {transactions: transactions})
        })
        .catch(err => error(`get ledger: ${err}`))
      break

    case 'add transaction':
      try {
        const {
          account, date, amount, description, category, checked
        } = msg.content
        addTransaction(msg.content)
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
          account, id, date, amount, description, category, checked
        } = msg.content
        putTransaction(msg.content)
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
        deleteTransaction(id)
          .then(() => {
            broadcast('ledger updated', account)
          })
      }
      catch(err) {
        error(`delete transaction: ${err}`)
      }
      break

    case 'rename account':
      try {
        const {
          account, newName
        } = msg.content
        renameAccount(account, newName)
          .then(() => getAccountList())
          .then(accounts => respond(event, 'set account list', accounts))
          .catch(err => error(`rename account "${account}" to "${newName}": ${err}`))
      }
      catch(err) {
        error(`rename account: ${err}`)
      }
      break

    case 'delete account':
      try {
        deleteAccount(msg.content)
          .then(() => getAccountList())
          .then(accounts => respond(event, 'set account list', accounts))
          .catch(err => error(`delete account "${msg.content}": ${err}`))
      }
      catch(err) {
        error(`delete account: ${err}`)
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


// DATABASE /////////////////////////////////////////////////////////////////////////////


let database


function openDB() {
  return new Promise((resolve, reject) => {

    if (database != null) {
      resolve(database)
      return
    }

    log(`Opening database...`)
    let req = indexedDB.open("Pactole", 1)
    req.onerror = () => reject(new Error(`failed to open database: ${req.error}`))
    req.onblocked = () => log('database blocked...')

    req.onupgradeneeded = () => {
      log(`Upgrading database...`)
      const db = req.result

      // Settings Store
      {
        const os = db.createObjectStore('settings')
        os.add('calendar', 'defaultMode')
        os.add(false, 'categoriesEnabled')
        os.add(false, 'reconciliationEnabled')
        os.add(false, 'summaryEnabled')
      }

      // Accounts Store
      {
        const os = db.createObjectStore('accounts', {keyPath: 'id', autoIncrement: true})
        os.add({name: 'Mon Compte'})
      }

      // Categories Store
      {
        const os = db.createObjectStore('categories', {keyPath: 'id', autoIncrement: true})
        os.add({name: '', icon: ''})
        os.add({name: 'Maison', icon: ''})
        os.add({name: 'Santé', icon: ''})
        os.add({name: 'Nourriture', icon: ''})
        os.add({name: 'Habillement', icon: ''})
        os.add({name: 'Transports', icon: ''})
        os.add({name: 'Loisirs', icon: ''})
      }

      // Ledger Store
      {
        const os = db.createObjectStore('ledger', {keyPath: 'id', autoIncrement: true})
        os.createIndex('account', 'account') //TODO: remove?
        os.createIndex('account date', ['account', 'date'])
        os.createIndex('account category', ['account', 'category'])
      }

      log(`...database upgraded.`)
    }

    req.onsuccess = () => {
      const db = req.result
      database = db
      db.onerror = event => {
        //TODO
        error(`database error: ${event.target.errorCode}`)
      }
      log(`...database opened.`)
      resolve(db)
    }
  })
}


// SETTINGS /////////////////////////////////////////////////////////////////////////////


function getSetting(key) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['settings'], 'readonly')
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


// ACCOUNTS ///////////////////////////////////////////////////////////////////


function getAccountList() {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['accounts'], 'readonly')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('accounts')
        const req = os.getAll()
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


function createAccount(name) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['accounts'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('accounts')
        const req = os.add({name: name})
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


function renameAccount(id, newName) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['accounts'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('accounts')
        const req = os.put({id: id, name: newName})
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


function deleteAccount(id) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        log(`deleting account "${id}"`)
        const tr = db.transaction(['accounts', 'ledger'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('ledger')
        const idx = os.index('account')
        const req = idx.openCursor(IDBKeyRange.only(id))
        req.onerror = () => reject(req.error)
        req.onsuccess = () => {
          const cursor = req.result
          if(cursor) {
            log(`deleting key "${cursor.key}"`)
            cursor.delete()
            cursor.continue()
          }
          else {
            log("FINISHED?")
            const os = tr.objectStore('accounts')
            const req = os.delete(id)
            req.onerror = () => reject(req.error)
            req.onsuccess = () => resolve(req.result)
          }
        }
      })
      .catch(err => reject(err))
  })
}


// CATEGORIES /////////////////////////////////////////////////////////////////


// LEDGER /////////////////////////////////////////////////////////////////////


function getLedger(accountID) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['ledger'], 'readonly')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('ledger')
        const idx = os.index('account')
        const req = idx.getAll(accountID)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


//TODO
function addTransaction(transaction) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['ledger'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('ledger')
        const req = os.add(transaction)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


//TODO
function putTransaction(transaction) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['ledger'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('ledger')
        const req = os.put(transaction)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


//TODO
function deleteTransaction(id) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['ledger'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('ledger')
        const req = os.delete(id)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


// UTILITIES //////////////////////////////////////////////////////////////////


function log(msg, ...args) {
  console.log(`[SW] ${msg}`, ...args)
}


function error(msg, ...args) {
  console.error(`[SW] ${msg}`, ...args)
}
