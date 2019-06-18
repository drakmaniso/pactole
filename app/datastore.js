'use strict'

const log = console.log

let stickyError = null

function setError(err) {
  if (err !== null) {
    log(err)
    if (stickyError === null) {
      stickyError = err
    }
  }
}

export function hasError() {
  return stickyError !== null
}

export function error() {
  const err = error
  stickyError = null
  return err
}

let database = null

export function open() {
  return new Promise(function(resolve, reject) {
    if (database !== null) {
      reject(Error('internal error: database already opened'))
    }
    if (!window.indexedDB) {
      reject(Error('IndexedDB not supported by browser'))
    }

    let req = window.indexedDB.open('Pactole', 1)
    req.onerror = function(event) {
      reject(new Error(`failed to open database: ${event.target.error}`))
    }
    req.onsuccess = function(event) {
      log('Database opened.')
      database = event.target.result
      database.onerror = function(event) {
        //TODO
        setError(`database error: ${event.target.errorCode}`)
      }
      resolve()
    }
    req.onupgradeneeded = function(event) {
      log('Database: upgrade needed...')
      let db = event.target.result
      let os = db.createObjectStore('ledgers', { keyPath: 'name' })
      os.transaction.oncomplete = function(event) {}
      os = db.createObjectStore('assets', { keyPath: 'name' })
    }
  })
}

export function add(ledger) {
  return new Promise(function(resolve, reject) {
    if (database === null) {
      reject(new Error('datastore not opened'))
    }

    let tr = database.transaction('ledgers', 'readwrite')
    tr.onerror = function(event) {
      reject(new Error(`datastore add transaction: ${event.target.error}`))
    }
    tr.oncomplete = function(event) {
      resolve()
    }

    let os = tr.objectStore('ledgers')
    os.add(ledger)
  })
}

export function get(name) {
  return new Promise(function(resolve, reject) {
    if (database === null) {
      reject(new Error('datastore not opened'))
    }

    let tr = database.transaction('ledgers', 'readonly')
    tr.onerror = function(event) {
      reject(new Error(`datastore get transaction: ${event.target.error}`))
    }
    tr.oncomplete = function(event) {
      console.log('datastore get transaction completed')
    }

    let os = tr.objectStore('ledgers')
    let req = os.get(name)
    req.onerror = function(event) {
      reject(new Error(`datastore get request: ${event.target.error}`))
    }
    req.onsuccess = function(event) {
      resolve(req.result)
    }
  })
}

export function add2(ledger, ledgers) {
  return new Promise(function(resolve, reject) {
    if (database === null) {
      reject(new Error('datastore not opened'))
    }

    let tr = database.transaction(ledgers, 'readwrite')
    tr.onerror = function(event) {
      reject(new Error(`datastore add transaction: ${event.target.error}`))
    }
    tr.oncomplete = function(event) {
      resolve()
    }

    let os = tr.objectStore(ledgers)
    os.add(ledger)
  })
}

export function get2(name, ledgers) {
  return new Promise(function(resolve, reject) {
    if (database === null) {
      reject(new Error('datastore not opened'))
    }

    let tr = database.transaction(ledgers, 'readonly')
    tr.onerror = function(event) {
      reject(new Error(`datastore get transaction: ${event.target.error}`))
    }
    tr.oncomplete = function(event) {
      console.log('datastore get transaction completed')
    }

    let os = tr.objectStore(ledgers)
    let req = os.get(name)
    req.onerror = function(event) {
      reject(new Error(`datastore get request: ${event.target.error}`))
    }
    req.onsuccess = function(event) {
      resolve(req.result)
    }
  })
}

export function get3(fooname, barname) {
  return new Promise(function(resolve, reject) {
    if (database === null) {
      reject(new Error('datastore not opened'))
    }

    let tr = database.transaction(['ledgers', 'assets'], 'readonly')
    tr.onerror = function(event) {
      reject(new Error(`datastore get transaction: ${event.target.error}`))
    }
    tr.oncomplete = function(event) {
      console.log('datastore get transaction completed')
    }

    let os = tr.objectStore('ledgers')
    let req = os.get(barname)
    req.onerror = function(event) {
      reject(new Error(`datastore get barname request: ${event.target.error}`))
    }
    req.onsuccess = function(event) {
      const bar2 = req.result
      let os2 = tr.objectStore('assets')
      let req2 = os2.get(fooname)
      req2.onerror = function(event) {
        reject(
          new Error(`datastore get fooname request: ${event.target.error}`),
        )
      }
      req2.onsuccess = function(event) {
        resolve([req2.result, bar2])
      }
    }
  })
}
