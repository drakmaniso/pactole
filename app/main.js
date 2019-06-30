'use strict'

import * as calendar from './calendar.js'
import * as ledger from './ledger.js'

function id(id) {
  return document.getElementById(id)
}

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
      if (registration.installing) {
        console.log(
          `Service registration: installing (scope: ${registration.scope})`,
        )
      } else if (registration.waiting) {
        console.log(
          `Service registration: waiting (scope: ${registration.scope})`,
        )
      } else if (registration.active) {
        console.log(
          `Service registration: active (scope: ${registration.scope})`,
        )
      }
      registration.onupdatefound = () => {
        let w = registration.installing
        console.log(`A new service is being installed...`)
        w.onstatechange = event => {
          if (event.target.state === 'installed') {
            console.log(`The new service has been installed.`)
            //TODO: restart service?
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
  setupService(registration.active)
  main()
})

///////////////////////////////////////////////////////////////////////////////

function main() {
  console.log(`Starting application...`)

  wireHTML()
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
    switch (location.hash) {
      case '#calendar':
        id('calendar').hidden = false
        break
      case '#transactions':
        id('transactions').hidden = false
        break
      case '#summary':
        id('summary').hidden = false
        break
      case '#settings':
        id('settings').hidden = false
        id('nav-settings').hidden = true
        id('nav-close').hidden = false
        break
    }
  }

  window.addEventListener('keydown', e => {
    switch (e.keyCode) {
      case 9: // Tab
        document.body.classList.toggle('keyboard-navigation', true)
        break
    }
  })

  window.addEventListener('mousedown', e => {
    document.body.classList.toggle('keyboard-navigation', false)
  })

  id('select-account').onclick = () => {
    //id('account-list').hidden = false
  }

  id('nav-settings').onclick = () => {
    id('settings').hidden = false
  }

  id('settings').onclick = e => {
    if (e.target == id('settings')) {
      id('settings').hidden = true
      //history.back()
    }
  }

  id('list-income').onclick = () => {
    openDialog(calendar.today(), 'income', true)
  }

  id('list-expense').onclick = () => {
    openDialog(calendar.today(), 'expense', true)
  }

  id('dialog-cancel').onclick = event => {
    //event.preventDefault()
    closeDialog()
  }

  id('dialog').onclick = e => {
    if (e.target == id('dialog')) {
      closeDialog()
    }
  }

  id('dialog-confirm').onclick = event => {
    //event.preventDefault()
    const f = document.forms['dialog-form']
    const transac = {
      date: f['date'].value,
      amount: 100 * f['amount'].value,
      description: f['description'].value,
      category: f['category'].value,
      reconciled: false,
    }
    if (id('dialog').classList.contains('expense')) {
      transac.amount = -transac.amount
    }
    send('new transaction', transac)
    closeDialog()
  }
}

///////////////////////////////////////////////////////////////////////////////

