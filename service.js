'use strict'


// SERVICE WORKER CALLBACKS ///////////////////////////////////////////////////


const files = [
  './',
  'favicon.ico',
  'manifest.webmanifest',
  'elm.js',
  'fonts/fa-solid-900.woff2',
  'fonts/andika-new-basic-v15-latin-regular.woff2',
  'fonts/andika-new-basic-v15-latin-700.woff2',
  'images/icon-512x512.png',
]


// Database version
// - version 1 had recurring transactions stored inside settings
const version = 2

const staticCacheName = "pactole-cache-2"

// Used to force an update on client-side
const serviceVersion = "1.4.6beta"


self.addEventListener('install', event => {
  log('Installing service worker...')
  caches
    .open(staticCacheName)
    .then(cache => {
      log('    Installing cache')
      return cache.addAll(
        files.map(f => {
          return new Request(f, { cache: 'no-store' })
        })
      )
    })
    .then(() => {
      log('...service worker installed.')
    })
    .catch(err => {
      error(err)
    })
})


self.addEventListener('activate', event => {
  log('Service worker activated.')
  event.waitUntil(clients.claim())
  event.waitUntil(
    caches.keys()
      .then(names => {
        return Promise.all(
          names
            .filter(n => n != staticCacheName)
            .map(n => caches.delete(n))
        )
      })
      .catch(err => error(err))
  )
})


self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(responseFromCache => {
        if (responseFromCache) {
          return responseFromCache
        }
        return fetch(event.request)
      })
  )
})

