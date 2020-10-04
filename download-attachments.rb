#!/usr/bin/ruby

# frozen_string_literal: true

require 'nokogiri'
require 'http'
require 'colorize'

def help
  abort 'usage: <peer-id>'
end

help if ARGV.empty? || ARGV.include?('--help')

peer_id = ARGV[0]
abort "invalid id: #{peer_id}".red if peer_id.to_i.zero?

input_encoding = 'Windows-1251'
output_encoding = 'UTF-8'
allowed_attachment_descriptions = ['Фотография']

puts "reading peer id: #{peer_id}"
path_to_archive = "Archive/messages/#{peer_id}"
Dir.children(path_to_archive).sort_by { |s| s.scan(/\d+/).first.to_i }.each do |filename|
  puts "reading file: #{filename}"
  File.open("#{path_to_archive}/#{filename}") do |file|
    html = Nokogiri::HTML(file)
    name = html.xpath('//div[@class="ui_crumb"]/text()').to_s.force_encoding(input_encoding).encode(output_encoding)
    puts "peer: #{name}"

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
