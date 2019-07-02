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

///////////////////////////////////////////////////////////////////////////////

export function getCategories() {
  const s = localStorage.getItem('categories')
  if (!s) {
    localStorage.setItem('categories', JSON.stringify(dummyCategories))
    return dummyCategories
  }
  return JSON.parse(s)
}

const dummyCategories = [
  { name: 'Maison', icon: '\uf015' },
  { name: 'Santé', icon: '\uf0f1' },
  { name: 'Nourriture', icon: '\uf2e7' },
  { name: 'Habillement', icon: '\uf553' },
  { name: 'Transport', icon: '\uf1b9' },
  { name: 'Loisirs', icon: '\uf11b' },
  { name: 'Autre', icon: '\uf128' },
]
