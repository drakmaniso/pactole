'use strict'

export class Month {
  constructor(year, month) {
    this.year = year
    this.month = month
  }

  string() {
  }
}

export class Day {
  constructor(year, month, day) {
    this.year = year
    this.month = month
    this.day = day
  }

  string() {
  }
}

export function today() {
  const d = new Date()
  return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 10)
}

const dayNames = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
]

const monthNames = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
]

export function sameDate(a, b) {
  return (
    a.getDate() === b.getDate() &&
    a.getMonth() === b.getMonth() &&
    a.getFullYear() === b.getFullYear()
  )
}

export function dayNumber(date) {
  return date.getDate()
}

export function dayName(date) {
  let day = (date.getDay() + 6) % 7
  return dayNames[day]
}

export function monthName(date) {
  return monthNames[date.getMonth()]
}

export function delta(date, deltaYear, deltaMonth, deltaDay) {
  const day = date.getDate()
  const month = date.getMonth()
  const year = date.getFullYear()
  return new Date(year + deltaYear, month + deltaMonth, day + deltaDay)
}

export function grid(date, dayFunc) {
  let start = new Date(date.getFullYear(), date.getMonth())
  let weekday = start.getDay() - 1
  if (weekday < 0) {
    weekday += 7
  }
  let d = delta(start, 0, 0, -weekday)
  for (let row = 0; row < 6; row++) {
    if (
      d.getMonth() > date.getMonth() &&
      d.getFullYear() >= date.getFullYear()
    ) {
      return
    }
    for (let col = 0; col < 7; col++) {
      dayFunc(d, row, col)
      d = delta(d, 0, 0, 1)
    }
  }
}

export function dateID(date) {
  let result = `${date.getFullYear()}-`

  const m = date.getMonth() + 1
  if (m < 10) {
    result += ' '
  }
  result += `${m}-`

  const d = date.getDate()
  if (d < 10) {
    result += ' '
  }
  result += `${d}`

  return result
}