self.addEventListener('message', event => {
  const msg = event.data

  log(`Received "${msg.title}".`)
  switch (msg.title) {

    // Initialization

    case 'request whole database':
      requestWholeDatabase()
        .then(db => respond(event, 'update whole database', db))
        .catch(err => error(`request whole database`))
      break

    case 'persistent storage granted':
      broadcast('persistent storage granted', { granted: msg.content })
      break

    // Settings

    case 'store settings':
      setSettings(msg.content)
        .then(() => broadcast('update settings', msg.content))
        .catch(err => error(`store settings: ${err}`))
      break

    // Accounts

    case 'create account':
      createAccount(msg.content)
        .then(() => getAccounts())
        .then(accounts => broadcast('update accounts', accounts))
        .catch(err => error(`create account "${msg.content}": ${err}`))
      break

    case 'rename account':
      try {
        const { id, name } = msg.content
        renameAccount(id, name)
          .then(() => getAccounts())
          .then(accounts => broadcast('update accounts', accounts))
          .catch(err => error(`rename account "${id}" to "${name}": ${err}`))
      }
      catch (err) {
        error(`rename account: ${err}`)
      }
      break

    case 'delete account':
      try {
        deleteAccount(msg.content)
          .then(() => getAccounts())
          .then(accounts => {
            broadcast('update accounts', accounts)
            getLedger('ledger')
              .then(transactions => broadcast('update ledger', transactions))
          })
          .catch(err => error(`delete account "${msg.content}": ${err}`))
      }
      catch (err) {
        error(`delete account: ${err}`)
      }
      break

    // Categories

    case 'create category':
      try {
        const { name, icon } = msg.content
        createCategory(name, icon)
          .then(() => getCategories())
          .then(categories => broadcast('update categories', categories))
          .catch(err => error(`create category "${name}": ${err}`))
      }
      catch (err) {
        error(`create category: ${err}`)
      }
      break

    case 'rename category':
      try {
        const { id, name, icon } = msg.content
        renameCategory(id, name, icon)
          .then(() => getCategories())
          .then(categories => broadcast('update categories', categories))
          .catch(err => error(`rename category "${id}" to "${name}": ${err}`))
      }
      catch (err) {
        error(`rename category: ${err}`)
      }
      break

    case 'delete category':
      try {
        deleteCategory(msg.content)
          .then(() => getCategories())
          .then(categories => broadcast('update categories', categories))
          .catch(err => error(`delete category "${msg.content}": ${err}`))
      }
      catch (err) {
        error(`delete category: ${err}`)
      }
      break

    // Ledger Transactions

    case 'create transaction':
      try {
        const {
          account, date, amount, description, category, checked
        } = msg.content
        addTransaction('ledger', msg.content)
          .then(() => {
            getLedger('ledger')
              .then(transactions => broadcast('update ledger', transactions))
              .catch(err => error(`create transaction: ${err}`))
          })
      }
      catch (err) {
        error(`create transaction: ${err}`)
      }
      break

    case 'replace transaction':
      try {
        const {
          account, id, date, amount, description, category, checked
        } = msg.content
        putTransaction('ledger', msg.content)
          .then(() => {
            getLedger('ledger')
              .then(transactions => broadcast('update ledger', transactions))
              .catch(err => error(`replace transaction: ${err}`))
          })
      }
      catch (err) {
        error(`replace transaction: ${err}`)
      }
      break

    case 'delete transaction':
      try {
        const {
          id
        } = msg.content
        deleteTransaction('ledger', id)
          .then(() => {
            getLedger('ledger')
              .then(transactions => broadcast('update ledger', transactions))
              .catch(err => error(`delete transaction: ${err}`))
          })
      }
      catch (err) {
        error(`delete transaction: ${err}`)
      }
      break

    // Recurring Transactions

    case 'request recurring transactions':
      getLedger('recurring')
        .then(transactions => respond(event, 'update recurring transactions', transactions))
        .catch(err => error(`request recurring transactions: ${err}`))
      break

    case 'create recurring transaction':
      try {
        const {
          account, date, amount, description, category, checked
        } = msg.content
        addTransaction('recurring', msg.content)
          .then(() => {
            getLedger('recurring')
              .then(transactions => broadcast('update recurring transactions', transactions))
              .catch(err => error(`create recurring transaction: ${err}`))
          })
      }
      catch (err) {
        error(`create recurring transaction: ${err}`)
      }
      break

    case 'replace recurring transaction':
      try {
        const {
          account, id, date, amount, description, category, checked
        } = msg.content
        putTransaction('recurring', msg.content)
          .then(() => {
            getLedger('recurring')
              .then(transactions => broadcast('update recurring transactions', transactions))
          })
          .catch(err => error(`replace recurring transaction: ${err}`))
      }
      catch (err) {
        error(`replace recurring transaction: ${err}`)
      }
      break

    case 'delete recurring transaction':
      try {
        const {
          id
        } = msg.content
        deleteTransaction('recurring', id)
          .then(() => {
            getLedger('recurring')
              .then(transactions => broadcast('update recurring transactions', transactions))
              .catch(err => error(`delete recurring transaction: ${err}`))
          })
      }
      catch (err) {
        error(`delete recurring transaction: ${err}`)
      }
      break

    case 'broadcast import database':
      try {
        const {
          settings, recurring, accounts, categories, ledger
        } = msg.content
        setSettings(settings)
          .then(() => setAccounts(accounts))
          .then(() => setCategories(categories))
          .then(() => setAllTransactions('recurring', recurring))
          .then(() => setAllTransactions('ledger', ledger))
          .then(() => broadcast('update whole database', msg.content))
          .catch(err => error(`broadcast import database: ${err}`))

      }
      catch (err) {
        error(`broadcast import database: ${err}`)
      }
      break

    case 'user error':
      broadcast('user error', msg.content)
      break

    default:
      const e = `Unknown message \"${msg.title}\" with content: ${msg.content}`
      error(e)
      broadcast('javascript error', e)
  }
})


