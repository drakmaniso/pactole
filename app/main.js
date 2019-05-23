'use strict'

import * as client from './client.js'
import * as calendar from './calendar.js'

function log(msg) {
  console.log(`[client] ${msg}`)
}

const accounts = new Map()

if (!('serviceWorker' in navigator)) {
  log('FATAL: Service workers are not supported by the navigator.')
  throw(new Error('FATAL: Service workers are not supported by the navigator.'))
}

navigator.storage.persist().then(persisted => {
  if(persisted) {
    log('Persistent storage allowed.')
    navigator.storage.estimate().then(info => {
      log(`Persistent usage: ${Math.round(info.usage/1024)}kb (quota: ${Math.round(info.quota/1024)}kb).`)
    })
  } else {
    log('*** NOT Persisted! ***')
  }
})

onload = () => {
  navigator.serviceWorker.register('/app/service.js')
    .then((registration) => {
      log(`Service registration successful (scope: ${registration.scope})`)
      registration.onupdatefound = () => {
        let w = registration.installing
        log(`A new service is being installed...`)
        w.onstatechange = (event) => {
          if(event.target.state === 'installed') {
            log(`The new service has been installed.`)
            //TODO: restart service?
            //location.reload(true)
          }
        }
      }
    })
    .catch((err) => {
      log(`Service registration failed: ${err}`)
    })
}

//navigator.serviceWorker.startMessages()

navigator.serviceWorker.ready.then((registration) => {
  client.setup(registration.active)
  main()
})

function main() {
	log(`Starting application...`)

  client.addUpdateListener(onUpdate)

	client.send({msg: 'open', name: 'Mon Compte'})

  wireHTML()

  //TODO: better way to achieve this?
  document.location = '#transactions'
  window.scrollTo(0, document.body.scrollHeight)
}

function onUpdate(message) {
  log(`onUpdate ${message}`)
  client.send({msg: 'get accounts'}).then((data) => {
    log(`reply contains ${data.accounts.length} accounts`)
    fillAccounts(data.accounts)
  }).catch(() => {
    log(`reply error`)
  })

  client.send({msg: 'get transactions'}).then((data) => {
    log(`reply contains ${data.transactions.length} transactions`)
    fillTransactions(data.transactions)
  }).catch(() => {
    log(`reply error`)
  })
}

function fillTransactions(transactions) {
  const transList = id('transactions-list')
  while(transList.hasChildNodes()) {
    transList.removeChild(transList.firstChild)
  }
  const dateList = document.createElement('ul')
  let currentDate = new Date(0, 0, 0)
  let currentList = null
  for(const t of transactions) {
    if(!calendar.sameDate(t.date, currentDate)) {
      const li = document.createElement('li')
      li.setAttribute('class', 'date')
      li.innerHTML = '' + calendar.dayName(t.date) 
        + ' ' + calendar.dayNumber(t.date)
        + ' ' + calendar.monthName(t.date)
      dateList.appendChild(li)
      currentList = document.createElement('ul')
      dateList.appendChild(currentList)
      currentDate = t.date
    }
    //TODO: multiple credits and/or debits in the same transaction
    const debit = t.debits[0]
    const li = document.createElement('li')
    const amountSpan = document.createElement('span')
    amountSpan.setAttribute('class', 'amount')
    let amount = '' + (debit.amount/100) + ' €'
    const account = accounts.get(debit.account)
    li.setAttribute('class', account.kind)
    switch (account.kind) {
      case 'income':
        amount = '+' + amount
        break
      case 'expense':
        amount = '-' + amount
        break
    }
    amountSpan.appendChild(document.createTextNode(amount))
    li.appendChild(amountSpan)
    li.appendChild(document.createTextNode(' ' + account.name))
    if(t.description !== '') {
      li.appendChild(document.createTextNode(' (' + t.description + ')'))
    }
    currentList.appendChild(li)
  }
  transList.appendChild(dateList)
}

