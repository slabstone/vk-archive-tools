#!/usr/bin/ruby

# frozen_string_literal: true

require 'nokogiri'
require 'http'
require 'colorize'
require_relative 'filename_helpers'

def help
  abort 'usage: <peer-id>'
end

help if ARGV.empty? || ARGV.include?('--help')

peer_id = ARGV[0]
abort "invalid id: #{peer_id}".red if peer_id.to_i.zero?

path_to_archive = 'Archive'
path_to_messages = "#{path_to_archive}/messages"

File.open("#{path_to_messages}/index-messages.html") do |file|
  html = Nokogiri::HTML(file)
  html.css('div[class=message-peer--id]').each do |div|
    peer_link = div.css('a').first
    break puts "peer name: #{peer_link.text}" if peer_link['href'].include?(peer_id)
  end
end

allowed_attachment_descriptions = ['Фотография']

path_to_peer = "#{path_to_messages}/#{peer_id}"
Dir.children(path_to_peer).sort_by { |s| filename_to_page(s) }.each do |filename|
  puts "reading page #{filename_to_page(filename)} (messages: #{filename_to_message_numbers(filename)})"
  File.open("#{path_to_peer}/#{filename}") do |file|
    html = Nokogiri::HTML(file)
    html.css('div[class=attachment]').each do |div|
      description = div.css('div[class=attachment__description]')[0].text
      next puts "skipping #{description}".yellow unless allowed_attachment_descriptions.include?(description)

      link = div.css('a[class=attachment__link]')[0]['href']

      puts "downloading #{description}"
      response = HTTP.get(link)
      if response.status.success?
        downloaded_filename = link.split('/').last
        download_dir = "download/#{peer_id}"
        FileUtils.mkdir_p(download_dir)
        File.open("#{download_dir}/#{downloaded_filename}", 'w') do |downloaded_file|
          downloaded_file.write(response.body)
        end
      else
        puts "failed to download: #{link}".red
      end
    end
  end
end