function respond(event, title, content) {
  log(`Responding "${title}"...`)
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


function requestWholeDatabase(event) {
  return new Promise((resolve, reject) => {
    getSettings()
      .then(settings =>
        getAccounts()
          .then(accounts =>
            getCategories()
              .then(categories =>
                getLedger('ledger')
                  .then(ledger =>
                    getLedger('recurring')
                      .then(recurring => {
                        let db = {
                          settings: settings,
                          accounts: accounts,
                          categories: categories,
                          ledger: ledger,
                          recurring: recurring,
                          serviceVersion: serviceVersion
                        }
                        resolve(db)
                      })
                  )

              )
          )
      )
      .catch(err => error(`request whole database: ${err}`))
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
    let req = indexedDB.open("Pactole", version)
    req.onerror = () => reject(new Error(`failed to open database: ${req.error}`))
    req.onblocked = () => log('database blocked...')

    req.onupgradeneeded = () => {
      log(`    Upgrading database...`)
      const db = req.result

      // Settings Store
      if (!db.objectStoreNames.contains('settings')) {
        log(`        Creating settings object store...`)
        const os = db.createObjectStore('settings')
      }

      // Accounts Store
      if (!db.objectStoreNames.contains('accounts')) {
        log(`        Creating accounts object store...`)
        const os = db.createObjectStore('accounts', { keyPath: 'id', autoIncrement: true })
      }

      // Categories Store
      if (!db.objectStoreNames.contains('categories')) {
        log(`        Creating categories object store...`)
        const os = db.createObjectStore('categories', { keyPath: 'id', autoIncrement: true })
      }

      // Ledger Store
      if (!db.objectStoreNames.contains('ledger')) {
        log(`        Creating ledger object store...`)
        const os = db.createObjectStore('ledger', { keyPath: 'id', autoIncrement: true })
        os.createIndex('account', 'account')
        //os.createIndex('account date', ['account', 'date'])
        //os.createIndex('account category', ['account', 'category'])
      }

      // Recurring Transactions Store
      if (!db.objectStoreNames.contains('recurring')) {
        log(`        Creating recurring transactions object store...`)
        const os = db.createObjectStore('recurring', { keyPath: 'id', autoIncrement: true })
      }

      log(`    ...database upgraded.`)
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


function getSettings() {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['settings'], 'readonly')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('settings')
        const req = os.get('settings')
        req.onerror = () => reject(req.error)
        req.onsuccess = event => {
          resolve(req.result)
        }
      })
      .catch(err => reject(err))
  })
}


function setSettings(settings) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['settings'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        tr.oncomplete = () => resolve()
        const os = tr.objectStore('settings')
        os.put(settings, 'settings')
      })
      .catch(err => reject(err))
  })
}

// ACCOUNTS ///////////////////////////////////////////////////////////////////


function getAccounts() {
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


function setAccounts(accounts) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['accounts'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        tr.oncomplete = () => resolve()
        const os = tr.objectStore('accounts')
        os.clear()
        for (let account of accounts) {
          os.add(account)
        }
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
        const req = os.add({ name: name })
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


function renameAccount(id, name) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['accounts'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('accounts')
        const req = os.put({ id: id, name: name })
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
          if (cursor) {
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


function getCategories() {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['categories'], 'readonly')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('categories')
        const req = os.getAll()
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


function setCategories(categories) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['categories'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        tr.oncomplete = () => resolve()
        const os = tr.objectStore('categories')
        os.clear()
        for (let category of categories) {
          os.add(category)
        }
      })
      .catch(err => reject(err))
  })
}


function createCategory(name, icon) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['categories'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('categories')
        const req = os.add({ name: name, icon: icon })
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


function renameCategory(id, name, icon) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['categories'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('categories')
        const req = os.put({ id: id, name: name, icon: icon })
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


function deleteCategory(id) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction(['categories'], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore('categories')
        const req = os.delete(id)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


// TRANSACTIONS ///////////////////////////////////////////////////////////////


function getLedger(storeName) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction([storeName], 'readonly')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore(storeName)
        const req = os.getAll()
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
      .catch(err => reject(err))
  })
}


function setAllTransactions(storeName, transactions) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction([storeName], 'readwrite')
        tr.onerror = () => reject(tr.error)
        tr.oncomplete = () => resolve()
        const os = tr.objectStore(storeName)
        os.clear()
        for (let transaction of transactions) {
          os.add(transaction)
        }
      })
      .catch(err => reject(err))
  })
}


//TODO
function addTransaction(storeName, transaction) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction([storeName], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore(storeName)
        const req = os.add(transaction)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


//TODO
function putTransaction(storeName, transaction) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction([storeName], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore(storeName)
        const req = os.put(transaction)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


//TODO
function deleteTransaction(storeName, id) {
  return new Promise((resolve, reject) => {
    openDB()
      .then(db => {
        const tr = db.transaction([storeName], 'readwrite')
        tr.onerror = () => reject(tr.error)
        const os = tr.objectStore(storeName)
        const req = os.delete(id)
        req.onerror = () => reject(req.error)
        req.onsuccess = () => resolve(req.result)
      })
  })
}


// UTILITIES //////////////////////////////////////////////////////////////////


function log(msg, ...args) {
  console.log(`[SERVICE] ${msg}`, ...args)
}


function warn(msg, ...args) {
  console.warn(`[SERVICE] ${msg}`, ...args)
}


function error(msg, ...args) {
  console.error(`[SERVICE] ${msg}`, ...args)
}