function renderCalendar(date) {
  id('calendar-day').hidden = true
  const cal = id('calendar-month')
  while (cal.hasChildNodes()) {
    cal.removeChild(cal.firstChild)
  }

  {
    const header = document.createElement('header')
    const prev = document.createElement('button')
    prev.setAttribute('class', 'fa')
    prev.appendChild(document.createTextNode('\uf060'))
    prev.addEventListener('click', event => {
      closeDialog()
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

    const next = document.createElement('button')
    next.setAttribute('class', 'fa')
    next.appendChild(document.createTextNode('\uf061'))
    next.addEventListener('click', event => {
      closeDialog()
      renderCalendar(calendar.delta(date, 0, +1, 0))
    })
    header.appendChild(next)

    cal.appendChild(header)
  }

  const today = calendar.today()

  calendar.grid(date, (d, row, col) => {
    const section = document.createElement('section')
    section.classList.add('month-cell')
    if (calendar.month(d) == calendar.month(date)) {
      const header = document.createElement('header')
      if (d === today) {
        header.setAttribute('class', 'today')
        header.appendChild(document.createTextNode("Aujourd'hui"))
      } else {
        header.appendChild(document.createTextNode(calendar.day(d)))
      }
      section.appendChild(header)

      const transacs = ledger.getTransactionsOn(d)
      if (transacs) {
        /*
        const ul = document.createElement('ul')
        for (const t of transacs) {
          const li = document.createElement('li')
          if (t.amount > 0) {
            li.classList.add('income')
          } else {
            li.classList.add('expense')
          }
          li.appendChild(document.createTextNode(`${t.amount / 100}€`))
          ul.appendChild(li)
        }
        section.appendChild(ul)
        */
        const p = document.createElement('p')
        for (const t of transacs) {
          const span = document.createElement('span')
          if (t.amount > 0) {
            span.classList.add('income')
          } else {
            span.classList.add('expense')
          }
          span.appendChild(document.createTextNode(`${t.amount / 100}€ `))
          p.appendChild(span)
        }
        section.appendChild(p)
      }

      section.addEventListener('click', event => {
        for (const s of document.querySelectorAll(
          '#calendar-month > section',
        )) {
          s.classList.toggle('checked', false)
        }
        event.currentTarget.classList.toggle('checked', true)
        renderCalendarDay(d)
      })
    }
    cal.appendChild(section)
  })

  for (const w of calendar.dayNames) {
    const div = document.createElement('div')
    div.setAttribute('class', 'weekday')
    div.appendChild(document.createTextNode(w))
    cal.appendChild(div)
  }
}

function renderCalendarDay(date) {
  closeDialog()
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
  const transacs = ledger.getTransactionsOn(date)
  if (transacs) {
    for (const t of transacs) {
      const li = document.createElement('li')
      if (t.amount > 0) {
        li.classList.add('income')
      } else {
        li.classList.add('expense')
      }
      const div1 = document.createElement('div')
      div1.appendChild(document.createTextNode(`${t.amount / 100}€`))
      li.appendChild(div1)
      const div2 = document.createElement('div')
      if (t.description !== '') {
        div2.appendChild(document.createTextNode(t.description))
      } else {
        if (t.amount > 0) {
          div2.appendChild(document.createTextNode("Entrée d'argent"))
        } else {
          div2.appendChild(document.createTextNode('Dépense'))
        }
      }
      li.appendChild(div2)
      ul.appendChild(li)
    }
  }

  id('calendar-income').onclick = () => {
    openDialog(date, 'income', false)
  }

  id('calendar-expense').onclick = () => {
    openDialog(date, 'expense', false)
  }

  id('calendar-day').hidden = false
}

///////////////////////////////////////////////////////////////////////////////

function renderList(transactions) {
  const transList = id('transactions-list')
  while (transList.hasChildNodes()) {
    transList.removeChild(transList.firstChild)
  }
  const dateList = document.createElement('ul')
  let currentDate = calendar.today()
  let currentList = null
  for (const t of ledger.getTransactions()) {
    if (t.date !== currentDate) {
      const li = document.createElement('li')
      li.setAttribute('class', 'date')
      li.innerHTML =
        '' +
        calendar.weekdayName(t.date) +
        ' ' +
        calendar.day(t.date) +
        ' ' +
        calendar.monthName(t.date)
      dateList.appendChild(li)
      currentList = document.createElement('ul')
      dateList.appendChild(currentList)
      currentDate = t.date
    }
    const li = document.createElement('li')
    if (t.amount > 0) {
      li.classList.add('income')
    } else {
      li.classList.add('expense')
    }
    const span = document.createElement('span')
    span.setAttribute('class', 'amount')
    span.appendChild(document.createTextNode(`${t.amount / 100}€`))
    li.appendChild(span)
    li.appendChild(document.createTextNode(' ' + t.category))
    if (t.description !== '') {
      li.appendChild(document.createTextNode(' (' + t.description + ')'))
    }
    currentList.appendChild(li)
  }
  transList.appendChild(dateList)
}

///////////////////////////////////////////////////////////////////////////////

function renderMinicalendar(date) {
  const cal = id('minicalendar')
  const form = document.forms['dialog-form']
  while (cal.hasChildNodes()) {
    cal.removeChild(cal.firstChild)
  }

  const header = document.createElement('header')

  let div = document.createElement('div')
  div.setAttribute('class', 'fa')
  div.appendChild(document.createTextNode('\uf060'))
  div.addEventListener('click', event => {
    renderMinicalendar(calendar.delta(date, 0, -1, 0))
  })
  header.appendChild(div)

  div = document.createElement('div')
  div.setAttribute('class', 'month')
  div.appendChild(
    document.createTextNode(
      `${calendar.monthName(date)} ${calendar.year(date)}`,
    ),
  )
  header.appendChild(div)

  div = document.createElement('div')
  div.setAttribute('class', 'fa')
  div.appendChild(document.createTextNode('\uf061'))
  div.addEventListener('click', event => {
    renderMinicalendar(calendar.delta(date, 0, +1, 0))
  })
  header.appendChild(div)
  cal.appendChild(header)

  /*
  for (const w of ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']) {
    div = document.createElement('div')
    div.setAttribute('class', 'weekday')
    div.appendChild(document.createTextNode(w))
    cal.appendChild(div)
  }
  */

  calendar.grid(date, (d, row, col) => {
    div = document.createElement('div')
    div.setAttribute('class', 'day')
    if (calendar.month(d) == calendar.month(date)) {
      div.appendChild(document.createTextNode(calendar.day(d)))
      if (d === form['date'].value) {
        div.setAttribute('checked', 'true')
      }
      const thisdiv = div
      div.addEventListener('click', event => {
        form['date'].value = d
        const alldays = document.querySelectorAll('#minicalendar .day')
        for (const a of alldays) {
          //TODO: use class instead of attribute
          a.removeAttribute('checked')
        }
        thisdiv.setAttribute('checked', 'true')
      })
    }
    cal.appendChild(div)
  })

  id('date-section').hidden = false
}

function renderCategories(categories) {
  const listbox = id('categories')
  while (listbox.hasChildNodes()) {
    listbox.lastChild.remove()
  }
  let i = 0
  for (const c of categories) {
    const div = document.createElement('div')
    const input = document.createElement('input')
    input.hidden = true
    input.type = 'radio'
    input.name = 'category'
    input.id = `category-${i}`
    input.value = c.name
    div.appendChild(input)
    const label = document.createElement('label')
    label.setAttribute('for', input.id)
    const span = document.createElement('span')
    span.classList.add('fa')
    span.appendChild(document.createTextNode(c.icon))
    label.appendChild(span)
    label.appendChild(document.createTextNode(c.name))
    div.appendChild(label)
    listbox.appendChild(div)
    i++
  }
}

///////////////////////////////////////////////////////////////////////////////

function openDialog(date, kind, withMinicalendar) {
  const dialog = id('dialog')
  dialog.classList.remove('income', 'expense')
  dialog.classList.add(kind)

  const label = id('amount-label')
  switch (kind) {
    case 'income':
      label.innerHTML = "Entrée d'argent:"
      break
    case 'expense':
      label.innerHTML = 'Dépense:'
      break
  }

  if (withMinicalendar === true) {
    renderMinicalendar(date)
  } else {
    id('date-section').hidden = true
  }

  const form = document.forms['dialog-form']
  form.reset()

  form.elements['date'].value = date

  dialog.hidden = false
  form.elements['amount'].focus()
}

function closeDialog() {
  id('dialog').hidden = true
}

///////////////////////////////////////////////////////////////////////////////

let service = null

function setupService(s) {
  service = s
  navigator.serviceWorker.onmessage = event => {
    console.log(`Received ${event.data.title}.`)
    switch (event.data.title) {
      case 'accounts':
        ledger.updateAccounts(event.data.content)
        break

      case 'categories':
        ledger.updateCategories(event.data.content)
        renderCategories(event.data.content)
        break

      case 'transactions':
        ledger.updateTransactions(event.data.content)
        renderCalendar(calendar.today())
        renderList(ledger.getTransactions())
        break
    }
  }
  send('connect', null)
}

function send(title, content) {
  console.log(`Sending ${title} to service...`)
  return new Promise((resolve, reject) => {
    service.postMessage({ title: title, content: content })
  })
}
