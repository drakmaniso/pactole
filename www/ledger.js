'use strict'

export function getAccounts() {
  const s = localStorage.getItem('accounts')
  if (!s) {
    localStorage.setItem('accounts', JSON.stringify(defaultAccounts))
    return defaultAccounts
  }
  return JSON.parse(s)
}

///////////////////////////////////////////////////////////////////////////////

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
      /*
      os.transaction.oncomplete = () => {
        const os = db
          .transaction('transactions', 'readwrite')
          .objectStore('transactions')
        dummyTransactions.forEach(t => {
          os.add(t)
        })
      }
        */
      console.log(`  ...database ${name} upgraded.`)
    }
  })
}

function getAll(osName) {
  return new Promise((resolve, reject) => {
    const errhandler = event => {
      reject(new Error(`getAll('${osName}'): ${event.target.error}`))
    }
    const tr = _database.transaction(osName, 'readonly')
    tr.onerror = errhandler

    const os = tr.objectStore(osName)
    const req = os.getAll()
    req.onerror = errhandler
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}

export function getTransactionKeys(date) {
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

export function getTransaction(key) {
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

export function addTransaction(t) {
  return new Promise((resolve, reject) => {
    const errhandler = event => {
      reject(new Error(`addTransaction('${t}'): ${event.target.error}`))
    }
    const tr = _database.transaction('transactions', 'readwrite')
    tr.onerror = errhandler

    const os = tr.objectStore('transactions')
    const req = os.add(t)
    req.onerror = errhandler
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}

export function putTransaction(t, k) {
  return new Promise((resolve, reject) => {
    const errhandler = event => {
      reject(new Error(`putTransaction('${t}, ${k}'): ${event.target.error}`))
    }
    const tr = _database.transaction('transactions', 'readwrite')
    tr.onerror = errhandler

    const os = tr.objectStore('transactions')
    const req = os.put(t, k)
    req.onerror = errhandler
    req.onsuccess = event => {
      resolve(req.result)
    }
  })
}

export function deleteTransaction(k) {
  return new Promise((resolve, reject) => {
    const errhandler = event => {
      reject(new Error(`deleteTransaction('${k}'): ${event.target.error}`))
    }
    const tr = _database.transaction('transactions', 'readwrite')
    tr.onerror = errhandler

    const os = tr.objectStore('transactions')
    const req = os.delete(k)
    req.onerror = errhandler
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

///////////////////////////////////////////////////////////////////////////////

const defaultAccounts = [{ name: 'Compte' }]
