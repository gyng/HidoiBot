﻿# Ng Guoyou
# Reminder.rb
# Handles alarm and reminders. These are non-persistent.

require 'time'

class Reminder < BotPlugin
    def initialize
      # Authorisations
      @requiredLevelForOthers = 3
      @requiredLevelForClear = 3

      # Strings
      @noAuthMessage = 'You are not authorised for this.'

      # Required plugin stuff
      name = self.class.name
      @hook = 'remind'
      processEvery = false
      help = "Usage: #{@hook} (clearall|clearrecurring|clearmine|<userOrChannelToRemind|me> about <event> (in|every|at) <time>)\nFunction: Sets or clears reminders. Takes in a relative time for 'in' and 'every' and an absolute time for 'at'. (eg. at 2011-11-11 05:00 or November 5th, 2011, 7:48 pm. Uses Ruby's Time.parse for absolute date-times."
      super(name, @hook, processEvery, help)
    end

    def main(data)
      @givenLevel = data["authLevel"]
      mode = arguments(data)[0]

      case mode
      when 'clearall'
        return checkAuth(@requiredLevelForClear) ? clearReminders(data) : sayf(@noAuthMessage)
      when 'clearrecurring'
        return checkAuth(@requiredLevelForClear) ? clearRecurring(data) : sayf(@noAuthMessage)
      when 'clearmine'
        return clearMyReminders(data)
      else
        return addReminder(data)
      end
    rescue => e
      handleError(e)
      return nil
    end

    def addReminder(data)
      extract = data["message"].split(/(remind | about | in | every | at )/)
      type = 'reminder'
      user = extract[2]
      message = extract[4]
      givenTime = extract[6]

      isRecurring = data["message"].split(/(#{user}|about| #{message} | #{givenTime})/)[6]

      # Making time given relative
      if isRecurring == 'every' || isRecurring == 'in'
        parsedTime = Time.now.to_i + Time.at(parseRemindTime(givenTime)).to_i
      elsif isRecurring == 'at'
        parsedTime = Time.parse(givenTime)
      end

      # Checking for type
      if isRecurring == 'every'
        occurrence = 'recurring'
        occurrenceOffset = parsedTimeRelative
      elsif isRecurring == 'in'
        occurrence = 'single'
        occurrenceOffset = 0
      elsif isRecurring == 'at'
        occurrence = 'single'
        occurrenceOffset = 0
      end

      # Checking for authorisation
      if user == 'me' || user == data['sender'] && occurrence != 'recurring'
        # No auth required for single event for self
        data["origin"].addEvent(data['sender'], type, parsedTime.to_i, occurrence, occurrenceOffset, message)
        return sayf('Reminder added.')

      elsif checkAuth(@requiredLevelForOthers)
        # Auth required for single/recurring event for other people
        data["origin"].addEvent(user, type, parsedTime.to_i, occurrence, occurrenceOffset, message)
        return sayf('Reminder added.')

      elsif !checkAuth(@requiredLevelForOthers)
        return sayf(@noAuthMessage)
      end
    rescue => e
      handleError(e)
      return sayf("Error in addReminder: Check console for details.")
    end

    def clearRecurring(data)
      data["origin"].deleteEventOccurrence('recurring')
      return sayf('Clearing recurring events.')
    end

    def clearReminders(data)
      data["origin"].deleteEventType('reminder')
      return sayf('Clearing all reminders.')
    end

    def clearMyReminders(data)
      data["origin"].deleteReminderUser(data["sender"])
      return sayf('Clearing your reminders.')
    end

    # Consider chronic gem for relative time parsing
    def parseRemindTime(time)
      timeUnit = time[/[a-z]+$/i]
      timeDigit = time[/[0-9\.]+/]

      if timeUnit.match(/(^s$|seconds?|secs?)/)
      elsif timeUnit.match(/(m|minutes?|mins?)/)
        timeDigit = timeDigit.to_f * 60
      elsif timeUnit.match(/(h|hrs?|hours?)/)
        timeDigit = timeDigit.to_f * 60 * 60
      elsif timeUnit.match(/(d|days?)/)
        timeDigit = timeDigit.to_f * 24 * 60 * 60
      end

    remindTime = timeDigit.to_i

    return remindTime
  end
end