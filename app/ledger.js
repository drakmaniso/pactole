'use strict'

import * as database from './database.js'

// Transactions
let _list = []
const _calendar = new Map()

export function open(name) {
  return database.open(name)
}

export function updateCategories() {
  return database.getAll('categories').then(categories => {
    console.log(`Updating categories: ${categories.length}`)
    _categories.clear()
    for (const c of categories) {
      _categories.set(c.name, c)
    }
  })
}

export function updateTransactions() {
  return database.getAll('transactions').then(transactions => {
    console.log(`Updating transactions: ${transactions.length}`)
    _list = transactions
    _calendar.clear()
    for (const t of transactions) {
      if (!_calendar.get(t.date)) {
        _calendar.set(t.date, [])
      }
      _calendar.get(t.date).push(t)
    }
  })
}

export function getTransactions() {
  return database.getTransactionsOn()
  // return _list
}

export function getTransactionsOn(date) {
  return database.getTransactionsOn(date)
  // return _calendar.get(date)
}

export function getTransaction(key) {
  return database.getTransaction(key)
}

export function addTransaction(t) {
  return database.addTransaction(t).then(() => {
    return updateTransactions()
  })
}

export function putTransaction(t, k) {
  return database.putTransaction(t, k).then(() => {
    return updateTransactions()
  })
}

export function deleteTransaction(k) {
  return database.deleteTransaction(k).then(() => {
    return updateTransactions()
  })
}

///////////////////////////////////////////////////////////////////////////////

export function getAccounts() {
  const s = localStorage.getItem('accounts')
  if (!s) {
    localStorage.setItem('accounts', JSON.stringify(dummyAccounts))
    return dummyAccounts
  }
  return JSON.parse(s)
}

const dummyAccounts = [{ name: 'Christelle' }, { name: 'Laurent' }]
