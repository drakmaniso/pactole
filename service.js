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


const version = 1
const staticCacheName = "pactole-cache-1"


self.addEventListener('install', event => {
  log('Installing service worker...')
  event.waitUntil(self.skipWaiting())
  event.waitUntil(
    caches
      .open(staticCacheName)
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
      })
      .catch(err => {
        error(err)
      })
  )
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
  //log(`fetch: ${event.request.url}...`)
  //TODO: handle favicon?
  event.respondWith(
    caches.match(event.request)
  )
})


self.addEventListener('message', event => {
  const msg = event.data

  log(`Received "${msg.title}".`)
  switch (msg.title) {
    case 'request accounts':
      getAccounts()
        .then(accounts => respond(event, 'update accounts', accounts))
        .catch(err => error(`request accounts: ${err}`))
      break

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
          .then(accounts => broadcast('update accounts', accounts))
          .catch(err => error(`delete account "${msg.content}": ${err}`))
      }
      catch (err) {
        error(`delete account: ${err}`)
      }
      break

    case 'request categories':
      getCategories()
        .then(accounts => respond(event, 'update categories', accounts))
        .catch(err => error(`request categories: ${err}`))
      break

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

    case 'request ledger':
      getLedger(msg.content)
        .then(transactions => respond(event, 'update ledger', { transactions: transactions }))
        .catch(err => error(`request ledger: ${err}`))
      break

    case 'create transaction':
      try {
        const {
          account, date, amount, description, category, checked
        } = msg.content
        addTransaction(msg.content)
          .then(() => {
            broadcast('invalidate ledger', account)
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
        putTransaction(msg.content)
          .then(() => {
            broadcast('invalidate ledger', account)
          })
      }
      catch (err) {
        error(`replace transaction: ${err}`)
      }
      break

    case 'delete transaction':
      try {
        const {
          account, id
        } = msg.content
        deleteTransaction(id)
          .then(() => {
            broadcast('invalidate ledger', account)
          })
      }
      catch (err) {
        error(`delete transaction: ${err}`)
      }
      break

    case 'request settings':
      getSettings()
        .then(settings => respond(event, 'update settings', settings))
        .catch(err => error(`request settings: ${err}`))
      break

    case 'store settings':
      setSettings(msg.content)
        .then(() => broadcast('update settings', msg.content))
        .catch(err => error(`store settings: ${err}`))
      break
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
      log(`Upgrading database...`)
      const db = req.result

      // Settings Store
      {
        const os = db.createObjectStore('settings')
        //os.add({}, 'settings')
      }

      // Accounts Store
      {
        const os = db.createObjectStore('accounts', { keyPath: 'id', autoIncrement: true })
      }

      // Categories Store
      {
        const os = db.createObjectStore('categories', { keyPath: 'id', autoIncrement: true })
        os.add({ name: 'Maison', icon: '\u{F015}' })
        os.add({ name: 'Santé', icon: '\u{F0F1}' })
        os.add({ name: 'Nourriture', icon: '\u{F2E7}' })
        os.add({ name: 'Vêtements', icon: '\u{F553}' })
        os.add({ name: 'Transports', icon: '\u{F5E4}' })
        os.add({ name: 'Loisirs', icon: '\u{F5CA}' })
        os.add({ name: 'Banque', icon: '\u{F19C}' })
      }

      // Ledger Store
      {
        const os = db.createObjectStore('ledger', { keyPath: 'id', autoIncrement: true })
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
        req.onsuccess = () => {
          if (req.result.length == 0) {
            const tr = db.transaction(['accounts'], 'readwrite')
            tr.onerror = () => reject(tr.error)
            const os = tr.objectStore('accounts')
            const req = os.put({ name: 'Compte' })
            req.onerror = () => reject(req.error)
            req.onsuccess = () => resolve([{ id: req.result, name: 'Compte' }])
          } else {
            resolve(req.result)
          }
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
  console.log(`[SERVICE] ${msg}`, ...args)
}


function error(msg, ...args) {
  console.error(`[SERVICE] ${msg}`, ...args)
}
