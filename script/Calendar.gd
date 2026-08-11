extends Node

## Counts the days of the world and names them.
##
## Time is turn-based: every step the player takes on a map costs one day
## (see [method Global.entity_entered_cell]). This node turns that single
## count into a date — weeks, months, seasons, years — and announces every
## boundary it crosses, so tiles holding events and NPCs can react to the
## passing of time by connecting to the signals below.
##
## Only [member days_passed] is state; everything else is derived from it.
## The save keeps that one number.

## A day of the month passed. Fires on every change of [member days_passed],
## with the new [method day_of_month].
signal day_changed(day : int)

## A week boundary was crossed. Carries the new [method week_of_month].
signal week_changed(week : int)

## A month boundary was crossed. Carries the new [method month_of_year].
signal month_changed(month : int)

## A season boundary was crossed. Carries the new [method season_name].
signal season_changed(season : String)

## A year boundary was crossed. Carries the new [method year].
signal year_changed(year : int)

## The season names, in the order they pass. A year opens on the first.
const SEASONS : Array[String] = ["Follia", "Grash", "Fatigue", "Bloom"]

const DAYS_PER_WEEK		:= 6
const WEEKS_PER_MONTH	:= 4
const MONTHS_PER_SEASON	:= 4
const SEASONS_PER_YEAR	:= 4

const DAYS_PER_MONTH	:= DAYS_PER_WEEK * WEEKS_PER_MONTH
const DAYS_PER_SEASON	:= DAYS_PER_MONTH * MONTHS_PER_SEASON
const DAYS_PER_YEAR		:= DAYS_PER_SEASON * SEASONS_PER_YEAR

## Whole days since the very first morning of the game. Setting it announces
## every calendar boundary between the old date and the new one, so it is safe
## to assign directly — loading a save does exactly that.
var	days_passed : int = 0 :
	set(value):
		var previous := days_passed
		days_passed = maxi(value, 0)
		if days_passed != previous:
			_announce(previous)


## Moves the world one day forward. Called once per player step.
func	advance_day() -> void:
	days_passed += 1


## Day inside the current month, counted 1 to [constant DAYS_PER_MONTH].
func	day_of_month() -> int:
	return days_passed % DAYS_PER_MONTH + 1


## Week inside the current month, counted 1 to [constant WEEKS_PER_MONTH].
func	week_of_month() -> int:
	@warning_ignore("integer_division")
	return days_passed % DAYS_PER_MONTH / DAYS_PER_WEEK + 1


## Month inside the current year, counted 1 to 16 — months run across the
## seasons, four to each.
func	month_of_year() -> int:
	@warning_ignore("integer_division")
	return days_passed % DAYS_PER_YEAR / DAYS_PER_MONTH + 1


## Name of the current season.
func	season_name() -> String:
	@warning_ignore("integer_division")
	return SEASONS[days_passed / DAYS_PER_SEASON % SEASONS_PER_YEAR]


## The current year, counted from 1.
func	year() -> int:
	@warning_ignore("integer_division")
	return days_passed / DAYS_PER_YEAR + 1


## The date as the waila writes it: "d,m, Season of year y".
func	date_text() -> String:
	return "%d,%d, %s of year %d" % [day_of_month(), month_of_year(), season_name(), year()]


## Emits a signal for every calendar unit that ticked over between
## [param previous] and the current [member days_passed]. Boundaries are
## compared on the absolute count, so jumping several days — or backwards,
## as a save load can — still announces each unit exactly once.
func	_announce(previous : int) -> void:
	day_changed.emit(day_of_month())
	@warning_ignore_start("integer_division")
	if previous / DAYS_PER_WEEK != days_passed / DAYS_PER_WEEK:
		week_changed.emit(week_of_month())
	if previous / DAYS_PER_MONTH != days_passed / DAYS_PER_MONTH:
		month_changed.emit(month_of_year())
	if previous / DAYS_PER_SEASON != days_passed / DAYS_PER_SEASON:
		season_changed.emit(season_name())
	if previous / DAYS_PER_YEAR != days_passed / DAYS_PER_YEAR:
		year_changed.emit(year())
	@warning_ignore_restore("integer_division")
