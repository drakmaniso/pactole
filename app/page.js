'use strict'

import * as settings from './settings.js'
import * as calendar from './calendar.js'
import * as ledger from './ledger.js'

function id(id) {
  return document.getElementById(id)
}

///////////////////////////////////////////////////////////////////////////////

export function render() {
  const dataset = id('page').dataset
  switch (history.state.mode) {
    case 'calendar':
      if (
        history.state.update ||
        id('calendar').hidden ||
        history.state.month != dataset.month
      ) {
        renderCalendar()
        dataset.month = history.state.month
        id('calendar').hidden = false
        id('list').hidden = true
      }
      if (history.state.update || history.state.day != dataset.day) {
        if (history.state.day) {
          renderCalendarDay()
          id('calendar-day').hidden = false
        } else {
          id('calendar-day').hidden = true
        }
        dataset.day = history.state.day
      }
      removeState('update')
      break
    case 'list':
      if (history.state.update || id('list').hidden) {
        renderList()
        id('calendar').hidden = true
        id('list').hidden = false
        removeState('update')
      }
      break
    default:
      console.error(`page.render: unknown mode ${history.state.mode}`)
  }

  const dialog = id('dialog')
  if (dialog.hidden && history.state.dialog) {
    if (history.state.dialog === 'edit') {
      openEditDialog()
    } else {
      openDialog()
    }
  } else if (!dialog.hidden && !history.state.dialog) {
    closeDialog()
  }

  const settings = id('settings')
  if (settings.hidden && history.state.settings) {
    settings.hidden = false
  } else if (!settings.hidden && !history.state.settings) {
    settings.hidden = true
  }
}

///////////////////////////////////////////////////////////////////////////////

