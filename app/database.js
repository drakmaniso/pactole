'use strict'

const _allDatabases = new Map()
let _database

export function open(name) {
  return new Promise((resolve, reject) => {
    /*
    if (!indexedDB) {
      reject(new Error('IndexedDB not supported by browser'))
    }
    */

    if (_allDatabases.has(name)) {
      _database = _allDatabases.get(name)
      resolve(_database)
      return
    }

    console.log(`Opening database ${name}...`)
    let req = indexedDB.open(name, 1)
    req.onerror = event => {
      reject(new Error(`failed to open database: ${event.target.error}`))
    }
    req.onsuccess = event => {
      _database = event.target.result
      _database.onerror = event => {
        //TODO
        console.Error(`database error: ${event.target.errorCode}`)
      }
      console.log(`...database ${name} opened.`)
      _allDatabases.set(name, _database)
      resolve(_database)
    }

    req.onupgradeneeded = event => {
      console.log(`  Upgrading database ${name}...`)
      const db = event.target.result
      const os = db.createObjectStore('transactions', { autoIncrement: true })
      os.createIndex('date', 'date')
      os.createIndex('category', 'category')
      os.transaction.oncomplete = () => {
        /*
        const os = db
          .transaction('transactions', 'readwrite')
          .objectStore('transactions')
        dummyTransactions.forEach(t => {
          os.add(t)
        })
        */
      }
      console.log(`  ...database ${name} upgraded.`)
    }
  })
}

export function getAll(osName) {
  return new Promise(function(resolve, reject) {
    let tr = _database.transaction(osName, 'readonly')
    tr.onerror = event => {
      reject(new Error(`getAll('${osName}'): ${event.target.error}`))
    }
    tr.oncomplete = event => {
      //console.log(`getAll('${osName}'): transaction completed`)
    }

    let os = tr.objectStore(osName)
    let req = os.getAll()
    req.onerror = event => {
      reject(new Error(`datastore get request: ${event.target.error}`))
    }
    req.onsuccess = event => {
      //console.log(`getAll('${osName}'): ${req.result.length} objects`)
      resolve(req.result)
    }
  })
}

export function getTransactionsOn(date) {
  return new Promise(function(resolve, reject) {
    let tr = _database.transaction('transactions', 'readonly')
    tr.onerror = event => {
      reject(new Error(`getTransactionsOn('${date}'): ${event.target.error}`))
    }
    tr.oncomplete = event => {
      //console.log(`getAll('${osName}'): transaction completed`)
    }

    let os = tr.objectStore('transactions')
    const idx = os.index('date')
    let req = idx.getAllKeys(date)
    req.onerror = event => {
      reject(new Error(`datastore get request: ${event.target.error}`))
    }
    req.onsuccess = event => {
      //console.log(`getAll('${osName}'): ${req.result.length} objects`)
      resolve(req.result)
    }
  })
}

