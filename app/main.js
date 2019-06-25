'use strict'

import * as client from './client.js'
import * as calendar from './calendar.js'

function id(id) {
  return document.getElementById(id)
}

const accounts = new Map()
const categories = new Map()
const transactions = []
const transactionsByDate = new Map()

if (!('serviceWorker' in navigator)) {
  console.error('FATAL: Service workers are not supported by the navigator.')
  throw new Error('FATAL: Service workers are not supported by the navigator.')
}

navigator.storage.persist().then(persisted => {
  if (persisted) {
    console.log('Persistent storage allowed.')
    navigator.storage.estimate().then(info => {
      console.log(
        `Persistent usage: ${Math.round(
          info.usage / 1024,
        )}kb (quota: ${Math.round(info.quota / 1024)}kb).`,
      )
    })
  } else {
    console.error('*** NOT Persisted! ***')
  }
})

onload = () => {
  navigator.serviceWorker
    .register('/service.js')
    .then(registration => {
      console.log(
        `Service registration successful (scope: ${registration.scope})`,
      )
      registration.onupdatefound = () => {
        let w = registration.installing
        console.log(`A new service is being installed...`)
        w.onstatechange = event => {
          if (event.target.state === 'installed') {
            console.log(`The new service has been installed.`)
            //TODO: restart service?
            //location.reload(true)
          }
        }
      }
    })
    .catch(err => {
      console.error(`Service registration failed: ${err}`)
    })
}

//navigator.serviceWorker.startMessages()

navigator.serviceWorker.ready.then(registration => {
  client.setup(registration.active)
  main()
})

///////////////////////////////////////////////////////////////////////////////

function main() {
  console.log(`Starting application...`)

  wireHTML()

  client.addUpdateListener(onUpdate)

  client.send({ msg: 'connect' })

  //TODO: better way to achieve this?
  //document.location = '#calendar'
  //window.scrollTo(0, document.body.scrollHeight)
}

function wireHTML() {
  window.onpopstate = () => {
    console.log(`*** POPSTATE: ${window.location.pathname} ***`)
  }
  window.onhashchange = () => {
    id('calendar').hidden = true
    id('transactions').hidden = true
    id('summary').hidden = true
    id('settings').hidden = true
    id('expense').hidden = true
    switch (location.hash) {
      case '#calendar':
        //id('expense-navigation').hidden = true
        //id('navigation').hidden = false
        id('calendar').hidden = false
        break
      case '#transactions':
        //id('expense-navigation').hidden = true
        //id('navigation').hidden = false
        id('transactions').hidden = false
        break
      case '#summary':
        //id('expense-navigation').hidden = true
        //id('navigation').hidden = false
        id('summary').hidden = false
        break
      case '#settings':
        //id('expense-navigation').hidden = true
        //id('navigation').hidden = false
        id('settings').hidden = false
        break
      case '#expense':
        //id('navigation').hidden = true
        //id('expense-navigation').hidden = false
        id('expense-date').value = calendar.today()
        //renderMinicalendar('expense-date', 'expense-calendar', calendar.today())
        id('expense').hidden = false
        break
    }
  }

  id('calendar-dialog-cancel').onclick = event => {
    //event.preventDefault()
    closeCalendarDialog()
  }

  id('calendar-dialog-confirm').onclick = event => {
    //event.preventDefault()
    const f = document.forms['calendar-dialog-form']
    const transac = {
      date: f['date'].value,
      debits: [{ account: 'Divers', amount: 100 * f['amount'].value }],
      credits: [{ account: 'Mon Compte', amount: 100 * f['amount'].value }],
      description: f['description'].value,
      reconciled: false,
    }
    client.send({
      msg: 'new transaction',
      transaction: transac,
    })
    closeCalendarDialog()
  }

  id('expense-cancel').onclick = () => {
    window.history.back()
  }
  id('expense-close').onclick = () => {
    window.history.back()
  }
  id('expense-submit').onclick = () => {
    const f = document.forms['expense']
    const transac = {
      date: f['expense-date'].value,
      debits: [
        {
          account: f['expense-category'].value,
          amount: 100 * f['expense-amount'].value,
        },
      ],
      credits: [
        { account: 'Mon Compte', amount: 100 * f['expense-amount'].value },
      ],
      description: f['expense-description'].value,
      reconciled: false,
    }
    client.send({
      msg: 'new transaction',
      transaction: transac,
    })
    window.location = '#transactions'
  }
}

