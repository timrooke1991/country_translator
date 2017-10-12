require 'open-uri'
require 'nokogiri'
require 'csv'
require 'mechanize'
require 'logger'
require 'io/console'

mechanize = Mechanize.new

puts "Please supply a list of languages: (e.g. German, Spanish)"
languages = gets.chomp

required_languages = languages.split(',').map { |country|
  country.strip.capitalize
}

countries = []
store_languages = {}
urls = [
  'wiki/List_of_country_names_in_various_languages_(A%E2%80%93C)',
  'wiki/List_of_country_names_in_various_languages_(D%E2%80%93I)',
  'wiki/List_of_country_names_in_various_languages_(J%E2%80%93P)',
  'wiki/List_of_country_names_in_various_languages_(Q%E2%80%93Z)'
]

required_languages.each_with_index do |country|
  store_languages.merge!("#{country.downcase}": [])
end

urls.each do |url|
  ### Need to create a new variable with the county names
  page = mechanize.get("https://en.wikipedia.org/#{url}")
  index = 0

  rows_total = page.css('table tr').length

  while index < rows_total do
    country = page.css('table tr')[index]

    if country.css('td').length === 2
      name = country.css('td a')[0].text

      if name === ''
        name = country.css('td').text
        if name === ''
          countries << name
        else
          countries << 'not found'
        end
      else
        countries << name
      end

      required_languages.each do |c|
        translations = country.css('td')[1].to_s
        arr = translations.split('),').select {|e| e.include? c }
        value = c.downcase
        begin
          if !arr.empty?
            translated_name = arr.to_s.scan(/<([A-z0-9]*)\b[^>]*>(.*?)<\/\1>/)[-1][-1]
            store_languages[value.to_sym] << translated_name
          else
            store_languages[value.to_sym] << 'not found'
          end
        rescue
          store_languages[value.to_sym] << 'not found'
        end
      end
    end
    index += 1
  end
end

puts "Creating .csv file"
time = Time.now.strftime('%Y-%m-%d_%H-%M-%S')

CSV.open("#{time}_countries.csv", "wb") do |file|
	# Column Titles
  row_headings = store_languages.keys.map { |key| "#{key.capitalize}" }
  file << row_headings.unshift("Countries")

	countries.length.times do |i|
    # add row
    row = []
    store_languages.keys.each do |key|
      row << store_languages[key.to_sym][i]
    end
		file << row.unshift(countries[i])
	end
end