export function getTransaction(key) {
  return new Promise((resolve, reject) => {
    const tr = _database.transaction('transactions', 'readonly')
    tr.onerrror = event => {
      reject(new Error(`getTransaction('${key}): ${event.target.error}`))
    }
    const os = tr.objectStore('transactions')
    const req = os.get(key)
    req.onerror = event => {
      reject(new Error(`getTransaction('${key}): ${event.target.error}`))
    }
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}

export function addTransaction(t) {
  return new Promise(function(resolve, reject) {
    let tr = _database.transaction('transactions', 'readwrite')
    tr.onerror = event => {
      reject(new Error(`addTransaction('${t}'): ${event.target.error}`))
    }
    tr.oncomplete = event => {
      //console.log(`addTransaction('${t}'): transaction completed`)
    }

    let os = tr.objectStore('transactions')
    let req = os.add(t)
    req.onerror = event => {
      reject(new Error(`addTransaction(${t}): ${event.target.error}`))
    }
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}

export function putTransaction(t, k) {
  return new Promise(function(resolve, reject) {
    let tr = _database.transaction('transactions', 'readwrite')
    tr.onerror = event => {
      reject(new Error(`putTransaction('${t}, ${k}'): ${event.target.error}`))
    }
    tr.oncomplete = event => {
      //console.log(`addTransaction('${t}'): transaction completed`)
    }

    let os = tr.objectStore('transactions')
    let req = os.put(t, k)
    req.onerror = event => {
      reject(new Error(`putTransaction(${t}, ${k}): ${event.target.error}`))
    }
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}

export function deleteTransaction(k) {
  return new Promise(function(resolve, reject) {
    let tr = _database.transaction('transactions', 'readwrite')
    tr.onerror = event => {
      reject(new Error(`deleteTransaction('${k}'): ${event.target.error}`))
    }
    tr.oncomplete = event => {
      //console.log(`addTransaction('${t}'): transaction completed`)
    }

    let os = tr.objectStore('transactions')
    let req = os.delete(k)
    req.onerror = event => {
      reject(new Error(`deleteTransaction(${k}): ${event.target.error}`))
    }
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}

///////////////////////////////////////////////////////////////////////////////

const dummyTransactions = [
  {
    date: '2019-07-02',
    amount: 50000,
    category: "Entrée d'argent",
    description: 'AAH',
    reconciled: false,
  },
  {
    date: '2019-07-02',
    amount: 20000,
    category: "Entrée d'argent",
    description: '',
    reconciled: false,
  },
  {
    account: 'Christelle',
    date: '2019-07-02',
    amount: 87600,
    category: "Entrée d'argent",
    description: 'Salaire',
    reconciled: false,
  },
  {
    date: '2019-07-03',
    amount: -56000,
    category: 'Loyer',
    description: '',
    reconciled: false,
  },
  {
    date: '2019-07-03',
    amount: -15000,
    category: 'Électricité',
    description: '',
    reconciled: false,
  },
  {
    date: '2019-07-03',
    amount: -3000,
    category: 'Téléphone',
    description: '',
    reconciled: false,
  },
  {
    date: '2019-07-05',
    amount: -2300,
    category: 'Santé',
    description: 'pharmacie',
    reconciled: false,
  },
  {
    date: '2019-07-09',
    amount: -700,
    category: 'Transports',
    description: '',
    reconciled: false,
  },
  {
    date: '2019-07-18',
    amount: -6000,
    category: 'Alimentation',
    description: 'courses Super U',
    reconciled: false,
  },
  {
    date: '2019-07-18',
    amount: -2000,
    category: 'Divers',
    description: 'distributeur',
    reconciled: false,
  },
  {
    account: 'Christelle',
    date: '2019-07-20',
    amount: -3200,
    category: 'Habillement',
    description: 'La Halle aux Vêtements',
    reconciled: false,
  },
  {
    date: '2019-07-21',
    amount: -2000,
    category: 'Divers',
    description: 'distributeur',
    reconciled: false,
  },
  {
    date: '2019-07-23',
    amount: -5500,
    category: 'Transports',
    description: 'essence',
    reconciled: false,
  },
  {
    date: '2019-07-24',
    amount: -3500,
    category: 'Loisirs',
    description: 'Raspberry Pi',
    reconciled: false,
  },
  {
    date: '2019-06-01',
    amount: 50000,
    category: "Entrée d'argent",
    description: 'AAH',
    reconciled: false,
  },
  {
    date: '2019-06-02',
    amount: 20000,
    category: "Entrée d'argent",
    description: '',
    reconciled: false,
  },
  {
    date: '2019-06-02',
    amount: -2000,
    category: 'Divers',
    description: '',
    reconciled: false,
  },
  {
    date: '2019-06-03',
    amount: -56000,
    category: 'Loyer',
    description: 'Loyer',
    reconciled: false,
  },
  {
    date: '2019-06-03',
    amount: -3000,
    category: 'Téléphone',
    description: 'Facture téléphone',
    reconciled: false,
  },
  {
    date: '2019-06-11',
    amount: -800,
    category: 'Transports',
    description: '',
    reconciled: false,
  },
  {
    date: '2019-06-18',
    amount: -6500,
    category: 'Alimentation',
    description: 'courses Super U',
    reconciled: false,
  },
]