function onUpdate(message) {
  console.log(`onUpdate ${message}`)
  client
    .send({ msg: 'get accounts' })
    .then(data => {
      console.log(`reply contains ${data.accounts.length} accounts`)
      fillAccounts(data.accounts)
    })
    .catch(err => {
      console.error(`reply error ${err}`)
    })

  client
    .send({ msg: 'get transactions' })
    .then(data => {
      console.log(`reply contains ${data.transactions.length} transactions`)
      fillTransactions(data.transactions)
    })
    .catch(err => {
      console.error(`reply error ${err}`)
    })
}

function fillAccounts(acc) {
  accounts.clear()
  for (const a of acc) {
    accounts.set(a.name, a)
  }
  //TODO
}

function fillTransactions(transactions) {
  transactionsByDate.clear()
  for (const t of transactions) {
    if (!transactionsByDate.get(t.date)) {
      transactionsByDate.set(t.date, [])
    }
    transactionsByDate.get(t.date).push(t)
  }

  renderCalendar(calendar.today())
  //renderTransactionsList(transactions)
}

///////////////////////////////////////////////////////////////////////////////

/*
function renderTransactionsList(transactions) {
  const transList = id('transactions-list')
  while (transList.hasChildNodes()) {
    transList.removeChild(transList.firstChild)
  }
  const dateList = document.createElement('ul')
  let currentDate = calendar.today()
  let currentList = null
  for (const t of transactions) {
    if (!calendar.sameDate(t.date, currentDate)) {
      const li = document.createElement('li')
      li.setAttribute('class', 'date')
      li.innerHTML =
        '' +
        calendar.weekdayName(t.date) +
        ' ' +
        calendar.dayNumber(t.date) +
        ' ' +
        calendar.monthName(t.date)
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
    let amount = '' + debit.amount / 100 + ' €'
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
    if (t.description !== '') {
      li.appendChild(document.createTextNode(' (' + t.description + ')'))
    }
    currentList.appendChild(li)
  }
  transList.appendChild(dateList)
}

function renderMinicalendar(dateId, calId, date) {
  const dateInput = id(dateId)
  const cal = id(calId)
  while (cal.hasChildNodes()) {
    cal.removeChild(cal.firstChild)
  }

  let div = document.createElement('div')
  div.setAttribute('class', 'fa')
  div.appendChild(document.createTextNode('\uf060'))
  div.addEventListener('click', event => {
    renderMinicalendar(dateId, calId, calendar.delta(date, 0, -1, 0))
  })
  cal.appendChild(div)

  div = document.createElement('div')
  div.setAttribute('class', 'month')
  div.appendChild(
    document.createTextNode(
      `${calendar.monthName(date)} ${date.getFullYear()}`,
    ),
  )
  cal.appendChild(div)

  div = document.createElement('div')
  div.setAttribute('class', 'fa')
  div.appendChild(document.createTextNode('\uf061'))
  div.addEventListener('click', event => {
    renderMinicalendar(dateId, calId, calendar.delta(date, 0, +1, 0))
  })
  cal.appendChild(div)

  for (const w of ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']) {
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
      div.addEventListener('click', event => {
        let s = `${d.getFullYear()}-`
        if (d.getMonth() + 1 < 10) {
          s = s + '0'
        }
        s = s + `${d.getMonth() + 1}-`
        if (d.getDate() < 10) {
          s = s + '0'
        }
        s = s + `${d.getDate()}`
        dateInput.value = s
        const alldays = document.querySelectorAll('#' + calId + ' .day')
        for (const a of alldays) {
          a.removeAttribute('checked')
        }
        thisdiv.setAttribute('checked', 'true')
      })
    }
    cal.appendChild(div)
  })
}
*/

///////////////////////////////////////////////////////////////////////////////

