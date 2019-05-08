'use strict'

import * as accounting from './accounting.js'
import ledger from './dummy.js' 


document.getElementById('expense-date').valueAsDate = new Date()

document.getElementById('nav-calendar').addEventListener('click', evt => {
  document.getElementById('transactions-main').hidden = true
  document.getElementById('summary-main').hidden = true
  document.getElementById('calendar-main').hidden = false
  document.getElementById('transactions-sidebar').hidden = false
})
document.getElementById('nav-transactions').addEventListener('click', evt => {
  document.getElementById('summary-main').hidden = true
  document.getElementById('calendar-main').hidden = true
  document.getElementById('transactions-main').hidden = false
  document.getElementById('transactions-sidebar').hidden = false
})
document.getElementById('nav-summary').addEventListener('click', evt => {
  document.getElementById('transactions-sidebar').hidden = true
  document.getElementById('calendar-main').hidden = true
  document.getElementById('transactions-main').hidden = true
  document.getElementById('summary-main').hidden = false
})

let btnList = document.getElementById('transactions-income-actions')
for (let a of ledger.income.children) {
  const b = document.createElement('button')
  b.textContent = a.name
  b.setAttribute('class', 'action')
  b.setAttribute('value', a.name)
  btnList.appendChild(b)
}
let b = document.createElement('button')
b.setAttribute('class', 'action')
b.setAttribute('value', '')
b.textContent = 'Autre'
btnList.appendChild(b)

btnList = document.getElementById('transactions-expense-actions')
let i = 0
for (let a of ledger.expenses.children) {
  const b = document.createElement('button')
  b.textContent = a.name
  b.setAttribute('class', 'action')
  b.setAttribute('value', a.name)
  b.setAttribute('mySelectIndex', i) //TODO
  btnList.appendChild(b)
  i++
}
b = document.createElement('button')
b.setAttribute('class', 'action')
b.setAttribute('value', '')
b.textContent = 'Divers'
b.setAttribute('mySelectIndex', i) //TODO
btnList.appendChild(b)
for (let d of document.getElementsByClassName('action')) {
  d.addEventListener('click', evt => {
    //let i = 0
    //for (let o of document.getElementById('expense-categories').options) {
      //if (o.value === evt.target.value) {
        //break
      //}
      //i++
    //}
    //document.getElementById('expense-categories').selectedIndex = i
    document.getElementById('expense-category').value = evt.target.value 
    if (evt.target.value === '') {
      document.getElementById('expense-category-description').innerHTML = 'Divers'
    } else {
      document.getElementById('expense-category-description').innerHTML = evt.target.value
    }
    document.getElementById('expense-dialog').showModal()
  })
}

//const catList = document.getElementById('expense-categories')
//for (let a of ledger.expenses.children) {
  //const o = document.createElement('option')
  //o.textContent = a.name
  //o.setAttribute('value', a.name)
  //catList.appendChild(o)
//}
//const o = document.createElement('option')
//o.textContent = 'Autre'
//o.setAttribute('value', '')
//catList.appendChild(o)

document.getElementById('expense-submit').addEventListener('click', evt => {
  evt.preventDefault()
  let date = document.getElementById('expense-date').valueAsDate
  let desc = document.getElementById('expense-description').value
  let cat = document.getElementById('expense-category').value
  let amount = document.getElementById('expense-amount').valueAsNumber
  if (!(amount > 0)) {
    //TODO
    document.getElementById('expense-dialog').close()
    return  
  }
  let t = new accounting.Transaction(date,
    [new accounting.Debit(ledger.getAccount('expenses', cat), amount)],
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
  const expEl = document.getElementById('transactions-content')
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

