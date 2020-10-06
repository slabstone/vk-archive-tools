#!/usr/bin/ruby

# frozen_string_literal: true

require 'nokogiri'
require 'http'
require 'colorize'
require_relative 'filename_helpers'

def help
  abort 'usage: <peer-id> [--dry-run] [--print] [--order]
  --dry-run: simulate, do not download
  --print: print links if possible
  --order: prepend sequence number to filename'
end

help if ARGV.empty? || ARGV.include?('--help')

peer_id = ARGV[0]
abort "invalid id: #{peer_id}".red if peer_id.to_i.zero?

print_links = ARGV.include?('--print')
dry_run = ARGV.include?('--dry-run')
order = ARGV.include?('--order')

path_to_archive = 'Archive'
path_to_messages = "#{path_to_archive}/messages"

peer_name = nil
File.open("#{path_to_messages}/index-messages.html") do |file|
  html = Nokogiri::HTML(file)
  html.css('div[class=message-peer--id]').each do |div|
    peer_link = div.css('a').first

    if peer_link['href'].include?(peer_id)
      peer_name = peer_link.text
      break puts "peer name: #{peer_name}"
    end
  end
end
abort "failed to determine peer name for #{peer_id}".red unless peer_name

allowed_attachment_descriptions = ['Фотография']

statistics = {
  downloaded: 0,
  skipped: 0,
  failed: 0
}

path_to_peer = "#{path_to_messages}/#{peer_id}"
Dir.children(path_to_peer).sort_by { |s| filename_to_page(s) }.each do |filename|
  puts "reading page #{filename_to_page(filename)} (messages: #{filename_to_message_numbers(filename)})"
  File.open("#{path_to_peer}/#{filename}") do |file|
    html = Nokogiri::HTML(file)
    html.css('div[class=attachment]').each do |div|
      description = div.css('div[class=attachment__description]').first.text
      link_element = div.css('a[class=attachment__link]')
      link = if link_element.empty?
               nil
             else
               link_element.first['href']
             end

      link_postfix = ": #{link}" if link && print_links
      unless allowed_attachment_descriptions.include?(description)
        statistics[:skipped] += 1
        next puts "skipping #{description}#{link_postfix}".colorize(link ? :yellow : :red)
      end

      puts "downloading #{description}#{link_postfix}"
      next if dry_run

      begin
        response = HTTP.get(link)
        if response.status.success?
          downloaded_filename = "#{"#{statistics[:downloaded] + 1}_" if order}#{link.split('/').last}"
          download_dir = "download/#{peer_id} #{peer_name}"
          FileUtils.mkdir_p(download_dir)
          File.open("#{download_dir}/#{downloaded_filename}", 'w') do |downloaded_file|
            downloaded_file.write(response.body)
          end
          statistics[:downloaded] += 1
        else
          puts "failed to download: #{link}".red
          statistics[:failed] += 1
        end
      rescue HTTP::Request::UnsupportedSchemeError => e
        puts "failed to download #{link}: #{e}".red
      rescue e
        puts "unknown error: #{e}".red
      end
    end
  end
end

puts "total: #{statistics}"
