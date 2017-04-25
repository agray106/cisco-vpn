#!/usr/bin/env ruby

# to run this as a cron job use the following:
# * * * * * /bin/bash -l -c 'ruby <path to ruby script>'

require 'date'
require 'net/smtp'

str_yestrdy = (Date.today - 1)
ary_yestrdy = (Date.today - 1).to_s.split('-')
from = 'from_address'
to = 'to_address'
subject = "*** VPN User Report #{str_yestrdy} ***"

message = <<MESSAGE_END
From: #{from}
To: #{to}
Subject: #{subject}
Mime-Version: 1.0
Content-Type: text/html
Content-Disposition: inline
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
  text-align: left;
}
table tr:nth-child(even) {
  background-color: #eee;
}
table tr:nth-child(odd) {
  background-color: #fff;
}
</style>
<table style="width:100%">
  <caption>VPN User Usage #{str_yestrdy}</caption>
  <tr>
    <th>User</th>
    <th>Duration</th>
    <th>Disconnect Time</th>
    <th>Source IP</th>
    <th>Reason for Disconnect</th>
  </tr>
</table>
MESSAGE_END

File.open("/var/log/device/#{ary_yestrdy[0]}/#{ary_yestrdy[1]}/\
device-#{str_yestrdy}.log", 'r') do |f|
  f.each_line do |line|
    @regex = (/(^.*)%(ASA-4-113019)(.*)/i)
    next unless line.match(@regex)
    # Create array from string
    ma = line.split(',')
    next if (ma[2].split(' ')[2].include?("ip_to_exclude") || ma[2].split(' ')[2].include?("ip_to_exclude"))
    dt=ma[0].split(' ')[0]
    message.insert(-11, "  <tr><th>#{ma[1]}<\/th><th>#{ma[4]}<\/th>\
      <th>#{dt[11..18]}<\/th><th>#{ma[2]}<\/th>\
      <th>#{ma[7].chomp}<\/th><\/tr>\n")
  end
end

Net::SMTP.start('smtp_server') do |smtp|
  smtp.send_message message, from, to
end