function fillAccounts(acc) {
  accounts.clear()
  for(const a of acc) {
    accounts.set(a.name, a)
  }
  return
  const sidebar = document.getElementById('sidebar')
  while(sidebar.hasChildNodes()) {
    sidebar.removeChild(sidebar.firstChild)
  }
  //const shadow = sidebar.attachShadow({mode: 'open'})
  const list = document.createElement('ul')
  list.id = 'transactions-income-actions'
  //shadow.appendChild(list)
  for(const a of message.accounts) {
    const b = document.createElement('button')
    b.textContent = a.name
    b.setAttribute('class', 'action')
    b.setAttribute('value', a.name)
    list.appendChild(b)
  }
  sidebar.appendChild(list)
}

function id(id) { return document.getElementById(id) }

function wireHTML() {
  window.onhashchange = () => {
    id('transactions').hidden = true
    id('summary').hidden = true
    id('settings').hidden = true
    id('expense').hidden = true
    switch(location.hash) {
      case '#transactions':
        id('expense-navigation').hidden = true
        id('navigation').hidden = false
        id('transactions').hidden = false
        break
      case '#summary':
        id('expense-navigation').hidden = true
        id('navigation').hidden = false
        id('summary').hidden = false
        break
      case '#settings':
        id('expense-navigation').hidden = true
        id('navigation').hidden = false
        id('settings').hidden = false
        break
      case '#expense':
        id('navigation').hidden = true
        id('expense-navigation').hidden = false
        id('expense-date').valueAsDate = calendar.today()
        fillMinicalendar('expense-date', 'expense-calendar', calendar.today())
        id('expense').hidden = false
        break
    }
  }

  id('expense-cancel').onclick = () => {
    window.history.back()
  }
  id('expense-close').onclick = () => {
    window.history.back()
  }
}

function fillMinicalendar(dateId, calId, date) {
  const dateInput = id(dateId)
  const cal = id(calId)
  while(cal.hasChildNodes()) {
    cal.removeChild(cal.firstChild)
  }

  let div = document.createElement('div')
  div.setAttribute('class', 'fa')
  div.appendChild(document.createTextNode('\uf060'))
  div.addEventListener('click', (event) => {
    fillMinicalendar(dateId, calId, calendar.delta(date, 0, -1, 0))
  })
  cal.appendChild(div)

  div = document.createElement('div')
  div.setAttribute('class', 'month')
  div.appendChild(document.createTextNode(`${calendar.monthName(date)} ${date.getFullYear()}`))
  cal.appendChild(div)

  div = document.createElement('div')
  div.setAttribute('class', 'fa')
  div.appendChild(document.createTextNode('\uf061'))
  div.addEventListener('click', (event) => {
    fillMinicalendar(dateId, calId, calendar.delta(date, 0, +1, 0))
  })
  cal.appendChild(div)

  
  for(const w of ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']) {
    div = document.createElement('div')
    div.setAttribute('class', 'weekday')
    div.appendChild(document.createTextNode(w))
    cal.appendChild(div)
  }

  calendar.grid(date, (d, row, col) => {
    div = document.createElement('div')
    div.setAttribute('class', 'day')
    if (d.getMonth() == date.getMonth()) {
      div.appendChild(document.createTextNode(d.getDate()))
      if (calendar.sameDate(d, dateInput.valueAsDate)) {
        div.setAttribute('checked', 'true')
      }
      const thisdiv = div
      div.addEventListener('click', (event) => {
        let s = `${d.getFullYear()}-`
        if(d.getMonth()+1 < 10) { 
          s = s + '0' 
        }
        s = s + `${d.getMonth()+1}-`
        if(d.getDate() < 10) {
          s = s + '0' 
        }
        s = s + `${d.getDate()}`
        dateInput.value = s
        const alldays = document.querySelectorAll('#'+calId+' .day')
        for(const a of alldays) {
          a.removeAttribute('checked')
        }
        thisdiv.setAttribute('checked', 'true')
      })
    }
    cal.appendChild(div)
  })
}

