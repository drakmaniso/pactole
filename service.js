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


self.addEventListener('install', event => {
  log('Installing service worker...')
  event.waitUntil(
    caches
      .open('Pactole-v' + version)
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
                .filter(n =>  n != 'Pactole-v' + version)
                .map(n => caches.delete(n))
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
        .then(accounts => respond(event, 'set account list', accounts))
        .catch(err => error(`get account list: ${err}`))
      break

    case 'create account':
      createAccount(msg.content) 
        .then(() => getAccountList())
        .then(accounts => broadcast('set account list', accounts))
        .catch(err => error(`create account "${msg.content}": ${err}`))
      break

    case 'rename account':
      try {
        const {id, name} = msg.content
        renameAccount(id, name)
          .then(() => getAccountList())
          .then(accounts => broadcast('set account list', accounts))
          .catch(err => error(`rename account "${id}" to "${name}": ${err}`))
      }
      catch(err) {
        error(`rename account: ${err}`)
      }
      break

    case 'delete account':
      try {
        deleteAccount(msg.content)
          .then(() => getAccountList())
          .then(accounts => broadcast('set account list', accounts))
          .catch(err => error(`delete account "${msg.content}": ${err}`))
      }
      catch(err) {
        error(`delete account: ${err}`)
      }
      break

    case 'get category list':
      getCategoryList()
        .then(accounts => respond(event, 'set category list', accounts))
        .catch(err => error(`get category list: ${err}`))
      break

    case 'create category':
      try {
        const {name, icon} = msg.content
        createCategory(name, icon)
          .then(() => getCategoryList())
          .then(categories => broadcast('set category list', categories))
          .catch(err => error(`create category "${name}": ${err}`))
      }
      catch(err) {
        error(`create category: ${err}`)
      }
      break

    case 'rename category':
      try {
        const {id, name, icon} = msg.content
        renameCategory(id, name, icon)
          .then(() => getCategoryList())
          .then(categories => broadcast('set category list', categories))
          .catch(err => error(`rename category "${id}" to "${name}": ${err}`))
      }
      catch(err) {
        error(`rename category: ${err}`)
      }
      break

    case 'delete category':
      try {
        deleteCategory(msg.content)
          .then(() => getCategoryList())
          .then(categories => broadcast('set category list', categories))
          .catch(err => error(`delete category "${msg.content}": ${err}`))
      }
      catch(err) {
        error(`delete category: ${err}`)
      }
      break

    case 'get ledger':
      getLedger(msg.content)
        .then(transactions => respond(event, 'set ledger', {transactions: transactions}))
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

    case 'get settings':
      getSettings()
        .then(settings => respond(event, 'set settings', settings))
        .catch(err => error(`get settings: ${err}`))
      break

    case 'set settings':
      setSettings(msg.content)
        .then(() => broadcast('settings updated', msg.content))
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
    let req = indexedDB.open("Pactole", version)
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
      }

      // Categories Store
      {
        const os = db.createObjectStore('categories', {keyPath: 'id', autoIncrement: true})
        os.add({name: 'Maison', icon: ''})
        os.add({name: 'Santé', icon: ''})
        os.add({name: 'Nourriture', icon: ''})
        os.add({name: 'Vêtements', icon: ''})
        os.add({name: 'Transports', icon: ''})
        os.add({name: 'Loisirs', icon: ''})
        os.add({name: 'Banque', icon: ''})
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


function getSettings() {
  return new Promise((resolve, reject) => {
    var settings = {}
    getSetting('categoriesEnabled')
      .then(cat => { settings.categoriesEnabled = cat; return getSetting('defaultMode') })
      .then(mod => { settings.defaultMode = mod; return getSetting('summaryEnabled') })
      .then(sum => { settings.summaryEnabled = sum; return getSetting('reconciliationEnabled') })
      .then(rec => { settings.reconciliationEnabled = rec; resolve(settings) })
      .catch(err => reject(err))
  })
}

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


function setSettings(settings) {
  try {
    const {
      categoriesEnabled,
      defaultMode,
      reconciliationEnabled,
      summaryEnabled
    } = settings
    return new Promise((resolve, reject) => {
      openDB()
        .then(db => {
          const tr = db.transaction(['settings'], 'readwrite')
          tr.onerror = () => reject(tr.error)
          tr.oncomplete = () => resolve()
          const os = tr.objectStore('settings')
          os.put(categoriesEnabled, 'categoriesEnabled')
          os.put(defaultMode, 'defaultMode')
          os.put(reconciliationEnabled, 'reconciliationEnabled')
          os.put(summaryEnabled, 'summaryEnabled')
        })
        .catch(err => reject(err))
    })
  }
  catch(err) {
    error(`set settings: ${err}`)
  }
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
        req.onsuccess = () => {
          if(req.result.length == 0) {
            const tr = db.transaction(['accounts'], 'readwrite')
            tr.onerror = () => reject(tr.error)
            const os = tr.objectStore('accounts')
            const req = os.put({name: 'Compte'})
            req.onerror = () => reject(req.error)
            req.onsuccess = () => resolve([{id: req.result, name: 'Compte'}])
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
        const req = os.add({name: name})
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
        const req = os.put({id: id, name: name})
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


function getCategoryList() {
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
        const req = os.add({name: name, icon: icon})
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
        const req = os.put({id: id, name: name, icon: icon})
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
  console.log(`[SW] ${msg}`, ...args)
}


function error(msg, ...args) {
  console.error(`[SW] ${msg}`, ...args)
}
