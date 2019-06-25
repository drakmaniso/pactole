'use strict'

export function date(year, month, day) {
  return (
    String(year).padStart(4, '0') +
    '-' +
    String(month).padStart(2, 0) +
    '-' +
    String(day).padStart(2, 0)
  )
}

export function today() {
  const d = new Date()
  return date(d.getFullYear(), d.getMonth() + 1, d.getDate())
}

export const dayNames = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
]

export const monthNames = [
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

export function day(date) {
  return Number(date.slice(8, 10))
}

export function weekday(date) {
  const d = new Date(year(date), month(date) - 1, day(date))
  return d.getDay()
}

export function weekdayName(date) {
  let w = weekday(date) - 1
  if (w < 0) {
    w += 7
  }
  return dayNames[w]
}

export function month(date) {
  return Number(date.slice(5, 7))
}

export function monthName(date) {
  return monthNames[month(date) - 1]
}

export function year(date) {
  return Number(date.slice(0, 4))
}

export function delta(startDate, deltaYear, deltaMonth, deltaDay) {
  const d = new Date(
    year(startDate) + deltaYear,
    month(startDate) - 1 + deltaMonth,
    day(startDate) + deltaDay,
  )
  return date(d.getFullYear(), d.getMonth() + 1, d.getDate())
}

export function grid(monthDate, dayFunc) {
  let start = date(year(monthDate), month(monthDate), 1)
  let wd = weekday(start) - 1
  if (wd < 0) {
    wd += 7
  }
  let d = delta(start, 0, 0, -wd)
  for (let row = 0; row < 6; row++) {
    if (month(d) > month(start) && year(d) >= year(start)) {
      return
    }
    for (let col = 0; col < 7; col++) {
      dayFunc(d, row, col)
      d = delta(d, 0, 0, 1)
    }
  }
}