function renderCalendar() {
  console.log('Rendering calendar page.')

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
      pushState({
        month: calendar.delta(history.state.month, 0, -1, 0),
        day: null,
      })
    })
    header.appendChild(prev)

    const par = document.createElement('p')
    if (
      calendar.year(history.state.month) === calendar.year(calendar.today())
    ) {
      par.appendChild(
        document.createTextNode(`${calendar.monthName(history.state.month)}`),
      )
    } else {
      par.appendChild(
        document.createTextNode(
          `${calendar.monthName(history.state.month)} ${calendar.year(
            history.state.month,
          )}`,
        ),
      )
    }
    header.appendChild(par)

    const next = document.createElement('button')
    next.setAttribute('class', 'fa')
    next.appendChild(document.createTextNode('\uf061'))
    next.addEventListener('click', event => {
      pushState({
        month: calendar.delta(history.state.month, 0, +1, 0),
        day: null,
      })
    })
    header.appendChild(next)

    cal.appendChild(header)
  }

  const today = calendar.today()

  calendar.grid(history.state.month, (d, row, col) => {
    const section = document.createElement('section')
    section.classList.add('month-cell')
    if (calendar.month(d) == calendar.month(history.state.month)) {
      const header = document.createElement('header')
      if (d === today) {
        header.setAttribute('class', 'today')
        header.appendChild(document.createTextNode("Aujourd'hui"))
      } else {
        header.appendChild(document.createTextNode(calendar.day(d)))
      }
      section.appendChild(header)

      ledger.getTransactionKeys(d).then(keys => {
        const ul = document.createElement('ul')
        for (const k of keys) {
          ledger.getTransaction(k).then(t => {
            const li = document.createElement('li')
            appendMoney(li, t.amount)
            ul.appendChild(li)
          })
        }
        section.appendChild(ul)
      })

      if (d === history.state.day) {
        section.classList.toggle('checked', true)
      }

      section.addEventListener('click', event => {
        for (const s of document.querySelectorAll(
          '#calendar-month > section',
        )) {
          s.classList.toggle('checked', false)
        }
        event.currentTarget.classList.toggle('checked', true)
        pushState({ day: d })
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

function renderCalendarDay() {
  const header = id('calendar-day-header')
  while (header.hasChildNodes()) {
    header.removeChild(header.lastChild)
  }
  if (history.state.day === calendar.today()) {
    header.appendChild(document.createTextNode("Aujourd'hui"))
  } else {
    header.appendChild(
      document.createTextNode(
        `${calendar.weekdayName(history.state.day)} ${calendar.day(
          history.state.day,
        )}`,
      ),
    )
  }

  const ul = id('calendar-day-ul')
  while (ul.hasChildNodes()) {
    ul.removeChild(ul.lastChild)
  }
  ledger.getTransactionKeys(history.state.day).then(keys => {
    for (const k of keys) {
      ledger.getTransaction(k).then(t => {
        const li = document.createElement('li')
        appendMoney(li, t.amount)
        const span = document.createElement('span')
        if (t.description !== '') {
          span.appendChild(document.createTextNode(t.description))
        } else {
          if (t.amount > 0) {
            span.appendChild(document.createTextNode("Entrée d'argent"))
          } else {
            span.appendChild(document.createTextNode('Dépense'))
          }
        }
        li.appendChild(span)
        li.dataset.key = k
        li.onclick = () => {
          replaceState({ dialog: 'edit', transaction: k })
        }
        ul.appendChild(li)
      })
    }
  })
}

///////////////////////////////////////////////////////////////////////////////

function renderList() {
  ledger.getTransactionKeys().then(keys => {
    console.log('Rendering list page')
    const transList = id('transactions-list')
    while (transList.hasChildNodes()) {
      transList.removeChild(transList.firstChild)
    }
    const dateList = document.createElement('ul')
    let currentDate = null
    let currentList = null
    for (const k of keys) {
      ledger.getTransaction(k).then(t => {
        if ((currentDate === null) | (t.date !== currentDate)) {
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
        appendMoney(li, t.amount)
        if (t.description !== '') {
          li.appendChild(document.createTextNode(t.description))
        }
        if (t.category !== '') {
          li.appendChild(document.createTextNode(' (' + t.category + ')'))
        }
        li.onclick = () => {
          replaceState({ dialog: 'edit', transaction: k })
        }
        currentList.appendChild(li)
      })
    }
    transList.appendChild(dateList)
  })
}

///////////////////////////////////////////////////////////////////////////////

export function renderMinicalendar(date) {
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

///////////////////////////////////////////////////////////////////////////////

export function renderCategories() {
  const categories = settings.get('categories')
  console.log(`Rendering categories.`)
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

export function renderAccounts() {
  const accounts = ledger.getAccounts()
  console.log(`Rendering accounts.`)
  const options = id('accounts')
  while (options.hasChildNodes()) {
    options.lastChild.remove()
  }
  let i = 0
  for (const a of accounts) {
    const input = document.createElement('input')
    input.hidden = true
    input.type = 'radio'
    input.name = 'account'
    input.id = `account-${i}`
    input.value = a.name
    if (i === 0) {
      input.checked = true
    }
    options.appendChild(input)
    const label = document.createElement('label')
    label.setAttribute('for', input.id)
    label.appendChild(document.createTextNode(a.name))
    options.appendChild(label)
    i++
  }
}

///////////////////////////////////////////////////////////////////////////////

function openDialog() {
  let date = history.state.day
  if (history.state.mode === 'list') {
    date = calendar.today()
  }
  const dialog = id('dialog')
  dialog.classList.remove('income', 'expense')
  dialog.classList.add(history.state.dialog)

  const label = id('amount-label')
  switch (history.state.dialog) {
    case 'income':
      label.innerHTML = "Entrée d'argent:"
      break
    case 'expense':
      label.innerHTML = 'Dépense:'
      break
  }

  if (history.state.mode === 'list') {
    renderMinicalendar(date)
  } else {
    id('date-section').hidden = true
  }

  const form = document.forms['dialog-form']
  form.reset()

  form.elements['date'].value = date

  id('dialog-delete').hidden = true
  dialog.hidden = false
  form.elements['amount'].focus()
}

function openEditDialog() {
  ledger.getTransaction(history.state.transaction).then(t => {
    const dialog = id('dialog')
    const label = id('amount-label')
    let amount = t.amount
    dialog.classList.remove('income', 'expense')
    if (t.amount < 0) {
      dialog.classList.add('expense')
      label.innerHTML = 'Dépense:'
      amount = -amount
    } else {
      dialog.classList.add('income')
      label.innerHTML = "Entrée d'argent:"
    }

    const form = document.forms['dialog-form']
    form.reset()

    form.elements['date'].value = t.date
    form.elements['amount'].value = amount / 100
    form.elements['category'].value = t.category
    form.elements['description'].value = t.description

    renderMinicalendar(t.date)
    id('date-section').hidden = false

    id('dialog-delete').hidden = false
    dialog.hidden = false
    form.elements['amount'].focus()
  })
}

function closeDialog() {
  id('dialog').hidden = true
}

///////////////////////////////////////////////////////////////////////////////

function appendMoney(container, amount) {
  let a = Math.abs(amount)
  let b = Math.floor(a / 100)
  let c = Math.round(a % 100) //TODO: real modulo???

  const span1 = document.createElement('span')
  if (amount < 0) {
    container.classList.toggle('expense', true)
    span1.appendChild(document.createTextNode(`-${b}`))
  } else {
    container.classList.toggle('income', true)
    span1.appendChild(document.createTextNode(`+${b}`))
  }
  container.appendChild(span1)

  const span2 = document.createElement('span')
  if (c > 0) {
    span2.classList.toggle('cents', true)
    span2.appendChild(document.createTextNode('.' + `${c}`.padStart(2, '0')))
  }
  container.appendChild(span2)
  //result.appendChild(document.createTextNode(' €'))
}

///////////////////////////////////////////////////////////////////////////////

export function pushState(changes) {
  let h = Object.fromEntries(Object.entries(history.state))
  for (const [k, v] of Object.entries(changes)) {
    h[k] = v
  }
  history.pushState(h, 'Pactole')
  render()
}

export function replaceState(changes) {
  let h = Object.fromEntries(Object.entries(history.state))
  for (const [k, v] of Object.entries(changes)) {
    h[k] = v
  }
  history.replaceState(h, 'Pactole')
  render()
}

export function removeState(keys) {
  let h = {}
  for (const [k, v] of Object.entries(history.state)) {
    if (keys.indexOf(k) === -1) {
      h[k] = v
    }
  }
  history.replaceState(h, 'Pactole')
}