function renderCalendar(date) {
  id('calendar-day').hidden = true
  const cal = id('calendar-month')
  while (cal.hasChildNodes()) {
    cal.removeChild(cal.firstChild)
  }

  {
    const header = document.createElement('header')
    const prev = document.createElement('div')
    prev.setAttribute('class', 'fa button')
    prev.appendChild(document.createTextNode('\uf060'))
    prev.addEventListener('click', event => {
      closeCalendarDialog()
      renderCalendar(calendar.delta(date, 0, -1, 0))
    })
    header.appendChild(prev)

    const par = document.createElement('p')
    if (calendar.year(date) === calendar.year(calendar.today())) {
      par.appendChild(document.createTextNode(`${calendar.monthName(date)}`))
    } else {
      par.appendChild(
        document.createTextNode(
          `${calendar.monthName(date)} ${calendar.year(date)}`,
        ),
      )
    }
    header.appendChild(par)

    const next = document.createElement('div')
    next.setAttribute('class', 'fa button')
    next.appendChild(document.createTextNode('\uf061'))
    next.addEventListener('click', event => {
      closeCalendarDialog()
      renderCalendar(calendar.delta(date, 0, +1, 0))
    })
    header.appendChild(next)

    for (const w of calendar.dayNames) {
      const div = document.createElement('div')
      div.setAttribute('class', 'weekday')
      div.appendChild(document.createTextNode(w))
      header.appendChild(div)
    }

    cal.appendChild(header)
  }

  const today = calendar.today()

  calendar.grid(date, (d, row, col) => {
    const section = document.createElement('section')
    if (calendar.month(d) == calendar.month(date)) {
      const header = document.createElement('header')
      if (d === today) {
        header.setAttribute('class', 'today')
        header.appendChild(document.createTextNode("Aujourd'hui"))
      } else {
        header.appendChild(document.createTextNode(calendar.day(d)))
      }
      section.appendChild(header)

      const transacs = transactionsByDate.get(d)
      if (transacs) {
        const ul = document.createElement('ul')
        for (const t of transacs) {
          const account = accounts.get(t.debits[0].account)
          const li = document.createElement('li')
          li.setAttribute('class', account.kind)
          switch (account.kind) {
            case 'income':
              li.appendChild(
                document.createTextNode(`+${t.debits[0].amount / 100}€`),
              )
              break
            case 'expense':
              li.appendChild(
                document.createTextNode(`-${t.debits[0].amount / 100}€`),
              )
              break
          }
          ul.appendChild(li)
        }
        section.appendChild(ul)
      }

      section.addEventListener('click', event => {
        for (const s of document.querySelectorAll(
          '#calendar-month > section',
        )) {
          s.setAttribute('class', '')
        }
        event.currentTarget.setAttribute('class', 'checked')
        renderCalendarDay(d)
      })
    }
    cal.appendChild(section)
  })
}

function renderCalendarDay(date) {
  closeCalendarDialog()
  const header = id('calendar-day-header')
  while (header.hasChildNodes()) {
    header.removeChild(header.lastChild)
  }
  if (date === calendar.today()) {
    header.appendChild(document.createTextNode("Aujourd'hui"))
  } else {
    header.appendChild(
      document.createTextNode(
        `${calendar.weekdayName(date)} ${calendar.day(date)}`,
      ),
    )
  }

  const ul = id('calendar-day-ul')
  while (ul.hasChildNodes()) {
    ul.removeChild(ul.lastChild)
  }
  const transacs = transactionsByDate.get(date)
  if (transacs) {
    for (const t of transacs) {
      const li = document.createElement('li')
      const account = accounts.get(t.debits[0].account)
      li.setAttribute('class', account.kind)
      const desc = document.createElement('div')
      const amount = document.createElement('div')
      switch (account.kind) {
        case 'income':
          amount.appendChild(
            document.createTextNode(`+${t.debits[0].amount / 100}€`),
          )
          if (t.description !== '') {
            desc.appendChild(document.createTextNode(t.description))
          } else {
            desc.appendChild(document.createTextNode("Entrée d'argent"))
          }
          break
        case 'expense':
          amount.appendChild(
            document.createTextNode(`-${t.debits[0].amount / 100}€`),
          )
          if (t.description !== '') {
            desc.appendChild(document.createTextNode(t.description))
          } else {
            desc.appendChild(document.createTextNode('Dépense'))
          }
          break
      }
      li.appendChild(amount)
      li.appendChild(desc)
      ul.appendChild(li)
    }
  }

  id('calendar-income').onclick = () => {
    openCalendarDialog(date, 'income')
  }

  id('calendar-expense').onclick = () => {
    openCalendarDialog(date, 'expense')
  }

  id('calendar-day').hidden = false
}

function openCalendarDialog(date, kind) {
  const dialog = id('calendar-dialog')
  dialog.classList.remove('income', 'expense')
  dialog.classList.add(kind)

  const form = document.forms['calendar-dialog-form']
  form.reset()

  form.elements['date'].value = date

  dialog.hidden = false
  form.elements['amount'].focus()
}

function closeCalendarDialog() {
  id('calendar-dialog').hidden = true
}
