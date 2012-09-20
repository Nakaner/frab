class Availability < ActiveRecord::Base

  belongs_to :person
  belongs_to :conference

  validate :start_time_before_end_time
  after_save :update_event_conflicts

  def self.build_for(conference)
    result = Array.new
    conference.each_day do |date|
      result << self.new(
        :day => date,
        :start_time => "%02d:00:00" % conference.day_start,
        :end_time => "%02d:00:00" % conference.day_end,
        :conference => conference
      )
    end
    result
  end

  def time_range
    "#{self.start_time.hour}-#{self.end_time.hour}"
  end

  def fix_hour_range(h)
    if h.to_i<0
      "0"
    elsif h.to_i>=24
      "23"
    else
      h
    end
  end

  def time_range=(new_range) 
    unless new_range.blank?
      if new_range.starts_with?("-")
        new_range = "0-0"
      end
      from, to = new_range.split("-")
      self.start_time = fix_hour_range(from)
      self.end_time = fix_hour_range(to)
    end
  end

  def within_range?(time)
    if self.conference.timezone and time.zone != self.conference.timezone
      time = time.in_time_zone(self.conference.timezone)
    end
    start_minutes = time_in_minutes(self.start_time)
    end_minutes = time_in_minutes(self.end_time)
    test_minutes = time_in_minutes(time)
    start_minutes <= test_minutes and end_minutes >= test_minutes
  end

  private

  def time_in_minutes(time)
    time.hour * 60 + time.min
  end

  def update_event_conflicts
    self.person.events_in(self.conference).each do |event|
      event.update_conflicts if event.start_time and event.start_time.to_date == self.day
    end
  end
  
  def start_time_before_end_time
    self.errors.add(:end_time, "should be after start time") if self.end_time < self.start_time
  end

end
