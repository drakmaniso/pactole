'use strict'

// Module datastore implements the storage of all the application data.
//
// A transaction is an object:
//
//     {
//       date:        string  // "YYYY-MM-DD" (always 10 characters)
//       account:     string
//       amount:      integer // in cents
//       category:    string
//       description: string
//     }

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
  return new Promise((resolve, reject) => {
    if (database !== null) {
      reject(new Error('internal error: database already opened'))
    }
    if (!window.indexedDB) {
      reject(new Error('IndexedDB not supported by browser'))
    }

    let req = window.indexedDB.open('Pactole', 1)
    req.onerror = event => {
      reject(new Error(`failed to open database: ${event.target.error}`))
    }
    req.onsuccess = event => {
      log('Database opened.')
      database = event.target.result
      database.onerror = event => {
        //TODO
        log(new Error(`database error: ${event.target.errorCode}`))
      }
      resolve()
    }
    req.onupgradeneeded = event => {
      log('Database: upgrade needed...')
      const db = event.target.result

      const accounts = db.createObjectStore('accounts', { keyPath: 'name' })
      accounts.transaction.oncomplete = event => {
        const os = db.transaction('accounts', 'readwrite').objectStore('accounts')
        os.add({name: 'Compte'})
      }

      const categories = db.createObjectStore('categories', { keyPath: 'name' })
      categories.transaction.oncomplete = event => {
        const os = db.transaction('categories', 'readwrite').objectStore('categories')
        os.add({name: 'Nourriture'})
        os.add({name: 'Habillement'})
        os.add({name: 'Maison'})
        os.add({name: 'Santé'})
        os.add({name: 'Loisirs'})
      }

      const transactions = db.createObjectStore('transactions', { autoIncrement: true })
      transactions.transaction.oncomplete = event => {
        const os = db.transaction('accounts', 'readwrite').objectStore('accounts')
        dummyTransactions.forEach(t => {
          os.add(t)
        })
      }
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

const dummyTransactions = [
  {
    date: "2019-05-02",
    amount: 50000,
    category: 'Allocations',
    description: 'AAH',
    reconciled: false,
  },
  {
    date: "2019-05-02",
    amount: 20000,
    category: 'Allocations',
    description: '',
    reconciled: false,
  },
  {
    date: "2019-05-03",
    amount: 56000,
    category: 'Loyer',
    description: '',
    reconciled: false,
  },
  {
    date: "2019-05-03",
    amount: 15000,
    category: 'Électricité',
    description: '',
    reconciled: false,
  },
  {
    date: "2019-05-03",
    amount: 3000,
    category: 'Téléphone',
    description: '',
    reconciled: false,
  },
  {
    date: "2019-05-06",
    amount: 2300,
    category: 'Santé',
    description: 'pharmacie',
    reconciled: false,
  },
  {
    date: "2019-05-09",
    amount: 700,
    category: 'Transports',
    description: '',
    reconciled: false,
  },
  {
    date: "2019-05-18",
    amount: 6000,
    category: 'Alimentation',
    description: 'courses Super U',
    reconciled: false,
  },
  {
    date: "2019-05-18",
    amount: 2000,
    category: 'Divers',
    description: 'distributeur',
    reconciled: false,
  },
  {
    date: "2019-05-20",
    amount: 3200,
    category: 'Habillement',
    description: 'La Halle aux Vêtements',
    reconciled: false,
  },
  {
    date: "2019-05-21",
    amount: 2000,
    category: 'Divers',
    description: 'distributeur',
    reconciled: false,
  },
  {
    date: "2019-05-23",
    amount: 5500,
    category: 'Transports',
    description: 'essence',
    reconciled: false,
  },
  {
    date: "2019-05-24",
    amount: 3500,
    category: 'Loisirs',
    description: 'Raspberry Pi',
    reconciled: false,
  },
  {
    date: "2019-05-01",
    amount: 50000,
    category: 'Allocations',
    description: 'AAH',
    reconciled: false,
  },
  {
    date: "2019-05-02",
    amount: 20000,
    category: 'Allocations',
    description: '',
    reconciled: false,
  },
  {
    date: "2019-05-02",
    amount: 2000,
    category: 'Divers',
    description: '',
    reconciled: false,
  },
  {
    date: "2019-05-03",
    amount: 56000,
    category: 'Loyer',
    description: 'Loyer',
    reconciled: false,
  },
  {
    date: "2019-05-03",
    amount: 3000,
    category: 'Téléphone',
    description: 'Facture téléphone',
    reconciled: false,
  },
  {
    date: "2019-05-11",
    amount: 800,
    category: 'Transports',
    description: '',
    reconciled: false,
  },
  {
    date: "2019-05-18",
    amount: 6500,
    category: 'Alimentation',
    description: 'courses Super U',
    reconciled: false,
  },
]
