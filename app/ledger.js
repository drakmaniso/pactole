'use strict'

const log = console.log

let database = null
let accounts = null
let transactions = null

export async function open(name) {
  return new Promise((resolve, reject) => {

    if (name === '') {
      reject(Error('ledger.open: unable to open without a name'))
    }
    if (database !== null) {
      reject(Error(`ledger.open: database "${name}" already opened`))
    }
    if (!indexedDB) {
      reject(Error('ledger.open: IndexedDB not supported by browser'))
    }

    let req = window.indexedDB.open(name, 1)
    req.onerror = (event) => reject(new Error(`ledger.open: failed to open database "${name}": ${event.target.error}`))
    req.onblocked = (event) => reject(new Error(`ledger.open: database "${name}" is blocked`))

    // Database creation
    req.onupgradeneeded = (event) => {
      log('Ledger database: upgrade needed...')
      const db = event.target.result
      let os = db.createObjectStore('accounts', {keyPath: 'name'})
      os.add({name: 'Mon compte bancaire', kind: 'assets'})
      os.add({name: 'Alimentation', kind: 'expense'})
      os.add({name: 'Habillement', kind: 'expense'})
      os.transaction.oncomplete = (event) => {}
      os = db.createObjectStore('transactions', {autoincrement: true})
    }

    // Ledger globals initialization
    req.onsuccess = (event) => {
      log(`Ledger ${name} opened.`)
      database = event.target.result
      database.onerror = (event) => {
        //TODO
        log(`Ledger database error: ${event.target.errorCode}`)
      }
      
      accounts = new Map()

      const tr = database.transaction(['accounts', 'transactions'])
      tr.onerror = (event) => reject(new Error(`ledger.open transaction: ${event.target.error}`))
      tr.oncomplete = () => resolve(accounts)

      const os1 = tr.objectStore('accounts')
      const req1 = os1.getAll()
      req1.onerror = (event) => reject(new Error(`ledger.open accounts initialization: ${req1.error}`))
      req1.onsuccess = () => { 
        for(let a of req1.result) {
          accounts.set(a.name, a)
        }
      }

      let os2 = tr.objectStore('transactions')
      //TODO
    }

  })
}

export function getAccounts() {
  return new Promise((resolve, reject) => {
    let result = new Map()

    const tr = database.transaction('accounts')
    tr.onerror = (event) => reject(new Error(`ledger.open transaction: ${event.target.error}`))
    tr.oncomplete = () => resolve(result)

    const os = tr.objectStore('accounts')
    const req = os.getAll()
    req.onerror = (event) => reject(new Error(`ledger.open accounts initialization: ${req.error}`))
    req.onsuccess = () => { 
      for(let a of req.result) {
        result.set(a.name, a)
      }
    }
  })
}

function dbGet(store, key) {
  return new Promise((resolve, reject) => {
    const req = store.get(key)
    req.onsuccess = () => resolve(req.result)
    req.onerror = () => reject(req.error)
    //TODO: onblocked?
  })
}
