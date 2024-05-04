require 'progressbar'
require 'colorize'
require 'faker'
require 'faker/default/company'

range = ('AAAA'..'ZZZZ') # 456976 records
progressbar = ProgressBar.create(
  total: range.count,
  format: "%a %e %P% %b#{"\u{15E7}".yellow}%i RateOfChange: %r Processed: %c from %C",
  progress_mark: ' ',
  remainder_mark: "\u{FF65}".light_green
)

range.each_slice(10_000) do |symbols|
  companies = []

  symbols.each do |symbol|
    name = Faker::Company.unique.name
    exchange = "#{rand(0.00..100.00).round(2)}%"
    description = Faker::Company.bs

    companies << { name:, exchange:, symbol:, description: }

    progressbar.increment
  end

  Company.insert_all(companies)
end

Company.create!(name: 'Melbourne', exchange: '1.00%', symbol: 'MELBS',
                         description: 'the weather in Melbourne is known for its variability as well as predictability')
Company.create!(name: 'Auckland', exchange: '0.10%', symbol: 'AUCKL',
                         description: 'the variable weather in Auckland is not as predictable as in Melbourne')
