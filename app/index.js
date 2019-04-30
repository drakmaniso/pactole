'use strict'

//const acc = import("accounting.js")

document.getElementById('expense-date').valueAsDate = new Date()

document.getElementById('expense-button-1').addEventListener('click', evt => {
  document.getElementById('expense-dialog').showModal()
})
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
  let t = new Transaction(date, [new Debit(ledger.expenses, amount)], [new Credit(ledger.assets.children[0], amount)])
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
    let item = document.createElement('li')
    item.textContent = `${t.date.getFullYear()}/${t.date.getMonth()+1}/${t.date.getDate()}: ${t.description}`
    expEl.appendChild(item)
  }
}

updateTransactionList(ledger)

