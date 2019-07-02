'use strict'

import * as database from './database.js'

const _accounts = new Map()
const _categories = new Map()

// Transactions
let _list = []
const _calendar = new Map()

export function open() {
  return database.open()
}

export function updateAccounts() {
  return database.getAll('accounts').then(accounts => {
    console.log(`Updating accounts: ${accounts.length}`)
    _accounts.clear()
    for (const a of accounts) {
      _accounts.set(a.name, a)
    }
  })
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

export function getCategories() {
  return _categories
}

export function getTransactions() {
  return _list
}

export function getTransactionsOn(date) {
  return _calendar.get(date)
}

export function addTransaction(t) {
  return database.addTransaction(t).then(() => {
    return updateTransactions()
  })
}
