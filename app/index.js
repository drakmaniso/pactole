'use strict'

import * as accounting from './accounting.js'
import ledger from './dummy.js' 

window.addEventListener('hashchange', function() {
  document.getElementById('calendar-main').hidden = true
  document.getElementById('transactions-main').hidden = true
  document.getElementById('summary-main').hidden = true
  document.getElementById(`${location.hash}-main`.slice(1)).hidden = false
})


let selectedDate = new Date()
document.getElementById('expense-date').valueAsDate = selectedDate
function deltaDate(date, deltaYear, deltaMonth, deltaDay) {
  const day = date.getDate()
  const month = date.getMonth()
  const year = date.getFullYear()
  return new Date(year + deltaYear, month + deltaMonth, day + deltaDay)
}
function updateMinicalendar(date) {
  const month = date.getMonth()
  const year = date.getFullYear()
  const monthNames = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet',
    'Aout', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ]
  document.getElementById('expense-month').innerHTML = `${monthNames[month]} ${year}`
  let start = new Date(date.getFullYear(), date.getMonth())
  let weekday = start.getDay() - 1 
  if (weekday < 0) {
    weekday += 7
  }
  let d = deltaDate(start, 0, 0, -weekday)
  for (let week = 0; week < 6; week++) {
    for (let day = 0; day < 7; day++) {
      let e = document.getElementById(`expense-day-${week}-${day}`)
      if (d.getMonth() !== month) {
        e.innerHTML = ''
      } else {
        e.innerHTML = '' + d.getDate()
      }
      d = deltaDate(d, 0, 0, 1)
    }
  }
}
updateMinicalendar(selectedDate)
document.getElementById('expense-prevmonth').addEventListener('click', evt => {
  selectedDate = deltaDate(selectedDate, 0, -1, 0)
  updateMinicalendar(selectedDate)
})
document.getElementById('expense-nextmonth').addEventListener('click', evt => {
  selectedDate = deltaDate(selectedDate, 0, +1, 0)
  updateMinicalendar(selectedDate)
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

