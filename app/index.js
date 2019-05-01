'use strict'

import * as accounting from './accounting.js'
import ledger from './dummy.js' 


document.getElementById('expense-date').valueAsDate = new Date()

for (let d of document.getElementsByClassName('expense-button')) {
  d.addEventListener('click', evt => {
    document.getElementById('expense-dialog').showModal()
  })
}
document.getElementById('expense-ok').addEventListener('click', evt => {
  evt.preventDefault()
  let date = document.getElementById('expense-date').valueAsDate
  let desc = document.getElementById('expense-description').value
  let amount = document.getElementById('expense-amount').valueAsNumber
  if (!(amount > 0)) {
    //TODO
    document.getElementById('expense-dialog').close()
    return  
  }
  let t = new accounting.Transaction(date,
    [new accounting.Debit(ledger.expenses, amount)],
    [new accounting.Credit(ledger.assets.children[0], amount)])
  t.setDescription(desc)
  ledger.addTransaction(t)
  updateTransactionList()
  document.getElementById('expense-dialog').close()
})
document.getElementById('expense-cancel').addEventListener('click', evt => {
  document.getElementById('expense-dialog').close()
})

function updateTransactionList() {
  const expEl = document.getElementById('transactions')
  expEl.innerHTML = ''
  for (let t of ledger.transactions) {
    t.date = new Date(t.date)
    let row = document.createElement('tr')
    let col
    col = document.createElement('td')
    col.textContent = `${t.date.getDate()}/${t.date.getMonth()+1}/${t.date.getFullYear()}:` 
    row.appendChild(col)
    col = document.createElement('td')
    col.textContent = `${t.debits[0].account.name}`
    row.appendChild(col)
    col = document.createElement('td')
    col.textContent = `${t.credits[0].account.name}`
    row.appendChild(col)
    col = document.createElement('td')
    col.textContent = `${t.debits[0].amount}`
    row.appendChild(col)
    col = document.createElement('td')
    col.textContent = `${t.description}`
    row.appendChild(col)
    expEl.appendChild(row)
  }
}

updateTransactionList(ledger)

