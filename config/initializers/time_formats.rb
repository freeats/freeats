# frozen_string_literal: true

Time::DATE_FORMATS[:date] = "%d.%m.%Y" # DD.MM.YYYY
Date::DATE_FORMATS[:date] = "%d.%m.%Y" # DD.MM.YYYY
Time::DATE_FORMATS[:monthyear] = "%m.%Y" # MM.YYYY
Date::DATE_FORMATS[:monthyear] = "%m.%Y" # MM.YYYY
Time::DATE_FORMATS[:daymonth] = "%d.%m" # DD.MM
Date::DATE_FORMATS[:daymonth] = "%d.%m" # DD.MM
Time::DATE_FORMATS[:datetime] = "%d.%m.%Y %H:%M" # DD.MM.YYYY HH:MM
Time::DATE_FORMATS[:datetime_full] = "%d.%m.%Y %H:%M" # DD.MM.YYYY HH:MM
Time::DATE_FORMATS[:time] = "%H:%M" # HH:MM
Time::DATE_FORMATS[:human_date] = "%b %-d" # Jun 3
Date::DATE_FORMATS[:human_date] = "%b %-d" # Jun 3
Time::DATE_FORMATS[:datetime_pretty] = "%A %b %d %Y at %H:%M GMT%:::z" # Friday Dec 23 2022 at 11:49 GMT+03
