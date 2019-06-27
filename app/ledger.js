'use strict'

const _accounts = new Map()
const _categories = new Map()

// Transactions
let _list = []
const _calendar = new Map()

export function updateAccounts(accounts) {
  _accounts.clear()
  for (const a of accounts) {
    _accounts.set(a.name, a)
  }
}

export function updateCategories(categories) {
  _categories.clear()
  for (const c of categories) {
    _categories.set(c.name, c)
  }
}

export function updateTransactions(transactions) {
  _list = transactions
  _calendar.clear()
  for (const t of transactions) {
    if (!_calendar.get(t.date)) {
      _calendar.set(t.date, [])
    }
    _calendar.get(t.date).push(t)
  }
}

export function getTransactions() {
  return _list
}

export function getTransactionsOn(date) {
  return _calendar.get(date)
}
